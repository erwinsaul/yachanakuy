defmodule Yachanakuy.Reports do
  @moduledoc """
  Módulo principal para generar todos los tipos de reportes del sistema.
  """

  alias Yachanakuy.Reports.OperatorReport
  alias Yachanakuy.Reports.CommissionReport
  alias Yachanakuy.Reports.AdminReport

  @doc """
  Genera un reporte según el rol del usuario.
  
  ## Parámetros
  - user: Usuario que solicita el reporte
  - opts: Opciones adicionales para el reporte
  
  ## Retorna
  - Mapa con el reporte correspondiente al rol
  """
  def generate_report_for_user(user, opts \\ [])
  def generate_report_for_user(%{rol: "operador"} = user, _opts), do: OperatorReport.generate_operator_report(user.id)
  def generate_report_for_user(%{rol: "encargado_comision"} = user, _opts) do
    # Find the commission this supervisor is responsible for
    commissions = Yachanakuy.Commissions.list_commissions_by_supervisor(user.id)
    if length(commissions) > 0 do
      # For now, use the first commission - in a real system, might need to handle multiple
      commission = List.first(commissions)
      CommissionReport.generate_commission_report(commission.id)
    else
      # If the user is not assigned to a specific commission as supervisor,
      # we can generate a combined report of all commissions they're associated with as an operator
      %{
        supervisor_report: "No assigned commission found",
        operator_activities: OperatorReport.generate_operator_report(user.id)
      }
    end
  end
  def generate_report_for_user(%{rol: "admin"} = _user, _opts), do: AdminReport.generate_admin_report()
  def generate_report_for_user(_, _opts), do: {:error, "Usuario no autorizado para generar reportes"}

  @doc """
  Genera un reporte detallado según el rol del usuario.
  
  ## Parámetros
  - user: Usuario que solicita el reporte
  - report_type: Tipo de reporte a generar
  - opts: Opciones adicionales
  
  ## Retorna
  - Mapa con el reporte detallado
  """
  def generate_detailed_report(%{rol: "operador"} = user, "operator_activities", opts) do
    OperatorReport.get_operator_activities_history(user.id, opts)
  end

  def generate_detailed_report(%{rol: "encargado_comision"} = user, "commission_summary", opts) do
    # Find the commission this supervisor is responsible for
    commissions = Yachanakuy.Commissions.list_commissions_by_supervisor(user.id)
    if length(commissions) > 0 do
      # For now, use the first commission - in a real system, might need to handle multiple
      commission = List.first(commissions)
      CommissionReport.get_operators_in_commission_report(commission.id, Keyword.get(opts, :activity_type, "all"))
    else
      {:error, "Encargado no asignado a ninguna comisión"}
    end
  end

  def generate_detailed_report(%{rol: "admin"} = _user, "category_summary", _opts) do
    AdminReport.generate_category_report()
  end

  def generate_detailed_report(%{rol: "admin"} = _user, "session_attendance", _opts) do
    AdminReport.generate_session_attendance_report()
  end

  def generate_detailed_report(%{rol: "admin"} = _user, "commission_activity", _opts) do
    AdminReport.generate_commission_activity_report()
  end

  def generate_detailed_report(%{rol: "admin"} = _user, "registration_trends", _opts) do
    AdminReport.generate_registration_trends()
  end

  def generate_detailed_report(%{rol: "admin"} = _user, "attendee_attendance", _opts) do
    AdminReport.generate_attendee_attendance_report()
  end

  def generate_detailed_report(_, _, _) do
    {:error, "Usuario no autorizado o tipo de reporte inválido"}
  end

  @doc """
  Genera un reporte comparativo entre diferentes periodos o comisiones.
  
  ## Parámetros
  - comparison_type: Tipo de comparación a realizar
  - opts: Opciones para la comparación
  
  ## Retorna
  - Mapa con el reporte comparativo
  """
  def generate_comparison_report("daily_trends", opts) do
    date_from = Keyword.get(opts, :date_from)
    date_to = Keyword.get(opts, :date_to)

    if date_from && date_to do
      # Get trends for the specified period using the AdminReport module
      AdminReport.generate_registration_trends()
    else
      {:error, "Fechas requeridas para reporte de tendencias"}
    end
  end

  def generate_comparison_report("commission_performance", _opts) do
    AdminReport.generate_commission_activity_report()
  end

  def generate_comparison_report("category_performance", _opts) do
    AdminReport.generate_category_report()
  end

  def generate_comparison_report(_, _) do
    {:error, "Tipo de reporte comparativo inválido"}
  end
end