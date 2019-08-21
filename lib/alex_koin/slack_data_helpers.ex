defmodule AlexKoin.SlackDataHelpers do
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
end
