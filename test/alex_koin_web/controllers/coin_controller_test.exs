defmodule AlexKoinWeb.CoinControllerTest do
  use AlexKoinWeb.ConnCase

  alias AlexKoin.Coins
  alias AlexKoin.Coins.Coin
  alias AlexKoin.Account

  @create_attrs %{hash: "some hash", origin: "some origin"}
  @update_attrs %{hash: "some updated hash", origin: "some updated origin"}
  @invalid_attrs %{hash: nil, origin: nil}

  @wallet_attrs %{balance: 1.0}
  @user_attrs %{email: "test@internet.com", first_name: "alex", last_name: "koin", slack_id: "U1234567"}

  def fixture(:coin, coin_attrs) do
    {:ok, coin} = Coins.create_coin(coin_attrs)
    coin
  end

  def fixture(:wallet, wallet_attrs) do
    {:ok, wallet} = Account.create_wallet(wallet_attrs)
    wallet
  end

  def fixture(:user) do
    {:ok, user} = Account.create_user(@user_attrs)
    user
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all coins", %{conn: conn} do
      conn = get conn, coin_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create coin" do
    setup [:create_coin]

    test "renders coin when data is valid", %{conn: conn, user: user, wallet: wallet} do
      attrs = @create_attrs |> Map.put(:mined_by_id, user.id) |> Map.put(:wallet_id, wallet.id) |> Map.put(:created_by_user_id, user.id)

      conn = post conn, coin_path(conn, :create), coin: attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, coin_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "hash" => "some hash",
        "origin" => "some origin"}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, coin_path(conn, :create), coin: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update coin" do
    setup [:create_coin]

    test "renders coin when data is valid", %{conn: conn, coin: %Coin{id: id} = coin, user: user, wallet: wallet} do
      attrs = @update_attrs |> Map.put(:mined_by_id, user.id) |> Map.put(:wallet_id, wallet.id)

      conn = post conn, coin_path(conn, :create), coin: attrs
      conn = put conn, coin_path(conn, :update, coin), coin: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, coin_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "hash" => "some updated hash",
        "origin" => "some updated origin"}
    end

    test "renders errors when data is invalid", %{conn: conn, coin: coin} do
      conn = put conn, coin_path(conn, :update, coin), coin: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete coin" do
    setup [:create_coin]

    test "deletes chosen coin", %{conn: conn, coin: coin} do
      conn = delete conn, coin_path(conn, :delete, coin)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, coin_path(conn, :show, coin)
      end
    end
  end

  defp create_user() do
    user = fixture(:user)
    {:ok, user: user}
  end

  defp create_wallet(user) do
    wallet_attrs = Map.put(@wallet_attrs, :user_id, user.id)
    wallet = fixture(:wallet, wallet_attrs)
    {:ok, wallet: wallet}
  end

  defp create_coin(_) do
    {:ok, user: user} = create_user()
    {:ok, wallet: wallet} = create_wallet(user)

    coin_attrs = @create_attrs |> Map.put(:mined_by_id, user.id) |> Map.put(:wallet_id, wallet.id) |> Map.put(:created_by_user_id, user.id)
    coin = fixture(:coin, coin_attrs)
    {:ok, coin: coin, user: user, wallet: wallet}
  end
end
