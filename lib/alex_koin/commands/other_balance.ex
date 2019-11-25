defmodule AlexKoin.Commands.OtherBalance do
  require Logger
  alias AlexKoin.SlackCommands
  alias AlexKoin.SlackDataHelpers
  alias AlexKoin.Account

  def execute(_user, slack_id_to_check, message, slack) do
    balance =
      SlackCommands.get_or_create(slack_id_to_check, slack)
      |> user_wallet
      |> Account.Wallet.balance()

    slack_display_name =
      SlackDataHelpers.name_to_display_from_slack_id(slack_id_to_check, slack.users)

    {"#{slack_display_name} has #{balance} :akc:", SlackDataHelpers.message_ts(message)}
  end

  defp user_wallet(user) do
    user.wallet
  end
end
