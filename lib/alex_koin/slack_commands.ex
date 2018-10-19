defmodule AlexKoin.SlackCommands do
  require Logger

  alias AlexKoin.Repo
  alias AlexKoin.Account
  alias AlexKoin.Account.{User, Wallet, Transaction}
  alias AlexKoin.Coins.Coin
  alias AlexKoin.Factoids

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
    {:ok, _txn} = transfer_coin(coin, user_wallet, user_wallet, "Initial creation.")

    coin
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

  def fact() do
    fact_funcs = Factoids.__info__(:functions)

    {func_name, _arity} = Enum.random(fact_funcs)
    apply(Factoids, func_name, [])
  end

  def reconcile() do
    Account.list_wallets
    |> Enum.each(fn(w) -> reconcile_wallet(w) end)
  end

  defp reconcile_wallet(wallet) do
    wallet_user = User |> Repo.get_by(id: wallet.user_id)

    coins = Repo.all(Coin.for_wallet(wallet))
    coin_count = Enum.count(coins)

    if coin_count != wallet.balance do
      Logger.info "#{wallet_user.first_name}'s wallet balance is: #{wallet.balance}", ansi_color: :green
      Logger.info "Wallet has #{coin_count} koins associated with it.", ansi_color: :green

      Logger.info "Updating wallet balance from #{wallet.balance} to #{coin_count}."
      AlexKoin.Account.update_wallet(wallet, %{balance: coin_count})
    end
  end
end
