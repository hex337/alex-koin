defmodule AlexKoin.SlackRtm do
  require Logger
  alias AlexKoin.SlackCommands

  @slack_module Application.get_env(
    :alex_koin, :slack_module, Slack.Sends
  )

  @koin_bot_id Application.get_env(:alex_koin, :koin_bot_id)

  def handle_close(_info, _slack, state) do
    {:ok, state}
  end

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
    SlackCommands.get_or_create(user, slack)
    |> create_reply(message, message_type, slack) # returns tuple {text, message_ts}
    |> send_raw_message(message.channel, slack)

    {:ok, state}
  end

  defp message_type(text) do
    cond do
      text =~ "create koin" -> {:create, text}
      text =~ "my balance" -> {:balance, text}
      text =~ "balance for" -> {:other_balance, text}
      text =~ "transfer" -> {:transfer, text}
      text =~ "list koins" -> {:list_koins, text}
      text =~ "leaderboard" -> {:leaderboard, text}
      text =~ "fact" -> {:fact, text}
      true -> {:nothing, text}
    end
  end

  defp create_reply(user, message, {:balance, _text}, _slack) do
    Logger.info "#{user.first_name} is asking about their balance.", ansi_color: :green
    balance = SlackCommands.get_balance(user_wallet(user))
    {"You have #{balance}:akc:.", message_ts(message)}
  end
  defp create_reply(user, message, {:other_balance, text}, slack) do
    regex = ~r/<@(?<slack_id>[A-Z0-9]+)>/

    if Regex.match?(regex, text) do
      %{ "slack_id" => slack_id } = Regex.named_captures(regex, text)
      user_to_check = SlackCommands.get_or_create(slack_id, slack)
      balance = user_wallet(user_to_check) |> SlackCommands.get_balance
      Logger.info "#{user.first_name} is asking about #{user_to_check.first_name}'s balance.", ansi_color: :green

      {"#{name_to_display_from_slack_id(slack_id, slack.users)} has #{balance} :akc:", message_ts(message)}
    end
  end
  defp create_reply(_user, _message, {:fact, _text}, _slack) do
    factoid = SlackCommands.fact()
    {factoid, nil}
  end
  defp create_reply(_user = %{slack_id: "U8BBZEB35"}, _message, {:create, text}, slack) do
    regex = ~r/<@(?<to_slack_id>[A-Z0-9]+)> for (?<reason>.*)/

    if Regex.match?(regex, text) do
      %{"to_slack_id" => to_slack_id, "reason" => reason} = Regex.named_captures(regex, text)
      to_user = SlackCommands.get_or_create(to_slack_id, slack)

      coin = to_user |> SlackCommands.create_coin(reason)
      notify_creator(to_user, reason, slack)

      {"Created a new coin: `#{coin.hash}` with origin: '#{coin.origin}'", nil}
    else
      {"Invalid syntax: `create koin [@user] for [reason here]`", nil}
    end
  end
  defp create_reply(user, message, {:transfer, text}, slack) do
    regex = ~r/transfer (?<amount>[0-9]+) to <@(?<to_slack_id>[A-Z0-9]+)> (?<memo>.*)/

    if Regex.match?(regex, text) do
      %{"memo" => memo, "to_slack_id" => to_slack_id, "amount" => amount} = Regex.named_captures(regex, text)
      usr_wlt_amt = Kernel.round(user_wallet(user).balance)
      {amt, _rem} = Integer.parse(amount)
      to_user = SlackCommands.get_or_create(to_slack_id, slack)
      Logger.info "#{user.first_name} is transfering #{amt} koin to #{to_user.first_name}.", ansi_color: :green

      transfer_reply(usr_wlt_amt, amt, user, to_user, message, memo, slack)
    else
      {"Error: Transfer format is 'transfer [koin amount: integer] to @user [memo here]'", message_ts(message)}
    end
  end
  defp create_reply(user, _message, {:leaderboard, _text}, slack) do
    Logger.info "#{user.first_name} is asking for the leaderboard.", ansi_color: :green
    limit = 5
    wallets = SlackCommands.leaderboard(limit)

    leader_text = wallets
                  |> Enum.map(fn(w) -> leaderboard_text_for_wallet(w, slack) end)
                  |> Enum.join("\n")

    {leader_text, nil}
  end
  defp create_reply(user, _, {:list_koins, _text}, _slack), do: SlackCommands.get_coins(user_wallet(user))
  defp create_reply(_user,_,_,_), do: nil

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

  defp transfer_reply(usr_amount, amt, _user, _to_user, message, _memo, _slack) when usr_amount < amt, do: {"Not enough koin to do that transfer.", message_ts(message)}
  defp transfer_reply(_usr_amount, _amt, user, to_user, message, _memo, _slack) when user == to_user, do: {"No.", message_ts(message)}
  defp transfer_reply(_usr_amount, amt, user, to_user, message, memo, slack) do
    SlackCommands.transfer(user_wallet(user), user_wallet(to_user), amt, memo)
    notify_receiver(user, to_user, amt, memo, slack)
    {"Transfered koin.", message_ts(message)}
  end

  defp notify_creator(creator, reason, slack) do
    msg = "You just mined an :akc_in_motion: for '#{reason}'."
    dm_channel = dm_channel_for_slack_id(creator.slack_id, slack.ims)

    if dm_channel do
      send_raw_message({msg, nil}, dm_channel, slack)
    end
  end

  defp notify_receiver(from, to, amount, memo, slack) do
    notify_msg = "<@#{from.slack_id}> just transfered #{amount} :akc: for: '#{memo}'"
    dm_channel = dm_channel_for_slack_id(to.slack_id, slack.ims)

    if dm_channel do
      send_raw_message({notify_msg, nil}, dm_channel, slack)
    end
  end

  defp dm_channel_for_slack_id(slack_id, ims) do
    Enum.into(ims, [])
    |> get_channel_id(slack_id)
  end

  defp get_channel_id([], _), do: nil
  defp get_channel_id([{id, %{user: uid}} | _rest], user_id) when uid == user_id, do: id
  defp get_channel_id([_|rest], user_id), do: get_channel_id(rest, user_id)

  defp leaderboard_text_for_wallet(wallet, slack) do
    "#{wallet.balance} :akc: - #{name_to_display_from_slack_id(wallet.user.slack_id, slack.users)}"
  end

  defp name_to_display_from_slack_id(slack_id, profiles) do
    case Map.fetch(profiles, slack_id) do
      :error -> ""
      {:ok, user_info} -> name_to_display(user_info)
    end
  end

  defp name_to_display(%{ profile: %{ display_name: display_name } }) when display_name != "", do: display_name
  defp name_to_display(%{ profile: %{ real_name: real_name } }) when real_name != "", do: real_name
  defp name_to_display(%{ profile: _profile }), do: "" # Catch all if we don't have what we need
  defp name_to_display(nil), do: ""
end
