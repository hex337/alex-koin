defmodule AlexKoinWeb.WalletControllerTest do
  use AlexKoinWeb.ConnCase

  alias AlexKoin.Account
  alias AlexKoin.Account.Wallet

  @create_attrs %{balance: 120.5}
  @update_attrs %{balance: 456.7}
  @invalid_attrs %{balance: nil}

  @user_attrs %{email: "asdf@asdf.net", first_name: "alex", last_name: "koin", slack_id: "U1234567"}

  def fixture(:user) do
    {:ok, user} = Account.create_user(@user_attrs)
    user
  end

  def fixture(:wallet, attrs) do
    {:ok, wallet} = Account.create_wallet(attrs)
    wallet
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all wallets", %{conn: conn} do
      conn = get conn, wallet_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create wallet" do
    test "renders wallet when data is valid", %{conn: conn} do
      user = fixture(:user)
      attrs = @create_attrs |> Map.put(:user_id, user.id)
      conn = post conn, wallet_path(conn, :create), wallet: attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, wallet_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "balance" => 120.5}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, wallet_path(conn, :create), wallet: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update wallet" do
    setup [:create_wallet]

    test "renders wallet when data is valid", %{conn: conn, wallet: %Wallet{id: id} = wallet} do
      conn = put conn, wallet_path(conn, :update, wallet), wallet: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, wallet_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "balance" => 456.7}
    end

    test "renders errors when data is invalid", %{conn: conn, wallet: wallet} do
      conn = put conn, wallet_path(conn, :update, wallet), wallet: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete wallet" do
    setup [:create_wallet]

    test "deletes chosen wallet", %{conn: conn, wallet: wallet} do
      conn = delete conn, wallet_path(conn, :delete, wallet)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, wallet_path(conn, :show, wallet)
      end
    end
  end

  defp create_user() do
    user = fixture(:user)
    {:ok, user: user}
  end

  defp create_wallet(_) do
    {:ok, user: user} = create_user()
    wallet_attrs = @create_attrs |> Map.put(:user_id, user.id)
    wallet = fixture(:wallet, wallet_attrs)
    {:ok, wallet: wallet, user: user}
  end
end
