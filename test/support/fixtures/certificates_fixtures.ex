defmodule Yachanakuy.CertificatesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Yachanakuy.Certificates` context.
  """

  alias Yachanakuy.Certificates

  def unique_certificate_code, do: "CERT#{System.unique_integer()}"
  def valid_certificate_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      porcentaje_asistencia: Decimal.new("85.50"),
      sesiones_asistidas: 8,
      total_sesiones: 10,
      codigo_verificacion: unique_certificate_code(),
      archivo_pdf: "/uploads/certificados/certificado_#{System.unique_integer()}.pdf",
      fecha_generacion: DateTime.utc_now()
    })
  end

  def certificate_fixture(attrs \\ %{}) do
    attendee = Yachanakuy.RegistrationFixtures.approved_attendee_fixture(%{sesiones_asistidas: 8})
    attrs = Map.merge(valid_certificate_attributes(attrs), %{attendee_id: attendee.id})
    
    {:ok, certificate} =
      attrs
      |> Certificates.create_certificate()

    certificate
  end

  def invalid_certificate_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      porcentaje_asistencia: nil,
      sesiones_asistidas: nil,
      total_sesiones: nil,
      codigo_verificacion: nil,
      archivo_pdf: nil
    })
  end
end