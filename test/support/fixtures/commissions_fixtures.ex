defmodule Yachanakuy.CommissionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Yachanakuy.Commissions` context.
  """

  alias Yachanakuy.Commissions

  def valid_commission_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      nombre: "Comisión de Prueba #{System.unique_integer()}",
      codigo: "ACRED"
    })
  end

  def commission_fixture(attrs \\ %{}) do
    {:ok, commission} =
      attrs
      |> valid_commission_attributes()
      |> Commissions.create_commission()

    commission
  end

  def valid_commission_operator_attributes(attrs \\ %{}) do
    commission = commission_fixture()
    user = Yachanakuy.AccountsFixtures.user_fixture(%{rol: "operador"})
    
    Enum.into(attrs, %{
      commission_id: commission.id,
      user_id: user.id
    })
  end

  def commission_operator_fixture(attrs \\ %{}) do
    {:ok, commission_operator} =
      attrs
      |> valid_commission_operator_attributes()
      |> Commissions.create_commission_operator()

    commission_operator
  end

  def invalid_commission_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      nombre: nil,
      codigo: nil
    })
  end

  def invalid_commission_operator_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      commission_id: nil,
      user_id: nil
    })
  end
end