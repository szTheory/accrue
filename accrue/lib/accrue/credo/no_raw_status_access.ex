defmodule Accrue.Credo.NoRawStatusAccess do
  @moduledoc """
  Custom Credo check that enforces BILL-05 at lint time: never gate
  feature access on raw `subscription.status` comparisons.

  Phase 3 exposes a small set of predicates on
  `Accrue.Billing.Subscription` (`active?/1`, `canceling?/1`,
  `canceled?/1`, `past_due?/1`, `paused?/1`, `trialing?/1`) and query
  fragments on `Accrue.Billing.Query`. These are the only sanctioned
  ways to ask "does this subscription entitle its owner to X?" — they
  encode invariants (`:active` unioned with `:trialing`, grace-period
  windows, pause states) that are too easy to get wrong when the
  comparison is spelled out by hand.

  This check flags the following AST shapes when they occur OUTSIDE
  `Accrue.Billing.Subscription`:

    * `expr.status == <any>` — direct equality on a `.status` field
    * `expr.status in <any>` — membership check on a `.status` field
    * `<any> == :active | :trialing | :past_due | :canceled | ...`
      — equality against a Stripe status atom from either side

  Violators should either call a predicate or add a new one — resist
  the urge to suppress this check.
  """

  use Credo.Check,
    base_priority: :high,
    category: :warning,
    explanations: [
      check: """
      Never gate features on raw subscription.status. Use
      `Accrue.Billing.Subscription` predicates (`active?/1`,
      `canceling?/1`, `canceled?/1`, `past_due?/1`, `paused?/1`,
      `trialing?/1`) or `Accrue.Billing.Query` fragments. Enforces
      BILL-05.
      """
    ]

  @stripe_statuses ~w(trialing active past_due canceled unpaid incomplete incomplete_expired paused)a

  @exempt_module_prefixes ["Accrue.Billing.Subscription", "Accrue.Billing.Query"]

  @impl true
  def run(%SourceFile{filename: filename} = source_file, params) do
    if exempt_file?(filename) do
      []
    else
      issue_meta = IssueMeta.for(source_file, params)
      ast = SourceFile.ast(source_file)

      {_ast, {issues, _stack}} =
        Macro.traverse(
          ast,
          {[], []},
          &pre_traverse(&1, &2, issue_meta),
          &post_traverse/2
        )

      issues
    end
  end

  # Test files under `test/` are exempt — tests construct Stripe status
  # payloads and assert on them directly; predicates don't apply.
  #
  # WR-06: tightened to `test/**` only. The previous `contains?("/test/")`
  # matcher inadvertently exempted production modules like
  # `lib/accrue/test/factory.ex` and `lib/accrue/test/generators.ex`.
  defp exempt_file?(nil), do: false

  defp exempt_file?(filename) when is_binary(filename) do
    String.starts_with?(filename, "test/") or
      String.contains?(filename, "/test/accrue/") or
      String.contains?(filename, "/test/support/") or
      Path.basename(Path.dirname(filename)) == "test"
  end

  # Track defmodule nesting so we can exempt Accrue.Billing.Subscription.
  defp pre_traverse(
         {:defmodule, _meta, [{:__aliases__, _, name_parts}, _body]} = node,
         {issues, stack},
         _issue_meta
       ) do
    current = Enum.map_join(name_parts, ".", &Atom.to_string/1)
    {node, {issues, [current | stack]}}
  end

  defp pre_traverse(node, {issues, stack} = acc, issue_meta) do
    if exempt?(stack) do
      {node, acc}
    else
      case check_node(node, issue_meta) do
        nil -> {node, acc}
        issue -> {node, {[issue | issues], stack}}
      end
    end
  end

  defp post_traverse({:defmodule, _meta, _} = node, {issues, [_top | rest]}) do
    {node, {issues, rest}}
  end

  defp post_traverse(node, acc), do: {node, acc}

  defp exempt?([]), do: false

  defp exempt?([current | _rest]) do
    Enum.any?(@exempt_module_prefixes, fn prefix ->
      current == prefix or String.starts_with?(current, prefix <> ".")
    end)
  end

  # sub.status == :active | :trialing | ...
  defp check_node(
         {:==, meta, [{{:., _, [_, :status]}, _, _}, rhs]},
         issue_meta
       )
       when rhs in @stripe_statuses do
    issue_for(issue_meta, line_of(meta), "== on .status")
  end

  # :active | :trialing | ... == sub.status
  defp check_node(
         {:==, meta, [lhs, {{:., _, [_, :status]}, _, _}]},
         issue_meta
       )
       when lhs in @stripe_statuses do
    issue_for(issue_meta, line_of(meta), "== on .status")
  end

  # WR-06: `sub.status != :active | :trialing | ...` — same shape as
  # `==` but for the inequality operator.
  defp check_node(
         {:!=, meta, [{{:., _, [_, :status]}, _, _}, rhs]},
         issue_meta
       )
       when rhs in @stripe_statuses do
    issue_for(issue_meta, line_of(meta), "!= on .status")
  end

  defp check_node(
         {:!=, meta, [lhs, {{:., _, [_, :status]}, _, _}]},
         issue_meta
       )
       when lhs in @stripe_statuses do
    issue_for(issue_meta, line_of(meta), "!= on .status")
  end

  # WR-06: string-status equality (e.g. `charge.status == "succeeded"`).
  # Charge.status is `:string`, not an enum; the same BILL-05 invariant
  # applies — use a predicate, not a raw comparison.
  @string_statuses ~w(trialing active past_due canceled unpaid incomplete incomplete_expired paused succeeded failed pending)

  defp check_node(
         {:==, meta, [{{:., _, [_, :status]}, _, _}, rhs]},
         issue_meta
       )
       when is_binary(rhs) and rhs in @string_statuses do
    issue_for(issue_meta, line_of(meta), "== on .status (string)")
  end

  defp check_node(
         {:==, meta, [lhs, {{:., _, [_, :status]}, _, _}]},
         issue_meta
       )
       when is_binary(lhs) and lhs in @string_statuses do
    issue_for(issue_meta, line_of(meta), "== on .status (string)")
  end

  # sub.status in [:active, :trialing, ...] — flag only if any element of
  # the RHS list is a Stripe status atom.
  defp check_node(
         {:in, meta, [{{:., _, [_, :status]}, _, _}, rhs]},
         issue_meta
       ) do
    if list_contains_stripe_status?(rhs) do
      issue_for(issue_meta, line_of(meta), "in on .status")
    end
  end

  defp check_node(_node, _issue_meta), do: nil

  defp list_contains_stripe_status?(list) when is_list(list) do
    Enum.any?(list, &(&1 in @stripe_statuses))
  end

  defp list_contains_stripe_status?(_), do: false

  defp line_of(meta), do: Keyword.get(meta, :line, 0)

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message:
        "Raw subscription.status access (#{trigger}); use " <>
          "Accrue.Billing.Subscription predicates or Accrue.Billing.Query fragments (BILL-05)",
      line_no: line_no
    )
  end
end
