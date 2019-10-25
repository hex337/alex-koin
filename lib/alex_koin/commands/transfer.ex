defmodule AlexKoin.Commands.Transfer do
  require Logger
  alias AlexKoin.SlackCommands
  alias AlexKoin.SlackDataHelpers

  def execute(user, message, slack, memo, to_slack_id, amount, localization) do
    usr_wlt_amt = Kernel.round(user.wallet.balance)
    {amt, _rem} = Integer.parse(amount)
    to_user = SlackCommands.get_or_create(to_slack_id, slack)
    Logger.info "#{user.first_name} is transfering #{amt} koin to #{to_user.first_name}.", ansi_color: :green

    transfer_reply(usr_wlt_amt, amt, user, to_user, message, memo, slack, localization)
  end

  defp transfer_reply(usr_amount, amt, _user, _to_user, message, _memo, _slack, _loc) when usr_amount < amt, do: {"Not enough koin to do that transfer.", SlackDataHelpers.message_ts(message)}
  defp transfer_reply(_usr_amount, _amt, user, to_user, message, _memo, _slack, _loc) when user == to_user, do: {"How about a big ol' ball of nope.", SlackDataHelpers.message_ts(message)}
  defp transfer_reply(_usr_amount, amt, user, to_user, message, memo, slack, localization) do
    SlackCommands.transfer(user.wallet, to_user.wallet, amt, memo)
    notify_msg = "<@#{user.slack_id}> just transfered #{amt} :akc: for: '#{memo}'"

    SlackDataHelpers.dm_user(to_user, slack, notify_msg)

    {"Transfered koin#{transfer_reply_post(localization)}", SlackDataHelpers.message_ts(message)}
  end

  defp transfer_reply_post(loc) when loc == "us", do: "."
  defp transfer_reply_post(loc) when loc == "ca", do: ", eh?"
  defp transfer_reply_post(_loc) do
    "."
  end
end
