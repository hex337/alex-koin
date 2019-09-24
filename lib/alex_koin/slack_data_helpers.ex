defmodule AlexKoin.SlackDataHelpers do
  @slack_module Application.get_env(
    :alex_koin, :slack_module, Slack.Sends
  )

  def message_ts(%{channel: "D" <> _rest}), do: nil
  def message_ts(%{thread_ts: message_ts}), do: message_ts
  def message_ts(%{ts: message_ts}), do: message_ts

  def channel_id_for_name(name, channels) do
    Enum.into(channels, [])
    |> get_channel_id_from_name(name)
  end

  defp get_channel_id_from_name([], _), do: nil
  defp get_channel_id_from_name([{id, %{name: found_name}} | _rest], name) when name == found_name, do: id
  defp get_channel_id_from_name([_|rest], name), do: get_channel_id_from_name(rest, name)

  def dm_channel_for_slack_id(slack_id, ims) do
    Enum.into(ims, [])
    |> get_channel_id(slack_id)
  end

  defp get_channel_id([], _), do: nil
  defp get_channel_id([{id, %{user: uid}} | _rest], user_id) when uid == user_id, do: id
  defp get_channel_id([_|rest], user_id), do: get_channel_id(rest, user_id)

  def name_to_display_from_slack_id(slack_id, profiles) do
    case Map.fetch(profiles, slack_id) do
      :error -> ""
      {:ok, user_info} -> name_to_display(user_info)
    end
  end

  defp name_to_display(%{ profile: %{ display_name: display_name } }) when display_name != "", do: display_name
  defp name_to_display(%{ profile: %{ real_name: real_name } }) when real_name != "", do: real_name
  defp name_to_display(%{ profile: _profile }), do: "" # Catch all if we don't have what we need
  defp name_to_display(nil), do: ""

  def dm_user(user, slack, msg) do
    dm_channel = dm_channel_for_slack_id(user.slack_id, slack.ims)
    send_direct_msg({msg, nil}, slack, dm_channel)
  end

  defp send_direct_msg(_msg, _slack, nil) do
  end
  defp send_direct_msg(msg, slack, dm_channel) do
    send_raw_message({msg, nil}, dm_channel, slack)
  end

  def send_raw_message(nil, _channel, _slack) do
  end
  def send_raw_message({text, message_ts}, channel, slack) do
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
