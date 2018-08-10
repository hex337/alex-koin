defmodule AlexKoin.CoinsTest do
  use AlexKoin.DataCase

  alias AlexKoin.Coins
  alias AlexKoin.Account

  describe "coins" do
    alias AlexKoin.Coins.Coin

    @valid_attrs %{hash: "some hash", origin: "some origin"}
    @update_attrs %{hash: "some updated hash", origin: "some updated origin"}
    @invalid_attrs %{hash: nil, origin: nil}

    @wallet_attrs %{balance: 0.0}
    @user_attrs %{email: "asdf@asdf.com", first_name: "alex", last_name: "koin", slack_id: "U1234567"}

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@user_attrs)
        |> Account.create_user()

      user
    end

    def wallet_fixture(attrs \\ %{}) do
      {:ok, wallet} =
        attrs
        |> Enum.into(@wallet_attrs)
        |> Account.create_wallet()

      wallet
    end

    def coin_fixture(attrs \\ %{}) do
      user = user_fixture()
      wallet = wallet_fixture(%{user_id: user.id})

      fk_attrs = %{mined_by_id: user.id, wallet_id: wallet.id}

      {:ok, coin} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Enum.into(fk_attrs)
        |> Coins.create_coin()

      coin
    end

    test "list_coins/0 returns all coins" do
      coin = coin_fixture()
      assert Coins.list_coins() == [coin]
    end

    test "get_coin!/1 returns the coin with given id" do
      coin = coin_fixture()
      assert Coins.get_coin!(coin.id) == coin
    end

    test "create_coin/1 with valid data creates a coin" do
      user = user_fixture()
      wallet = wallet_fixture(%{user_id: user.id})
      attrs = @valid_attrs |> Enum.into(%{mined_by_id: user.id, wallet_id: wallet.id})

      assert {:ok, %Coin{} = coin} = Coins.create_coin(attrs)
      assert coin.hash == "some hash"
      assert coin.origin == "some origin"
    end

    test "create_coin/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Coins.create_coin(@invalid_attrs)
    end

    test "update_coin/2 with valid data updates the coin" do
      coin = coin_fixture()
      assert {:ok, coin} = Coins.update_coin(coin, @update_attrs)
      assert %Coin{} = coin
      assert coin.hash == "some updated hash"
      assert coin.origin == "some updated origin"
    end

    test "update_coin/2 with invalid data returns error changeset" do
      coin = coin_fixture()
      assert {:error, %Ecto.Changeset{}} = Coins.update_coin(coin, @invalid_attrs)
      assert coin == Coins.get_coin!(coin.id)
    end

    test "delete_coin/1 deletes the coin" do
      coin = coin_fixture()
      assert {:ok, %Coin{}} = Coins.delete_coin(coin)
      assert_raise Ecto.NoResultsError, fn -> Coins.get_coin!(coin.id) end
    end

    test "change_coin/1 returns a coin changeset" do
      coin = coin_fixture()
      assert %Ecto.Changeset{} = Coins.change_coin(coin)
    end
  end
end
