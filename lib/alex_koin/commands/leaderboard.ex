defmodule AlexKoin.Commands.Leaderboard do
  alias AlexKoin.Repo
  alias AlexKoin.Account.User
  alias AlexKoin.SlackCommands
  alias AlexKoin.SlackDataHelpers

  def execute(_user, text, slack) do
    limit = fetch_limit_from_input(text)
    board = SlackCommands.leaderboard_v2(limit)

    leader_text = board
                  |> Enum.map(fn(map) -> leaderboard_text(map, slack) end)
                  |> Enum.join("\n")

    {leader_text, nil}
  end

  defp leaderboard_text(map, slack) do
    {:ok, user_id} = Map.fetch(map, :user_id)
    {:ok, score} = Map.fetch(map, :score)
    user = Repo.get_by(User, id: user_id)
    "#{score} points :star: - #{SlackDataHelpers.name_to_display_from_slack_id(user.slack_id, slack.users)}"
  end

  defp fetch_limit_from_input(text) when text == "leaderboard", do: 5
  defp fetch_limit_from_input(text) do
    regex = ~r/leaderboard (?<limit>[0-9]+)/

    if Regex.match?(regex, text) do
      %{"limit" => input_limit} = Regex.named_captures(regex, text)
      {limit, _rem} = Integer.parse(input_limit)

      limit
    else
      5
    end
  end
end
