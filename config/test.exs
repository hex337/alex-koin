use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :alex_koin, AlexKoinWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :alex_koin, AlexKoin.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "alex_koin_test",
  hostname: "db",
  pool: Ecto.Adapters.SQL.Sandbox

config :alex_koin,
  :slack_module, AlexKoin.Test.SlackSendStub
