defmodule Yachanakuy.Repo.Migrations.CreateAttendeeCategories do
  use Ecto.Migration

  def change do
    create table(:attendee_categories) do
      add :nombre, :string
      add :codigo, :string
      add :precio, :decimal
      add :color, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:attendee_categories, [:codigo])
  end
end
