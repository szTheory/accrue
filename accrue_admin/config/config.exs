import Config

config :ex_cldr, default_backend: Accrue.Cldr
config :ex_money, default_cldr_backend: Accrue.Cldr
config :swoosh, :api_client, false

import_config "#{config_env()}.exs"
