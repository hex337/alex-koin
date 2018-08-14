defmodule AlexKoin.SlackRtm do
  @slack_module Application.get_env(
    :alex_koin, :slack_module, Slack.Sends
  )

  alias AlexKoin.SlackCommands

  def handle_connect(slack, state) do
    IO.puts "Connected as #{slack.me.name}"
    {:ok, state}
  end

  def handle_event(message = %{type: "message", text: "<@UC37P4L3Y> " <> text, user: user}, slack, state) do
    SlackCommands.get_or_create(user)
    |> create_reply(message, message_type(text)) # returns tuple {text, message_ts}
    |> send_raw_message(message.channel, slack)

    {:ok, state}
  end

  def handle_event(_, _, state), do: {:ok, state}

  def handle_info({:message, text, channel}, slack, state) do
    IO.puts "Sending your message, captain!"

    @slack_module.send_message(text, channel, slack)

    {:ok, state}
  end

  def handle_info(_, _, state), do: {:ok, state}

  defp message_type(text) do
    cond do
      text =~ "my balance" -> {:balance, text}
      text =~ "create koin" -> {:create, text}
      text =~ "transfer" -> {:transfer, text}
      text =~ "list koins" -> {:list_koins, text}
      text =~ "leaderboard" -> {:leaderboard, text}
    end
  end

  defp create_reply(user, message, {:balance, _text}) do
    balance = SlackCommands.get_balance(user_wallet(user))

    {"You have #{balance}:akc:.", message_ts(message)}
  end
  defp create_reply(user = %{slack_id: "U8BBZEB35"}, _message, {:create, text}) do
    " create koin " <> reason = text
    coin = user |> SlackCommands.create_coin(reason)

    {"Created a new coin: `#{coin.hash}` with origin: '#{coin.origin}'", nil}
  end
  defp create_reply(user, _message, {:transfer, text}) do
    regex = ~r/ transfer (?<coin_uuid>[0-9a-zA-Z-]+) to <@(?<to_slack_id>[A-Z0-9]+)> (?<memo>.*)/
    captures = Regex.named_captures(regex, text)
    IO.puts inspect(captures)

    to_user = SlackCommands.get_or_create(captures["to_slack_id"])
    coin = AlexKoin.Coins.Coin |> AlexKoin.Repo.get_by(hash: captures["coin_uuid"])

    # validate this coin belongs to the user currently
    if coin.wallet_id == user_wallet(user).id do
      SlackCommands.transfer_coin(coin, user_wallet(user), user_wallet(to_user), captures["memo"])
      {"Transfered coin.", nil}
    else
      {"You don't own that coin.", nil}
    end
  end
  defp create_reply(user, _, {:list_koins, _text}), do: SlackCommands.get_coins(user_wallet(user))
  defp create_reply(user,_,_), do: IO.inspect(user); {nil, nil}

  defp user_wallet(_user = %{id: user_id}) do
    AlexKoin.Repo.get_by(AlexKoin.Account.Wallet, user_id: user_id)
  end
  defp message_ts(%{thread_ts: message_ts}), do: message_ts
  defp message_ts(%{ts: message_ts}), do: message_ts

  defp send_raw_message({text, message_ts}, channel, slack) do
    %{
      type: "message",
      text: text,
      channel: channel,
      thread_ts: message_ts
    }
    |> Poison.encode!()
    |> @slack_module.send_raw(slack)
  end
end
