defmodule AlexKoin.Factoids do
  alias AlexKoin.Repo
  alias AlexKoin.Coins.Coin

  def koins_this_week do
    count =
      one_week_ago()
      |> Coin.count_from_date()
      |> Repo.one()

    "In the last 7 days, Chime has mined a total of #{count} koins."
  end

  def total_koins do
    count =
      %DateTime{
        year: 2018,
        month: 1,
        day: 1,
        hour: 1,
        minute: 1,
        second: 1,
        time_zone: "America/Los_Angeles",
        zone_abbr: "PST",
        utc_offset: -28800,
        std_offset: 0
      }
      |> Coin.count_from_date()
      |> Repo.one()

    "Chime has mined total of #{count} koins since the dawn of Koin."
  end

  def random_mine_message_from_the_last_week do
    coin =
      one_week_ago()
      |> Coin.mined_since()
      |> Repo.all()
      |> Enum.random()

    {:ok, relative_str} = coin.inserted_at |> Timex.format("{relative}", :relative)

    "#{coin.user.first_name} mined a koin #{relative_str} for '#{coin.origin}'."
  end

  defp one_week_ago do
    Timex.now() |> Timex.shift(days: -7)
  end
end
