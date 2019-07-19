# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

config :phoenix, :json_library, Poison

# General application configuration
config :alex_koin,
  ecto_repos: [AlexKoin.Repo],
  koin_bot_id: System.get_env("KOIN_BOT_ID")

# Configures the endpoint
config :alex_koin, AlexKoinWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "bB7leglq64+Lvhx7d7W0BY6m6rJDv0+X9NJEoaZfKMea1RTpUPWNawG4y+w/yz7+",
  render_errors: [view: AlexKoinWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: AlexKoin.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id],
  colors: [enabled: true]

# Configure Slack Bot
config :alex_koin, AlexKoin.Slack,
  token: System.get_env("SLACK_TOKEN")

config :slack, 
  api_token: System.get_env("SLACK_TOKEN")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
