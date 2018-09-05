defmodule AlexKoin.SlackCommands do
  alias AlexKoin.Repo
  alias AlexKoin.Account
  alias AlexKoin.Account.{User, Wallet, Transaction}
  alias AlexKoin.Coins.Coin

  # Use slack to populate name and email
  def get_or_create(slack_id, slack) do
    user_info = case Map.fetch(slack.users, slack_id) do
      :error -> nil
      {:ok, info} -> info
    end

    user = case User |> Repo.get_by(slack_id: slack_id) do
      nil ->
        new_user = %User{ slack_id: slack_id }
        {:ok, user_obj} = Repo.insert(new_user)

        new_wallet = %Wallet{ user_id: user_obj.id, balance: 0.0 }
        {:ok, _wallet} = Repo.insert(new_wallet)

        user_obj
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

  def create_coin(user, reason) do
    user_wallet =  Wallet |> Repo.get_by(user_id: user.id)

    new_coin = %Coin{
      origin: reason,
      mined_by_id: user.id,
      hash: UUID.uuid1(),
      wallet_id: user_wallet.id
    }

    {:ok, coin} = Repo.insert(new_coin)

    # Now we create the initial transaction to set the coin up
    transfer_coin(coin, user_wallet, user_wallet, "Initial creation.")

    coin
  end

  def transfer(from_wallet, to_wallet, amount, memo) do
    # 1. get coins to transfer
    coins = Repo.all(Coin.for_wallet(from_wallet, amount))

    # 2. move the coins over to the other wallet
    Enum.each(coins, fn(c) -> transfer_coin(c, from_wallet, to_wallet, memo) end)
  end

  def transfer_coin(coin, from_wallet, to_wallet, memo) do
    #Logger.info "Transfering coin #{coin.hash} from #{from_wallet} to #{to_wallet}."

    txn = %{
        amount: 1.0,
        memo: memo,
        from_id: from_wallet.id,
        to_id: to_wallet.id,
        coin_id: coin.id
      }
    |> Transaction.changeset()
    |> Repo.insert!()

    # update the balance

    AlexKoin.Account.update_wallet(to_wallet, %{balance: to_wallet.balance + 1})
    AlexKoin.Coins.update_coin(coin, %{wallet_id: to_wallet.id})

    if from_wallet.id != to_wallet.id do # if we're not creating a coin, decrement the from_wallet
      AlexKoin.Account.update_wallet(from_wallet, %{balance: from_wallet.balance - 1})
    end

    txn
  end

  # Returns wallet objects with the users preloaded.
  def leaderboard(limit) do
    wallets = Repo.all(Wallet.by_balance(limit))
    min_balance = List.last(wallets).balance

    Repo.all(Wallet.by_minimum_balance(min_balance))
  end

  def fact() do
    fact_funcs = AlexKoin.Factoids.__info__(:functions)

    {func_name, _arity} = Enum.random(fact_funcs)
    apply(AlexKoin.Factoids, func_name, [])
  end
end
