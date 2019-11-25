defmodule AlexKoinWeb.TransactionController do
  use AlexKoinWeb, :controller

  alias AlexKoin.Account
  alias AlexKoin.Account.Transaction

  action_fallback(AlexKoinWeb.FallbackController)

  def index(conn, _params) do
    transactions = Account.list_transactions()
    render(conn, "index.json", transactions: transactions)
  end

  def create(conn, %{"transaction" => transaction_params}) do
    with {:ok, %Transaction{} = transaction} <- Account.create_transaction(transaction_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", transaction_path(conn, :show, transaction))
      |> put_view(AlexKoinWeb.TransactionView)
      |> render("show.json", transaction: transaction)
    end
  end

  def show(conn, %{"id" => id}) do
    transaction = Account.get_transaction!(id)
    render(conn, "show.json", transaction: transaction)
  end

  def update(conn, %{"id" => id, "transaction" => transaction_params}) do
    transaction = Account.get_transaction!(id)

    with {:ok, %Transaction{} = transaction} <-
           Account.update_transaction(transaction, transaction_params) do
      render(conn, "show.json", transaction: transaction)
    end
  end

  def delete(conn, %{"id" => id}) do
    transaction = Account.get_transaction!(id)

    with {:ok, %Transaction{}} <- Account.delete_transaction(transaction) do
      send_resp(conn, :no_content, "")
    end
  end
end
