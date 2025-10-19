defmodule Yachanakuy.Certificates.Certificate do
  use Ecto.Schema
  import Ecto.Changeset

  schema "certificates" do
    field :codigo_verificacion, :string
    field :archivo_pdf, :string
    field :porcentaje_asistencia, :decimal
    field :sesiones_asistidas, :integer
    field :total_sesiones, :integer
    field :fecha_generacion, :utc_datetime

    belongs_to :attendee, Yachanakuy.Registration.Attendee

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(certificate, attrs) do
    certificate
    |> cast(attrs, [:codigo_verificacion, :archivo_pdf, :porcentaje_asistencia, :sesiones_asistidas, :total_sesiones, :fecha_generacion, :attendee_id])
    |> validate_required([:codigo_verificacion, :archivo_pdf, :fecha_generacion, :attendee_id])
    |> unique_constraint(:codigo_verificacion)
    |> unique_constraint(:attendee_id)
    |> foreign_key_constraint(:attendee_id)
  end
end
