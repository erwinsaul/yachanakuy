defmodule Yachanakuy.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :nombre, :string
      add :capacidad, :integer
      add :ubicacion, :string

      timestamps(type: :utc_datetime)
    end
  end
end
