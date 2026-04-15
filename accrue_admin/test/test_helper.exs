Application.put_env(:accrue, :env, :test)
Application.put_env(:accrue, :auth_adapter, Accrue.Auth.Default)

ExUnit.start()
