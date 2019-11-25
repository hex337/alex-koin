defmodule AlexKoin.Commands.Balance do
  require Logger
  alias AlexKoin.SlackDataHelpers
  alias AlexKoin.Account

  def execute(user, message) do
    Logger.info("#{user.first_name} is asking about their balance.", ansi_color: :green)
    balance = Account.wallet_for_user(user).balance
    {"You have #{balance} :akc:.", SlackDataHelpers.message_ts(message)}
  end
end
