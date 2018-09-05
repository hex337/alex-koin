defmodule AlexKoin.Factoids do
  alias AlexKoin.Repo
  alias AlexKoin.Account
  alias AlexKoin.Account.{User, Wallet, Transaction}
  alias AlexKoin.Coins.Coin

  def koins_this_week do
    date = Timex.shift(Timex.now, days: -7)
    count = Repo.one(Coin.count_from_date(date))

    "In the last 7 days, Chime has mined a total of #{count} koins."
  end

  def total_koins do
    date = %DateTime{year: 2018, month: 1, day: 1, hour: 1, minute: 1, second: 1, time_zone: "America/Los_Angeles", zone_abbr: "PST", utc_offset: -28800, std_offset: 0}
    count = Repo.one(Coin.count_from_date(date))

    "Chime has mined total of #{count} koins since the dawn of Koin." 
  end
end
