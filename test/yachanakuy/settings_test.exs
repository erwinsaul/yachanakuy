defmodule Yachanakuy.SettingsTest do
  use Yachanakuy.DataCase

  alias Yachanakuy.Settings

  describe "module_configurations" do
    alias Yachanakuy.Settings.ModuleConfiguration

    import Yachanakuy.AccountsFixtures, only: [user_scope_fixture: 0]
    import Yachanakuy.SettingsFixtures

    @invalid_attrs %{enabled: nil, module_name: nil}

    test "list_module_configurations/1 returns all scoped module_configurations" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      module_configuration = module_configuration_fixture(scope)
      other_module_configuration = module_configuration_fixture(other_scope)
      assert Settings.list_module_configurations(scope) == [module_configuration]
      assert Settings.list_module_configurations(other_scope) == [other_module_configuration]
    end

    test "get_module_configuration!/2 returns the module_configuration with given id" do
      scope = user_scope_fixture()
      module_configuration = module_configuration_fixture(scope)
      other_scope = user_scope_fixture()
      assert Settings.get_module_configuration!(scope, module_configuration.id) == module_configuration
      assert_raise Ecto.NoResultsError, fn -> Settings.get_module_configuration!(other_scope, module_configuration.id) end
    end

    test "create_module_configuration/2 with valid data creates a module_configuration" do
      valid_attrs = %{enabled: true, module_name: "some module_name"}
      scope = user_scope_fixture()

      assert {:ok, %ModuleConfiguration{} = module_configuration} = Settings.create_module_configuration(scope, valid_attrs)
      assert module_configuration.enabled == true
      assert module_configuration.module_name == "some module_name"
      assert module_configuration.user_id == scope.user.id
    end

    test "create_module_configuration/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Settings.create_module_configuration(scope, @invalid_attrs)
    end

    test "update_module_configuration/3 with valid data updates the module_configuration" do
      scope = user_scope_fixture()
      module_configuration = module_configuration_fixture(scope)
      update_attrs = %{enabled: false, module_name: "some updated module_name"}

      assert {:ok, %ModuleConfiguration{} = module_configuration} = Settings.update_module_configuration(scope, module_configuration, update_attrs)
      assert module_configuration.enabled == false
      assert module_configuration.module_name == "some updated module_name"
    end

    test "update_module_configuration/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      module_configuration = module_configuration_fixture(scope)

      assert_raise MatchError, fn ->
        Settings.update_module_configuration(other_scope, module_configuration, %{})
      end
    end

    test "update_module_configuration/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      module_configuration = module_configuration_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Settings.update_module_configuration(scope, module_configuration, @invalid_attrs)
      assert module_configuration == Settings.get_module_configuration!(scope, module_configuration.id)
    end

    test "delete_module_configuration/2 deletes the module_configuration" do
      scope = user_scope_fixture()
      module_configuration = module_configuration_fixture(scope)
      assert {:ok, %ModuleConfiguration{}} = Settings.delete_module_configuration(scope, module_configuration)
      assert_raise Ecto.NoResultsError, fn -> Settings.get_module_configuration!(scope, module_configuration.id) end
    end

    test "delete_module_configuration/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      module_configuration = module_configuration_fixture(scope)
      assert_raise MatchError, fn -> Settings.delete_module_configuration(other_scope, module_configuration) end
    end

    test "change_module_configuration/2 returns a module_configuration changeset" do
      scope = user_scope_fixture()
      module_configuration = module_configuration_fixture(scope)
      assert %Ecto.Changeset{} = Settings.change_module_configuration(scope, module_configuration)
    end
  end
end
