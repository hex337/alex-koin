defmodule AlexKoin.Commands.CreateKoin do
  require Logger
  alias AlexKoin.Repo
  alias AlexKoin.SlackCommands
  alias AlexKoin.SlackDataHelpers
  alias AlexKoin.Account.User
  alias AlexKoin.Coins.Coin

  def execute(user, message, text, slack) do
    start_of_week = Timex.beginning_of_week(Timex.now(), :sun)
    created_coins_this_week = Coin.created_by_user_since(user, start_of_week) |> Repo.one()

    cond do
      User.admin?(user) ->
        do_create_coin(user, text, slack, message, 0)

      User.koin_lord?(user) ->
        do_create_coin(user, text, slack, message, 0)

      true ->
        do_create_coin(user, text, slack, message, created_coins_this_week)
    end
  end

  defp do_create_coin(user, text, slack, message, created_koin_num) do
    regex = ~r/<@(?<to_slack_id>[A-Z0-9]+)>\s+for\s+(?<reason>.*)/
    Logger.info("#{user.first_name} #{user.last_name} creating new koin.", ansi_color: :green)

    if created_koin_num >= 1 do
      Logger.info(
        "#{user.first_name} #{user.last_name} tried to create a koin, but already made one this week.",
        ansi_color: :green
      )

      {"You get 1 koin per week, try again after Sunday.", SlackDataHelpers.message_ts(message)}
    else
      if Regex.match?(regex, text) do
        %{"to_slack_id" => to_slack_id, "reason" => reason} = Regex.named_captures(regex, text)
        to_user = SlackCommands.get_or_create(to_slack_id, slack)

        if !User.admin?(user) && to_user.id == user.id do
          {"You can only create a koin for someone else.", SlackDataHelpers.message_ts(message)}
        else
          {:ok, coin} = to_user |> SlackCommands.create_coin(user, reason)
          mine_message = "You just mined an :akc: for '#{reason}'."
          SlackDataHelpers.dm_user(to_user, slack, mine_message)

          {"Created a new koin: `#{coin.hash}` with origin: '#{coin.origin}'",
           SlackDataHelpers.message_ts(message)}
        end
      else
        {"Invalid syntax: `create koin [@user] for [reason here]`",
         SlackDataHelpers.message_ts(message)}
      end
    end
  end
end
