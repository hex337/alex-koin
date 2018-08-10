defmodule AlexKoin.SlackRtm do
  use Slack

  alias AlexKoin.SlackCommands

  def handle_connect(slack, state) do
    IO.puts "Connected as #{slack.me.name}"
    {:ok, state}
  end

  def handle_event(message = %{type: "message", text: "<UC37P4L3Y>" <> text, user: user}, slack, state) do
    user = SlackCommands.get_or_create(user)
    
    IO.puts inspect(message)

    handle_message(user, message, slack, message_type(text))

    {:ok, state}
  end

  def handle_event(_, _, state), do: {:ok, state}

  def handle_info({:message, text, channel}, slack, state) do
    IO.puts "Sending your message, captain!"

    send_message(text, channel, slack)

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

  defp handle_message(user, message, slack, {:balance, _text}) do
    msg_ts = case Map.has_key?(message, :thread_ts) do
      true -> message.thread_ts
      false -> message.ts
    end

    IO.puts "#{user.id} is asking about their balance"

    msg = "You have #{SlackCommands.get_balance(user_wallet(user))}:akc:."

    %{
      type: "message",
      text: msg,
      channel: message.channel,
      thread_ts: msg_ts
    }
    |> Poison.encode!()
    |> send_raw(slack)
  end
  defp handle_message(user = %{id: "U8BBZEB35"}, message, slack, {:create, text}) do
    "create koin " <> reason = text
    coin = user |> SlackCommands.create_coin(reason)

    send_message("Created a new coin: `#{coin.hash}` with origin: '#{coin.origin}'", message.channel, slack)
  end
  defp handle_message(user, message, slack, {:transfer, text}) do
    regex = ~r/transfer (?<coin_uuid>[0-9a-zA-Z-]+) to <@(?<to_slack_id>[A-Z0-9]+)> (?<memo>.*)/
    captures = Regex.named_captures(regex, text)
    IO.puts inspect(captures)

    to_user = SlackCommands.get_or_create(captures["to_slack_id"])
    coin = AlexKoin.Coins.Coin |> AlexKoin.Repo.get_by(hash: captures["coin_uuid"])

    # validate this coin belongs to the user currently
    if coin.wallet_id == user_wallet(user).id do
      SlackCommands.transfer_coin(coin, user, to_user, captures["memo"])

      send_message("Transfered coin.", message.channel, slack)
    else
      send_message("You don't own that coin.", message.channel, slack)
    end
  end
  defp handle_message(user, _, _, {:list_koins, _text}), do: SlackCommands.get_coins(user_wallet(user))
  defp handle_message(_,_,_,_), do: nil

  defp user_wallet(_user = %{id: user_id}) do
    AlexKoin.Repo.get_by(AlexKoin.Account.Wallet, user_id: user_id)
  end
end
