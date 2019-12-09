defmodule AlexKoin.Factory do
  use ExMachina.Ecto, repo: AlexKoin.Repo

  alias AlexKoin.Coins.Coin
  alias AlexKoin.Account.{Transaction, User, Wallet}

  def coin_factory(params) do
    {user, params} = Map.pop_lazy(params, :user, fn -> build(:user) end)
    {wallet, params} = Map.pop_lazy(params, :user, fn -> build(:wallet, user: user) end)

    %Coin{
      origin: Faker.Lorem.sentence(),
      user: user,
      hash: UUID.uuid1(),
      created_by_user: user,
      wallet_id: wallet.id
    }
    |> merge_attributes(params)
  end

  def wallet_factory do
    %Wallet{
      balance: 0,
      user: build(:user)
    }
  end

  def user_factory do
    %User{
      email: Faker.Internet.email(),
      first_name: Faker.Name.first_name(),
      last_name: Faker.Name.last_name(),
      slack_id: sequence(:slack_id, fn x -> "#{Faker.Name.first_name()}_#{x}" end)
    }
  end

  def transaction_factory do
    %Transaction{
      amount: 120.5,
      memo: "some memo"
    }
  end
end
