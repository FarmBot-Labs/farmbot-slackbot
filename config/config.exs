# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :farmbot_slackbot, FarmbotSlackbotWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "LGkVlPvzDd++5AGTZTP/R/DgpTo+d+F5NgRO+/0W83KXKptDOojdPK27UY2OYTsM",
  render_errors: [view: FarmbotSlackbotWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: FarmbotSlackbot.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]


config :ex_slack, :token, Map.fetch!(System.get_env(), "SLACK_API_TOKEN")
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
