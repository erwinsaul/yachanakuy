defmodule Yachanakuy.Repo.Migrations.CreateMeals do
  use Ecto.Migration

  def change do
    create table(:meals) do
      add :nombre, :string
      add :tipo, :string
      add :fecha, :date
      add :hora_desde, :time
      add :hora_hasta, :time

      timestamps(type: :utc_datetime)
    end

    create index(:meals, [:fecha])
  end
end
