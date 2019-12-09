defmodule AlexKoin.Coins.Coin do
  import Ecto.{Changeset, Query}
  use Ecto.Schema

  alias AlexKoin.Repo
  alias AlexKoin.Account.{User, Wallet}
  alias __MODULE__

  schema "coins" do
    field(:hash, :string)
    field(:origin, :string)

    belongs_to(:user, User, foreign_key: :mined_by_id)
    belongs_to(:created_by_user, User)
    belongs_to(:wallet, Wallet)

    timestamps()
  end

  @doc false
  def changeset(coin, attrs) do
    coin
    |> cast(attrs, [:hash, :origin, :mined_by_id, :wallet_id, :created_by_user_id])
    |> validate_required([:hash, :origin, :mined_by_id, :wallet_id, :created_by_user_id])
    |> foreign_key_constraint(:created_by_user_id)
  end

  def get_amount_from_wallet(wallet, amount) do
    from(c in Coin,
      where: c.wallet_id == ^wallet.id,
      limit: ^amount
    )
    |> Repo.all()
    |> case do
      coins when length(coins) < amount -> {:error, :not_enough_coins}
      coins -> {:ok, coins}
    end
  end

  def for_wallet(wallet, amount) do
    from(c in Coin,
      where: c.wallet_id == ^wallet.id,
      limit: ^amount
    )
  end

  def for_wallet(wallet) do
    from(c in Coin,
      where: c.wallet_id == ^wallet.id
    )
  end

  def count_from_date(date) do
    naive_date = DateTime.to_naive(date)

    from(c in Coin,
      select: count(c.id),
      where: c.inserted_at >= ^naive_date
    )
  end

  def mined_since(date) do
    naive_date = DateTime.to_naive(date)

    from(c in Coin,
      where: c.inserted_at >= ^naive_date,
      preload: :user
    )
  end

  def created_by_user_since(user, date) do
    naive_date = DateTime.to_naive(date)

    from(c in Coin,
      select: count(c.id),
      where: c.inserted_at >= ^naive_date and c.created_by_user_id == ^user.id
    )
  end
end
