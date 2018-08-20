defmodule AlexKoin.SlackCommands do
  alias AlexKoin.Repo
  alias AlexKoin.Account.{User, Wallet, Transaction}
  alias AlexKoin.Coins.Coin

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
end
