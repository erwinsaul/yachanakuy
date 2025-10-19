defmodule Yachanakuy.Repo.Migrations.CreateCommissions do
  use Ecto.Migration

  def change do
    create table(:commissions) do
      add :nombre, :string
      add :codigo, :string
      add :encargado_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:commissions, [:codigo])
    create index(:commissions, [:encargado_id])
  end
end
