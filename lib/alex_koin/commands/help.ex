defmodule AlexKoin.Commands.Help do
  alias AlexKoin.SlackDataHelpers

  @koin_lord_ids Application.get_env(:alex_koin, :koin_lord_ids)

  def execute(message, slack) do
    koin_lord_names = String.split(@koin_lord_ids, ",")
                      |> Enum.map(fn id -> SlackDataHelpers.name_to_display_from_slack_id(id, slack.users) end)

    msg = "Any questions about Alex Koin can be directed to the Lords of Koin: #{Enum.join(koin_lord_names, ", ")}"
    {msg, SlackDataHelpers.message_ts(message)}
  end
end
