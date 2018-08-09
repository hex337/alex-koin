defmodule AlexKoin.Repo.Migrations.CreateCoins do
  use Ecto.Migration

  def change do
    create table(:coins) do
      add :hash, :string
      add :origin, :string
      add :mined_by_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:coins, [:mined_by_id])
  end
end
