defmodule AlexKoin.SlackCommandsTest do
  use AlexKoin.DataCase

  alias AlexKoin.SlackCommands
  alias AlexKoin.Repo
  alias AlexKoin.Account.{Transaction, User, Wallet}
  alias AlexKoin.Coins.Coin

  @memo "All of the reasons"

  describe "create_coin" do
    setup do
      user = insert(:user)

      %{
        user: user,
        wallet: insert(:wallet, user: user),
        reason: Faker.Lorem.sentence()
      }
    end

    test "creates a coin with a reason", %{user: user, reason: reason} do
      %User{id: user_id} = user

      assert {:ok, %Coin{} = new_coin} = SlackCommands.create_coin(user, user, reason)
      assert new_coin.origin == reason
      assert new_coin.created_by_user_id == user_id
      assert new_coin.mined_by_id == user_id
    end

    test "fails with invalid reason", %{user: user} do
      assert {:error, :new_coin, _, _} = SlackCommands.create_coin(user, user, nil)
    end
  end

  describe "remove_coins" do
    setup do
      %{
        wallet: insert(:wallet)
      }
    end

    test "errors when there are no coins", %{wallet: wallet} do
      assert {:error, :not_enough_coins} = SlackCommands.remove_coins(wallet, 1)
    end

    test "errors when there are not enough coins", %{wallet: wallet} do
      insert(:coin, wallet: wallet)
      assert {:error, :not_enough_coins} = SlackCommands.remove_coins(wallet, 2)
    end

    test "success if there are enough coins", %{wallet: wallet} do
      insert(:coin, wallet: wallet)
      assert :ok = SlackCommands.remove_coins(wallet, 1)
    end
  end

  describe "transfer" do
    setup context do
      coin_count = Map.get(context, :coin_count, 1)
      source_wallet = insert(:wallet, balance: coin_count)

      %{
        source_wallet: source_wallet,
        target_wallet: insert(:wallet),
        coins: insert_list(coin_count, :coin, wallet: source_wallet)
      }
    end

    def assert_balances([]), do: true
    def assert_balances([{wallet, amount} | rest]) do
      float_amount = amount / 1

      assert %Wallet{balance: ^float_amount} = Repo.get(Wallet, wallet.id)
      assert amount == wallet |> Coin.for_wallet() |> Repo.all |> length

      assert_balances(rest)
    end

    @tag coin_count: 0
    test "errors when there are no coins", %{source_wallet: source_wallet , target_wallet: target_wallet} do
      assert_balances([{source_wallet, 0}, {target_wallet, 0}])

      assert %Wallet{balance: 0.0} = Repo.get(Wallet, source_wallet.id)
      assert_balances([{source_wallet, 0}, {target_wallet, 0}])
    end

    @tag coin_count: 1
    test "fails if wallet has insufficient coins", %{source_wallet: source_wallet , target_wallet: target_wallet} do
      assert_balances([{source_wallet, 1}, {target_wallet, 0}])

      assert {:error, _, _, _} = SlackCommands.transfer(source_wallet, target_wallet, 2, @memo)

      assert_balances([{source_wallet, 1}, {target_wallet, 0}])
    end

    @tag coin_count: 1
    test "transfers coin successfully", %{source_wallet: source_wallet , target_wallet: target_wallet} do
      assert_balances([{source_wallet, 1}, {target_wallet, 0}])

      assert {:ok, %Transaction{amount: 1.0}} = SlackCommands.transfer(source_wallet, target_wallet, 1, @memo)

      assert_balances([{source_wallet, 0}, {target_wallet, 1}])
    end

    @tag coin_count: 2
    test "transfers 2 coins successfully", %{source_wallet: source_wallet , target_wallet: target_wallet} do
      assert_balances([{source_wallet, 2}, {target_wallet, 0}])

      assert {:ok, %Transaction{amount: 2.0}} = SlackCommands.transfer(source_wallet, target_wallet, 2, @memo)

      assert_balances([{source_wallet, 0}, {target_wallet, 2}])
    end

    @tag coin_count: 10
    test "transfers 5 coins successfully", %{source_wallet: source_wallet , target_wallet: target_wallet} do
      assert_balances([{source_wallet, 10}, {target_wallet, 0}])
      assert {:ok, %Transaction{amount: 5.0}} = SlackCommands.transfer(source_wallet, target_wallet, 5, @memo)
      assert_balances([{source_wallet, 5}, {target_wallet, 5}])
    end
  end
end
