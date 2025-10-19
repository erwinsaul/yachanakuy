defmodule Yachanakuy.EventsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Yachanakuy.Events` context.
  """

  alias Yachanakuy.Events

  def valid_settings_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      nombre: "Congreso Test #{System.unique_integer()}",
      descripcion: "Congreso de prueba para testing",
      fecha_inicio: ~D[2025-06-15],
      fecha_fin: ~D[2025-06-17],
      ubicacion: "La Paz, Bolivia",
      direccion_evento: "Campus Universitario - UMSA",
      logo: "/images/congreso-logo.png",
      estado: "publicado",
      inscripciones_abiertas: true,
      info_turismo: "La Paz es una ciudad multicultural."
    })
  end

  def settings_fixture(attrs \\ %{}) do
    {:ok, settings} =
      attrs
      |> valid_settings_attributes()
      |> Events.create_settings()

    settings
  end

  def valid_attendee_category_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      nombre: "Estudiante Test",
      codigo: "EST#{System.unique_integer()}",
      precio: Decimal.new("50.00"),
      color: "#3b82f6"
    })
  end

  def attendee_category_fixture(attrs \\ %{}) do
    {:ok, attendee_category} =
      attrs
      |> valid_attendee_category_attributes()
      |> Events.create_attendee_category()

    attendee_category
  end

  def invalid_attendee_category_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      nombre: nil,
      codigo: nil,
      precio: nil
    })
  end
end