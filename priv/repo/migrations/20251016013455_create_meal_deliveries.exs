defmodule Yachanakuy.Repo.Migrations.CreateMealDeliveries do
  use Ecto.Migration

  def change do
    create table(:meal_deliveries) do
      add :fecha_entrega, :utc_datetime
      add :attendee_id, references(:attendees, on_delete: :delete_all)
      add :meal_id, references(:meals, on_delete: :delete_all)
      add :entregado_por, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:meal_deliveries, [:attendee_id, :meal_id], name: :meal_deliveries_attendee_id_meal_id_index)
    create index(:meal_deliveries, [:attendee_id])
    create index(:meal_deliveries, [:meal_id])
    create index(:meal_deliveries, [:entregado_por])
  end
end
