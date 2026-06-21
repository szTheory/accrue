defmodule AccrueAdmin.DataTableNavTest do
  @moduledoc """
  Regression guard for the org-scope double-`?` corruption blocker (260621-io6).

  `DataTableNav.patch_with_filters/3` MUST merge filter params into the table
  path's existing query (which carries `?org=<slug>` in organization mode) rather
  than naively appending a second `?`. A `"/billing/customers?org=acme?q=foo"`
  URL drops the org param and breaks owner-scoping on every apply/change/clear.
  """

  use ExUnit.Case, async: true

  alias AccrueAdmin.DataTableNav

  describe "merge_query/2 (the merge contract)" do
    test "merges filter params into an org-scoped path with exactly one '?'" do
      result = DataTableNav.merge_query("/billing/customers?org=acme", %{"q" => "foo"})

      # Exactly one query separator — no /customers?org=acme?q=foo corruption.
      assert query_separator_count(result) == 1
      assert result =~ "org=acme"
      assert result =~ "q=foo"

      # And it decodes back to both params (order-independent).
      assert %{"org" => "acme", "q" => "foo"} = decoded_query(result)
    end

    test "drops blank and nil param values from the merged query" do
      result =
        DataTableNav.merge_query("/billing/customers?org=acme", %{
          "q" => "foo",
          "owner_type" => "",
          "has_default_payment_method" => nil,
          "whitespace" => "   "
        })

      decoded = decoded_query(result)
      assert decoded == %{"org" => "acme", "q" => "foo"}
      refute Map.has_key?(decoded, "owner_type")
      refute Map.has_key?(decoded, "has_default_payment_method")
      refute Map.has_key?(decoded, "whitespace")
    end

    test "only-blank params against an org-scoped path yield the org-only path (no trailing ?)" do
      result =
        DataTableNav.merge_query("/billing/customers?org=acme", %{
          "q" => "",
          "owner_type" => nil
        })

      assert result == "/billing/customers?org=acme"
      assert query_separator_count(result) == 1
    end

    test "real params against a query-less path yield a single '?query'" do
      result = DataTableNav.merge_query("/billing/customers", %{"q" => "foo"})

      assert query_separator_count(result) == 1
      assert result == "/billing/customers?q=foo"
    end

    test "an empty merge against a query-less path leaves no trailing '?'" do
      result = DataTableNav.merge_query("/billing/customers", %{"q" => ""})

      assert result == "/billing/customers"
      refute String.contains?(result, "?")
    end

    test "filter params win over pre-existing query keys they set, org survives" do
      result =
        DataTableNav.merge_query("/billing/customers?org=acme&q=stale", %{"q" => "fresh"})

      assert %{"org" => "acme", "q" => "fresh"} = decoded_query(result)
      assert query_separator_count(result) == 1
    end
  end

  describe "patch_with_filters/3 (the socket push_patch)" do
    test "push_patches the merged path onto the socket" do
      socket = %Phoenix.LiveView.Socket{}

      patched =
        DataTableNav.patch_with_filters(socket, "/billing/customers?org=acme", %{"q" => "foo"})

      assert {:live, :patch, %{to: to}} = patched.redirected
      assert query_separator_count(to) == 1
      assert %{"org" => "acme", "q" => "foo"} = decoded_query(to)
    end
  end

  defp query_separator_count(url), do: url |> String.graphemes() |> Enum.count(&(&1 == "?"))

  defp decoded_query(url) do
    %URI{query: query} = URI.parse(url)
    URI.decode_query(query || "")
  end
end
