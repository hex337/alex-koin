use Mix.Config

config :alex_koin,
  ecro_repos: [AlexKoin.Repo],
  koin_bot_id: System.get_env("KOIN_BOT_ID"),
  koin_lord_ids: System.get_env("KOIN_LORD_IDS")
  admin_id: System.get_env("ADMIN_ID")

# Configure Slack Bot
config :alex_koin, AlexKoin.Slack,
  token: System.get_env("SLACK_TOKEN")

config :slack, 
  api_token: System.get_env("SLACK_TOKEN")

config :alex_koin, AlexKoin.Repo,
  username: System.get_env("DATABASE_USER"),
  password: System.get_env("DATABASE_PASS"),
  database: System.get_env("DATABASE_NAME"),
  hostname: System.get_env("DATABASE_HOST"),
  pool_size: 2

port = String.to_integer(System.get_env("PORT") || "8080")
config :alex_koin, AlexKoin.Endpoint,
  http: [port: port],
  url: [host: System.get_env("HOSTNAME"), port: port],
  root: '.',
  secret_key_base: System.get_env("SECRET_KEY_BASE")
