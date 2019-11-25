defmodule AlexKoin.SlackRtm do
  require Logger
  alias AlexKoin.SlackCommands
  alias AlexKoin.Repo
  alias AlexKoin.Commands
  alias AlexKoin.SlackDataHelpers

  @slack_module Application.get_env(
                  :alex_koin,
                  :slack_module,
                  Slack.Sends
                )

  @koin_bot_id Application.get_env(:alex_koin, :koin_bot_id)
  @admin_id Application.get_env(:alex_koin, :admin_id)

  def handle_close(_info, _slack, state) do
    {:ok, state}
  end

  def handle_connect(slack, state) do
    IO.puts("Connected as #{slack.me.name}")
    {:ok, state}
  end

  def handle_event(%{type: "message", user: @koin_bot_id}, _slack, state), do: {:ok, state}

  def handle_event(message = %{type: "message", channel: "D" <> _rest, user: user}, slack, state) do
    handle_msg(user, message, message_type(message.text), slack, state)
  end

  def handle_event(
        message = %{type: "message", text: "<@" <> @koin_bot_id <> "> " <> text, user: user},
        slack,
        state
      ) do
    handle_msg(user, message, message_type(text), slack, state)
  end

  def handle_event(_, _, state), do: {:ok, state}

  def handle_info({:message, text, channel}, slack, state) do
    IO.puts("Sending your message, captain!")

    @slack_module.send_message(text, channel, slack)

    {:ok, state}
  end

  def handle_info(_, _, state), do: {:ok, state}

  defp handle_msg(user, message, message_type, slack, state) do
    SlackCommands.get_or_create(user, slack)
    # returns tuple {text, message_ts}
    |> create_reply(message, message_type, slack)
    |> SlackDataHelpers.send_raw_message(message.channel, slack)

    {:ok, state}
  end

  defp message_type(text) do
    match_text = String.downcase(text)

    cond do
      match_text == "fact" -> {:fact, text}
      match_text == "help" -> {:help, text}
      match_text =~ "create koin" -> {:create, text}
      match_text =~ "my balance" -> {:balance, text}
      match_text =~ "balance for" -> {:other_balance, text}
      match_text =~ "transfer" -> {:transfer, text}
      match_text =~ "list koins" -> {:list_koins, text}
      match_text =~ "leaderboard" -> {:leaderboard, text}
      match_text =~ "announce" -> {:announce, text}
      match_text =~ "display" -> {:display, text}
      true -> {:nothing, text}
    end
  end

  defp create_reply(user, message, {:balance, _text}, _slack) do
    Commands.Balance.execute(user, message)
  end

  defp create_reply(user, message, {:other_balance, text}, slack) do
    regex = ~r/<@(?<slack_id>[A-Z0-9]+)>/

    if Regex.match?(regex, text) do
      %{"slack_id" => slack_id} = Regex.named_captures(regex, text)
      Commands.OtherBalance.execute(user, slack_id, message, slack)
    end
  end

  defp create_reply(_user, _message, {:fact, _text}, _slack) do
    Commands.Fact.execute()
  end

  defp create_reply(_user, message, {:help, _text}, slack) do
    Commands.Help.execute(message, slack)
  end

  defp create_reply(user, message, {:create, text}, slack) do
    Commands.CreateKoin.execute(user, message, text, slack)
  end

  defp create_reply(user, message, {:transfer, text}, slack) do
    regex = ~r/transfer (?<amount>[0-9]+) to <@(?<to_slack_id>[A-Z0-9]+)> (?<memo>.*)/
    regex_canada_localized = ~r/transfer a loon(ie)? to <@(?<to_slack_id>[A-Z0-9]+)> (?<memo>.*)/
    regex_canada_localized2 = ~r/transfer a toonie to <@(?<to_slack_id>[A-Z0-9]+)> (?<memo>.*)/

    cond do
      Regex.match?(regex, text) ->
        %{"memo" => memo, "to_slack_id" => to_slack_id, "amount" => amount} =
          Regex.named_captures(regex, text)

        loc = "us"
        Commands.Transfer.execute(user, message, slack, memo, to_slack_id, amount, loc)

      Regex.match?(regex_canada_localized, text) ->
        %{"memo" => memo, "to_slack_id" => to_slack_id} =
          Regex.named_captures(regex_canada_localized, text)

        amount = "1"
        loc = "ca"
        Commands.Transfer.execute(user, message, slack, memo, to_slack_id, amount, loc)

      Regex.match?(regex_canada_localized2, text) ->
        %{"memo" => memo, "to_slack_id" => to_slack_id} =
          Regex.named_captures(regex_canada_localized2, text)

        amount = "2"
        loc = "ca"
        Commands.Transfer.execute(user, message, slack, memo, to_slack_id, amount, loc)

      true ->
        {"Error: Transfer format is 'transfer [koin amount: integer] to @user [memo here]'",
         SlackDataHelpers.message_ts(message)}
    end
  end

  defp create_reply(user, _message, {:leaderboard, text}, slack) do
    Commands.Leaderboard.execute(user, text, slack)
  end

  defp create_reply(user, message, {:display, text}, slack) do
    regex = ~r/display (?<msg>.*)/

    if Regex.match?(regex, text) do
      %{"msg" => msg} = Regex.named_captures(regex, text)
      usr_wlt_amt = Kernel.round(user_wallet(user).balance)

      display_message(usr_wlt_amt, user, message, msg, slack)
    end
  end

  defp create_reply(_user = %{slack_id: @admin_id}, _message, {:announce, text}, slack) do
    regex = ~r/announce (?<msg>.*)/

    if Regex.match?(regex, text) do
      %{"msg" => msg} = Regex.named_captures(regex, text)
      Logger.info("Sending announcement: '#{msg}'", ansi_color: :green)
      channel = SlackDataHelpers.channel_id_for_name("alex_koin", slack.channels)

      if channel do
        SlackDataHelpers.send_raw_message({msg, nil}, channel, slack)
      end
    end

    {"Announcement sent.", nil}
  end

  defp create_reply(_user, _, _, _), do: nil

  defp user_wallet(_user = %{id: user_id}) do
    Repo.get_by(AlexKoin.Account.Wallet, user_id: user_id)
  end

  defp display_message(amt, _user, message, _text, _slack) when amt < 1,
    do: {"Insufficient koin.", SlackDataHelpers.message_ts(message)}

  defp display_message(_amt, user, message, text, slack) do
    # Spend a koin first, then display
    SlackCommands.remove_coins(user_wallet(user), 1)
    channel = "GKGAM9DD1"

    SlackDataHelpers.send_raw_message({text, nil}, channel, slack)

    {"A koin well spent, no doubt.", SlackDataHelpers.message_ts(message)}
  end
end
