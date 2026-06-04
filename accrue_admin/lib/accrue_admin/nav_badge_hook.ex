defmodule AccrueAdmin.NavBadgeHook do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]

  @spec on_mount(atom(), map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:cont, Phoenix.LiveView.Socket.t()}
  def on_mount(:default, _params, _session, socket) do
    counts =
      try do
        AccrueAdmin.AttentionCounts.compute(socket.assigns[:current_owner_scope])
      rescue
        _ -> %{recovery: 0, developer: 0}
      end

    {:cont, assign(socket, :nav_attention_counts, counts)}
  end
end
