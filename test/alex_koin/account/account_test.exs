defmodule AlexKoin.AccountTest do
  use AlexKoin.DataCase

  alias AlexKoin.Account

  describe "wallets" do
    alias AlexKoin.Account.Wallet

    @valid_attrs %{balance: 120.5}
    @update_attrs %{balance: 456.7}
    @invalid_attrs %{balance: nil}

    @user_attrs %{
      email: "asdf@asdf.net",
      first_name: "alex",
      last_name: "koin",
      slack_id: "U1234567"
    }

    def fixture(:user) do
      {:ok, user} = Account.create_user(@user_attrs)
      user
    end

    def wallet_fixture(attrs \\ %{}) do
      user = fixture(:user)
      fk_attrs = %{user_id: user.id}

      {:ok, wallet} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Enum.into(fk_attrs)
        |> Account.create_wallet()

      wallet
    end

    test "list_wallets/0 returns all wallets" do
      wallet = wallet_fixture()
      assert Account.list_wallets() == [wallet]
    end

    test "get_wallet!/1 returns the wallet with given id" do
      wallet = wallet_fixture()
      assert Account.get_wallet!(wallet.id) == wallet
    end

    test "create_wallet/1 with valid data creates a wallet" do
      user = fixture(:user)
      attrs = @valid_attrs |> Map.put(:user_id, user.id)
      assert {:ok, %Wallet{} = wallet} = Account.create_wallet(attrs)
      assert wallet.balance == 120.5
    end

    test "create_wallet/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Account.create_wallet(@invalid_attrs)
    end

    test "update_wallet/2 with valid data updates the wallet" do
      wallet = wallet_fixture()
      assert {:ok, wallet} = Account.update_wallet(wallet, @update_attrs)
      assert %Wallet{} = wallet
      assert wallet.balance == 456.7
    end

    test "update_wallet/2 with invalid data returns error changeset" do
      wallet = wallet_fixture()
      assert {:error, %Ecto.Changeset{}} = Account.update_wallet(wallet, @invalid_attrs)
      assert wallet == Account.get_wallet!(wallet.id)
    end

    test "delete_wallet/1 deletes the wallet" do
      wallet = wallet_fixture()
      assert {:ok, %Wallet{}} = Account.delete_wallet(wallet)
      assert_raise Ecto.NoResultsError, fn -> Account.get_wallet!(wallet.id) end
    end

    test "change_wallet/1 returns a wallet changeset" do
      wallet = wallet_fixture()
      assert %Ecto.Changeset{} = Account.change_wallet(wallet)
    end
  end

  describe "users" do
    alias AlexKoin.Account.User

    @valid_attrs %{
      email: "some email",
      first_name: "some first_name",
      last_name: "some last_name",
      slack_id: "some slack_id"
    }
    @update_attrs %{
      email: "some updated email",
      first_name: "some updated first_name",
      last_name: "some updated last_name",
      slack_id: "some updated slack_id"
    }
    @invalid_attrs %{email: nil, first_name: nil, last_name: nil, slack_id: nil}

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Account.create_user()

      user
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Account.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Account.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Account.create_user(@valid_attrs)
      assert user.email == "some email"
      assert user.first_name == "some first_name"
      assert user.last_name == "some last_name"
      assert user.slack_id == "some slack_id"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Account.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, user} = Account.update_user(user, @update_attrs)
      assert %User{} = user
      assert user.email == "some updated email"
      assert user.first_name == "some updated first_name"
      assert user.last_name == "some updated last_name"
      assert user.slack_id == "some updated slack_id"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Account.update_user(user, @invalid_attrs)
      assert user == Account.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Account.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Account.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Account.change_user(user)
    end
  end

  describe "transactions" do
    alias AlexKoin.Account.Transaction

    @valid_attrs %{amount: 120.5, memo: "some memo"}
    @update_attrs %{amount: 456.7, memo: "some updated memo"}
    @invalid_attrs %{amount: nil, memo: nil}

    def transaction_fixture(attrs \\ %{}) do
      {:ok, transaction} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Account.create_transaction()

      transaction
    end

    test "list_transactions/0 returns all transactions" do
      transaction = transaction_fixture()
      assert Account.list_transactions() == [transaction]
    end

    test "get_transaction!/1 returns the transaction with given id" do
      transaction = transaction_fixture()
      assert Account.get_transaction!(transaction.id) == transaction
    end

    test "create_transaction/1 with valid data creates a transaction" do
      assert {:ok, %Transaction{} = transaction} = Account.create_transaction(@valid_attrs)
      assert transaction.amount == 120.5
      assert transaction.memo == "some memo"
    end

    test "create_transaction/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Account.create_transaction(@invalid_attrs)
    end

    test "update_transaction/2 with valid data updates the transaction" do
      transaction = transaction_fixture()
      assert {:ok, transaction} = Account.update_transaction(transaction, @update_attrs)
      assert %Transaction{} = transaction
      assert transaction.amount == 456.7
      assert transaction.memo == "some updated memo"
    end

    test "update_transaction/2 with invalid data returns error changeset" do
      transaction = transaction_fixture()
      assert {:error, %Ecto.Changeset{}} = Account.update_transaction(transaction, @invalid_attrs)
      assert transaction == Account.get_transaction!(transaction.id)
    end

    test "delete_transaction/1 deletes the transaction" do
      transaction = transaction_fixture()
      assert {:ok, %Transaction{}} = Account.delete_transaction(transaction)
      assert_raise Ecto.NoResultsError, fn -> Account.get_transaction!(transaction.id) end
    end

    test "change_transaction/1 returns a transaction changeset" do
      transaction = transaction_fixture()
      assert %Ecto.Changeset{} = Account.change_transaction(transaction)
    end
  end
end
