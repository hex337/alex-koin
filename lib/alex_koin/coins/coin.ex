defmodule AlexKoin.Coins.Coin do
  import Ecto.{ Changeset, Query }
  use Ecto.Schema

  alias AlexKoin.Account.{ User, Wallet }
  alias __MODULE__


  schema "coins" do
    field :hash, :string
    field :origin, :string

    belongs_to :user, User, foreign_key: :mined_by_id
    belongs_to :wallet, Wallet

    timestamps()
  end

  @doc false
  def changeset(coin, attrs) do
    coin
    |> cast(attrs, [:hash, :origin, :mined_by_id, :wallet_id])
    |> validate_required([:hash, :origin, :mined_by_id, :wallet_id])
  end

  def for_wallet(wallet, amount) do
    from c in Coin,
      where: c.wallet_id == ^wallet.id,
      limit: ^amount
  end

  def for_wallet(wallet) do
    from c in Coin,
      where: c.wallet_id == ^wallet.id
  end

  def count_from_date(date) do
    naive_date = DateTime.to_naive(date)

    from c in Coin,
      select: count(c.id),
      where: c.inserted_at >= ^naive_date
  end

  def mined_since(date) do
    naive_date = DateTime.to_naive(date)

    from c in Coin,
      where: c.inserted_at >= ^naive_date,
      preload: :user
  end
end
