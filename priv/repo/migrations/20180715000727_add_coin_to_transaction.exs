defmodule AlexKoin.Repo.Migrations.AddCoinToTransaction do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :coin_id, references(:coins)
    end
  end
end
