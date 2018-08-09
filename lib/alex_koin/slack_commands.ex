defmodule AlexKoin.SlackCommands do
  alias AlexKoin.Repo
  alias AlexKoin.Account.User
  alias AlexKoin.Account.Wallet
  alias AlexKoin.Account.Transaction
  alias AlexKoin.Coins.Coin

  @admin_user_id "U8BBZEB35"

  def get_or_create(slack_id) do
    case User |> Repo.get_by(slack_id: slack_id) do
      nil ->
        new_user = %User{ slack_id: slack_id }
        {:ok, user_obj} = Repo.insert(new_user)

        new_wallet = %Wallet{ user_id: user_obj.id, balance: 0.0 }
        {:ok, _wallet} = Repo.insert(new_wallet)

        user_obj
      db_user ->
        db_user
    end
  end

  def get_balance(wallet) do
    wallet.balance
  end

  def get_coins(wallet) do
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
    transfer_coin(coin, user, user, "Initial creation.")

    coin
  end

  def transfer_coin(coin, from, to_user, memo) do
    new_txn = %Transaction{
      amount: 1.0,
      memo: memo,
      from_id: from.id,
      to_id: to_user.id,
      coin_id: coin.id
    }

    {:ok, txn} = Repo.insert(new_txn)

    # update the balance
    to_wallet = Wallet |> Repo.get_by(user_id: to_user.id)

    AlexKoin.Account.update_wallet(to_wallet, %{balance: to_wallet.balance + 1})
    AlexKoin.Coins.update_coin(coin, %{wallet_id: to_wallet.id})

    if from.id != to_user.id do
      from_wallet = Wallet |> Repo.get_by(user_id: from.id)

      AlexKoin.Account.update_wallet(from_wallet, %{balance: from_wallet.balance - 1})
    end

    {:ok, txn}
  end
end
