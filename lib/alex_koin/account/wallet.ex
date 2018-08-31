defmodule AlexKoin.Account.Wallet do
  import Ecto.Query

  use Ecto.Schema
  import Ecto.Changeset
  alias AlexKoin.Account.User


  schema "wallets" do
    field :balance, :float

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(wallet, attrs) do
    wallet
    |> cast(attrs, [:balance, :user_id])
    |> validate_required([:balance, :user_id])
  end

  def by_balance(limit) do
    from w in AlexKoin.Account.Wallet,
      order_by: [desc: w.balance],
      limit: ^limit,
      preload: :user
  end

  def by_minimum_balance(balance) do
    from w in AlexKoin.Account.Wallet,
      where: w.balance >= ^balance,
      order_by: [desc: w.balance],
      preload: :user
  end
end
