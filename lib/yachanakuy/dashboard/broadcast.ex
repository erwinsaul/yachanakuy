defmodule Yachanakuy.Dashboard.Broadcast do
  @moduledoc """
  Módulo para manejar la difusión de eventos en tiempo real a los dashboards.
  """

  alias Phoenix.PubSub

  @topic_prefix "dashboard_updates"

  @doc """
  Transmite una actualización a todos los usuarios conectados.
  
  ## Parámetros
  - event: Nombre del evento
  - payload: Datos a transmitir
  
  ## Ejemplo
      iex> Broadcast.broadcast_update("attendee_registered", %{count: 5})
      :ok
  """
  def broadcast_update(event, payload) do
    topic = "#{@topic_prefix}:all"
    PubSub.broadcast(Yachanakuy.PubSub, topic, {event, payload})
  end

  @doc """
  Transmite una actualización a usuarios específicos por rol.
  
  ## Parámetros
  - role: Rol del usuario (admin, encargado_comision, operador)
  - event: Nombre del evento
  - payload: Datos a transmitir
  
  ## Ejemplo
      iex> Broadcast.broadcast_role_update("admin", "attendee_registered", %{count: 5})
      :ok
  """
  def broadcast_role_update(role, event, payload) when role in ["admin", "encargado_comision", "operador"] do
    topic = "#{@topic_prefix}:#{role}"
    PubSub.broadcast(Yachanakuy.PubSub, topic, {event, payload})
  end

  @doc """
  Transmite una actualización a un usuario específico.
  
  ## Parámetros
  - user_id: ID del usuario
  - event: Nombre del evento
  - payload: Datos a transmitir
  
  ## Ejemplo
      iex> Broadcast.broadcast_user_update(123, "delivery_made", %{count: 5})
      :ok
  """
  def broadcast_user_update(user_id, event, payload) do
    topic = "#{@topic_prefix}:user:#{user_id}"
    PubSub.broadcast(Yachanakuy.PubSub, topic, {event, payload})
  end

  @doc """
  Suscribe a actualizaciones globales.
  """
  def subscribe_all do
    topic = "#{@topic_prefix}:all"
    PubSub.subscribe(Yachanakuy.PubSub, topic)
  end

  @doc """
  Suscribe a actualizaciones por rol.
  """
  def subscribe_role(role) when role in ["admin", "encargado_comision", "operador"] do
    topic = "#{@topic_prefix}:#{role}"
    PubSub.subscribe(Yachanakuy.PubSub, topic)
  end

  @doc """
  Suscribe a actualizaciones para un usuario específico.
  """
  def subscribe_user(user_id) do
    topic = "#{@topic_prefix}:user:#{user_id}"
    PubSub.subscribe(Yachanakuy.PubSub, topic)
  end

  @doc """
  Maneja eventos de actualización de inscripción de participantes.
  """
  def handle_attendee_registration(attendee) do
    # Emitir eventos a todos los dashboards interesados
    broadcast_update("attendee_registered", %{
      attendee_id: attendee.id,
      attendee_name: attendee.nombre_completo,
      timestamp: DateTime.utc_now()
    })
    
    # Emitir evento a dashboards de admin
    broadcast_role_update("admin", "attendee_registered", %{
      attendee_id: attendee.id,
      attendee_name: attendee.nombre_completo,
      total_count: Yachanakuy.Registration.count_attendees(),
      pending_count: Yachanakuy.Registration.count_pending_reviews()
    })
  end

  @doc """
  Maneja eventos de actualización de entregas.
  """
  def handle_delivery_made(delivery, user) do
    # Emitir eventos a todos los dashboards interesados
    broadcast_update("delivery_made", %{
      delivery_id: delivery.id,
      user_id: user.id,
      user_name: user.nombre_completo,
      type: get_delivery_type(delivery),
      timestamp: DateTime.utc_now()
    })
    
    # Emitir evento a dashboards de admin
    broadcast_role_update("admin", "delivery_made", %{
      delivery_id: delivery.id,
      user_id: user.id,
      user_name: user.nombre_completo,
      type: get_delivery_type(delivery),
      total_deliveries: Yachanakuy.Deliveries.count_deliveries(),
      user_deliveries: Yachanakuy.Deliveries.count_deliveries_by_user(user.id)
    })
    
    # Emitir evento al dashboard del usuario específico
    broadcast_user_update(user.id, "delivery_made", %{
      delivery_id: delivery.id,
      type: get_delivery_type(delivery),
      user_deliveries: Yachanakuy.Deliveries.count_deliveries_by_user(user.id)
    })
  end

  @doc """
  Maneja eventos de actualización de aprobación de participantes.
  """
  def handle_attendee_approval(attendee, user) do
    # Emitir eventos a todos los dashboards interesados
    broadcast_update("attendee_approved", %{
      attendee_id: attendee.id,
      attendee_name: attendee.nombre_completo,
      approved_by: user.nombre_completo,
      timestamp: DateTime.utc_now()
    })
    
    # Emitir evento a dashboards de admin
    broadcast_role_update("admin", "attendee_approved", %{
      attendee_id: attendee.id,
      attendee_name: attendee.nombre_completo,
      approved_by: user.nombre_completo,
      pending_count: Yachanakuy.Registration.count_pending_reviews(),
      approved_count: get_approved_attendees_count()
    })
  end

  defp get_delivery_type(%Yachanakuy.Deliveries.MealDelivery{}), do: "meal_delivery"
  defp get_delivery_type(%Yachanakuy.Deliveries.SessionAttendance{}), do: "session_attendance"
  defp get_delivery_type(_), do: "credential_or_material"

  defp get_approved_attendees_count do
    import Ecto.Query
    alias Yachanakuy.Repo
    alias Yachanakuy.Registration.Attendee

    query = from a in Attendee,
      where: a.estado == "aprobado",
      select: count(a.id)

    Repo.one(query) || 0
  end
end