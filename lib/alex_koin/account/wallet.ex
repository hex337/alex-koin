defmodule AlexKoin.Account.Wallet do
  import Ecto.Query

  use Ecto.Schema
  import Ecto.Changeset
  alias AlexKoin.Account.User
  alias AlexKoin.Coins.Coin
  alias __MODULE__


  schema "wallets" do
    field :balance, :float

    belongs_to :user, User
    has_many :coins, Coin, foreign_key: :mined_by_id

    timestamps()
  end

  @doc false
  def changeset(wallet, attrs) do
    wallet
    |> cast(attrs, [:balance, :user_id])
    |> validate_required([:balance, :user_id])
  end

  def by_balance(limit) do
    from w in Wallet,
      order_by: [desc: w.balance],
      limit: ^limit,
      preload: :user
  end

  def by_minimum_balance(balance) do
    from w in Wallet,
      where: w.balance >= ^balance,
      order_by: [desc: w.balance],
      preload: :user
  end

  def balance(wallet) do
    wallet.balance
  end
end
