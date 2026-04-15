Application.put_env(:accrue, :env, :test)
Application.put_env(:accrue, :auth_adapter, Accrue.Auth.Default)
Application.put_env(:accrue, :branding,
  business_name: "Accrue",
  from_email: "noreply@example.com",
  support_email: "support@example.com",
  logo_url: nil,
  accent_color: "#5D79F6"
)

ExUnit.start()
