defmodule AlexKoin.Account.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias AlexKoin.Account.Wallet


  schema "users" do
    field :email, :string
    field :first_name, :string
    field :last_name, :string
    field :slack_id, :string

    has_one :wallet, Wallet

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :first_name, :last_name, :slack_id])
    |> validate_required([:email, :first_name, :last_name, :slack_id])
  end
end
