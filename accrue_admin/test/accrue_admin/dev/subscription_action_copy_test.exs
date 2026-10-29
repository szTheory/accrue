Code.require_file(Path.expand("../../../../dev_support/phase252_tap_formatter.ex", __DIR__))

if System.get_env("PHASE252_TAP_REPORT") == "1" do
  ExUnit.start(formatters: [Accrue.Test.Phase252TapFormatter])
else
  ExUnit.start()
end

unless Code.ensure_loaded?(CadenceSubscriptionFacts) do
  Code.require_file(
    Path.expand("../../../../dev_support/ui_scenarios/cadence_subscriptions.exs", __DIR__)
  )
end

defmodule AccrueAdmin.SubscriptionActionCopyTest do
  @moduledoc """
  Phase 254 DR-254-05: the action-result link label and its scoped activity path have one owner each
  (`AccrueAdmin.Copy.subscription_action_activity_link_label/0` and
  `AccrueAdmin.Live.SubscriptionLive.action_activity_path/3`), and the mounted LiveView and the
  Storybook page adapter both call them instead of repeating the literal and the path construction.

  Every test name starts with the finding id so the red evidence (`--record-red --format exunit`)
  can key the failures. Until the owners exist, the owner functions are reached through
  `owner_exported?/3` guards so the module compiles and each test fails on its own assertion.
  """

  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias AccrueAdmin.Copy
  alias AccrueAdmin.Live.SubscriptionLive
  alias AccrueAdmin.Storybook.SubscriptionPageScenarios

  @label_text "Open scoped subscription activity"
  @repo_root Path.expand("../../../..", __DIR__)
  @scanned_paths ["accrue_admin/lib", "accrue_admin/storybook/_support"]
  @label_owner_file "accrue_admin/lib/accrue_admin/copy.ex"

  setup do
    {:ok, _started} = Application.ensure_all_started(:localize)
    Application.put_env(:localize, :default_locale, :en)
    :ok
  end

  test "DR-254-05 label owner: Copy owns the result link label and the story result uses it" do
    assert owner_exported?(Copy, :subscription_action_activity_link_label, 0) == true

    label = apply(Copy, :subscription_action_activity_link_label, [])
    assert label == @label_text

    for snapshot <- [:result_confirmed, :result_pending, :result_failed] do
      assigns =
        SubscriptionPageScenarios.assigns!(
          SubscriptionPageScenarios.attributes(:active, snapshot)
        )

      assert assigns.action_result.link_label == label
    end
  end

  test "DR-254-05 href owner: SubscriptionLive owns the scoped activity path and the story result uses it" do
    assert owner_exported?(SubscriptionLive, :action_activity_path, 3) == true

    for snapshot <- [:result_confirmed, :result_pending, :result_failed] do
      assigns =
        SubscriptionPageScenarios.assigns!(
          SubscriptionPageScenarios.attributes(:active, snapshot)
        )

      href =
        apply(SubscriptionLive, :action_activity_path, [
          assigns.admin_mount_path,
          assigns.current_owner_scope,
          assigns.subscription.id
        ])

      assert assigns.action_result.href == href
    end

    assigns =
      SubscriptionPageScenarios.assigns!(
        SubscriptionPageScenarios.attributes(:active, :result_pending)
      )

    assert apply(SubscriptionLive, :action_activity_path, [
             assigns.admin_mount_path,
             assigns.current_owner_scope,
             assigns.subscription.id
           ]) ==
             "/billing/events?org=cadence-demo&subject_id=ea26f232-b276-42bb-b862-d5c1b7d9d457&subject_type=Subscription"
  end

  test "DR-254-05 rendered result: the routed page renders the owner label and href in the result region" do
    assert owner_exported?(Copy, :subscription_action_activity_link_label, 0) == true
    assert owner_exported?(SubscriptionLive, :action_activity_path, 3) == true

    label = apply(Copy, :subscription_action_activity_link_label, [])

    for snapshot <- [:result_confirmed, :result_pending, :result_failed] do
      assigns =
        SubscriptionPageScenarios.assigns!(
          SubscriptionPageScenarios.attributes(:active, snapshot)
        )

      href =
        apply(SubscriptionLive, :action_activity_path, [
          assigns.admin_mount_path,
          assigns.current_owner_scope,
          assigns.subscription.id
        ])

      document =
        (&SubscriptionLive.render/1)
        |> render_component(assigns)
        |> Floki.parse_document!()

      [link] = Floki.find(document, "[data-role='subscription-action-result'] a")
      assert Floki.text(link) |> String.trim() == label
      assert Floki.attribute(link, "href") == [href]
    end
  end

  test "DR-254-05 production callers: the LiveView and the story adapter call both owners and keep no copy of either" do
    live = repo_file!("accrue_admin/lib/accrue_admin/live/subscription_live.ex")
    adapter = repo_file!("accrue_admin/storybook/_support/subscription_page_scenarios.ex")

    label_call = "Copy.subscription_action_activity_link_label()"

    assert String.contains?(live, label_call) == true
    assert String.contains?(adapter, label_call) == true

    assert Regex.match?(
             ~r/def action_activity_path\(admin_mount_path, owner_scope, subscription_id\)/,
             live
           ) == true

    assert Regex.match?(~r/action_activity_path\(\s*page\.admin_mount_path/, adapter) == true

    # The adapter builds no events path of its own any more.
    own_path_construction = ~S|ScopedPath.build(page.admin_mount_path, "/events"|
    assert String.contains?(adapter, own_path_construction) == false
  end

  test "DR-254-05 literal guard: the label string exists in copy.ex only, and the scan is shown able to find a seeded copy" do
    scratch = make_scratch_repo!()

    try do
      File.mkdir_p!(Path.join(scratch, "accrue_admin/lib"))

      File.write!(
        Path.join(scratch, "accrue_admin/lib/seeded.ex"),
        ~s(def l, do: "#{@label_text}"\n)
      )

      git!(scratch, ["add", "accrue_admin/lib/seeded.ex"])

      # Positive control: the very same scan finds the seeded occurrence.
      assert label_occurrences(scratch, @label_text) == [{"accrue_admin/lib/seeded.ex", 1}]
    after
      File.rm_rf!(scratch)
    end

    assert label_occurrences(@repo_root, @label_text) == [{@label_owner_file, 1}]
  end

  # -- helpers ------------------------------------------------------------------------------

  defp owner_exported?(module, function, arity) do
    Code.ensure_loaded?(module) and function_exported?(module, function, arity)
  end

  defp repo_file!(relative), do: File.read!(Path.join(@repo_root, relative))

  # `git grep -c -e <pattern> -- <paths>`: the pattern is always introduced by -e, never placed
  # after `--` (where git would read it as a pathspec and report nothing).
  defp label_occurrences(root, label) do
    {output, status} =
      System.cmd("git", ["-C", root, "grep", "-c", "-F", "-e", label, "--" | @scanned_paths],
        stderr_to_stdout: true
      )

    # git grep exits 1 when nothing matches; any other non-zero status is an error.
    assert status in [0, 1], "git grep failed: #{output}"

    output
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      [_, path, count] = Regex.run(~r/^(.+):(\d+)$/, line)
      {path, String.to_integer(count)}
    end)
    |> Enum.sort()
  end

  defp make_scratch_repo! do
    dir =
      Path.join(System.tmp_dir!(), "phase254-copy-guard-#{System.unique_integer([:positive])}")

    File.mkdir_p!(dir)
    git!(dir, ["init", "--quiet"])
    dir
  end

  defp git!(dir, args) do
    {output, status} = System.cmd("git", ["-C", dir | args], stderr_to_stdout: true)
    assert status == 0, "git #{Enum.join(args, " ")} failed: #{output}"
    output
  end
end
