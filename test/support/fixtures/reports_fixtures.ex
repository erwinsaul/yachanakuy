defmodule Yachanakuy.ReportsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Yachanakuy.Reports` context.
  """

  alias Yachanakuy.Commissions
  alias Yachanakuy.Events

  def valid_commission_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      nombre: "Comisión de Prueba",
      codigo: "TEST#{System.unique_integer()}",
      encargado_id: nil
    })
  end

  def commission_fixture(attrs \\ %{}) do
    {:ok, commission} =
      attrs
      |> valid_commission_attributes()
      |> Commissions.create_commission()

    commission
  end

  def valid_category_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      nombre: "Categoría de Prueba",
      codigo: "CTEST#{System.unique_integer()}",
      precio: Decimal.new("100.00"),
      color: "#3b82f6"
    })
  end

  def category_fixture(attrs \\ %{}) do
    {:ok, category} =
      attrs
      |> valid_category_attributes()
      |> Events.create_attendee_category()

    category
  end

  def valid_operator_report_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      credential_deliveries: 0,
      material_deliveries: 0,
      meal_deliveries: 0,
      session_attendances: 0,
      total_activities: 0,
      report_date: DateTime.utc_now()
    })
  end

  def operator_report_fixture(attrs \\ %{}) do
    user = Yachanakuy.AccountsFixtures.user_fixture()
    attrs = Map.merge(valid_operator_report_attributes(attrs), %{user_id: user.id})
    
    struct!(Yachanakuy.Reports.OperatorReport, attrs)
  end

  def valid_commission_report_attributes(attrs \\ %{}) do
    commission = commission_fixture()
    
    Enum.into(attrs, %{
      commission_id: commission.id,
      commission_name: commission.nombre,
      commission_code: commission.codigo,
      operators_count: 0,
      total_deliveries: 0,
      credential_deliveries: 0,
      material_deliveries: 0,
      meal_deliveries: 0,
      session_attendances: 0,
      report_date: DateTime.utc_now()
    })
  end

  def commission_report_fixture(attrs \\ %{}) do
    struct!(Yachanakuy.Reports.CommissionReport, valid_commission_report_attributes(attrs))
  end

  def valid_admin_report_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      total_attendees: 0,
      pending_reviews: 0,
      approved_attendees: 0,
      rejected_attendees: 0,
      credential_deliveries: 0,
      material_deliveries: 0,
      meal_deliveries: 0,
      session_attendances: 0,
      certificates_generated: 0,
      report_date: DateTime.utc_now()
    })
  end

  def admin_report_fixture(attrs \\ %{}) do
    struct!(Yachanakuy.Reports.AdminReport, valid_admin_report_attributes(attrs))
  end
end