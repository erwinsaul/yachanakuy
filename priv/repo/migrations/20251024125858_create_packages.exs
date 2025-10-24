defmodule Yachanakuy.Repo.Migrations.CreatePackages do
  use Ecto.Migration

  def change do
    create table(:packages) do
      add :titulo, :string
      add :descripcion, :text

      timestamps(type: :utc_datetime)
    end
  end
end
