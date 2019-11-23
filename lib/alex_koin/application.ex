defmodule AlexKoin.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(AlexKoin.Repo, []),
      # Start the endpoint when the application starts
      supervisor(AlexKoinWeb.Endpoint, [])
    ]

    children =
      if System.get_env("MIX_ENV") == "test" do
        children
      else
        slack_token = Application.get_env(:alex_koin, AlexKoin.Slack)[:token]
        slackbot_supervisor = supervisor(Slack.Bot, [AlexKoin.SlackRtm, [], slack_token])
        [slackbot_supervisor | children]
      end

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
end
