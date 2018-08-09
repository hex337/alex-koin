defmodule AlexKoin.Account.Transaction do
  use Ecto.Schema
  import Ecto.Changeset


  schema "transactions" do
    field :amount, :float
    field :memo, :string
    field :from_id, :id
    field :to_id, :id
    field :coin_id, :id

    timestamps()
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:amount, :memo])
    |> validate_required([:amount, :memo])
  end
end
