defmodule AlexKoin.Account.Transaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias AlexKoin.Account.User

  schema "transactions" do
    field(:amount, :float)
    field(:memo, :string)
    field(:coin_id, :id)

    belongs_to(:sender, User, foreign_key: :from_id)
    belongs_to(:recipient, User, foreign_key: :to_id)
    timestamps()
  end

  @doc false
  def changeset(transaction \\ %__MODULE__{}, attrs) do
    transaction
    |> cast(attrs, [:amount, :memo, :from_id, :to_id])
    |> validate_required([:amount, :memo])
    |> foreign_key_constraint(:from_id)
    |> foreign_key_constraint(:to_id)
  end
end
