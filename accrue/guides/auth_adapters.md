# Auth Adapters

Accrue does not own authentication. The host app wires an adapter with:

```elixir
config :accrue, :auth_adapter, MyApp.Auth.PhxGenAuth
```

An adapter implements `Accrue.Auth` so Accrue Admin, audit logging, and destructive-action step-up checks can read host auth state without knowing how the host signs users in.

## Required callbacks

- `current_user/1` reads the signed-in user from a `%Plug.Conn{}` or compatible map and returns the user struct/map or `nil`.
- `require_admin_plug/0` returns a plug that allows authorized admins and rejects everyone else before Accrue Admin routes run.
- `user_schema/0` returns the host user schema module when the adapter can name it, such as `MyApp.Accounts.User`.
- `log_audit/2` records or forwards an admin action. It should not log raw Stripe payloads, API keys, webhook secrets, or request bodies.
- `actor_id/1` returns the canonical actor id string used when Accrue records event-ledger rows.
- `step_up_challenge/2` starts a destructive-action challenge, such as password confirmation, TOTP, WebAuthn, or a Sigra-backed challenge.
- `verify_step_up/3` verifies the challenge result for the user and action.

`step_up_challenge/2` and `verify_step_up/3` are optional callbacks, but production admin installs should implement them for destructive billing actions.

## MyApp.Auth.PhxGenAuth

Phoenix `phx.gen.auth` apps usually already have `fetch_current_user` and route-level plugs in `MyAppWeb.UserAuth`. Keep that module as the source of truth and wrap it with a small adapter.

```elixir
defmodule MyApp.Auth.PhxGenAuth do
  @behaviour Accrue.Auth

  import Plug.Conn

  alias MyApp.Accounts.User
  alias MyAppWeb.UserAuth

  @impl Accrue.Auth
  def current_user(conn), do: conn.assigns[:current_user]

  @impl Accrue.Auth
  def require_admin_plug do
    fn conn, _opts ->
      conn = UserAuth.fetch_current_user(conn, [])

      if admin?(conn.assigns[:current_user]) do
        conn
      else
        conn
        |> send_resp(:forbidden, "forbidden")
        |> halt()
      end
    end
  end

  @impl Accrue.Auth
  def user_schema, do: User

  @impl Accrue.Auth
  def log_audit(user, event), do: MyApp.Audit.log(user, event)

  @impl Accrue.Auth
  def actor_id(%User{id: id}), do: to_string(id)
  def actor_id(%{id: id}), do: to_string(id)
  def actor_id(_user), do: nil

  @impl Accrue.Auth
  def step_up_challenge(user, action), do: MyApp.Accounts.start_step_up(user, action)

  @impl Accrue.Auth
  def verify_step_up(user, params, action), do: MyApp.Accounts.verify_step_up(user, params, action)

  defp admin?(%User{role: :admin}), do: true
  defp admin?(%User{role: "admin"}), do: true
  defp admin?(_user), do: false
end
```

The important boundary is `require_admin_plug/0`: do not rely on hiding links in the UI. Protect the Accrue Admin mount in the router.

## MyApp.Auth.Pow

Pow apps can read the current user through `Pow.Plug.current_user/1` and use the host role policy for admin checks.

```elixir
defmodule MyApp.Auth.Pow do
  @behaviour Accrue.Auth

  import Plug.Conn

  alias MyApp.Users.User

  @impl Accrue.Auth
  def current_user(conn), do: Pow.Plug.current_user(conn)

  @impl Accrue.Auth
  def require_admin_plug do
    fn conn, _opts ->
      user = Pow.Plug.current_user(conn)

      if user && MyApp.Policy.admin?(user) do
        conn
      else
        conn
        |> send_resp(:forbidden, "forbidden")
        |> halt()
      end
    end
  end

  @impl Accrue.Auth
  def user_schema, do: User

  @impl Accrue.Auth
  def log_audit(user, event), do: MyApp.Audit.log(user, event)

  @impl Accrue.Auth
  def actor_id(%User{id: id}), do: to_string(id)
  def actor_id(_user), do: nil

  @impl Accrue.Auth
  def step_up_challenge(user, action), do: MyApp.Security.start_step_up(user, action)

  @impl Accrue.Auth
  def verify_step_up(user, params, action), do: MyApp.Security.verify_step_up(user, params, action)
end
```

## MyApp.Auth.Assent

Assent is often used behind a host-owned session pipeline. The adapter should read the already-loaded user from assigns or session-backed host helpers, not re-run OAuth inside Accrue.

```elixir
defmodule MyApp.Auth.Assent do
  @behaviour Accrue.Auth

  import Plug.Conn

  alias MyApp.Accounts
  alias MyApp.Accounts.User

  @impl Accrue.Auth
  def current_user(conn), do: conn.assigns[:current_user] || Accounts.current_user(conn)

  @impl Accrue.Auth
  def require_admin_plug do
    fn conn, _opts ->
      user = current_user(conn)

      if user && Accounts.admin?(user) do
        conn
      else
        conn
        |> send_resp(:forbidden, "forbidden")
        |> halt()
      end
    end
  end

  @impl Accrue.Auth
  def user_schema, do: User

  @impl Accrue.Auth
  def log_audit(user, event), do: Accounts.log_admin_audit(user, event)

  @impl Accrue.Auth
  def actor_id(%User{id: id}), do: to_string(id)
  def actor_id(_user), do: nil

  @impl Accrue.Auth
  def step_up_challenge(user, action), do: Accounts.start_step_up(user, action)

  @impl Accrue.Auth
  def verify_step_up(user, params, action), do: Accounts.verify_step_up(user, params, action)
end
```

## Sigra

When `:sigra` is present, the installer can wire the first-party adapter:

```elixir
config :accrue, :auth_adapter, Accrue.Integrations.Sigra
```

`Accrue.Integrations.Sigra` is conditionally compiled. In projects without Sigra, the module is not defined and Accrue stays on the configured fallback adapter.

## Default adapter warning

`Accrue.Auth.Default` is for local development and tests. It returns a dev admin user in `:dev` and `:test`, but it refuses to boot in `:prod` when it is still the configured adapter. Production installs must configure `MyApp.Auth.PhxGenAuth`, `MyApp.Auth.Pow`, `MyApp.Auth.Assent`, `Accrue.Integrations.Sigra`, or another host-owned adapter that protects admin routes and records audit actor ids.

## Router placement

Place the auth plug before mounting Accrue Admin:

```elixir
pipeline :admin do
  plug Accrue.Auth.require_admin_plug()
end

scope "/billing" do
  pipe_through [:browser, :admin]

  accrue_admin "/"
end
```

Keep the policy in the host app. Accrue only asks the adapter for the current user, admin boundary, user schema, audit sink, actor id, and step-up challenge behavior.
