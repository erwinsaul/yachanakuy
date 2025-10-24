defmodule Yachanakuy.TourismTest do
  use Yachanakuy.DataCase

  alias Yachanakuy.Tourism

  describe "packages" do
    alias Yachanakuy.Tourism.Package

    import Yachanakuy.AccountsFixtures, only: [user_scope_fixture: 0]
    import Yachanakuy.TourismFixtures

    @invalid_attrs %{titulo: nil, descripcion: nil}

    test "list_packages/1 returns all scoped packages" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      package = package_fixture(scope)
      other_package = package_fixture(other_scope)
      assert Tourism.list_packages(scope) == [package]
      assert Tourism.list_packages(other_scope) == [other_package]
    end

    test "get_package!/2 returns the package with given id" do
      scope = user_scope_fixture()
      package = package_fixture(scope)
      other_scope = user_scope_fixture()
      assert Tourism.get_package!(scope, package.id) == package
      assert_raise Ecto.NoResultsError, fn -> Tourism.get_package!(other_scope, package.id) end
    end

    test "create_package/2 with valid data creates a package" do
      valid_attrs = %{titulo: "some titulo", descripcion: "some descripcion"}
      scope = user_scope_fixture()

      assert {:ok, %Package{} = package} = Tourism.create_package(scope, valid_attrs)
      assert package.titulo == "some titulo"
      assert package.descripcion == "some descripcion"
      assert package.user_id == scope.user.id
    end

    test "create_package/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Tourism.create_package(scope, @invalid_attrs)
    end

    test "update_package/3 with valid data updates the package" do
      scope = user_scope_fixture()
      package = package_fixture(scope)
      update_attrs = %{titulo: "some updated titulo", descripcion: "some updated descripcion"}

      assert {:ok, %Package{} = package} = Tourism.update_package(scope, package, update_attrs)
      assert package.titulo == "some updated titulo"
      assert package.descripcion == "some updated descripcion"
    end

    test "update_package/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      package = package_fixture(scope)

      assert_raise MatchError, fn ->
        Tourism.update_package(other_scope, package, %{})
      end
    end

    test "update_package/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      package = package_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Tourism.update_package(scope, package, @invalid_attrs)
      assert package == Tourism.get_package!(scope, package.id)
    end

    test "delete_package/2 deletes the package" do
      scope = user_scope_fixture()
      package = package_fixture(scope)
      assert {:ok, %Package{}} = Tourism.delete_package(scope, package)
      assert_raise Ecto.NoResultsError, fn -> Tourism.get_package!(scope, package.id) end
    end

    test "delete_package/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      package = package_fixture(scope)
      assert_raise MatchError, fn -> Tourism.delete_package(other_scope, package) end
    end

    test "change_package/2 returns a package changeset" do
      scope = user_scope_fixture()
      package = package_fixture(scope)
      assert %Ecto.Changeset{} = Tourism.change_package(scope, package)
    end
  end
end
