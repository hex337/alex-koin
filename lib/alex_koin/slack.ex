defmodule AlexKoin.SlackRtm do
  use Slack

  alias AlexKoin.SlackCommands

  def handle_connect(slack, state) do
    IO.puts "Connected as #{slack.me.name}"
    {:ok, state}
  end

  def handle_event(message = %{type: "message"}, slack, state) do
    bot_user_id = "UC37P4L3Y"
    admin_id = "U8BBZEB35"

    if Map.has_key?(message, :text) && Map.has_key?(message, :user) && String.starts_with?(message.text, "<@#{bot_user_id}>") do
      text_with_bot = message.text
      "<@UC37P4L3Y> " <> text = text_with_bot 
      user = SlackCommands.get_or_create(message.user)
      user_wallet = AlexKoin.Account.Wallet |> AlexKoin.Repo.get_by(user_id: user.id)
      is_admin = user.slack_id == admin_id

      IO.puts inspect(message)

      if text =~ "my balance" do
        msg_ts = case Map.has_key?(message, :thread_ts) do
          true -> message.thread_ts
          false -> message.ts
        end

        IO.puts "#{user.id} is asking about their balance"

        balance = user_wallet |> SlackCommands.get_balance

        msg = "You have #{balance}:akc:."

        %{
          type: "message",
          text: msg,
          channel: message.channel,
          thread_ts: msg_ts
        }
        |> Poison.encode!()
        |> send_raw(slack)
      end

      if text =~ "create koin" && is_admin do
        "create koin " <> reason = text
        coin = user |> SlackCommands.create_coin(reason)

        send_message("Created a new coin: `#{coin.hash}` with origin: '#{coin.origin}'", message.channel, slack)
      end

      if text =~ "transfer" do
        regex = ~r/transfer (?<coin_uuid>[0-9a-zA-Z-]+) to <@(?<to_slack_id>[A-Z0-9]+)> (?<memo>.*)/
        captures = Regex.named_captures(regex, text)
        IO.puts inspect(captures)

        to_user = SlackCommands.get_or_create(captures["to_slack_id"])
        coin = AlexKoin.Coins.Coin |> AlexKoin.Repo.get_by(hash: captures["coin_uuid"])

        # validate this coin belongs to the user currently
        if coin.wallet_id == user_wallet.id do
          SlackCommands.transfer_coin(coin, user, to_user, captures["memo"])

          send_message("Transfered coin.", message.channel, slack)
        else
          send_message("You don't own that coin.", message.channel, slack)
        end
      end

      if text =~ "list koins" do
        SlackCommands.get_coins(user_wallet)
      end

      if text =~ "leaderboard" do
      end
    end

    #send_message("I got a message!", message.channel, slack)
    {:ok, state}
  end

  def handle_event(_, _, state), do: {:ok, state}

  def handle_info({:message, text, channel}, slack, state) do
    IO.puts "Sending your message, captain!"

    send_message(text, channel, slack)

    {:ok, state}
  end

  def handle_info(_, _, state), do: {:ok, state}
end
