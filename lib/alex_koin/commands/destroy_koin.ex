defmodule AlexKoin.Commands.DestroyKoin do
  require Logger
  alias AlexKoin.Repo
  alias AlexKoin.SlackCommands
  alias AlexKoin.SlackDataHelpers
  alias AlexKoin.Account.User
  alias AlexKoin.Coins.Coin

  def execute(user, _message, text, slack, amount \\ 1) do
    cond do
      User.admin?(user) ->
        do_destroy_koin(user, amount, text, slack)

      User.koin_lord?(user) ->
        do_destroy_koin(user, amount, text, slack)

      true ->
        peasant_message = "You pathetic human you don't have any family any friends or any land"
        SlackDataHelpers.message_ts(peasant_message)
    end
  end

  defp do_destroy_koin(user, amount, text, slack) do
    regex = ~r/<@(?<to_slack_id>[A-Z0-9]+)> for (?<reason>.*)/
    if Regex.match?(regex, text) do
      %{"to_slack_id" => to_slack_id, "reason" => reason} = Regex.named_captures(regex, text)
      to_user = SlackCommands.get_or_create(to_slack_id, slack)
      wallet = Repo.get_by(AlexKoin.Account.Wallet, user_id: to_user.id)

      if wallet.balance >= amount do
        Logger.info("#{user.first_name} #{user.last_name} destroying koin.", ansi_color: :green)
        SlackCommands.remove_coins(wallet, amount)

        koin_removed_message = "#{amount} of your koin has been destroyed. Reason: #{reason}"
        SlackDataHelpers.dm_user(to_user, slack, koin_removed_message)
      else
        insufficient_koin_message = "You cannot destroy koin that does not exist. Try giving the user koin so that you can destroy it."
        SlackDataHelpers.message_ts(insufficient_koin_message)
      end
    else
      invalid_syntax_message = "Invalid syntax: `destroy koin [@user] for [reason here]`"
      SlackDataHelpers.message_ts(invalid_syntax_message)
    end
  end
end
