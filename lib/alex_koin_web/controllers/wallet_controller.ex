defmodule AlexKoinWeb.WalletController do
  use AlexKoinWeb, :controller

  alias AlexKoin.Account
  alias AlexKoin.Account.Wallet

  action_fallback(AlexKoinWeb.FallbackController)

  def index(conn, _params) do
    wallets = Account.list_wallets()
    render(conn, "index.json", wallets: wallets)
  end

  def create(conn, %{"wallet" => wallet_params}) do
    with {:ok, %Wallet{} = wallet} <- Account.create_wallet(wallet_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", wallet_path(conn, :show, wallet))
      |> render("show.json", wallet: wallet)
    end
  end

  def show(conn, %{"id" => id}) do
    wallet = Account.get_wallet!(id)
    render(conn, "show.json", wallet: wallet)
  end

  def update(conn, %{"id" => id, "wallet" => wallet_params}) do
    wallet = Account.get_wallet!(id)

    with {:ok, %Wallet{} = wallet} <- Account.update_wallet(wallet, wallet_params) do
      render(conn, "show.json", wallet: wallet)
    end
  end

  def delete(conn, %{"id" => id}) do
    wallet = Account.get_wallet!(id)

    with {:ok, %Wallet{}} <- Account.delete_wallet(wallet) do
      send_resp(conn, :no_content, "")
    end
  end
end
