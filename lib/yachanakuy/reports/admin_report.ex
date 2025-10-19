defmodule Yachanakuy.Reports.AdminReport do
  @moduledoc """
  Módulo para generar reportes de actividad para administradores del sistema.
  """

  import Ecto.Query, warn: false
  alias Yachanakuy.Repo
  alias Yachanakuy.Registration.Attendee
  alias Yachanakuy.Deliveries.MealDelivery
  alias Yachanakuy.Deliveries.SessionAttendance
  alias Yachanakuy.Certificates.Certificate

  @doc """
  Genera un reporte completo para administradores.
  
  ## Retorna
  - Mapa con estadísticas globales del sistema
  """
  def generate_admin_report do
    %{
      total_attendees: count_total_attendees(),
      pending_reviews: count_pending_reviews(),
      approved_attendees: count_approved_attendees(),
      rejected_attendees: count_rejected_attendees(),
      credential_deliveries: count_total_credential_deliveries(),
      material_deliveries: count_total_material_deliveries(),
      meal_deliveries: count_total_meal_deliveries(),
      session_attendances: count_total_session_attendances(),
      certificates_generated: count_total_certificates(),
      report_date: DateTime.utc_now()
    }
  end

  defp count_total_attendees do
    Repo.aggregate(Attendee, :count, :id)
  end

  defp count_pending_reviews do
    query = from a in Attendee,
      where: a.estado == "pendiente_revision",
      select: count(a.id)

    Repo.one(query) || 0
  end

  defp count_approved_attendees do
    query = from a in Attendee,
      where: a.estado == "aprobado",
      select: count(a.id)

    Repo.one(query) || 0
  end

  defp count_rejected_attendees do
    query = from a in Attendee,
      where: a.estado == "rechazado",
      select: count(a.id)

    Repo.one(query) || 0
  end

  defp count_total_credential_deliveries do
    query = from a in Attendee,
      where: a.credencial_entregada == true,
      select: count(a.id)

    Repo.one(query) || 0
  end

  defp count_total_material_deliveries do
    query = from a in Attendee,
      where: a.material_entregado == true,
      select: count(a.id)

    Repo.one(query) || 0
  end

  defp count_total_meal_deliveries do
    Repo.aggregate(MealDelivery, :count, :id)
  end

  defp count_total_session_attendances do
    Repo.aggregate(SessionAttendance, :count, :id)
  end

  defp count_total_certificates do
    Repo.aggregate(Certificate, :count, :id)
  end

  @doc """
  Genera un reporte detallado por categorías de participantes.
  
  ## Retorna
  - Lista de estadísticas por categoría
  """
  def generate_category_report do
    # Este reporte requiere asociación con categorías
    # Vamos a generar estadísticas por cada categoría existente
    categories = Yachanakuy.Events.list_attendee_categories()

    category_stats = Enum.map(categories, fn category ->
      total_attendees_in_category = count_attendees_by_category(category.id)
      approved_attendees_in_category = count_approved_attendees_by_category(category.id)

      %{
        category_id: category.id,
        category_name: category.nombre,
        total_attendees: total_attendees_in_category,
        approved_attendees: approved_attendees_in_category,
        pending_reviews: total_attendees_in_category - approved_attendees_in_category,
        percentage: if(total_attendees_in_category > 0,
          do: Float.round(approved_attendees_in_category / total_attendees_in_category * 100, 2),
          else: 0.0
        )
      }
    end)

    category_stats
  end

  defp count_attendees_by_category(category_id) do
    query = from a in Attendee,
      where: a.category_id == ^category_id,
      select: count(a.id)

    Repo.one(query) || 0
  end

  defp count_approved_attendees_by_category(category_id) do
    query = from a in Attendee,
      where: a.category_id == ^category_id and a.estado == "aprobado",
      select: count(a.id)

    Repo.one(query) || 0
  end

  @doc """
  Genera un reporte de sesiones por asistencia.
  
  ## Retorna
  - Lista de sesiones con sus niveles de asistencia
  """
  def generate_session_attendance_report do
    sessions = Yachanakuy.Program.list_sessions()

    session_stats = Enum.map(sessions, fn session ->
      attendance_count = count_attendees_at_session(session.id)

      %{
        session_id: session.id,
        session_title: session.titulo,
        session_date: session.fecha,
        session_time: session.hora_inicio,
        total_attendances: attendance_count,
        session_capacity: session.room && session.room.capacidad || 0,
        attendance_percentage: if(session.room && session.room.capacidad && session.room.capacidad > 0,
          do: Float.round(attendance_count / session.room.capacidad * 100, 2),
          else: 0.0
        )
      }
    end)

    session_stats
  end

  defp count_attendees_at_session(session_id) do
    query = from sa in SessionAttendance,
      where: sa.session_id == ^session_id,
      select: count(sa.id)

    Repo.one(query) || 0
  end

  @doc """
  Genera un reporte de comisiones con sus actividades.
  
  ## Retorna
  - Lista de comisiones con sus estadísticas
  """
  def generate_commission_activity_report do
    commissions = Yachanakuy.Commissions.list_commissions()

    commission_stats = Enum.map(commissions, fn commission ->
      %{
        commission_id: commission.id,
        commission_name: commission.nombre,
        commission_code: commission.codigo,
        credential_deliveries: Yachanakuy.Deliveries.count_deliveries_by_commission(commission.id),
        material_deliveries: case commission.codigo do
          "MAT" -> Yachanakuy.Deliveries.count_deliveries_by_commission(commission.id)
          _ -> 0
        end,
        meal_deliveries: case commission.codigo do
          "REFRI" -> Yachanakuy.Deliveries.count_deliveries_by_commission(commission.id)
          _ -> 0
        end,
        session_attendances: Yachanakuy.Deliveries.count_attendances_by_commission(commission.id)
      }
    end)

    commission_stats
  end

  @doc """
  Genera un reporte de tendencias de inscripciones por día.
  
  ## Retorna
  - Lista de fechas con conteo de inscripciones
  """
  def generate_registration_trends do
    query = from a in Attendee,
      group_by: fragment("date(?)", a.inserted_at),
      order_by: [desc: fragment("date(?)", a.inserted_at)],
      select: %{
        date: fragment("date(?)", a.inserted_at),
        count: count(a.id)
      }

    Repo.all(query)
  end

  @doc """
  Genera un reporte de asistencia total por participante.
  
  ## Retorna
  - Lista de participantes con sus niveles de asistencia
  """
  def generate_attendee_attendance_report do
    # Get session count outside the query
    total_sessions = Yachanakuy.Program.list_sessions() |> length

    attendees = Repo.all(
      from a in Attendee,
        where: a.estado == "aprobado",
        select: %{
          id: a.id,
          nombre_completo: a.nombre_completo,
          sesiones_asistidas: a.sesiones_asistidas
        },
        order_by: [desc: a.sesiones_asistidas]
    )

    # Calculate percentage outside the query since Ecto doesn't handle complex conditionals well
    Enum.map(attendees, fn attendee ->
      porcentaje_asistencia = 
        if total_sessions > 0 do
          Float.round(attendee.sesiones_asistidas / total_sessions * 100, 2)
        else
          0.0
        end

      Map.merge(attendee, %{
        total_sesiones: total_sessions,
        porcentaje_asistencia: porcentaje_asistencia
      })
    end)
  end
end