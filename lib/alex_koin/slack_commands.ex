defmodule AlexKoin.SlackCommands do
  require Logger

  import Ecto.Query, only: [from: 2]
  alias Ecto.Multi

  alias AlexKoin.Repo
  alias AlexKoin.Account
  alias AlexKoin.Account.{User, Wallet, Transaction}
  # alias AlexKoin.Coins
  alias AlexKoin.Coins.Coin

  # Use slack to populate name and email
  def get_or_create(slack_id, slack) do
    user_info =
      case Map.fetch(slack.users, slack_id) do
        :error -> nil
        {:ok, info} -> info
      end

    from(u in User, where: u.slack_id == ^slack_id, preload: [:wallet])
    |> Repo.one()
    |> case do
      nil ->
        new_user = %User{slack_id: slack_id}
        {:ok, user_obj} = Repo.insert(new_user)

        new_wallet = %Wallet{user_id: user_obj.id, balance: 0.0}
        {:ok, _wallet} = Repo.insert(new_wallet)

        Repo.one(from(u in User, where: u.slack_id == ^slack_id, preload: [:wallet]))

      db_user ->
        db_user
    end
    |> update_user_info(user_info)
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

  defp get_user_wallet(%User{id: user_id}) do
    Wallet
    |> Repo.get_by(user_id: user_id)
    |> case do
      nil -> {:error, :not_found}
      wallet -> {:ok, wallet}
    end
  end

  def create_coin(user = %User{}, created_by_user = %User{}, reason) do
    Multi.new()
    |> Multi.run(:wallet, fn _repo, _changes -> get_user_wallet(user) end)
    |> Multi.insert(:new_coin, fn %{wallet: wallet} ->
      Coin.changeset(%Coin{}, %{
        origin: reason,
        mined_by_id: user.id,
        hash: UUID.uuid1(),
        created_by_user_id: created_by_user.id,
        wallet_id: wallet.id
      })
    end)
    |> transfer_coin_multi(:new_coin, :wallet, :wallet, "Initial creation.")
    |> Repo.transaction()
    |> case do
      {:ok, %{new_coin: new_coin}} -> {:ok, new_coin}
      err -> err
    end
  end

  def remove_coins(from_wallet = %Wallet{balance: balance}, amount) do
    with {:ok, coins} <- Coin.get_amount_from_wallet(from_wallet, amount),
         multi <-
           Enum.reduce(coins, Multi.new(), fn coin, multi ->
             Multi.delete(multi, coin, coin)
           end),
         multi <-
           Multi.update(
             multi,
             :update_wallet,
             Wallet.changeset(from_wallet, %{balance: balance - amount})
           ),
         {:ok, _} <- Repo.transaction(multi) do
      :ok
    end
  end

  def transfer(from_wallet = %Wallet{id: from_wallet_id}, to_wallet = %Wallet{}, amount, memo) do
    Multi.new()
    |> Multi.run(:coins, fn _, _ -> Coin.get_amount_from_wallet(from_wallet, amount) end)
    |> Multi.insert(:transaction, fn %{coins: [%{id: coin_id} | _]} ->
      Transaction.changeset(%Transaction{}, %{
        amount: amount,
        memo: memo,
        from_id: from_wallet_id,
        to_id: to_wallet.id,
        coin_id: coin_id
      })
    end)
    |> Multi.run(:coin_ids, fn _repo, %{coins: coins} -> {:ok, Enum.map(coins, & &1.id)} end)
    |> Multi.run(:transfer_coin_ownership, fn repo, %{coin_ids: coin_ids} ->
      {update_count, nil} =
        from(c in Coin, where: c.id in ^coin_ids and c.wallet_id == ^from_wallet_id)
        |> repo.update_all(set: [wallet_id: to_wallet.id, updated_at: Timex.now()])

      if update_count == amount do
        {:ok, nil}
      else
        {:error, :coin_transfer_mismatch}
      end
    end)
    |> Multi.update(
      :decrement_from_wallet,
      Wallet.changeset(from_wallet, %{balance: from_wallet.balance - amount})
    )
    |> Multi.update(
      :increment_to_wallet,
      Wallet.changeset(to_wallet, %{balance: to_wallet.balance + amount})
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{transaction: transaction}} -> {:ok, transaction}
      err -> err
    end
  end

  defp transfer_coin_multi(multi, coin_key, from_wallet_key, to_wallet_key, memo) do
    multi
    |> Multi.insert(
      :transaction,
      fn %{^coin_key => coin, ^from_wallet_key => from_wallet, ^to_wallet_key => to_wallet} ->
        Transaction.changeset(%Transaction{}, %{
          amount: 1.0,
          memo: memo,
          from_id: from_wallet.id,
          to_id: to_wallet.id,
          coin_id: coin.id
        })
      end
    )
    |> Multi.update(
      :update_to_wallet,
      fn %{^to_wallet_key => to_wallet} ->
        Wallet.changeset(to_wallet, %{balance: to_wallet.balance + 1})
      end
    )
    |> Multi.update(:update_from_wallet, fn %{^from_wallet_key => from_wallet} ->
      Wallet.changeset(from_wallet, %{balance: from_wallet.balance - 1})
    end)
    |> Multi.update(:update_coin, fn %{^coin_key => coin, ^to_wallet_key => to_wallet} ->
      Coin.changeset(coin, %{wallet_id: to_wallet.id})
    end)
  end

  def transfer_coin(coin = %Coin{}, from_wallet = %Wallet{}, to_wallet = %Wallet{}, memo) do
    Logger.info("Transfering koin #{coin.id} from #{from_wallet.id} to #{to_wallet.id}",
      ansi_color: :green
    )

    Multi.new()
    |> Multi.run(:from_wallet, fn _, _ -> {:ok, from_wallet} end)
    |> Multi.run(:to_wallet, fn _, _ -> {:ok, to_wallet} end)
    |> Multi.run(:coin, fn _, %{from_wallet: %Wallet{id: wallet_id}} ->
      if wallet_id == coin.wallet_id do
        {:ok, coin}
      else
        {:error, :incorrect_coin_owner}
      end
    end)
    |> transfer_coin_multi(:coin, :from_wallet, :to_wallet, memo)
    |> Repo.transaction()
    |> case do
      {:ok, %{transaction: transaction}} -> {:ok, transaction}
      err -> err
    end
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
