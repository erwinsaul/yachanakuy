defmodule Yachanakuy.Reports.OperatorReport do
  @moduledoc """
  Módulo para generar reportes de actividad para operadores del sistema.
  """

  import Ecto.Query, warn: false
  alias Yachanakuy.Repo
  alias Yachanakuy.Registration.Attendee
  alias Yachanakuy.Deliveries.MealDelivery
  alias Yachanakuy.Deliveries.SessionAttendance

  @doc """
  Genera un reporte de actividad para un operador específico.
  
  ## Parámetros
  - user_id: ID del operador
  
  ## Retorna
  - Mapa con estadísticas de entregas y asistencias
  """
  def generate_operator_report(user_id) do
    %{
      credential_deliveries: count_credential_deliveries_by_operator(user_id),
      material_deliveries: count_material_deliveries_by_operator(user_id),
      meal_deliveries: count_meal_deliveries_by_operator(user_id),
      session_attendances: count_session_attendances_by_operator(user_id),
      total_activities: count_total_activities_by_operator(user_id),
      report_date: DateTime.utc_now()
    }
  end

  defp count_credential_deliveries_by_operator(user_id) do
    query = from a in Attendee,
      where: a.quien_entrego_credencial == ^user_id,
      select: count(a.id)

    Repo.one(query) || 0
  end

  defp count_material_deliveries_by_operator(user_id) do
    query = from a in Attendee,
      where: a.quien_entrego_material == ^user_id,
      select: count(a.id)

    Repo.one(query) || 0
  end

  defp count_meal_deliveries_by_operator(user_id) do
    query = from md in MealDelivery,
      where: md.entregado_por == ^user_id,
      select: count(md.id)

    Repo.one(query) || 0
  end

  defp count_session_attendances_by_operator(user_id) do
    query = from sa in SessionAttendance,
      where: sa.escaneado_por == ^user_id,
      select: count(sa.id)

    Repo.one(query) || 0
  end

  defp count_total_activities_by_operator(user_id) do
    credential_deliveries = count_credential_deliveries_by_operator(user_id)
    material_deliveries = count_material_deliveries_by_operator(user_id)
    meal_deliveries = count_meal_deliveries_by_operator(user_id)
    session_attendances = count_session_attendances_by_operator(user_id)

    credential_deliveries + material_deliveries + meal_deliveries + session_attendances
  end

  @doc """
  Obtiene el historial detallado de actividades de un operador.
  
  ## Parámetros
  - user_id: ID del operador
  - opts: Opciones para filtrar (fecha, tipo de actividad, etc.)
  
  ## Retorna
  - Lista de actividades realizadas por el operador
  """
  # Alternative implementation with separate optimized queries using Task.async
  def get_operator_activities_history(user_id, opts \\ []) do
    date_from = Keyword.get(opts, :date_from, ~D[1970-01-01])
    date_to = Keyword.get(opts, :date_to, DateTime.utc_now() |> Date.add(1))

    # More efficient queries using joins where possible
    credential_deliveries_query = from a in Attendee,
      where: a.quien_entrego_credencial == ^user_id and
             not is_nil(a.fecha_entrega_credencial) and
             a.fecha_entrega_credencial >= type(^date_from, :date) and
             a.fecha_entrega_credencial <= type(^date_to, :date),
      select: %{
        type: "credencial",
        attendee_id: a.id,
        attendee_name: a.nombre_completo,
        date: a.fecha_entrega_credencial,
        details: "Entrega de credencial"
      }

    material_deliveries_query = from a in Attendee,
      where: a.quien_entrego_material == ^user_id and
             not is_nil(a.fecha_entrega_material) and
             a.fecha_entrega_material >= type(^date_from, :date) and
             a.fecha_entrega_material <= type(^date_to, :date),
      select: %{
        type: "material",
        attendee_id: a.id,
        attendee_name: a.nombre_completo,
        date: a.fecha_entrega_material,
        details: "Entrega de material"
      }

    # Optimized query using join instead of separate query
    meal_deliveries_query = from md in MealDelivery,
      join: a in assoc(md, :attendee),
      where: md.entregado_por == ^user_id and
             md.fecha_entrega >= type(^date_from, :date) and
             md.fecha_entrega <= type(^date_to, :date),
      select: %{
        type: "refrigerio",
        attendee_id: a.id,
        attendee_name: a.nombre_completo,
        date: md.fecha_entrega,
        details: "Entrega de refrigerio"
      }

    # Optimized query using joins
    session_attendances_query = from sa in SessionAttendance,
      join: a in assoc(sa, :attendee),
      left_join: s in assoc(sa, :session),
      where: sa.escaneado_por == ^user_id and
             sa.fecha_escaneo >= type(^date_from, :date) and
             sa.fecha_escaneo <= type(^date_to, :date),
      select: %{
        type: "asistencia",
        attendee_id: a.id,
        attendee_name: a.nombre_completo,
        date: sa.fecha_escaneo,
        details: fragment("? || ': ' || ?", "Asistencia a sesión", coalesce(s.titulo, "Sesión sin título"))
      }

    # Execute all queries concurrently for better performance
    {credential_deliveries, material_deliveries, meal_deliveries, session_attendances} = 
      Task.await_many([
        Task.async(fn -> Repo.all(credential_deliveries_query) end),
        Task.async(fn -> Repo.all(material_deliveries_query) end),
        Task.async(fn -> Repo.all(meal_deliveries_query) end),
        Task.async(fn -> Repo.all(session_attendances_query) end)
      ])

    all_activities = []
    |> Kernel.++(credential_deliveries)
    |> Kernel.++(material_deliveries)
    |> Kernel.++(meal_deliveries)
    |> Kernel.++(session_attendances)
    |> Enum.sort_by(&(&1.date))

    all_activities
  end
end