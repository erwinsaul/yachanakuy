defmodule Yachanakuy.Repo.Migrations.CreateSpeakers do
  use Ecto.Migration

  def change do
    create table(:speakers) do
      add :nombre_completo, :string
      add :biografia, :text
      add :institucion, :string
      add :foto, :string
      add :email, :string

      timestamps(type: :utc_datetime)
    end
  end
end
