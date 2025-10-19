defmodule Yachanakuy.DeliveriesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Yachanakuy.Deliveries` context.
  """

  alias Yachanakuy.Deliveries

  def valid_meal_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      nombre: "Almuerzo Día 1",
      tipo: "almuerzo",
      fecha: Date.utc_today(),
      hora_desde: ~T[12:00:00],
      hora_hasta: ~T[14:00:00]
    })
  end

  def meal_fixture(attrs \\ %{}) do
    {:ok, meal} =
      attrs
      |> valid_meal_attributes()
      |> Deliveries.create_meal()

    meal
  end

  def valid_session_attributes(attrs \\ %{}) do
    room = room_fixture()
    
    Enum.into(attrs, %{
      titulo: "Tecnologías Emergentes",
      descripcion: "Una introducción a las últimas tecnologías emergentes",
      fecha: Date.utc_today(),
      hora_inicio: ~T[09:00:00],
      hora_fin: ~T[11:00:00],
      room_id: room.id
    })
  end

  def session_fixture(attrs \\ %{}) do
    {:ok, session} =
      attrs
      |> valid_session_attributes()
      |> Deliveries.create_session()

    session
  end

  def valid_room_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      nombre: "Auditorio Principal",
      capacidad: 500,
      ubicacion: "Edificio A, Primer Piso"
    })
  end

  def room_fixture(attrs \\ %{}) do
    {:ok, room} =
      attrs
      |> valid_room_attributes()
      |> Deliveries.create_room()

    room
  end

  def valid_meal_delivery_attributes(attrs \\ %{}) do
    attendee = Yachanakuy.RegistrationFixtures.attendee_fixture()
    meal = meal_fixture()
    user = Yachanakuy.AccountsFixtures.user_fixture()
    
    Enum.into(attrs, %{
      attendee_id: attendee.id,
      meal_id: meal.id,
      entregado_por: user.id,
      fecha_entrega: DateTime.utc_now()
    })
  end

  def meal_delivery_fixture(attrs \\ %{}) do
    {:ok, meal_delivery} =
      attrs
      |> valid_meal_delivery_attributes()
      |> Deliveries.create_meal_delivery()

    meal_delivery
  end

  def valid_session_attendance_attributes(attrs \\ %{}) do
    attendee = Yachanakuy.RegistrationFixtures.attendee_fixture(%{estado: "aprobado"})
    session = session_fixture()
    user = Yachanakuy.AccountsFixtures.user_fixture()
    
    Enum.into(attrs, %{
      attendee_id: attendee.id,
      session_id: session.id,
      escaneado_por: user.id,
      fecha_escaneo: DateTime.utc_now()
    })
  end

  def session_attendance_fixture(attrs \\ %{}) do
    {:ok, session_attendance} =
      attrs
      |> valid_session_attendance_attributes()
      |> Deliveries.create_session_attendance()

    session_attendance
  end
end