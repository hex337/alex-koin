defmodule AlexKoin.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    slack_token = Application.get_env(:alex_koin, AlexKoin.Slack)[:token]

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(AlexKoin.Repo, []),
      # Start the endpoint when the application starts
      supervisor(AlexKoinWeb.Endpoint, []),
      # Start your own worker by calling: AlexKoin.Worker.start_link(arg1, arg2, arg3)
      # worker(AlexKoin.Worker, [arg1, arg2, arg3]),
      %{
        id: Slack.Bot,
        start: { Slack.Bot, :start_link, [AlexKoin.SlackRtm, [], slack_token] }
      }
    ]

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
