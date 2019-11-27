defmodule AlexKoin.SlackCommands do
  require Logger

  import Ecto.Query, only: [from: 2]
  alias Ecto.Multi

  alias AlexKoin.Repo
  alias AlexKoin.Account
  alias AlexKoin.Account.{User, Wallet, Transaction}
  alias AlexKoin.Coins
  alias AlexKoin.Coins.Coin

  # Use slack to populate name and email
  def get_or_create(slack_id, slack) do
    user_info =
      case Map.fetch(slack.users, slack_id) do
        :error -> nil
        {:ok, info} -> info
      end

    user =
      case Repo.one(from(u in User, where: u.slack_id == ^slack_id, preload: [:wallet])) do
        nil ->
          new_user = %User{slack_id: slack_id}
          {:ok, user_obj} = Repo.insert(new_user)

          new_wallet = %Wallet{user_id: user_obj.id, balance: 0.0}
          {:ok, _wallet} = Repo.insert(new_wallet)

          Repo.one(from(u in User, where: u.slack_id == ^slack_id, preload: [:wallet]))

        db_user ->
          db_user
      end

    update_user_info(user, user_info)
  end

  defp update_user_info(user, nil), do: user

  defp update_user_info(user, %{
         profile: %{first_name: first_name, last_name: last_name, email: email}
       }) do
    if user.first_name != first_name || user.last_name != last_name || user.email != email do
      {:ok, updated_user} =
        Account.update_user(user, %{first_name: first_name, last_name: last_name, email: email})

      updated_user
    else
      user
    end
  end

  defp update_user_info(user, _user_info), do: user

  defp get_wallet(%User{id: user_id}) do
    Wallet
    |> Repo.get_by(user_id: user_id)
    |> case do
      nil -> {:error, :not_found}
      wallet -> {:ok, wallet}
    end
  end

  def create_coin(user = %User{}, created_by_user = %User{}, reason) do
    Multi.new
    |> Multi.run(:wallet, fn _repo, _changes->
      get_wallet(user)
    end)
    |> Multi.run(:new_coin, fn _repo, %{wallet: wallet} ->
      Coins.create_coin(%{
        origin: reason,
        mined_by_id: user.id,
        hash: UUID.uuid1(),
        created_by_user_id: created_by_user.id,
        wallet_id: wallet.id
      })
    end)
    |> Multi.run(:transfer_coin, fn _repo, %{new_coin: new_coin, wallet: wallet} ->
      # Now we create the initial transaction to set the coin up
      {:ok, _txn} = transfer_coin(new_coin, wallet, wallet, "Initial creation.")
    end)
    |> Repo.transaction
    |> case do
      {:ok, %{new_coin: new_coin}} -> {:ok, new_coin}
      err -> err
    end
  end

  def remove_coins(from_wallet = %Wallet{balance: balance}, amount) do
    Multi.new
    |> Multi.run(:delete_coins, fn _, _ ->
      coins =
        from_wallet
        |> Coin.for_wallet(amount)
        |> Repo.all()

      if length(coins) == amount do
        Enum.each(coins, &Coins.delete_coin(&1))
        {:ok, amount}
      else
        {:error, :not_enough_coins}
      end
    end)
    |> Multi.run(:update_wallet, fn _, _ ->
      AlexKoin.Account.update_wallet(from_wallet, %{balance: balance - amount})
    end)
    |> Repo.transaction
    |> case do
      {:ok, _} -> :ok
      {:error, :delete_coins, :not_enough_coins, _} -> {:error, :not_enough_coins}
      err -> err
    end
  end

  def transfer(%Wallet{id: from_wallet_id}, %Wallet{id: to_wallet_id}, amount, memo) do
    Multi.new
    |> Multi.run(:coins, fn _repo, _ ->
      coins = from(c in Coin,
        where: c.wallet_id == ^from_wallet_id,
        limit: ^amount)
        |> Repo.all
      {:ok, coins}
    end)
    |> Multi.run(:transaction, fn _repo, %{coins: [%{id: coin_id} | _]} ->
      transaction = %{
        amount: amount,
        memo: memo,
        from_id: from_wallet_id,
        to_id: to_wallet_id,
        coin_id: coin_id
      }
      |> Transaction.changeset()
      |> Repo.insert!()
      {:ok, transaction}
    end)
    |> Multi.run(:transfer_coin_ownership, fn _repo, %{coins: coins} ->
      coin_ids = Enum.map(coins, &(&1.id))

      from(c in Coin, where: c.id in ^coin_ids, update: [set: [wallet_id: ^to_wallet_id]])
      |> Repo.update_all([])

      {:ok, nil}
    end)
    |> Multi.run(:decrement_from_wallet, fn _repo, _ ->
      from_wallet = Repo.get(Wallet, from_wallet_id)
      Account.update_wallet(
        from_wallet,
        %{balance: from_wallet.balance - amount}
      )
      {:ok, nil}
    end)
    |> Multi.run(:increment_to_wallet, fn _repo, _ ->
      to_wallet = Repo.get(Wallet, to_wallet_id)
      Account.update_wallet(
        to_wallet,
        %{balance: to_wallet.balance + amount}
      )
      {:ok, nil}
    end)
    |> Repo.transaction
    |> case do
      {:ok, %{transaction: transaction}} -> {:ok, transaction}
      {:error, err} -> {:error, err}
    end
  end

  def transfer_coin(coin, from_wallet, to_wallet, memo) do
    Logger.info("Transfering koin #{coin.id} from #{from_wallet.id} to #{to_wallet.id}",
      ansi_color: :green
    )

    txn =
      %{
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

    # if we're not creating a coin, decrement the from_wallet
    if from_wallet.id != to_wallet.id do
      from_wallet = Wallet |> Repo.get_by(id: from_wallet.id)
      AlexKoin.Account.update_wallet(from_wallet, %{balance: from_wallet.balance - 1})
    end

    {:ok, txn}
  end

  # Returns wallet objects with the users preloaded.
  def leaderboard(limit) do
    limit
    |> Wallet.by_balance()
    |> Repo.all()
    |> List.last()
    |> case do
      nil ->
        {:ok, []}

      # Fetch again so that to include additional wallets with equal balance to the minimum
      %Wallet{balance: min_balance} ->
        min_balance
        |> Wallet.by_minimum_balance()
        |> Repo.all()

    end
  end

  def leaderboard_v2(limit) do
    mined_mult = 2.0
    transfered_mult = 0.25
    received_mult = 0.5

    start_of_week = Timex.beginning_of_week(Timex.now(), :sun)

    # First, get all koins mined in the last 7 days
    mined_koins = Repo.all(Coin.mined_since(start_of_week))
    # Get all transfers for the last 7 days
    transactions = Repo.all(Account.transactions_since(start_of_week))

    # Create a map of User id's to number of koins mined
    mined_koin_scores =
      mined_koins
      |> Enum.group_by(& &1.mined_by_id)
      |> Enum.map(fn {user_id, koins_ids} -> {user_id, Enum.count(koins_ids) * mined_mult} end)
      |> Enum.into(%{})

    transfered_koin_scores =
      transactions
      |> Enum.group_by(& &1.from_id)
      |> Enum.map(fn {user_id, from_ids} ->
        {user_id, Enum.count(Enum.uniq(from_ids)) * transfered_mult}
      end)
      |> Enum.into(%{})

    received_koin_scores =
      transactions
      |> Enum.group_by(& &1.to_id)
      |> Enum.map(fn {user_id, to_ids} ->
        {user_id, Enum.count(Enum.uniq(to_ids)) * received_mult}
      end)
      |> Enum.into(%{})

    # Now we go through and add up the scores:
    scores =
      mined_koin_scores
      |> Map.merge(transfered_koin_scores, fn _k, score1, score2 -> score1 + score2 end)
      |> Map.merge(received_koin_scores, fn _k, score1, score2 -> score1 + score2 end)
      |> Map.to_list()
      |> Enum.sort_by(&elem(&1, 1), &>=/2)
      |> Enum.slice(0, limit)

    # This should give us a list like [{user_id, score}, {user_id, score}], and we want to
    # turn that into [{user_id: id, score: score}, {user_id: id, score: score}]
    Enum.map(scores, fn tup -> %{user_id: elem(tup, 0), score: elem(tup, 1)} end)
  end
end
