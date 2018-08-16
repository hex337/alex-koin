defmodule AlexKoin.SlackRtm do
  @slack_module Application.get_env(
    :alex_koin, :slack_module, Slack.Sends
  )

  @koin_bot_id Application.get_env(:alex_koin, :koin_bot_id)

  alias AlexKoin.SlackCommands

  def handle_connect(slack, state) do
    IO.puts "Connected as #{slack.me.name}"
    {:ok, state}
  end

  def handle_event(%{type: "message", user: @koin_bot_id}, _slack, state), do: {:ok, state}
  def handle_event(message = %{type: "message", channel: "D" <> _rest, user: user}, slack, state) do
    handle_msg(user, message, message_type(message.text), slack, state)
  end

  def handle_event(message = %{type: "message", text: "<@" <> @koin_bot_id <> "> " <> text, user: user}, slack, state) do
    handle_msg(user, message, message_type(text), slack, state)
  end

  def handle_event(_, _, state), do: {:ok, state}

  def handle_info({:message, text, channel}, slack, state) do
    IO.puts "Sending your message, captain!"

    @slack_module.send_message(text, channel, slack)

    {:ok, state}
  end

  def handle_info(_, _, state), do: {:ok, state}

  defp handle_msg(user, message, message_type, slack, state) do
    SlackCommands.get_or_create(user)
    |> create_reply(message, message_type) # returns tuple {text, message_ts}
    |> send_raw_message(message.channel, slack)

    {:ok, state}
  end

  defp message_type(text) do
    cond do
      text =~ "my balance" -> {:balance, text}
      text =~ "create koin" -> {:create, text}
      text =~ "transfer" -> {:transfer, text}
      text =~ "list koins" -> {:list_koins, text}
      text =~ "leaderboard" -> {:leaderboard, text}
      true -> {:nothing, text}
    end
  end

  defp create_reply(user, message, {:balance, _text}) do
    balance = SlackCommands.get_balance(user_wallet(user))

    {"You have #{balance}:akc:.", message_ts(message)}
  end
  defp create_reply(user = %{slack_id: "U8BBZEB35"}, _message, {:create, text}) do
    coin = user |> SlackCommands.create_coin(reason(text))

    {"Created a new coin: `#{coin.hash}` with origin: '#{coin.origin}'", nil}
  end
  defp create_reply(user, _message, {:transfer, text}) do
    regex = ~r/transfer (?<coin_uuid>[0-9a-zA-Z-]+) to <@(?<to_slack_id>[A-Z0-9]+)> (?<memo>.*)/
    %{"memo" => memo, "to_slack_id" => to_slack_id, "coin_uuid" => coin_uuid} = Regex.named_captures(regex, text)

    to_user = SlackCommands.get_or_create(to_slack_id)
    coin = AlexKoin.Coins.Coin |> AlexKoin.Repo.get_by(hash: coin_uuid)

    # validate this coin belongs to the user currently
    if coin.wallet_id == user_wallet(user).id do
      SlackCommands.transfer_coin(coin, user_wallet(user), user_wallet(to_user), memo)

      # Notify the recipient of the new koin
      #notify_msg = "<@#{user.slack_id}> just transfered 1.0 :akc: with the memo: '#{memo}'"
      #dm_channel = Slack.Web.Im.open(%{user: to_user.slack_id})
      #  |> Map.get("channel")
      #  |> Map.get("id")

      #send_raw_message({notify_msg, nil}, dm_channel, slack)

      {"Transfered coin.", nil}
    else
      {"You don't own that coin.", nil}
    end
  end
  defp create_reply(user, _, {:list_koins, _text}), do: SlackCommands.get_coins(user_wallet(user))
  defp create_reply(user,_,_), do: nil

  defp user_wallet(_user = %{id: user_id}) do
    AlexKoin.Repo.get_by(AlexKoin.Account.Wallet, user_id: user_id)
  end
  defp message_ts(%{channel: "D" <> _rest}), do: nil
  defp message_ts(%{thread_ts: message_ts}), do: message_ts
  defp message_ts(%{ts: message_ts}), do: message_ts

  defp send_raw_message(nil, _channel, _slack) do
  end

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

  defp reason(text) do
    %{"reason" => reason} = Regex.named_captures(~r/create koin\s+(?<reason>.*)/, text)
    reason
  end
end
