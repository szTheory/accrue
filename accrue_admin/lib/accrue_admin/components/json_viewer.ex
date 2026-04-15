defmodule AccrueAdmin.Components.JsonViewer do
  @moduledoc """
  Shared escaped payload viewer with tree, raw, and copy surfaces.
  """

  use Phoenix.Component

  attr(:id, :string, required: true)
  attr(:payload, :any, required: true)
  attr(:active_tab, :string, default: "tree")
  attr(:label, :string, default: "Payload")
  attr(:max_depth, :integer, default: 8)

  def json_viewer(assigns) do
    normalized = normalize_payload(assigns.payload)
    raw_json = Jason.encode_to_iodata!(normalized, pretty: true) |> IO.iodata_to_binary()

    assigns =
      assigns
      |> assign(:normalized_payload, normalized)
      |> assign(:raw_json, raw_json)
      |> assign(:active_tab, normalize_tab(assigns.active_tab))

    ~H"""
    <section id={@id} class="ax-card ax-json-viewer" aria-label={@label}>
      <header class="ax-json-viewer-header">
        <div>
          <p class="ax-eyebrow">Payload</p>
          <h3 class="ax-heading"><%= @label %></h3>
        </div>

        <nav class="ax-tabs" aria-label="Payload views">
          <button
            :for={tab <- ["tree", "raw", "copy"]}
            type="button"
            class={["ax-tab", @active_tab == tab && "ax-tab-active"]}
            aria-current={if(@active_tab == tab, do: "page", else: nil)}
          >
            <%= String.capitalize(tab) %>
          </button>
        </nav>
      </header>

      <div :if={@active_tab == "tree"} class="ax-json-tree">
        <ul class="ax-json-tree-root">
          <.tree_node value={@normalized_payload} depth={0} max_depth={@max_depth} />
        </ul>
      </div>

      <pre :if={@active_tab == "raw"} class="ax-json-raw"><%= @raw_json %></pre>

      <div :if={@active_tab == "copy"} class="ax-json-copy">
        <button
          id={@id <> "-copy"}
          type="button"
          class="ax-button ax-button-secondary"
          phx-hook="Clipboard"
          data-clipboard-text={@raw_json}
        >
          Copy payload
        </button>
        <pre class="ax-json-raw ax-json-copy-preview"><%= @raw_json %></pre>
      </div>
    </section>
    """
  end

  attr(:value, :any, required: true)
  attr(:name, :string, default: nil)
  attr(:depth, :integer, default: 0)
  attr(:max_depth, :integer, default: 8)

  defp tree_node(assigns) do
    assigns =
      assigns
      |> assign(:expandable, expandable?(assigns.value, assigns.depth, assigns.max_depth))
      |> assign(:children, child_entries(assigns.value))
      |> assign(:summary, node_summary(assigns.value))
      |> assign(:name, normalize_name(assigns.name))

    ~H"""
    <li class="ax-json-node">
      <details :if={@expandable} class="ax-json-details" open={@depth < 1}>
        <summary>
          <span :if={@name} class="ax-json-key"><%= @name %></span>
          <span class="ax-json-summary"><%= @summary %></span>
        </summary>
        <ul class="ax-json-children">
          <.tree_node
            :for={child <- @children}
            name={child.name}
            value={child.value}
            depth={@depth + 1}
            max_depth={@max_depth}
          />
        </ul>
      </details>

      <div :if={!@expandable} class="ax-json-leaf">
        <span :if={@name} class="ax-json-key"><%= @name %></span>
        <span class="ax-json-value"><%= scalar_preview(@value) %></span>
      </div>
    </li>
    """
  end

  defp normalize_tab(tab) when tab in ["tree", "raw", "copy"], do: tab
  defp normalize_tab(_tab), do: "tree"

  defp normalize_name(nil), do: nil
  defp normalize_name(name) when is_binary(name), do: name
  defp normalize_name(name), do: to_string(name)

  defp expandable?(_value, depth, max_depth) when depth >= max_depth, do: false
  defp expandable?(value, _depth, _max_depth) when is_map(value), do: map_size(value) > 0
  defp expandable?(value, _depth, _max_depth) when is_list(value), do: value != []
  defp expandable?(_value, _depth, _max_depth), do: false

  defp child_entries(value) when is_map(value) do
    value
    |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
    |> Enum.map(fn {key, child} -> %{name: to_string(key), value: child} end)
  end

  defp child_entries(value) when is_list(value) do
    value
    |> Enum.with_index()
    |> Enum.map(fn {child, index} -> %{name: "[#{index}]", value: child} end)
  end

  defp child_entries(_value), do: []

  defp node_summary(value) when is_map(value), do: "Object (#{map_size(value)} keys)"
  defp node_summary(value) when is_list(value), do: "List (#{length(value)} items)"
  defp node_summary(value), do: scalar_preview(value)

  defp scalar_preview(nil), do: "null"
  defp scalar_preview(true), do: "true"
  defp scalar_preview(false), do: "false"
  defp scalar_preview(value) when is_binary(value), do: value
  defp scalar_preview(value) when is_atom(value), do: Atom.to_string(value)
  defp scalar_preview(%Decimal{} = value), do: Decimal.to_string(value)
  defp scalar_preview(value) when is_integer(value) or is_float(value), do: to_string(value)
  defp scalar_preview(value), do: inspect(value)

  defp normalize_payload(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp normalize_payload(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)
  defp normalize_payload(%Date{} = value), do: Date.to_iso8601(value)
  defp normalize_payload(%Time{} = value), do: Time.to_iso8601(value)
  defp normalize_payload(%Decimal{} = value), do: Decimal.to_string(value)

  defp normalize_payload(%mod{} = _value) do
    %{"__struct__" => inspect(mod)}
  end

  defp normalize_payload(value) when is_map(value) do
    Enum.into(value, %{}, fn {key, child} ->
      {to_string(key), normalize_payload(child)}
    end)
  end

  defp normalize_payload(value) when is_list(value), do: Enum.map(value, &normalize_payload/1)
  defp normalize_payload(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_payload(value), do: value
end
