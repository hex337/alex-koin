defmodule AlexKoin.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :amount, :float
      add :memo, :string
      add :from_id, references(:wallets, on_delete: :nothing)
      add :to_id, references(:wallets, on_delete: :nothing)

      timestamps()
    end

    create index(:transactions, [:from_id])
    create index(:transactions, [:to_id])
  end
end
