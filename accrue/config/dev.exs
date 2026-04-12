import Config

# Dev: Swoosh Local adapter writes emails to an in-process mailbox visible via
# Swoosh.Adapters.Local.Storage.Memory / Phoenix LiveDashboard.
config :accrue, Accrue.Mailer.Swoosh, adapter: Swoosh.Adapters.Local
