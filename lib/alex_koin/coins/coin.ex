defmodule AlexKoin.Coins.Coin do
  import Ecto.Query

  use Ecto.Schema
  import Ecto.Changeset


  schema "coins" do
    field :hash, :string
    field :origin, :string
    field :mined_by_id, :id
    field :wallet_id, :id

    timestamps()
  end

  @doc false
  def changeset(coin, attrs) do
    coin
    |> cast(attrs, [:hash, :origin, :mined_by_id, :wallet_id])
    |> validate_required([:hash, :origin, :mined_by_id, :wallet_id])
  end

  def for_wallet(wallet, amount) do
    from c in AlexKoin.Coins.Coin,
      where: c.wallet_id == ^wallet.id,
      limit: ^amount
  end

  def count_from_date(date) do
    naive_date = DateTime.to_naive(date)

    from c in AlexKoin.Coins.Coin,
      select: count(c.id),
      where: c.inserted_at >= ^naive_date
  end
end
