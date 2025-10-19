defmodule Yachanakuy.Reports.CommissionReport do
  @moduledoc """
  Módulo para generar reportes de actividad para comisiones del sistema.
  """

  import Ecto.Query, warn: false
  alias Yachanakuy.Repo
  alias Yachanakuy.Registration.Attendee
  alias Yachanakuy.Deliveries.MealDelivery
  alias Yachanakuy.Deliveries.SessionAttendance
  alias Yachanakuy.Commissions.Commission
  alias Yachanakuy.Commissions.CommissionOperator

  @doc """
  Genera un reporte de actividad para una comisión específica.
  
  ## Parámetros
  - commission_id: ID de la comisión
  
  ## Retorna
  - Mapa con estadísticas de entregas y asistencias para la comisión
  """
  def generate_commission_report(commission_id) do
    # Obtener el código de la comisión para determinar qué reporte generar
    commission = Repo.get!(Commission, commission_id)

    base_report = %{
      commission_name: commission.nombre,
      commission_code: commission.codigo,
      commission_id: commission_id,
      report_date: DateTime.utc_now()
    }

    case commission.codigo do
      "ACRED" -> Map.merge(base_report, get_accreditation_report_data(commission_id))
      "MAT" -> Map.merge(base_report, get_material_report_data(commission_id))
      "REFRI" -> Map.merge(base_report, get_meal_report_data(commission_id))
      "ASIST" -> Map.merge(base_report, get_attendance_report_data(commission_id))
      _ -> base_report
    end
  end

  defp get_accreditation_report_data(commission_id) do
    operator_ids = get_commission_operator_ids(commission_id)

    %{
      credential_deliveries: count_credential_deliveries_by_commission_operators(operator_ids),
      total_attendees: Yachanakuy.Registration.count_attendees(),
      operators: get_operators_in_commission_report(commission_id, "credencial")
    }
  end

  defp get_material_report_data(commission_id) do
    operator_ids = get_commission_operator_ids(commission_id)

    %{
      material_deliveries: count_material_deliveries_by_commission_operators(operator_ids),
      total_attendees: Yachanakuy.Registration.count_attendees(),
      operators: get_operators_in_commission_report(commission_id, "material")
    }
  end

  defp get_meal_report_data(commission_id) do
    operator_ids = get_commission_operator_ids(commission_id)

    %{
      meal_deliveries: count_meal_deliveries_by_commission_operators(operator_ids),
      total_meals: Yachanakuy.Deliveries.list_meals() |> length,
      operators: get_operators_in_commission_report(commission_id, "refrigerio")
    }
  end

  defp get_attendance_report_data(commission_id) do
    operator_ids = get_commission_operator_ids(commission_id)

    %{
      session_attendances: count_session_attendances_by_commission_operators(operator_ids),
      total_sessions: Yachanakuy.Program.list_sessions() |> length,
      operators: get_operators_in_commission_report(commission_id, "asistencia")
    }
  end

  defp get_commission_operator_ids(commission_id) do
    query = from co in CommissionOperator,
      where: co.commission_id == ^commission_id,
      select: co.user_id

    Repo.all(query)
  end

  defp count_credential_deliveries_by_commission_operators(operator_ids) do
    query = from a in Attendee,
      where: a.quien_entrego_credencial in ^operator_ids,
      select: count(a.id)

    Repo.one(query) || 0
  end

  defp count_material_deliveries_by_commission_operators(operator_ids) do
    query = from a in Attendee,
      where: a.quien_entrego_material in ^operator_ids,
      select: count(a.id)

    Repo.one(query) || 0
  end

  defp count_meal_deliveries_by_commission_operators(operator_ids) do
    query = from md in MealDelivery,
      where: md.entregado_por in ^operator_ids,
      select: count(md.id)

    Repo.one(query) || 0
  end

  defp count_session_attendances_by_commission_operators(operator_ids) do
    query = from sa in SessionAttendance,
      where: sa.escaneado_por in ^operator_ids,
      select: count(sa.id)

    Repo.one(query) || 0
  end

  @doc """
  Obtiene el reporte detallado de operadores dentro de una comisión.
  
  ## Parámetros
  - commission_id: ID de la comisión
  - activity_type: Tipo de actividad ("credencial", "material", "refrigerio", "asistencia")
  
  ## Retorna
  - Lista de operadores con sus estadísticas
  """
  def get_operators_in_commission_report(commission_id, activity_type) do
    operator_ids = get_commission_operator_ids(commission_id)

    operator_stats = for user_id <- operator_ids do
      activity_count = case activity_type do
        "credencial" -> count_credential_deliveries_by_operator(user_id)
        "material" -> count_material_deliveries_by_operator(user_id)
        "refrigerio" -> count_meal_deliveries_by_operator(user_id)
        "asistencia" -> count_session_attendances_by_operator(user_id)
        _ -> 0
      end

      # Obtener nombre del usuario
      user = Yachanakuy.Accounts.get_user!(user_id)

      %{
        user_id: user_id,
        user_name: user.nombre_completo,
        activity_count: activity_count,
        activity_type: activity_type
      }
    end

    operator_stats
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

  @doc """
  Genera un reporte consolidado para todas las comisiones.
  
  ## Retorna
  - Lista de reportes por comisión
  """
  def generate_all_commissions_report do
    commissions = Yachanakuy.Commissions.list_commissions()

    Enum.map(commissions, fn commission ->
      generate_commission_report(commission.id)
    end)
  end
end