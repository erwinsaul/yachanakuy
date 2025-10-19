defmodule Yachanakuy.Repo.Migrations.CreateCertificates do
  use Ecto.Migration

  def change do
    create table(:certificates) do
      add :codigo_verificacion, :string
      add :archivo_pdf, :string
      add :porcentaje_asistencia, :decimal
      add :sesiones_asistidas, :integer
      add :total_sesiones, :integer
      add :fecha_generacion, :utc_datetime
      add :attendee_id, references(:attendees, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:certificates, [:codigo_verificacion])
    create unique_index(:certificates, [:attendee_id])
  end
end
