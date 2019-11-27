defmodule AlexKoin.SlackCommandsTest do
  use AlexKoin.DataCase

  alias AlexKoin.SlackCommands
  alias AlexKoin.Account.User
  alias AlexKoin.Coins.Coin

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
    setup do
      %{
        wallet: insert(:wallet),
        target_wallet: insert(:wallet)
      }
    end

    test "errors when there are no coins" do
    end
  end
end
