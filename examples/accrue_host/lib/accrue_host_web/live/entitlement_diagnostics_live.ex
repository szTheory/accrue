defmodule AccrueHostWeb.EntitlementDiagnosticsLive do
  @moduledoc false

  use AccrueHostWeb, :live_view

  alias Accrue.Entitlements.{Account, Admin}
  alias AccrueHost.Auth
  alias AccrueHostWeb.Layouts

  @impl true
  def mount(_params, _session, socket) do
    case socket.assigns.current_scope do
      %{user: user} when not is_nil(user) ->
        if Auth.admin?(user) do
          {:ok,
           socket
           |> assign(:page_title, "Access diagnostic")
           |> assign(:diagnostic, load_diagnostic(user))}
        else
          {:ok,
           socket
           |> put_flash(:error, "This access diagnostic is available to operators only.")
           |> redirect(to: ~p"/")}
        end

      _ ->
        {:ok, redirect(socket, to: ~p"/users/log-in")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="mx-auto flex max-w-5xl flex-col gap-6" data-testid="entitlement-diagnostic">
        <div>
          <p class="text-sm font-semibold text-primary">Account access</p>
          <h1 class="mt-2 text-3xl font-semibold">Access diagnostic</h1>
          <p class="mt-2 max-w-3xl text-base leading-7 text-base-content/70">
            Review the current access picture and the next safe step. This page does not change access.
          </p>
        </div>

        <%= case @diagnostic do %>
          <% {:ok, diagnostic} -> %>
            <section
              class="rounded-lg border border-base-300 bg-base-100 p-6 shadow-sm"
              aria-labelledby="current-access-heading"
            >
              <h2 id="current-access-heading" class="text-2xl font-semibold">Current access</h2>
              <p class="mt-1 text-base leading-7 text-base-content/70">
                {snapshot_copy(diagnostic.snapshot.state)}
              </p>
              <dl class="mt-5 grid gap-4 sm:grid-cols-2">
                <.fact label="Access status" value={status_copy(diagnostic.snapshot.state)} />
                <.fact label="Account revision" value={to_string(diagnostic.snapshot.revision)} />
                <.fact label="Source count" value={to_string(diagnostic.snapshot.source_count)} />
                <.fact label="Provider check" value={status_copy(diagnostic.provider.state)} />
              </dl>
            </section>

            <section
              class="rounded-lg border border-base-300 bg-base-100 p-6 shadow-sm"
              aria-labelledby="device-access-heading"
            >
              <h2 id="device-access-heading" class="text-2xl font-semibold">
                Device and reconnect status
              </h2>
              <dl class="mt-5 grid gap-4 sm:grid-cols-2">
                <.fact
                  label="Devices"
                  value={device_copy(diagnostic.devices.state, diagnostic.devices.count)}
                />
                <.fact label="Proof horizon" value={proof_copy(diagnostic.devices.proof_horizon)} />
                <.fact label="Recovery" value={status_copy(diagnostic.recovery.state)} />
                <.fact label="Retry" value={retry_copy(diagnostic.recovery.retry_state)} />
              </dl>
            </section>

            <section
              class="rounded-lg border border-base-300 bg-base-100 p-6 shadow-sm"
              aria-labelledby="next-action-heading"
            >
              <h2 id="next-action-heading" class="text-2xl font-semibold">Next safe action</h2>
              <p class="mt-2 text-base leading-7 text-base-content/70">
                {action_copy(diagnostic.next_action)}
              </p>
              <button
                type="button"
                class="btn btn-outline btn-sm mt-4"
                disabled
                aria-describedby="diagnostic-read-only-reason"
              >
                Refresh access
              </button>
              <p id="diagnostic-read-only-reason" class="mt-2 text-sm text-base-content/60">
                Refreshing access is disabled here because this page is read-only.
              </p>
            </section>
          <% {:error, :not_found} -> %>
            <.unavailable />
          <% {:error, :unavailable} -> %>
            <.unavailable />
        <% end %>
      </section>
    </Layouts.app>
    """
  end

  attr :label, :string, required: true
  attr :value, :string, required: true

  defp fact(assigns) do
    ~H"""
    <div>
      <dt class="text-sm font-semibold text-base-content/60">{@label}</dt>
      <dd class="mt-1 text-base">{@value}</dd>
    </div>
    """
  end

  defp unavailable(assigns) do
    ~H"""
    <section
      class="rounded-lg border border-base-300 bg-base-100 p-6 shadow-sm"
      aria-labelledby="access-unavailable-heading"
    >
      <h2 id="access-unavailable-heading" class="text-2xl font-semibold">Access check unavailable</h2>
      <p class="mt-2 text-base leading-7 text-base-content/70">
        We can’t show an access diagnostic right now. Check the account setup and try again.
      </p>
    </section>
    """
  end

  defp load_diagnostic(user) do
    repo = Accrue.Repo.repo()

    with %Account{} = account <- repo.get_by(Account, owner_type: "User", owner_id: user.id) do
      Admin.diagnostic_for_account(account, repo: repo)
    else
      _ -> {:error, :not_found}
    end
  rescue
    _ -> {:error, :unavailable}
  end

  defp snapshot_copy(:available), do: "Access is available from the current account record."

  defp snapshot_copy(:stale),
    do: "The access picture needs an updated check before it can be relied on."

  defp snapshot_copy(:repairing),
    do: "The access picture is being repaired. Check back after it completes."

  defp snapshot_copy(:ambiguous), do: "The access picture needs review before a change is made."
  defp snapshot_copy(_), do: "Access information is currently unavailable."

  defp status_copy(:available), do: "Available"
  defp status_copy(:not_observed), do: "Not checked yet"
  defp status_copy(:pending), do: "Waiting for a check"
  defp status_copy(:quarantined), do: "Needs review"
  defp status_copy(:retrying), do: "Retry scheduled"
  defp status_copy(:needs_repair), do: "Needs repair"
  defp status_copy(:clear), do: "No repair needed"
  defp status_copy(:stale), do: "Needs an updated check"
  defp status_copy(:repairing), do: "Repair in progress"
  defp status_copy(:ambiguous), do: "Needs review"
  defp status_copy(_), do: "Unavailable"

  defp device_copy(:not_registered, _count), do: "No device has checked in yet"

  defp device_copy(:available, count),
    do: "#{count} device#{if count == 1, do: "", else: "s"} checked in"

  defp device_copy(_, _count), do: "Needs review"
  defp proof_copy(:recent), do: "Recently checked"
  defp proof_copy(:stale), do: "Needs a new check"
  defp proof_copy(_), do: "Not available"
  defp retry_copy(:scheduled), do: "A retry is scheduled"
  defp retry_copy(_), do: "No retry scheduled"
  defp action_copy(:review_access), do: "Review access before making any change."
  defp action_copy(_), do: "Review access before making any change."
end
