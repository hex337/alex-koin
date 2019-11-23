defmodule AlexKoin.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = "MIX_ENV" |> System.get_env() |> get_children()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AlexKoin.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    AlexKoinWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp get_children("test") do
    [
      # Start the Ecto repository
      supervisor(AlexKoin.Repo, []),
      # Start the endpoint when the application starts
      supervisor(AlexKoinWeb.Endpoint, [])
    ]
  end

  defp get_children(_) do
    [slackbot_supervisor() | get_children("test")]
  end

  defp slackbot_supervisor do
    slack_token = Application.get_env(:alex_koin, AlexKoin.Slack)[:token]

    supervisor(Slack.Bot, [AlexKoin.SlackRtm, [], slack_token])
  end
end
