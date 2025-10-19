defmodule Yachanakuy.RegistrationFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Yachanakuy.Registration` context.
  """

  alias Yachanakuy.Registration

  def unique_attendee_email, do: "attendee#{System.unique_integer()}@example.com"
  def unique_attendee_document, do: "DOC#{System.unique_integer()}"

  def valid_attendee_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      nombre_completo: "Test Attendee",
      numero_documento: unique_attendee_document(),
      email: unique_attendee_email(),
      telefono: "789456123",
      institucion: "Test Institution",
      estado: "pendiente_revision"
    })
  end

  def attendee_fixture(attrs \\ %{}) do
    {:ok, attendee} =
      attrs
      |> valid_attendee_attributes()
      |> Registration.create_attendee()

    attendee
  end

  def approved_attendee_fixture(attrs \\ %{}) do
    attendee = attendee_fixture(Enum.into(attrs, %{estado: "aprobado"}))
    
    # If we need an admin to approve, we would do that here
    # For now, we'll just create an already approved attendee
    attendee
  end

  def rejected_attendee_fixture(attrs \\ %{}) do
    attendee_fixture(Enum.into(attrs, %{estado: "rechazado"}))
  end
end