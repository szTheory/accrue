defmodule AccrueAdmin.Live.ConnectAccountLive do
  @moduledoc false

  use Phoenix.LiveView

  alias Accrue.{Auth, Config, Connect, Events, Money}
  alias Accrue.Connect.Account
  alias Accrue.Repo

  alias AccrueAdmin.Components.{
    AppShell,
    Breadcrumbs,
    Detail,
    DetailDrawer,
    FlashGroup,
    JsonViewer,
    RelatedResources,
    StepUpAuthModal,
    Timeline
  }

  alias AccrueAdmin.Copy
  alias AccrueAdmin.ScopedPath
  alias AccrueAdmin.StepUp

  @default_preview_amount_minor 10_000
  @default_preview_currency "usd"

  @impl true
  def mount(%{"id" => account_id}, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    case load_account(account_id, socket.assigns.current_owner_scope) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, Copy.connect_account_not_found())
         |> redirect(to: scoped_admin_path(admin, socket.assigns.current_owner_scope, "/connect"))}

      account ->
        mount_path = admin["mount_path"] || "/billing"
        scope = socket.assigns.current_owner_scope

        {:ok,
         socket
         |> assign_shell(admin)
         |> assign_account(account)
         |> assign(:related_items, related_items(account, mount_path, scope))
         |> assign(:timeline_events, [])
         |> assign(:timeline_events_loaded?, false)
         |> assign(:raw_json_loaded?, false)
         |> assign(:drawer_action_type, nil)
         |> assign(:pending_override, nil)
         |> assign(:flashes, [])}
    end
  end

  @impl true
  def handle_event("validate_override", %{"override" => params}, socket) do
    {:noreply, apply_override_preview(socket, params)}
  end

  def handle_event("open_override_drawer", _params, socket) do
    {:noreply, assign(socket, :drawer_action_type, "platform_fee_override")}
  end

  def handle_event("cancel_override_drawer", _params, socket) do
    {:noreply,
     socket
     |> assign(:drawer_action_type, nil)
     |> assign(:pending_override, nil)}
  end

  def handle_event("save_override", %{"override" => params}, socket) do
    socket = apply_override_preview(socket, params)

    case socket.assigns.override_preview do
      %{error: nil, override_payload: override_payload} ->
        socket = assign(socket, :pending_override, override_payload)

        case StepUp.require_fresh(
               socket,
               step_up_action(socket.assigns.account),
               &execute_override_save(&1, override_payload)
             ) do
          {:ok, socket} ->
            {:noreply, socket}

          {:challenge, socket} ->
            {:noreply, socket}

          {:error, _reason, socket} ->
            {:noreply,
             socket
             |> assign(:pending_override, nil)
             |> assign(:flashes, [
               %{kind: :error, message: AccrueAdmin.Copy.connect_account_step_up_unavailable()}
             ])}
        end

      %{error: error} ->
        {:noreply, socket |> assign(:flashes, [%{kind: :error, message: error}])}
    end
  end

  def handle_event("load_activity", _params, socket) do
    {:noreply, ensure_timeline_events(socket)}
  end

  def handle_event("load_raw_json", _params, socket) do
    {:noreply, assign(socket, :raw_json_loaded?, true)}
  end

  def handle_event("step_up_submit", params, socket) do
    case StepUp.verify(socket, params) do
      {:ok, socket} -> {:noreply, socket}
      {:error, _reason, socket} -> {:noreply, socket}
    end
  end

  def handle_event("step_up_escape", _params, socket) do
    {:noreply, dismiss_step_up_if_pending(socket)}
  end

  def handle_event("step_up_dismiss", _params, socket) do
    {:noreply, dismiss_step_up_if_pending(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AppShell.app_shell
      brand={@brand}
      current_path={@current_path}
      mount_path={@admin_mount_path}
      page_title={@page_title}
      theme={@theme}
      current_owner_scope={assigns[:current_owner_scope]}
      active_organization_name={@active_organization_name}
    >
      <section class="ax-page" phx-window-keydown="step_up_escape" phx-key="escape">
        <Breadcrumbs.breadcrumbs
          items={[
            %{
              label: AccrueAdmin.Copy.dashboard_breadcrumb_home(),
              href: ScopedPath.build(@admin_mount_path, "", @current_owner_scope)
            },
            %{
              label: AccrueAdmin.Copy.connect_account_breadcrumb_connect(),
              href: ScopedPath.build(@admin_mount_path, "/connect", @current_owner_scope)
            },
            %{label: @account.stripe_account_id || @account.id}
          ]}
        />

        <Detail.summary_card
          eyebrow={AccrueAdmin.Copy.connect_account_eyebrow()}
          title={@account.stripe_account_id}
        >
          <:facts>
            <span><%= @account.type |> humanize() %></span>
            <span><%= owner_summary(@account) %></span>
            <span><%= account_status(@account) %></span>
          </:facts>
        </Detail.summary_card>

        <Detail.summary_list rows={summary_rows(@account, @admin_mount_path, @current_owner_scope)} />

        <FlashGroup.flash_group flashes={@flashes} />

        <section class="ax-card ax-detail-action-band" data-ax-action-band>
          <header class="ax-page-header">
            <div>
              <p class="ax-eyebrow"><%= AccrueAdmin.Copy.connect_account_actions_eyebrow() %></p>
              <h2 class="ax-heading"><%= AccrueAdmin.Copy.connect_account_actions_heading() %></h2>
            </div>
            <div class="ax-page-actions">
              <button
                type="button"
                class="ax-button ax-button-primary"
                phx-click="open_override_drawer"
                data-ax-primary-action
                aria-label={AccrueAdmin.Copy.action_hidden_context("Change", resource: "platform fee override", object: @account.stripe_account_id || @account.id)}
              >
                <%= AccrueAdmin.Copy.connect_account_action_edit_platform_fee_override() %>
              </button>
            </div>
          </header>
          <p class="ax-body ax-measure"><%= AccrueAdmin.Copy.connect_account_actions_body() %></p>
        </section>

        <section class="ax-stack-xl" aria-label={AccrueAdmin.Copy.connect_account_drills_aria_label()}>
          <details class="ax-detail-section" data-ax-drill-section="capabilities-requirements" open>
            <summary class="ax-detail-section-head">
              <span class="ax-detail-section-title"><%= AccrueAdmin.Copy.connect_account_section_capabilities_heading() %></span>
            </summary>
            <Detail.detail_field_list fields={capability_requirement_fields(@account)} />
          </details>

          <details class="ax-detail-section" data-ax-drill-section="platform-fee-policy">
            <summary class="ax-detail-section-head">
              <span class="ax-detail-section-title"><%= AccrueAdmin.Copy.connect_account_section_effective_fee_heading() %></span>
            </summary>
            <Detail.detail_field_list fields={platform_fee_policy_fields(@account, @override_preview, @default_fee_config)} />
            <p :if={@override_preview.error} class="ax-body"><%= @override_preview.error %></p>
          </details>
        </section>

        <div data-ax-related-resources>
          <RelatedResources.related_resources items={@related_items} />
        </div>

        <details class="ax-detail-section" data-ax-lazy-activity phx-click="load_activity">
          <summary class="ax-detail-section-head">
            <span class="ax-detail-section-title"><%= AccrueAdmin.Copy.connect_account_activity_heading() %></span>
          </summary>
          <%= if @timeline_events_loaded? do %>
            <Timeline.timeline
              label={AccrueAdmin.Copy.connect_account_timeline_label()}
              empty_label={AccrueAdmin.Copy.connect_account_timeline_empty()}
              items={timeline_items(@timeline_events)}
            />
          <% else %>
            <p class="ax-body"><%= AccrueAdmin.Copy.connect_account_lazy_activity_prompt() %></p>
          <% end %>
        </details>

        <details class="ax-detail-section" data-ax-lazy-json phx-click="load_raw_json">
          <summary class="ax-detail-section-head">
            <span class="ax-detail-section-title"><%= AccrueAdmin.Copy.connect_account_raw_data_heading() %></span>
          </summary>
          <%= if @raw_json_loaded? do %>
            <JsonViewer.json_viewer
              id="connect-account-data"
              label={AccrueAdmin.Copy.connect_account_json_payload_label()}
              payload={raw_payload(@account)}
            />
          <% else %>
            <p class="ax-body"><%= AccrueAdmin.Copy.connect_account_lazy_json_prompt() %></p>
          <% end %>
        </details>

        <DetailDrawer.detail_drawer
          id="connect-platform-fee-drawer"
          open={drawer_open?(@drawer_action_type)}
          title={override_drawer_title(@account)}
          subtitle={AccrueAdmin.Copy.connect_account_drawer_subtitle()}
          close_event="cancel_override_drawer"
        >
          <.override_drawer_form
            preview={@override_preview}
            default_fee_config={@default_fee_config}
          />
        </DetailDrawer.detail_drawer>

        <div
          :if={drawer_open?(@drawer_action_type)}
          hidden
          aria-hidden="true"
          data-role="connect-platform-fee-drawer-test-mirror"
        >
          <section data-ax-overlay-panel data-presentation="drawer">
            <.override_drawer_form
              preview={@override_preview}
              default_fee_config={@default_fee_config}
            />
          </section>
        </div>

        <StepUpAuthModal.step_up_auth_modal
          pending={@step_up_pending}
          challenge={@step_up_challenge}
          error={@step_up_error}
        />

        <div :if={@step_up_pending} hidden aria-hidden="true" data-role="step-up-test-mirror">
          <form phx-submit="step_up_submit">
            <input type="text" name="code" value="" />
            <button type="submit" data-role="step-up-submit"><%= AccrueAdmin.Copy.step_up_submit_label() %></button>
          </form>
        </div>
      </section>
    </AppShell.app_shell>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, AccrueAdmin.Copy.connect_account_page_title())
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, admin_path(admin, "/connect"))
  end

  defp assign_account(socket, account) do
    form = override_form(account)

    socket
    |> assign(:account, account)
    |> assign(:default_fee_config, default_fee_config())
    |> assign(:override_preview, preview_override(form))
  end

  defp apply_override_preview(socket, params) do
    assign(socket, :override_preview, preview_override(normalize_override_form(params)))
  end

  defp execute_override_save(socket, override_payload) do
    case load_account(socket.assigns.account.id, socket.assigns.current_owner_scope) do
      nil ->
        socket
        |> assign(:pending_override, nil)
        |> assign(:flashes, [%{kind: :error, message: Copy.connect_account_not_found()}])

      %Account{} = account ->
        data = merged_data(account, override_payload)

        case account |> Account.changeset(%{data: data}) |> Repo.update() do
          {:ok, updated_account} ->
            socket
            |> record_override_update(updated_account, override_payload)
            |> assign_account(updated_account)
            |> assign(:drawer_action_type, nil)
            |> assign(:pending_override, nil)
            |> assign(:flashes, [
              %{kind: :info, message: AccrueAdmin.Copy.connect_account_flash_override_saved()}
            ])

          {:error, changeset} ->
            assign(socket, :override_preview, %{
              socket.assigns.override_preview
              | error: humanize_changeset_errors(changeset)
            })
        end
    end
  end

  attr(:preview, :map, required: true)
  attr(:default_fee_config, :list, required: true)

  defp override_drawer_form(assigns) do
    ~H"""
    <section class="ax-stack-md">
      <p class="ax-body ax-measure">
        <%= AccrueAdmin.Copy.connect_account_section_platform_fee_body() %>
      </p>

      <Detail.detail_field_list fields={[
        %{
          label: AccrueAdmin.Copy.connect_account_detail_label_default_policy(),
          value: describe_config(@default_fee_config)
        },
        %{
          label: AccrueAdmin.Copy.connect_account_detail_label_preview_gross(),
          value: preview_gross_summary(@preview.form)
        },
        %{
          label: AccrueAdmin.Copy.connect_account_detail_label_computed_fee(),
          value: @preview.fee_label
        }
      ]} />

      <p :if={@preview.error} class="ax-body"><%= @preview.error %></p>

      <form phx-change="validate_override" phx-submit="save_override" data-ax-action-drawer-form>
        <div class="ax-grid ax-grid-2">
          <label class="ax-label">
            <%= AccrueAdmin.Copy.connect_account_label_percent() %>
            <input
              type="text"
              name="override[percent]"
              value={@preview.form["percent"]}
              class="ax-input"
            />
          </label>

          <label class="ax-label">
            <%= AccrueAdmin.Copy.connect_account_label_fixed_minor_units() %>
            <input
              type="text"
              name="override[fixed_cents]"
              value={@preview.form["fixed_cents"]}
              class="ax-input"
            />
          </label>

          <label class="ax-label">
            <%= AccrueAdmin.Copy.connect_account_label_min_minor_units() %>
            <input
              type="text"
              name="override[min_cents]"
              value={@preview.form["min_cents"]}
              class="ax-input"
            />
          </label>

          <label class="ax-label">
            <%= AccrueAdmin.Copy.connect_account_label_max_minor_units() %>
            <input
              type="text"
              name="override[max_cents]"
              value={@preview.form["max_cents"]}
              class="ax-input"
            />
          </label>

          <label class="ax-label">
            <%= AccrueAdmin.Copy.connect_account_label_preview_gross_minor_units() %>
            <input
              type="text"
              name="override[preview_amount_minor]"
              value={@preview.form["preview_amount_minor"]}
              class="ax-input"
            />
          </label>

          <label class="ax-label">
            <%= AccrueAdmin.Copy.connect_account_label_preview_currency() %>
            <input
              type="text"
              name="override[preview_currency]"
              value={@preview.form["preview_currency"]}
              class="ax-input"
            />
          </label>
        </div>

        <div class="ax-page-header">
          <button type="submit" class="ax-button ax-button-primary" data-role="save-override">
            <%= AccrueAdmin.Copy.connect_account_save_platform_fee_override() %>
          </button>
        </div>
      </form>
    </section>
    """
  end

  defp summary_rows(account, mount_path, scope) do
    account_label = account.stripe_account_id || account.id

    [
      %{
        label: AccrueAdmin.Copy.connect_account_summary_label_readiness(),
        value: readiness_summary(account)
      },
      %{
        label: AccrueAdmin.Copy.connect_account_summary_label_owner(),
        value: owner_summary(account)
      },
      %{
        label: AccrueAdmin.Copy.connect_account_summary_label_country(),
        value: account.country || "--"
      },
      %{
        label: AccrueAdmin.Copy.connect_account_summary_label_charges_enabled(),
        value: enabled_label(account.charges_enabled)
      },
      %{
        label: AccrueAdmin.Copy.connect_account_summary_label_payouts_enabled(),
        value: enabled_label(account.payouts_enabled)
      },
      %{
        label: AccrueAdmin.Copy.connect_account_summary_label_onboarding(),
        value: enabled_label(account.details_submitted)
      },
      %{
        label: AccrueAdmin.Copy.connect_account_summary_label_override(),
        value: override_state_label(account),
        action_label: "Change",
        action_context:
          AccrueAdmin.Copy.action_hidden_context("Change",
            resource: "platform fee override",
            object: "account #{account_label}"
          ),
        action_event: "open_override_drawer",
        action_value: "platform_fee_override"
      }
    ]
    |> maybe_add_events_row(account, account_label, mount_path, scope)
  end

  defp maybe_add_events_row(rows, account, account_label, mount_path, scope) do
    rows ++
      [
        %{
          label: AccrueAdmin.Copy.connect_account_summary_label_activity(),
          value: AccrueAdmin.Copy.connect_account_activity_summary(),
          action_label: "View",
          action_context:
            AccrueAdmin.Copy.action_hidden_context("View",
              resource: "events",
              object: "account #{account_label}"
            ),
          action_href:
            ScopedPath.build(mount_path, "/events", scope, %{
              "subject_type" => "ConnectAccount",
              "subject_id" => account.id
            })
        }
      ]
  end

  defp capability_requirement_fields(account) do
    [
      %{
        label: AccrueAdmin.Copy.connect_account_detail_label_owner(),
        value: owner_summary(account)
      },
      %{
        label: AccrueAdmin.Copy.connect_account_detail_label_email(),
        value: account.email || "--"
      },
      %{
        label: AccrueAdmin.Copy.connect_account_detail_label_type(),
        value: humanize(account.type)
      },
      %{
        label: AccrueAdmin.Copy.connect_account_detail_label_capabilities(),
        value: capabilities_summary(account.capabilities)
      },
      %{
        label: AccrueAdmin.Copy.connect_account_detail_label_requirements(),
        value: requirements_summary(account.requirements)
      }
    ]
  end

  defp platform_fee_policy_fields(account, override_preview, default_fee_config) do
    [
      %{
        label: AccrueAdmin.Copy.connect_account_detail_label_stored_override(),
        value: describe_override(account)
      },
      %{
        label: AccrueAdmin.Copy.connect_account_detail_label_default_policy(),
        value: describe_config(default_fee_config)
      },
      %{
        label: AccrueAdmin.Copy.connect_account_detail_label_preview_gross(),
        value: preview_gross_summary(override_preview.form)
      },
      %{
        label: AccrueAdmin.Copy.connect_account_detail_label_computed_fee(),
        value: override_preview.fee_label
      }
    ]
  end

  defp override_drawer_title(account) do
    AccrueAdmin.Copy.connect_account_drawer_title(account.stripe_account_id || account.id)
  end

  defp drawer_open?("platform_fee_override"), do: true
  defp drawer_open?(_drawer_action_type), do: false

  defp ensure_timeline_events(%{assigns: %{timeline_events_loaded?: true}} = socket), do: socket

  defp ensure_timeline_events(socket) do
    socket
    |> assign(:timeline_events, timeline_events(socket.assigns.account.id))
    |> assign(:timeline_events_loaded?, true)
  end

  defp timeline_events(account_id),
    do: Events.timeline_for("ConnectAccount", account_id, limit: 25)

  defp timeline_items(events) do
    Enum.map(events, fn event ->
      %{
        title: event.type,
        at: format_datetime(event.inserted_at),
        body: event.subject_type <> " " <> event.subject_id,
        status: event.actor_type,
        tone: timeline_tone(event),
        meta: "event ##{event.id}"
      }
    end)
  end

  defp timeline_tone(%{actor_type: "admin"}), do: :cobalt
  defp timeline_tone(%{type: "admin.connect.platform_fee_override.updated"}), do: :amber
  defp timeline_tone(_event), do: :slate

  defp raw_payload(account) do
    %{
      "id" => account.id,
      "stripe_account_id" => account.stripe_account_id,
      "owner_type" => account.owner_type,
      "owner_id" => account.owner_id,
      "type" => account.type,
      "country" => account.country,
      "email" => account.email,
      "charges_enabled" => account.charges_enabled,
      "payouts_enabled" => account.payouts_enabled,
      "details_submitted" => account.details_submitted,
      "deauthorized_at" => account.deauthorized_at,
      "capabilities" => account.capabilities,
      "requirements" => account.requirements,
      "data" => account.data
    }
  end

  defp load_account(account_id, owner_scope) do
    case Repo.get(Account, account_id) do
      nil -> nil
      %Account{} = account -> if account_in_scope?(account, owner_scope), do: account
    end
  end

  defp account_in_scope?(_account, nil), do: true
  defp account_in_scope?(_account, %{mode: :global}), do: true

  defp account_in_scope?(account, %{mode: :organization, organization_id: organization_id}) do
    account.owner_type == "Organization" and account.owner_id == organization_id
  end

  defp account_in_scope?(_account, _owner_scope), do: false

  defp step_up_action(account) do
    %{
      type: "platform_fee_override",
      subject_type: "ConnectAccount",
      subject_id: account.id
    }
  end

  defp dismiss_step_up_if_pending(socket) do
    if socket.assigns[:step_up_pending] do
      StepUp.dismiss_challenge(socket)
    else
      socket
    end
  end

  defp record_override_update(socket, account, override_payload) do
    current_admin = socket.assigns.current_admin

    {:ok, _event} =
      Events.record(%{
        type: "admin.connect.platform_fee_override.updated",
        subject_type: "ConnectAccount",
        subject_id: account.id,
        actor_type: "admin",
        actor_id: Auth.actor_id(current_admin),
        data: %{
          "stripe_account_id" => account.stripe_account_id,
          "platform_fee_override" => override_payload
        }
      })

    :ok =
      Auth.log_audit(current_admin, %{
        type: "admin.connect.platform_fee_override.updated",
        connect_account_id: account.id,
        source: :accrue_admin
      })

    socket
  end

  defp default_fee_config do
    Config.get!(:connect)
    |> Keyword.get(:platform_fee, [])
  end

  defp override_form(account) do
    override = platform_fee_override(account)

    normalize_override_form(%{
      "percent" => override["percent"] || "",
      "fixed_cents" => override["fixed_cents"] || "",
      "min_cents" => override["min_cents"] || "",
      "max_cents" => override["max_cents"] || "",
      "preview_amount_minor" => Integer.to_string(@default_preview_amount_minor),
      "preview_currency" => @default_preview_currency
    })
  end

  defp normalize_override_form(params) do
    %{
      "percent" => normalize_string(Map.get(params, "percent")),
      "fixed_cents" => normalize_string(Map.get(params, "fixed_cents")),
      "min_cents" => normalize_string(Map.get(params, "min_cents")),
      "max_cents" => normalize_string(Map.get(params, "max_cents")),
      "preview_amount_minor" =>
        normalize_string(Map.get(params, "preview_amount_minor")) ||
          Integer.to_string(@default_preview_amount_minor),
      "preview_currency" =>
        normalize_string(Map.get(params, "preview_currency")) || @default_preview_currency
    }
  end

  defp preview_override(form) do
    with {:ok, override_payload, opts} <- override_opts(form),
         {:ok, gross} <- preview_gross(form),
         {:ok, fee} <- Connect.platform_fee(gross, opts) do
      %{
        form: form,
        error: nil,
        fee_label: Money.to_string(fee),
        override_payload: override_payload
      }
    else
      {:error, reason} ->
        %{
          form: form,
          error: reason,
          fee_label: AccrueAdmin.Copy.connect_account_preview_fee_unable(),
          override_payload: %{}
        }
    end
  end

  defp override_opts(form) do
    with {:ok, percent, payload} <- maybe_decimal(form, "percent", "percent"),
         {:ok, fixed, payload} <- maybe_money(form, "fixed_cents", "fixed_cents", payload),
         {:ok, min, payload} <- maybe_money(form, "min_cents", "min_cents", payload),
         {:ok, max, payload} <- maybe_money(form, "max_cents", "max_cents", payload) do
      opts =
        []
        |> put_if_present(:percent, percent)
        |> put_if_present(:fixed, fixed)
        |> put_if_present(:min, min)
        |> put_if_present(:max, max)

      {:ok, payload, opts}
    end
  end

  defp maybe_decimal(form, key, payload_key) do
    label = override_field_label(key)

    case Map.get(form, key) do
      nil ->
        {:ok, nil, %{}}

      value ->
        try do
          decimal = Decimal.new(value)
          {:ok, decimal, %{payload_key => value}}
        rescue
          _ ->
            {:error, AccrueAdmin.Copy.connect_account_error_field_must_be_decimal(label)}
        end
    end
  end

  defp maybe_money(form, key, payload_key, payload) do
    label = override_field_label(key)

    case Map.get(form, key) do
      nil ->
        {:ok, nil, payload}

      value ->
        case Integer.parse(value) do
          {amount_minor, ""} ->
            with {:ok, currency} <- preview_currency(form) do
              {:ok, Money.new(amount_minor, currency), Map.put(payload, payload_key, value)}
            end

          _ ->
            {:error, AccrueAdmin.Copy.connect_account_error_field_must_be_integer_minor(label)}
        end
    end
  end

  defp override_field_label("percent"), do: AccrueAdmin.Copy.connect_account_label_percent()

  defp override_field_label("fixed_cents"),
    do: AccrueAdmin.Copy.connect_account_label_fixed_minor_units()

  defp override_field_label("min_cents"),
    do: AccrueAdmin.Copy.connect_account_label_min_minor_units()

  defp override_field_label("max_cents"),
    do: AccrueAdmin.Copy.connect_account_label_max_minor_units()

  defp preview_gross(form) do
    with {amount_minor, ""} <- Integer.parse(form["preview_amount_minor"]),
         {:ok, currency} <- preview_currency(form) do
      {:ok, Money.new(amount_minor, currency)}
    else
      :error ->
        {:error, AccrueAdmin.Copy.connect_account_error_preview_amount_invalid()}

      {:error, _} = error ->
        error

      _ ->
        {:error, AccrueAdmin.Copy.connect_account_error_preview_amount_invalid()}
    end
  end

  defp preview_currency(form) do
    currency =
      form["preview_currency"]
      |> String.downcase()

    try do
      {:ok, String.to_existing_atom(currency)}
    rescue
      ArgumentError -> {:error, AccrueAdmin.Copy.connect_account_error_preview_currency_unknown()}
    end
  end

  defp merged_data(account, override_payload) do
    account.data
    |> Kernel.||(%{})
    |> case do
      data when map_size(override_payload) == 0 -> Map.delete(data, "platform_fee_override")
      data -> Map.put(data, "platform_fee_override", override_payload)
    end
  end

  defp platform_fee_override(account) do
    account.data
    |> Kernel.||(%{})
    |> Map.get("platform_fee_override", %{})
    |> case do
      value when is_map(value) -> value
      _ -> %{}
    end
  end

  defp override_state_label(account) do
    if map_size(platform_fee_override(account)) > 0,
      do: AccrueAdmin.Copy.connect_account_override_state_saved(),
      else: AccrueAdmin.Copy.connect_account_override_state_default_only()
  end

  defp describe_override(account) do
    case platform_fee_override(account) do
      override when map_size(override) == 0 ->
        AccrueAdmin.Copy.connect_account_override_state_no_override_saved()

      override ->
        describe_override_payload(override)
    end
  end

  defp describe_override_payload(override) do
    [
      override["percent"] && "#{override["percent"]}% percent",
      override["fixed_cents"] && "#{override["fixed_cents"]} fixed",
      override["min_cents"] && "#{override["min_cents"]} min",
      override["max_cents"] && "#{override["max_cents"]} max"
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
  end

  defp describe_config(config) do
    payload = %{}

    payload =
      if config[:percent],
        do: Map.put(payload, "percent", Decimal.to_string(config[:percent], :normal)),
        else: payload

    payload =
      if config[:fixed],
        do: Map.put(payload, "fixed_cents", Integer.to_string(config[:fixed].amount_minor)),
        else: payload

    payload =
      if config[:min],
        do: Map.put(payload, "min_cents", Integer.to_string(config[:min].amount_minor)),
        else: payload

    payload =
      if config[:max],
        do: Map.put(payload, "max_cents", Integer.to_string(config[:max].amount_minor)),
        else: payload

    describe_override_payload(payload)
  end

  defp preview_gross_summary(form) do
    case preview_gross(form) do
      {:ok, gross} -> Money.to_string(gross)
      {:error, _} -> AccrueAdmin.Copy.connect_account_preview_gross_invalid()
    end
  end

  defp owner_summary(account),
    do:
      "#{account.owner_type || AccrueAdmin.Copy.connect_accounts_row_owner_fallback()} #{account.owner_id || "--"}"

  defp readiness_summary(%{deauthorized_at: %DateTime{} = value}),
    do: account_status(%{deauthorized_at: value})

  defp readiness_summary(account) do
    if account.charges_enabled and account.payouts_enabled and account.details_submitted do
      AccrueAdmin.Copy.connect_account_readiness_ready()
    else
      AccrueAdmin.Copy.connect_account_readiness_needs_attention()
    end
  end

  defp account_status(%{deauthorized_at: %DateTime{} = value}),
    do: AccrueAdmin.Copy.connect_account_status_deauthorized_prefix() <> format_datetime(value)

  defp account_status(_account),
    do: AccrueAdmin.Copy.connect_account_status_active_authorization()

  defp enabled_label(true), do: AccrueAdmin.Copy.connect_account_enabled_label_true()
  defp enabled_label(false), do: AccrueAdmin.Copy.connect_account_enabled_label_false()
  defp enabled_label(nil), do: AccrueAdmin.Copy.connect_account_enabled_label_unknown()

  defp capabilities_summary(capabilities)
       when is_map(capabilities) and map_size(capabilities) > 0 do
    capabilities
    |> Enum.map(fn {key, value} -> "#{key}=#{inspect(value)}" end)
    |> Enum.join(", ")
  end

  defp capabilities_summary(_capabilities),
    do: AccrueAdmin.Copy.connect_account_capabilities_none()

  defp requirements_summary(requirements)
       when is_map(requirements) and map_size(requirements) > 0 do
    [
      requirements["disabled_reason"] || requirements[:disabled_reason],
      requirement_list(requirements["currently_due"] || requirements[:currently_due])
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
  end

  defp requirements_summary(_requirements),
    do: AccrueAdmin.Copy.resource_state_copy(:connect_accounts, :queue_empty).heading

  defp requirement_list(list) when is_list(list) and list != [],
    do:
      AccrueAdmin.Copy.connect_account_requirements_currently_due_prefix() <>
        Enum.join(list, ", ")

  defp requirement_list(_), do: nil

  defp humanize(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp format_datetime(%DateTime{} = value), do: Calendar.strftime(value, "%b %d, %Y %H:%M UTC")

  defp normalize_string(nil), do: nil

  defp normalize_string(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp put_if_present(opts, _key, nil), do: opts
  defp put_if_present(opts, key, value), do: Keyword.put(opts, key, value)

  defp humanize_changeset_errors(changeset) do
    changeset.errors
    |> Enum.map(fn {field, {message, _meta}} -> "#{field} #{message}" end)
    |> Enum.join(", ")
  end

  defp related_items(account, mount_path, scope) do
    [
      %{
        icon: :events,
        label: "Events",
        href:
          ScopedPath.build(mount_path, "/events", scope, %{
            "subject_type" => "ConnectAccount",
            "subject_id" => account.id
          })
      }
    ]
  end

  defp admin_path(admin, suffix), do: (admin["mount_path"] || "/billing") <> suffix

  defp scoped_admin_path(admin, owner_scope, suffix) do
    ScopedPath.build(admin["mount_path"] || "/billing", suffix, owner_scope)
  end

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
