defmodule AlexKoin.Commands.Reconcile do
  require Logger

  alias AlexKoin.Coins.Coin
  alias AlexKoin.Repo
  alias AlexKoin.Account
  alias AlexKoin.Account.User

  def execute() do
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
      Account.update_wallet(wallet, %{balance: coin_count})
    end

    { "Reconciled.", nil }
  end
end
