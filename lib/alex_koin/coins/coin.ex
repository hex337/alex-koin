defmodule AlexKoin.Coins.Coin do
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
end
