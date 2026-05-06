# Phase 101: Accrue Portal Foundation & Checkout - Pattern Map

**Mapped:** 2026-05-01
**Files analyzed:** 27
**Analogs found:** 26 / 27

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue_portal/mix.exs` | config | transform | `accrue_admin/mix.exs` | exact |
| `accrue_portal/lib/accrue_portal/application.ex` | provider | request-response | `accrue_admin/lib/accrue_admin/application.ex` | exact |
| `accrue_portal/lib/accrue_portal/router.ex` | route | request-response | `accrue_admin/lib/accrue_admin/router.ex` | exact |
| `accrue_portal/lib/accrue_portal/auth_hook.ex` | middleware | request-response | `accrue_admin/lib/accrue_admin/auth_hook.ex` | exact |
| `accrue_portal/lib/accrue_portal/csp_plug.ex` | middleware | request-response | `accrue_admin/lib/accrue_admin/csp_plug.ex` | exact |
| `accrue_portal/lib/accrue_portal/brand_plug.ex` | middleware | request-response | `accrue_admin/lib/accrue_admin/brand_plug.ex` | exact |
| `accrue_portal/lib/accrue_portal/live/home_live.ex` | component | request-response | `accrue_portal/lib/accrue_portal/live/home_live.ex` | exact-existing |
| `accrue_portal/lib/accrue_portal/live/checkout_live.ex` | component | request-response | `accrue_portal/lib/accrue_portal/live/checkout_live.ex` | exact-existing |
| `accrue_portal/lib/accrue_portal/live/subscriptions_live.ex` | component | CRUD | `accrue_portal/lib/accrue_portal/live/subscriptions_live.ex` | exact-existing |
| `accrue_portal/lib/accrue_portal/live/subscription_live.ex` | component | CRUD | `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | role-match |
| `accrue_portal/lib/accrue_portal/live/payment_methods_live.ex` | component | CRUD | `accrue_portal/lib/accrue_portal/live/payment_methods_live.ex` | exact-existing |
| `accrue_portal/lib/accrue_portal/live/invoices_live.ex` | component | request-response | `accrue_portal/lib/accrue_portal/live/invoices_live.ex` | exact-existing |
| `accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex` | controller | request-response | `accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex` | exact-existing |
| `accrue_portal/lib/accrue_portal/controllers/payment_method_controller.ex` | controller | CRUD | `accrue_portal/lib/accrue_portal/controllers/payment_method_controller.ex` | exact-existing |
| `accrue_portal/lib/accrue_portal/billing_read_model.ex` | service | CRUD | `accrue_portal/lib/accrue_portal/billing_read_model.ex` | exact-existing |
| `accrue_portal/lib/accrue_portal/braintree_client.ex` | service | request-response | `accrue_portal/lib/accrue_portal/braintree_client.ex` | exact-existing |
| `accrue_portal/lib/accrue_portal/customer_session.ex` | utility | request-response | `accrue_portal/lib/accrue_portal/customer_session.ex` | exact-existing |
| `accrue_portal/lib/accrue_portal/authorize.ex` | utility | request-response | none | no-analog |
| `accrue/lib/accrue/processor/braintree.ex` | service | request-response | `accrue/lib/accrue/processor/braintree.ex` | exact-existing |
| `accrue/lib/accrue/processor/capabilities.ex` | config | transform | `accrue/lib/accrue/processor/capabilities.ex` | exact-existing |
| `accrue/lib/accrue/checkout/local_session.ex` | model | CRUD | `accrue/lib/accrue/checkout/local_session.ex` | exact-existing |
| `accrue/priv/repo/migrations/20260501180000_create_accrue_checkout_sessions.exs` | migration | CRUD | `accrue/priv/repo/migrations/20260501180000_create_accrue_checkout_sessions.exs` | exact-existing |
| `accrue/lib/accrue/portal/checkout/completion_job.ex` | service | event-driven | `accrue/lib/accrue/jobs/reconcile_charge_fees.ex` | role-match |
| `examples/accrue_host/lib/accrue_host_web/router.ex` | route | request-response | `examples/accrue_host/lib/accrue_host_web/router.ex` | exact-existing |
| `release-please-config.json` | config | transform | `release-please-config.json` | exact-existing |
| `accrue_portal/test/accrue_portal/router_test.exs` | test | request-response | `accrue_admin/test/accrue_admin/router_test.exs` | exact |
| `accrue_portal/test/accrue_portal/live/*_test.exs` | test | CRUD | `accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs` | exact |
| `accrue/test/accrue/processor/braintree_local_portal_test.exs` | test | request-response | `accrue/test/accrue/processor/braintree_local_portal_test.exs` | exact-existing |

## Pattern Assignments

### `accrue_portal/mix.exs` and `accrue_portal/lib/accrue_portal/application.ex`

**Analogs:** `accrue_admin/mix.exs`, `accrue_admin/lib/accrue_admin/application.ex`

**Package/deps pattern** (`accrue_admin/mix.exs` lines 7-20, 23-28, 37-49):
```elixir
  def project do
    [
      app: :accrue_admin,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package(),
      description: "Admin LiveView UI for Accrue billing.",
      source_url: @source_url,
      docs: docs(),
      dialyzer: [plt_local_path: "priv/plts", plt_add_apps: [:mix, :ex_unit]]
    ]
  end

  def application do
    [
      mod: {AccrueAdmin.Application, []},
      extra_applications: [:logger]
    ]
  end
```

**Minimal mountable-app application pattern** (`accrue_admin/lib/accrue_admin/application.ex` lines 10-15):
```elixir
  use Application

  @impl true
  def start(_type, _args) do
    Supervisor.start_link([], strategy: :one_for_one, name: AccrueAdmin.Supervisor)
  end
```

### `accrue_portal/lib/accrue_portal/router.ex`

**Analog:** `accrue_admin/lib/accrue_admin/router.ex`

**Macro shape + browser pipeline** (`accrue_admin/lib/accrue_admin/router.ex` lines 24-55):
```elixir
  defmacro accrue_admin(path, opts \\ []) do
    opts = Macro.expand_literals(opts, __CALLER__)
    validated = validate_opts!(path, opts)
    mount_path = validated[:mount_path]
    session_keys = validated[:session_keys]
    on_mount = validated[:on_mount]
    dev_routes? = validated[:allow_live_reload]

    quote bind_quoted: [
            mount_path: mount_path,
            session_keys: session_keys,
            on_mount: on_mount,
            dev_routes?: dev_routes?
          ] do
      pipeline :accrue_admin_browser do
        plug(:fetch_session)
        plug(:protect_from_forgery)
        plug(AccrueAdmin.CSPPlug)
        plug(AccrueAdmin.BrandPlug)
      end

      scope mount_path, as: :accrue_admin do
        ...
        live_session :accrue_admin,
          root_layout: {AccrueAdmin.Layouts, :root},
          on_mount: on_mount,
          session: {AccrueAdmin.Router, :__session__, [session_keys, mount_path]} do
```

**Single `live_session` + sibling-scope rule** (`accrue_admin/lib/accrue_admin/router.ex` lines 88-113):
```elixir
  # Mounted as a SIBLING scope (not nested in the :accrue_admin live_session)
  # because mailglass_admin_routes/2 emits its own live_session internally and
  # Phoenix forbids nested live_session blocks.
```

**Session-threading callback** (`accrue_admin/lib/accrue_admin/router.ex` lines 118-140):
```elixir
  def __session__(conn, session_keys, mount_path)
      when is_list(session_keys) and is_binary(mount_path) do
    threaded_keys = Enum.uniq(session_keys ++ @owner_scope_session_keys)

    host_session =
      Map.new(threaded_keys, fn key ->
        string_key = to_string(key)
        {string_key, get_session(conn, key)}
      end)

    Map.merge(host_session, %{
      "accrue_admin" => %{
        "brand_css_path" => AccrueAdmin.Assets.hashed_path(:brand, mount_path),
        "assets_css_path" => AccrueAdmin.Assets.hashed_path(:css, mount_path),
        "assets_js_path" => AccrueAdmin.Assets.hashed_path(:js, mount_path),
        "mount_path" => AccrueAdmin.Assets.normalize_mount_path(mount_path),
        "brand" => conn.assigns[:accrue_admin_brand],
        "theme" => conn.assigns[:accrue_admin_theme] || "system",
        "csp_nonce" => conn.assigns[:accrue_admin_csp_nonce]
      }
    })
  end
```

**Portal-specific current implementation to preserve where already present** (`accrue_portal/lib/accrue_portal/router.ex` lines 30-74):
```elixir
      pipeline :accrue_portal_browser do
        plug(:fetch_session)
        plug(:fetch_live_flash)
        plug(:protect_from_forgery)
        plug(AccruePortal.CSPPlug)
        plug(AccruePortal.BrandPlug)
      end

      pipeline :accrue_portal_authenticated do
        plug(AccruePortal.AuthPlug)
      end

      scope mount_path, as: :accrue_portal do
        ...
        post("/payment-methods", AccruePortal.Controllers.PaymentMethodController, :create)
        post("/checkout/:token/complete", AccruePortal.Controllers.CheckoutController, :complete)

        live_session :accrue_portal,
          root_layout: {AccruePortal.Layouts, :root},
          on_mount: on_mount,
          session: {AccruePortal.Router, :__session__, [session_keys, mount_path]} do
          live("/", AccruePortal.Live.HomeLive, :index)
          live("/subscriptions", AccruePortal.Live.SubscriptionsLive, :index)
          live("/payment-methods", AccruePortal.Live.PaymentMethodsLive, :index)
          live("/invoices", AccruePortal.Live.InvoicesLive, :index)
          live("/checkout/:token", AccruePortal.Live.CheckoutLive, :show)
        end
```

### `accrue_portal/lib/accrue_portal/auth_hook.ex`, `customer_session.ex`, and implied `authorize.ex`

**Analogs:** `accrue_admin/lib/accrue_admin/auth_hook.ex`, `accrue_portal/lib/accrue_portal/customer_session.ex`, partial tenant-guard patterns from `checkout_live.ex` and `billing_read_model.ex`

**Callback-module `on_mount` pattern** (`accrue_admin/lib/accrue_admin/auth_hook.ex` lines 9-32):
```elixir
  @spec on_mount(atom(), map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:cont, Phoenix.LiveView.Socket.t()} | {:halt, Phoenix.LiveView.Socket.t()}
  def on_mount(:ensure_admin, params, session, socket) do
    case OwnerScope.resolve(session, params) do
      {:ok, owner_scope} ->
        {:cont,
         socket
         |> assign(:accrue_admin_session, session)
         |> assign(:current_admin, user)
         |> assign(:current_owner_scope, owner_scope)}

      {:error, _reason} ->
        {:halt, redirect(socket, to: "/")}
    end
  end
```

**Portal customer resolution pattern** (`accrue_portal/lib/accrue_portal/customer_session.ex` lines 6-17):
```elixir
  def resolve(session) when is_map(session) do
    case Accrue.Auth.current_user(session) do
      nil ->
        {:error, :unauthenticated}

      user ->
        case Billing.customer(user) do
          {:ok, customer} -> {:ok, user, customer}
          {:error, reason} -> {:error, reason}
        end
    end
  end
```

**Portal assign contract** (`accrue_portal/lib/accrue_portal/auth_hook.ex` lines 9-20):
```elixir
  def on_mount(:ensure_customer, _params, session, socket) do
    case CustomerSession.resolve(session) do
      {:ok, user, customer} ->
        {:cont,
         socket
         |> assign(:accrue_portal_session, session)
         |> assign(:current_user, user)
         |> assign(:current_customer, customer)}

      {:error, _reason} ->
        {:halt, redirect(socket, to: "/")}
    end
  end
```

**Tenant-guard pattern for implied `authorize.ex`** (`accrue_portal/lib/accrue_portal/live/checkout_live.ex` lines 9-18, `billing_read_model.ex` lines 38-39):
```elixir
  case session do
    %LocalSession{customer_id: customer_id} = checkout
    when customer_id == socket.assigns.current_customer.id ->
      ...
  end
```

```elixir
  def payment_method!(%Customer{id: customer_id}, id) do
    Repo.get_by!(PaymentMethod, id: id, customer_id: customer_id)
  end
```

### `accrue_portal/lib/accrue_portal/csp_plug.ex` and `brand_plug.ex`

**Analogs:** `accrue_admin/lib/accrue_admin/csp_plug.ex`, `accrue_admin/lib/accrue_admin/brand_plug.ex`

**Nonce + CSP header pattern** (`accrue_admin/lib/accrue_admin/csp_plug.ex` lines 9-31):
```elixir
  def call(conn, _opts) do
    nonce = 18 |> :crypto.strong_rand_bytes() |> Base.encode64(padding: false)

    policy =
      [
        "default-src 'self'",
        "base-uri 'self'",
        "connect-src 'self' ws: wss:",
        "font-src 'self' data:",
        "img-src 'self' data: https:",
        "object-src 'none'",
        "script-src 'self' 'nonce-#{nonce}'",
        "style-src 'self' 'nonce-#{nonce}'",
        "frame-ancestors 'self'"
      ]
      |> Enum.join("; ")

    conn
    |> assign(:accrue_admin_csp_nonce, nonce)
    |> put_private(:accrue_admin_csp_nonce, nonce)
    |> put_resp_header("content-security-policy", policy)
  end
```

**Portal Hosted Fields allowlist** (`accrue_portal/lib/accrue_portal/csp_plug.ex` lines 8-27):
```elixir
  def call(conn, _opts) do
    nonce = 18 |> :crypto.strong_rand_bytes() |> Base.encode64(padding: false)

    policy =
      [
        "default-src 'self'",
        "script-src 'self' 'nonce-#{nonce}' https://js.braintreegateway.com",
        "style-src 'self' 'nonce-#{nonce}'",
        "img-src 'self' data: https:",
        "connect-src 'self' https://api.braintreegateway.com https://client-analytics.braintreegateway.com",
        "frame-src https://assets.braintreegateway.com https://payments.braintree-api.com",
        "font-src 'self' data:"
      ]
```

**Brand assign pattern** (`accrue_admin/lib/accrue_admin/brand_plug.ex` lines 21-33):
```elixir
  def call(conn, _opts) do
    theme =
      conn
      |> fetch_cookies()
      |> Map.get(:cookies, %{})
      |> Map.get(@theme_cookie)
      |> sanitize_theme()

    conn
    |> assign(:accrue_admin_theme, theme)
    |> assign(:accrue_admin_brand, build_brand())
  end
```

### Portal LiveViews: `home_live.ex`, `checkout_live.ex`, `subscriptions_live.ex`, `payment_methods_live.ex`, `invoices_live.ex`

**Analogs:** current `accrue_portal` LiveViews; use `accrue_admin` only for overall mount/test layout.

**Mount assigns + read-model fetch pattern** (`accrue_portal/lib/accrue_portal/live/home_live.ex` lines 8-16):
```elixir
  def mount(_params, %{"accrue_portal" => portal} = _session, socket) do
    data = BillingReadModel.dashboard(socket.assigns.current_customer)

    {:ok,
     socket
     |> assign(:page_title, "Billing Portal")
     |> assign(:portal, portal)
     |> assign(:base_path, portal["mount_path"])
     |> assign(:dashboard, data)}
  end
```

**Token-scoped checkout guard + Hosted Fields form pattern** (`accrue_portal/lib/accrue_portal/live/checkout_live.ex` lines 9-27, 45-54):
```elixir
  def mount(%{"token" => token}, %{"accrue_portal" => portal}, socket) do
    session = LocalSession.by_token(token)

    case session do
      %LocalSession{customer_id: customer_id} = checkout
      when customer_id == socket.assigns.current_customer.id ->
        client_token =
          case BraintreeClient.client_token_for(socket.assigns.current_customer) do
            {:ok, value} -> value
            {:error, _reason} -> nil
          end
```

```heex
        <form
          :if={@client_token}
          action={Path.checkout_complete(@base_path, @checkout_session.session_token)}
          method="post"
          class="portal-hosted-fields-form"
          data-portal-hosted-fields="checkout"
          data-client-token={@client_token}
        >
          <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
          <input type="hidden" name="payment_method_nonce" value="" data-braintree-nonce-input />
```

**LiveView mutation pattern** (`accrue_portal/lib/accrue_portal/live/subscriptions_live.ex` lines 18-41):
```elixir
  def handle_event("cancel", %{"id" => id}, socket) do
    subscription =
      socket.assigns.subscriptions
      |> Enum.find(&(&1.id == id))

    case subscription do
      %Subscription{} = sub ->
        case Billing.cancel(sub) do
          {:ok, _} ->
            {:noreply,
             socket
             |> put_flash(:info, "Subscription canceled.")
             |> assign(:subscriptions, BillingReadModel.subscriptions(socket.assigns.current_customer))}
```

**CRUD form-post pattern for payment methods** (`accrue_portal/lib/accrue_portal/live/payment_methods_live.ex` lines 41-47, 54-64):
```heex
              <form action={Path.payment_method_default(@base_path, payment_method.id)} method="post">
                <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
                <button type="submit" class="portal-button-secondary">Set default</button>
              </form>
```

```heex
        <form
          action={Path.payment_methods(@base_path)}
          method="post"
          class="portal-hosted-fields-form"
          data-portal-hosted-fields="payment-method"
          data-client-token={@client_token}
        >
```

**Simple list-page pattern** (`accrue_portal/lib/accrue_portal/live/invoices_live.ex` lines 7-12, 20-28):
```elixir
  def mount(_params, %{"accrue_portal" => portal}, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Invoices")
     |> assign(:portal, portal)
     |> assign(:invoices, BillingReadModel.invoices(socket.assigns.current_customer))}
  end
```

### `accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex` and `payment_method_controller.ex`

**Analogs:** current portal controllers.

**Scope-check + domain call + redirect pattern** (`accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex` lines 10-31):
```elixir
  def complete(conn, %{"token" => token, "payment_method_nonce" => nonce})
      when is_binary(nonce) and nonce != "" do
    customer = conn.assigns.current_customer

    case LocalSession.by_token(token) do
      %LocalSession{customer_id: customer_id} = session when customer_id == customer.id ->
        case Billing.subscribe(customer, session.price_id,
               payment_method: %{vault_acquisition: %{reference: nonce}},
               operation_id: session.operation_id
             ) do
          {:ok, _subscription} ->
            {:ok, _session} = LocalSession.mark_completed(session)
            conn
            |> put_flash(:info, "Subscription created.")
            |> redirect(to: session.success_url || Path.home(base_path(conn)))
```

**Controller CRUD/error pattern** (`accrue_portal/lib/accrue_portal/controllers/payment_method_controller.ex` lines 10-23, 32-63):
```elixir
  def create(conn, %{"payment_method_nonce" => nonce}) when is_binary(nonce) and nonce != "" do
    customer = conn.assigns.current_customer

    case Billing.add_payment_method(customer, %{vault_acquisition: %{reference: nonce}}) do
      {:ok, _payment_method} ->
        conn
        |> put_flash(:info, "Payment method saved.")
        |> redirect(to: Path.payment_methods(base_path(conn)))
```

```elixir
  def set_default(conn, %{"id" => id}) do
    customer = conn.assigns.current_customer
    payment_method = BillingReadModel.payment_method!(customer, id)

    case Billing.set_default_payment_method(customer, payment_method) do
      {:ok, _customer} -> ...
      {:error, _reason} -> ...
    end
  end
```

### `accrue_portal/lib/accrue_portal/billing_read_model.ex` and `braintree_client.ex`

**Analogs:** current portal services.

**Customer-scoped query pattern** (`accrue_portal/lib/accrue_portal/billing_read_model.ex` lines 18-25, 42-49):
```elixir
  def subscriptions(%Customer{id: customer_id}) do
    from(subscription in Subscription,
      where: subscription.customer_id == ^customer_id,
      order_by: [desc: subscription.inserted_at]
    )
    |> Repo.all()
    |> Repo.preload(:subscription_items)
  end
```

```elixir
  def invoices(%Customer{id: customer_id}) do
    from(invoice in Invoice,
      where: invoice.customer_id == ^customer_id,
      order_by: [desc: invoice.inserted_at],
      limit: 20
    )
    |> Repo.all()
  end
```

**Thin adapter service pattern** (`accrue_portal/lib/accrue_portal/braintree_client.ex` lines 6-13):
```elixir
  def client_token_for(%Customer{processor_id: customer_id}) do
    generator =
      Application.get_env(:accrue, :braintree_client_token_generator, Braintree.ClientToken)

    case generator.generate(%{customer_id: customer_id}) do
      {:ok, token} -> {:ok, token}
      {:error, reason} -> {:error, reason}
    end
  end
```

### `accrue/lib/accrue/processor/braintree.ex` and `accrue/lib/accrue/processor/capabilities.ex`

**Analogs:** current core adapter/config.

**Capabilities shape** (`accrue/lib/accrue/processor/braintree.ex` lines 17-43):
```elixir
  def capabilities do
    %{
      customer: %{create: true, retrieve: true, update: true},
      payment_method: %{..., set_default: true},
      subscription: %{..., cancel_immediately: true, pause: false, resume: false},
      checkout: %{create: true, fetch: true, hosted: true, embedded: false},
      invoice: %{lifecycle_webhook_projection: true},
      webhook: %{verify: true, parse: true},
      billing_portal: %{create: true}
    }
  end
```

**Local portal session create/fetch pattern** (`accrue/lib/accrue/processor/braintree.ex` lines 360-391):
```elixir
  def checkout_session_create(params, opts) when is_map(params) and is_list(opts) do
    with {:ok, customer} <- checkout_customer(params),
         {:ok, attrs} <- build_local_checkout_attrs(customer, params, opts),
         {:ok, session} <- LocalSession.create_or_reuse(customer, attrs) do
      {:ok, local_checkout_payload(session)}
    end
  end

  def checkout_session_fetch(id, _opts) when is_binary(id) do
    case LocalSession.by_id(id) do
      %LocalSession{} = session -> {:ok, local_checkout_payload(session)}
      nil -> {:error, invalid_request("unknown local checkout session #{inspect(id)}")}
    end
  end

  def portal_session_create(params, _opts) when is_map(params) do
    with {:ok, customer} <- portal_customer(params) do
      {:ok,
       %{
         id: "bps_local_" <> customer.id,
         object: "billing_portal.session",
         customer: customer.processor_id,
         url: billing_portal_url(params)
       }}
    end
  end
```

**Session payload synthesis pattern** (`accrue/lib/accrue/processor/braintree.ex` lines 734-789):
```elixir
  defp build_local_checkout_attrs(%Customer{} = customer, params, opts) do
    line_items = params["line_items"] || params[:line_items] || []
    operation_id = Keyword.get(opts, :operation_id)

    with {:ok, price_id} <- checkout_price_id(line_items) do
      {:ok,
       %{
         processor: "braintree",
         mode: params["mode"] || params[:mode] || "subscription",
         ui_mode: params["ui_mode"] || params[:ui_mode] || "hosted",
         price_id: price_id,
         line_items: line_items,
         success_url: params["success_url"] || params[:success_url],
         cancel_url: params["cancel_url"] || params[:cancel_url],
         return_url: params["return_url"] || params[:return_url],
         operation_id: operation_id
       }}
    end
  end
```

**Support-label vocabulary pattern** (`accrue/lib/accrue/processor/capabilities.ex` lines 11-47, 68-93):
```elixir
  @support_labels %{
    ...
    checkout: %{
      create: "first-party local portal",
      fetch: "first-party local portal",
      hosted: "first-party local portal",
      embedded: "out of slice"
    },
    billing_portal: %{
      create: "first-party local portal"
    },
    ...
  }
```

```elixir
  def supports?(capabilities, path) when is_map(capabilities) and is_list(path) do
    case get_in(capabilities, path) do
      true -> true
      _ -> false
    end
  end

  def first_party_supported?(capabilities, path)
      when is_map(capabilities) and is_list(path) do
    support_label(path) == "all first-party" and supports?(capabilities, path)
  end
```

### `accrue/lib/accrue/checkout/local_session.ex` and migration `20260501180000_create_accrue_checkout_sessions.exs`

**Analogs:** current schema and migration.

**Schema + changeset + idempotency reuse pattern** (`accrue/lib/accrue/checkout/local_session.ex` lines 20-60, 62-74, 100-116):
```elixir
  schema "accrue_checkout_sessions" do
    belongs_to(:customer, Customer)
    field(:processor, :string)
    field(:session_token, :string)
    field(:mode, :string)
    field(:ui_mode, :string)
    field(:status, :string, default: "open")
    field(:price_id, :string)
    field(:line_items, {:array, :map}, default: [])
    ...
  end
```

```elixir
  def create_or_reuse(%Customer{} = customer, attrs) when is_map(attrs) do
    case Map.get(attrs, :operation_id) || Map.get(attrs, "operation_id") do
      op_id when is_binary(op_id) and op_id != "" ->
        case by_operation_id(customer, op_id) do
          %__MODULE__{} = existing -> {:ok, existing}
          nil -> insert_session(customer, attrs)
        end
```

```elixir
  defp insert_session(%Customer{} = customer, attrs) do
    payload =
      attrs
      |> Map.new()
      |> Map.put(:customer_id, customer.id)
      |> Map.put_new(:session_token, generate_token())
      |> Map.put_new(:status, "open")
      |> Map.put_new(:expires_at, DateTime.add(DateTime.utc_now(), 1_800, :second))
```

**Migration layout pattern** (`accrue/priv/repo/migrations/20260501180000_create_accrue_checkout_sessions.exs` lines 4-31):
```elixir
  def change do
    create table(:accrue_checkout_sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :customer_id, references(:accrue_customers, type: :binary_id, on_delete: :delete_all),
        null: false
      ...
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:accrue_checkout_sessions, [:session_token])
    create unique_index(:accrue_checkout_sessions, [:operation_id])
    create index(:accrue_checkout_sessions, [:customer_id, :inserted_at])
  end
```

### `accrue/lib/accrue/portal/checkout/completion_job.ex`

**Analog:** `accrue/lib/accrue/jobs/reconcile_charge_fees.ex`

**Oban worker shape + telemetry/event side effects** (`accrue/lib/accrue/jobs/reconcile_charge_fees.ex` lines 14-25, 60-72):
```elixir
  use Oban.Worker, queue: :accrue_reconcilers, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{} = job) do
    Accrue.Oban.Middleware.put(job)
    sweep()
  end
```

```elixir
      :telemetry.execute(
        [:accrue, :billing, :charge, :fees_settled],
        %{},
        %{charge_id: updated.id, source: :reconciler}
      )

      _ =
        Events.record(%{
          type: "charge.fees_settled",
          subject_type: "Charge",
          subject_id: updated.id,
          data: %{source: "reconciler"}
        })
```

### `examples/accrue_host/lib/accrue_host_web/router.ex` and `release-please-config.json`

**Analogs:** current example/config files.

**Host-router mount placement pattern** (`examples/accrue_host/lib/accrue_host_web/router.ex` lines 44-56, 83-90):
```elixir
  scope "/", AccrueHostWeb do
    pipe_through([:browser, :require_authenticated_user])

    live_session :require_authenticated_user,
      on_mount: [{AccrueHostWeb.UserAuth, :require_authenticated}] do
      live("/app/billing", SubscriptionLive, :show)
      ...
    end
  end

  ...

  accrue_admin "/billing", session_keys: [:user_token], allow_live_reload: false
```

**Linked-version release config pattern** (`release-please-config.json` lines 5-10, 12-33):
```json
  "plugins": [
    {
      "type": "linked-versions",
      "groupName": "accrue-monorepo",
      "components": ["accrue", "accrue_admin", "accrue_portal"]
    }
  ],
```

### Tests: `accrue_portal/test/...` and `accrue/test/accrue/processor/braintree_local_portal_test.exs`

**Analogs:** `accrue_admin/test/accrue_admin/router_test.exs`, `accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs`, `accrue/test/accrue/processor/braintree_local_portal_test.exs`

**Router macro test pattern** (`accrue_admin/test/accrue_admin/router_test.exs` lines 12-26, 28-56):
```elixir
  test "mount macro emits isolated asset routes and live session routes" do
    paths =
      AccrueAdmin.TestRouter.__routes__()
      |> Enum.map(& &1.path)

    assert "/billing/assets/css-#{AccrueAdmin.Assets.css_hash()}" in paths
    assert "/billing" in paths
  end
```

```elixir
  test "session callback only forwards explicit host session keys" do
    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{"admin_token" => "token-123", "ignored" => "secret"})

    session =
      conn
      |> AccrueAdmin.CSPPlug.call([])
      |> AccrueAdmin.BrandPlug.call([])
      |> AccrueAdmin.Router.__session__([:admin_token], "/billing")
```

**LiveView auth/test harness pattern** (`accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs` lines 9-33, 45-64):
```elixir
  defmodule AuthAdapter do
    @behaviour Accrue.Auth
    def current_user(%{"admin_token" => "admin"}), do: %{id: "admin_1", role: :admin}
    def current_user(_session), do: nil
    ...
  end

  setup do
    prior = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)
    on_exit(fn -> Application.put_env(:accrue, :auth_adapter, prior) end)
```

```elixir
  test "filters subscription rows and renders lifecycle-safe links", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _view, html} = live(conn, "/billing/subscriptions?status=canceling")
  end
```

**Core portal adapter regression test pattern** (`accrue/test/accrue/processor/braintree_local_portal_test.exs` lines 33-72):
```elixir
  test "create_checkout_session/2 persists and reuses local Braintree checkout sessions" do
    customer = insert_braintree_customer()

    assert {:ok, session} =
             CheckoutSession.create(
               customer: customer,
               line_items: [%{"price" => "plan_pro"}],
               success_url: "/after-checkout",
               operation_id: "checkout-op-1"
             )

    persisted = LocalSession.by_id(session.id)
    assert same_session.id == session.id
    assert {:ok, fetched} = CheckoutSession.retrieve(session.id)
  end
```

## Shared Patterns

### Mount Macro and Session Threading
**Source:** `accrue_admin/lib/accrue_admin/router.ex:24-55`, `:118-140`; `accrue_portal/lib/accrue_portal/router.ex:30-74`, `:79-97`
**Apply to:** `router.ex`, host example router, router tests

Copy the admin macro contract exactly: validate opts first, define a dedicated browser pipeline, emit one `live_session`, and build a namespaced session payload containing mount path, asset paths, theme, brand, and CSP nonce.

### Customer Auth Resolution
**Source:** `accrue_admin/lib/accrue_admin/auth_hook.ex:11-32`; `accrue_portal/lib/accrue_portal/customer_session.ex:6-17`; `accrue_portal/lib/accrue_portal/auth_hook.ex:9-20`
**Apply to:** `auth_hook.ex`, `customer_session.ex`, every portal LiveView

Use callback-module `on_mount` hooks, not a new behaviour. Resolve the host user through `Accrue.Auth.current_user/1`, assign `:current_user`, `:current_customer`, and the package session blob, and halt with redirect on failure.

### Tenant Scoping Defense-in-Depth
**Source:** `accrue_portal/lib/accrue_portal/live/checkout_live.ex:9-18`; `accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex:14-21`; `accrue_portal/lib/accrue_portal/billing_read_model.ex:18-25`, `:38-49`
**Apply to:** all portal LiveViews, controllers, implied `authorize.ex`, tenant-bound tests

Never trust URL ids or tokens alone. Every fetch must also constrain by `socket.assigns.current_customer.id` or `conn.assigns.current_customer.id`.

### Hosted Fields Bridge
**Source:** `accrue_portal/lib/accrue_portal/csp_plug.ex:8-27`; `accrue_portal/lib/accrue_portal/live/checkout_live.ex:45-54`; `accrue_portal/lib/accrue_portal/live/payment_methods_live.ex:54-64`; `accrue_portal/lib/accrue_portal/braintree_client.ex:6-13`
**Apply to:** checkout/payment-method UI, portal JS hook, CSP tests

The page contract is: generate a customer-scoped client token server-side, render a form with hidden nonce input plus `data-client-token`, and allow the Braintree domains in `script-src`, `connect-src`, and `frame-src`.

### Local Checkout Session Idempotency
**Source:** `accrue/lib/accrue/processor/braintree.ex:360-365`, `:734-789`; `accrue/lib/accrue/checkout/local_session.ex:62-74`, `:100-116`; migration `accrue/priv/repo/migrations/20260501180000_create_accrue_checkout_sessions.exs:28-30`
**Apply to:** Braintree adapter, local session schema, portal completion flow, core tests

Persist local sessions once per `operation_id`, reuse on duplicate calls, and synthesize returned URLs from `portal_mount_path`/`portal_url` instead of request context.

### Worker, Telemetry, and Event Recording
**Source:** `accrue/lib/accrue/jobs/reconcile_charge_fees.ex:14-25`, `:60-72`
**Apply to:** implied `completion_job.ex`

Use `Oban.Worker`, set operation context via `Accrue.Oban.Middleware.put/1`, emit a telemetry event, and record an internal event row instead of embedding side effects in controller/LiveView code.

### Test Harness
**Source:** `accrue_admin/test/accrue_admin/router_test.exs:12-56`; `accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs:9-33`, `:45-64`; `accrue/test/accrue/processor/braintree_local_portal_test.exs:33-72`
**Apply to:** portal router tests, portal LiveView tests, Braintree adapter tests

Mirror `accrue_admin/test/` structure: router macro coverage, LiveView auth/session harness, and facade-level regression tests that assert idempotency and returned URLs.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `accrue_portal/lib/accrue_portal/authorize.ex` | utility | request-response | No existing reusable LV authorization helper/macro exists. Use partial patterns from `checkout_live.ex` and `billing_read_model.ex` to build a small helper that enforces `current_customer` scoping on every route. |

## Metadata

**Analog search scope:** `accrue/`, `accrue_admin/`, `accrue_portal/`, `examples/accrue_host/`, repo-root release config
**Files scanned:** 20 direct analog files + repo-wide `rg` search for routes, LiveViews, processors, migrations, tests
**Pattern extraction date:** 2026-05-01
