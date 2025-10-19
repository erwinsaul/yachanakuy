defmodule Yachanakuy.ReportsTest do
  use Yachanakuy.DataCase

  alias Yachanakuy.Reports
  alias Yachanakuy.Registration

  import Yachanakuy.ReportsFixtures
  import Yachanakuy.RegistrationFixtures
  import Yachanakuy.AccountsFixtures
  import Yachanakuy.DeliveriesFixtures

  describe "operator_reports" do
    alias Yachanakuy.Reports.OperatorReport

    setup do
      user = user_fixture(%{rol: "operador"})
      {:ok, user: user}
    end

    test "generate_operator_report/1 returns activity summary for operator", %{user: user} do
      # Create some test data for the operator
      attendee1 = approved_attendee_fixture(%{quien_entrego_credencial: user.id, credencial_entregada: true})
      attendee2 = approved_attendee_fixture(%{quien_entrego_material: user.id, material_entregado: true})
      meal = meal_fixture()
      _meal_delivery = meal_delivery_fixture(%{attendee_id: attendee1.id, meal_id: meal.id, entregado_por: user.id})
      session = session_fixture()
      _session_attendance = session_attendance_fixture(%{attendee_id: attendee2.id, session_id: session.id, escaneado_por: user.id})
      
      report = OperatorReport.generate_operator_report(user.id)
      
      assert report.credential_deliveries >= 1
      assert report.material_deliveries >= 1
      assert report.meal_deliveries >= 1
      assert report.session_attendances >= 1
      assert report.total_activities >= 4
      assert report.report_date != nil
    end

    test "get_operator_activities_history/2 returns activity history", %{user: user} do
      attendee = approved_attendee_fixture()
      session = session_fixture()
      
      # Register session attendance
      _session_attendance = session_attendance_fixture(%{
        attendee_id: attendee.id, 
        session_id: session.id, 
        escaneado_por: user.id
      })
      
      activities = OperatorReport.get_operator_activities_history(user.id)
      
      assert length(activities) >= 1
      [activity] = activities
      assert activity.type == "asistencia"
      assert activity.attendee_id == attendee.id
      assert activity.details =~ "Asistencia a sesión:"
    end
  end

  describe "commission_reports" do
    alias Yachanakuy.Reports.CommissionReport

    setup do
      commission = commission_fixture(%{codigo: "ACRED"})  # Acreditación commission
      user = user_fixture(%{rol: "encargado_comision"})
      {:ok, commission: commission, user: user}
    end

    test "generate_commission_report/1 returns summary for commission", %{commission: commission} do
      report = CommissionReport.generate_commission_report(commission.id)
      
      assert report.commission_name == commission.nombre
      assert report.commission_code == commission.codigo
      assert report.commission_id == commission.id
      assert report.report_date != nil
    end

    test "get_operators_in_commission_report/2 returns operator statistics", %{commission: commission} do
      operators = CommissionReport.get_operators_in_commission_report(commission.id, "credencial")
      
      assert is_list(operators)
      # Could be empty if no operators assigned
    end
  end

  describe "admin_reports" do
    alias Yachanakuy.Reports.AdminReport

    test "generate_admin_report/0 returns global statistics" do
      report = AdminReport.generate_admin_report()
      
      assert is_integer(report.total_attendees)
      assert is_integer(report.pending_reviews)
      assert is_integer(report.approved_attendees)
      assert is_integer(report.rejected_attendees)
      assert is_integer(report.credential_deliveries)
      assert is_integer(report.material_deliveries)
      assert is_integer(report.meal_deliveries)
      assert is_integer(report.session_attendances)
      assert is_integer(report.certificates_generated)
      assert report.report_date != nil
    end

    test "generate_category_report/0 returns category statistics" do
      categories_report = AdminReport.generate_category_report()
      
      assert is_list(categories_report)
      # Could be empty if no categories exist
    end

    test "generate_session_attendance_report/0 returns session attendance statistics" do
      session_report = AdminReport.generate_session_attendance_report()
      
      assert is_list(session_report)
      # Could be empty if no sessions exist
    end

    test "generate_commission_activity_report/0 returns commission activity statistics" do
      commission_report = AdminReport.generate_commission_activity_report()
      
      assert is_list(commission_report)
      # Could be empty if no commissions exist
    end

    test "generate_registration_trends/0 returns registration trends" do
      trends = AdminReport.generate_registration_trends()
      
      assert is_list(trends)
      # Could be empty if no registrations exist
    end

    test "generate_attendee_attendance_report/0 returns attendee attendance statistics" do
      attendee_report = AdminReport.generate_attendee_attendance_report()
      
      assert is_list(attendee_report)
      # Could be empty if no attendees exist
    end
  end
end