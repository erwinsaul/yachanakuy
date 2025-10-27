defmodule Yachanakuy.Repo.Migrations.CreateAttendeePackages do
  use Ecto.Migration

  def change do
    create table(:attendee_packages) do
      add :attendee_id, references(:attendees, on_delete: :delete_all), null: false
      add :package_id, references(:packages, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:attendee_packages, [:package_id])
    create unique_index(:attendee_packages, [:attendee_id])
  end
end
