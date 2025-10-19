defmodule Yachanakuy.CommissionsTest do
  use Yachanakuy.DataCase

  alias Yachanakuy.Commissions

  import Yachanakuy.CommissionsFixtures
  import Yachanakuy.AccountsFixtures

  describe "commissions" do
    alias Yachanakuy.Commissions.Commission

    @valid_attrs %{
      nombre: "Comisión de Acreditación",
      codigo: "ACRED"
    }
    @update_attrs %{
      nombre: "Comisión de Materiales",
      codigo: "MAT"
    }
    @invalid_attrs %{
      nombre: nil,
      codigo: nil
    }

    test "list_commissions/0 returns all commissions" do
      commission = commission_fixture()
      assert Commissions.list_commissions() == [commission]
    end

    test "get_commission!/1 returns the commission with given id" do
      commission = commission_fixture()
      assert Commissions.get_commission!(commission.id) == commission
    end

    test "create_commission/1 with valid data creates a commission" do
      assert {:ok, %Commission{} = commission} = Commissions.create_commission(@valid_attrs)
      assert commission.nombre == "Comisión de Acreditación"
      assert commission.codigo == "ACRED"
    end

    test "create_commission/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Commissions.create_commission(@invalid_attrs)
    end

    test "commission codigo must be unique" do
      commission = commission_fixture()
      attrs_with_duplicate_codigo = Map.put(@valid_attrs, :codigo, commission.codigo)
      assert {:error, %Ecto.Changeset{}} = Commissions.create_commission(attrs_with_duplicate_codigo)
    end

    test "update_commission/2 with valid data updates the commission" do
      commission = commission_fixture()
      assert {:ok, %Commission{} = commission} = Commissions.update_commission(commission, @update_attrs)
      assert commission.nombre == "Comisión de Materiales"
      assert commission.codigo == "MAT"
    end

    test "update_commission/2 with invalid data returns error changeset" do
      commission = commission_fixture()
      assert {:error, %Ecto.Changeset{}} = Commissions.update_commission(commission, @invalid_attrs)
      assert commission == Commissions.get_commission!(commission.id)
    end

    test "delete_commission/1 deletes the commission" do
      commission = commission_fixture()
      assert {:ok, %Commission{}} = Commissions.delete_commission(commission)
      assert_raise Ecto.NoResultsError, fn -> Commissions.get_commission!(commission.id) end
    end

    test "change_commission/1 returns a commission changeset" do
      commission = commission_fixture()
      assert %Ecto.Changeset{} = Commissions.change_commission(commission)
    end
  end

  describe "commission_operators" do
    alias Yachanakuy.Commissions.CommissionOperator

    test "assign_operator_to_commission/2 assigns an operator to a commission" do
      commission = commission_fixture()
      user = user_fixture(%{rol: "operador"})
      
      assert {:ok, %CommissionOperator{} = commission_operator} = 
             Commissions.assign_operator_to_commission(commission.id, user.id)
      
      assert commission_operator.commission_id == commission.id
      assert commission_operator.user_id == user.id
    end

    test "cannot assign the same operator to commission twice" do
      commission = commission_fixture()
      user = user_fixture(%{rol: "operador"})
      
      # Assign first time
      assert {:ok, %CommissionOperator{}} = 
             Commissions.assign_operator_to_commission(commission.id, user.id)
      
      # Try to assign second time
      assert {:error, "El operador ya está asignado a esta comisión"} = 
             Commissions.assign_operator_to_commission(commission.id, user.id)
    end

    test "remove_operator_from_commission/2 removes an operator from a commission" do
      commission = commission_fixture()
      user = user_fixture(%{rol: "operador"})
      
      # Assign first
      assert {:ok, %CommissionOperator{} = commission_operator} = 
             Commissions.assign_operator_to_commission(commission.id, user.id)
      
      # Remove
      assert {:ok, %CommissionOperator{}} = 
             Commissions.remove_operator_from_commission(commission.id, user.id)
    end

    test "list_operators_in_commission/1 returns all operators in a commission" do
      commission = commission_fixture()
      user1 = user_fixture(%{rol: "operador"})
      user2 = user_fixture(%{rol: "operador"})
      
      # Assign operators
      assert {:ok, %CommissionOperator{}} = 
             Commissions.assign_operator_to_commission(commission.id, user1.id)
      assert {:ok, %CommissionOperator{}} = 
             Commissions.assign_operator_to_commission(commission.id, user2.id)
      
      operators = Commissions.list_operators_in_commission(commission.id)
      assert length(operators) == 2
      
      operator_ids = Enum.map(operators, &(&1.id))
      assert user1.id in operator_ids
      assert user2.id in operator_ids
    end

    test "list_commissions_by_operator/1 returns all commissions for an operator" do
      commission1 = commission_fixture(%{nombre: "Comisión 1", codigo: "C1"})
      commission2 = commission_fixture(%{nombre: "Comisión 2", codigo: "C2"})
      user = user_fixture(%{rol: "operador"})
      
      # Assign to commissions
      assert {:ok, %CommissionOperator{}} = 
             Commissions.assign_operator_to_commission(commission1.id, user.id)
      assert {:ok, %CommissionOperator{}} = 
             Commissions.assign_operator_to_commission(commission2.id, user.id)
      
      commissions = Commissions.list_commissions_by_operator(user.id)
      assert length(commissions) == 2
      
      commission_names = Enum.map(commissions, &(&1.nombre))
      assert "Comisión 1" in commission_names
      assert "Comisión 2" in commission_names
    end
  end

  describe "commission_supervisors" do
    alias Yachanakuy.Commissions.Commission

    test "assign_supervisor_to_commission/2 assigns a supervisor to a commission" do
      commission = commission_fixture()
      user = user_fixture(%{rol: "encargado_comision"})
      
      assert {:ok, %Commission{} = updated_commission} = 
             Commissions.assign_supervisor_to_commission(commission.id, user.id)
      
      assert updated_commission.encargado_id == user.id
    end

    test "remove_supervisor_from_commission/1 removes supervisor from a commission" do
      commission = commission_fixture()
      user = user_fixture(%{rol: "encargado_comision"})
      
      # Assign supervisor first
      assert {:ok, %Commission{} = updated_commission} = 
             Commissions.assign_supervisor_to_commission(commission.id, user.id)
      assert updated_commission.encargado_id == user.id
      
      # Remove supervisor
      assert {:ok, %Commission{} = updated_commission} = 
             Commissions.remove_supervisor_from_commission(commission.id)
      assert is_nil(updated_commission.encargado_id)
    end

    test "list_commissions_by_supervisor/1 returns commissions supervised by a user" do
      user = user_fixture(%{rol: "encargado_comision"})
      commission1 = commission_fixture(%{encargado_id: user.id})
      commission2 = commission_fixture(%{encargado_id: user.id})
      commission3 = commission_fixture() # Not supervised by user
      
      commissions = Commissions.list_commissions_by_supervisor(user.id)
      assert length(commissions) == 2
      
      commission_ids = Enum.map(commissions, &(&1.id))
      assert commission1.id in commission_ids
      assert commission2.id in commission_ids
      refute commission3.id in commission_ids
    end
  end

  describe "commission_validation" do
    test "commission codigo must be one of valid values" do
      valid_codes = ["ACRED", "MAT", "REFRI", "ASIST"]
      
      Enum.each(valid_codes, fn code ->
        attrs = %{nombre: "Test #{code}", codigo: code}
        assert {:ok, %Commission{}} = Commissions.create_commission(attrs)
        commission = Commissions.list_commissions() |> List.last()
        Commissions.delete_commission(commission)
      end)
      
      invalid_code_attrs = %{nombre: "Test Invalid", codigo: "INVALID"}
      assert {:error, %Ecto.Changeset{}} = Commissions.create_commission(invalid_code_attrs)
    end

    test "commission nombre must be between 1 and 100 characters" do
      # Valid names
      valid_name_attrs = Map.put(@valid_attrs, :nombre, "A")
      assert {:ok, %Commission{}} = Commissions.create_commission(valid_name_attrs)
      
      long_name = String.duplicate("A", 100)
      valid_long_name_attrs = Map.put(@valid_attrs, :nombre, long_name)
      assert {:ok, %Commission{}} = Commissions.create_commission(valid_long_name_attrs)
      
      # Invalid names
      empty_name_attrs = Map.put(@valid_attrs, :nombre, "")
      assert {:error, %Ecto.Changeset{}} = Commissions.create_commission(empty_name_attrs)
      
      too_long_name = String.duplicate("A", 101)
      invalid_long_name_attrs = Map.put(@valid_attrs, :nombre, too_long_name)
      assert {:error, %Ecto.Changeset{}} = Commissions.create_commission(invalid_long_name_attrs)
    end
  end
end