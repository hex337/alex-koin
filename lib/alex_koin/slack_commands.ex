defmodule AlexKoin.SlackCommands do
  require Logger

  import Ecto.Query, only: [from: 2]

  alias AlexKoin.Repo
  alias AlexKoin.Account
  alias AlexKoin.Account.{User, Wallet, Transaction}
  alias AlexKoin.Coins
  alias AlexKoin.Coins.Coin

  # Use slack to populate name and email
  def get_or_create(slack_id, slack) do
    user_info = case Map.fetch(slack.users, slack_id) do
      :error -> nil
      {:ok, info} -> info
    end

    user = case Repo.one from u in User, where: u.slack_id == ^slack_id, preload: [:wallet] do
      nil ->
        new_user = %User{ slack_id: slack_id }
        {:ok, user_obj} = Repo.insert(new_user)

        new_wallet = %Wallet{ user_id: user_obj.id, balance: 0.0 }
        {:ok, _wallet} = Repo.insert(new_wallet)

        Repo.one from u in User, where: u.slack_id == ^slack_id, preload: [:wallet]
      db_user ->
        db_user
    end

    update_user_info(user, user_info)
  end

  defp update_user_info(user, nil), do: user
  defp update_user_info(user, %{ profile: %{ first_name: first_name, last_name: last_name, email: email }}) do
    if user.first_name != first_name || user.last_name != last_name || user.email != email do
      {:ok, updated_user} = Account.update_user(user, %{first_name: first_name, last_name: last_name, email: email})
      updated_user
    else
      user
    end
  end
  defp update_user_info(user, _user_info), do: user

  def get_balance(wallet) do
    wallet.balance
  end

  def get_coins(_wallet) do
  end

  def create_coin(user, created_by_user, reason) do
    user_wallet =  Wallet |> Repo.get_by(user_id: user.id)

    new_coin = %Coin{
      origin: reason,
      mined_by_id: user.id,
      hash: UUID.uuid1(),
      created_by_user_id: created_by_user.id,
      wallet_id: user_wallet.id
    }

    {:ok, coin} = Repo.insert(new_coin)

    # Now we create the initial transaction to set the coin up
    {:ok, _txn} = transfer_coin(coin, user_wallet, user_wallet, "Initial creation.")

    coin
  end

  def remove_coins(from_wallet, amount) do
    coins = Repo.all(Coin.for_wallet(from_wallet, amount))
    Enum.each(coins, fn(c) -> Coins.delete_coin(c) end)
    
    AlexKoin.Account.update_wallet(from_wallet, %{balance: from_wallet.balance - amount})
  end

  def transfer(from_wallet, to_wallet, amount, memo) do
    # 1. get coins to transfer
    coins = Repo.all(Coin.for_wallet(from_wallet, amount))

    # 2. move the coins over to the other wallet
    Enum.each(coins, fn(c) -> transfer_coin(c, from_wallet, to_wallet, memo) end)
  end

  def transfer_coin(coin, from_wallet, to_wallet, memo) do
    Logger.info "Transfering koin #{coin.id} from #{from_wallet.id} to #{to_wallet.id}", ansi_color: :green

    txn = %{
        amount: 1.0,
        memo: memo,
        from_id: from_wallet.id,
        to_id: to_wallet.id,
        coin_id: coin.id
      }
    |> Transaction.changeset()
    |> Repo.insert!()

    # Pull the to_wallet again in case what we have is stale
    to_wallet = Wallet |> Repo.get_by(id: to_wallet.id)
    # update the balance
    AlexKoin.Account.update_wallet(to_wallet, %{balance: to_wallet.balance + 1})
    AlexKoin.Coins.update_coin(coin, %{wallet_id: to_wallet.id})

    if from_wallet.id != to_wallet.id do # if we're not creating a coin, decrement the from_wallet
      from_wallet = Wallet |> Repo.get_by(id: from_wallet.id)
      AlexKoin.Account.update_wallet(from_wallet, %{balance: from_wallet.balance - 1})
    end

    {:ok, txn}
  end

  # Returns wallet objects with the users preloaded.
  def leaderboard(limit) do
    wallets = Repo.all(Wallet.by_balance(limit))
    min_balance = List.last(wallets).balance

    Repo.all(Wallet.by_minimum_balance(min_balance))
  end

  def leaderboard_v2(limit) do
    mined_mult = 2.0
    transfered_mult = 0.25
    received_mult = 0.5

    start_of_week = Timex.beginning_of_week(Timex.now, :sun)

    # First, get all koins mined in the last 7 days
    mined_koins = Repo.all(Coin.mined_since(start_of_week))
    # Get all transfers for the last 7 days
    transactions = Repo.all(Account.transactions_since(start_of_week))

    # Create a map of User id's to number of koins mined
    mined_koin_scores = mined_koins
                        |> Enum.group_by(&(&1.mined_by_id))
                        |> Enum.map(fn {user_id, koins_ids} -> {user_id, Enum.count(koins_ids) * mined_mult} end)
                        |> Enum.into(%{})
    transfered_koin_scores = transactions
                             |> Enum.group_by(&(&1.from_id))
                             |> Enum.map(fn {user_id, from_ids} -> {user_id, Enum.count(Enum.uniq(from_ids)) * transfered_mult} end)
                             |> Enum.into(%{})
    received_koin_scores = transactions
                           |> Enum.group_by(&(&1.to_id))
                           |> Enum.map(fn {user_id, to_ids} -> {user_id, Enum.count(Enum.uniq(to_ids)) * received_mult} end)
                           |> Enum.into(%{})

    # Now we go through and add up the scores:
    scores = mined_koin_scores
             |> Map.merge(transfered_koin_scores, fn _k, score1, score2 -> score1 + score2 end)
             |> Map.merge(received_koin_scores, fn _k, score1, score2 -> score1 + score2 end)
             |> Map.to_list
             |> Enum.sort_by(&(elem(&1, 1)), &>=/2)
             |> Enum.slice(0, limit)

    # This should give us a list like [{user_id, score}, {user_id, score}], and we want to
    # turn that into [{user_id: id, score: score}, {user_id: id, score: score}]
    Enum.map(scores, fn tup -> %{user_id: elem(tup, 0), score: elem(tup, 1)} end)
  end
end
