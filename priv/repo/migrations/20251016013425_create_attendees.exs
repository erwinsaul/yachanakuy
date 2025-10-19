defmodule Yachanakuy.Repo.Migrations.CreateAttendees do
  use Ecto.Migration

  def change do
    create table(:attendees) do
      add :nombre_completo, :string
      add :numero_documento, :string
      add :email, :string
      add :telefono, :string
      add :institucion, :string
      add :foto, :string
      add :comprobante_pago, :string
      add :codigo_qr, :string
      add :imagen_qr, :string
      add :credencial_digital, :string
      add :token_descarga, :string
      add :estado, :string
      add :fecha_revision, :utc_datetime
      add :motivo_rechazo, :text
      add :credencial_entregada, :boolean, default: false, null: false
      add :fecha_entrega_credencial, :utc_datetime
      add :material_entregado, :boolean, default: false, null: false
      add :fecha_entrega_material, :utc_datetime
      add :sesiones_asistidas, :integer
      add :category_id, references(:attendee_categories, on_delete: :delete_all)
      add :revisado_por, references(:users, on_delete: :delete_all)
      add :quien_entrego_credencial, references(:users, on_delete: :delete_all)
      add :quien_entrego_material, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:attendees, [:token_descarga])
    create unique_index(:attendees, [:codigo_qr])
    create unique_index(:attendees, [:email])
    create unique_index(:attendees, [:numero_documento])
    create index(:attendees, [:category_id])
    create index(:attendees, [:revisado_por])
    create index(:attendees, [:quien_entrego_credencial])
    create index(:attendees, [:quien_entrego_material])
  end
end
