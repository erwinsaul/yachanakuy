defmodule YachanakuyWeb.ModuleConfigurationLiveTest do
  use YachanakuyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Yachanakuy.SettingsFixtures

  @create_attrs %{enabled: true, module_name: "some module_name"}
  @update_attrs %{enabled: false, module_name: "some updated module_name"}
  @invalid_attrs %{enabled: false, module_name: nil}

  setup :register_and_log_in_user

  defp create_module_configuration(%{scope: scope}) do
    module_configuration = module_configuration_fixture(scope)

    %{module_configuration: module_configuration}
  end

  describe "Index" do
    setup [:create_module_configuration]

    test "lists all module_configurations", %{conn: conn, module_configuration: module_configuration} do
      {:ok, _index_live, html} = live(conn, ~p"/module_configurations")

      assert html =~ "Listing Module configurations"
      assert html =~ module_configuration.module_name
    end

    test "saves new module_configuration", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/module_configurations")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Module configuration")
               |> render_click()
               |> follow_redirect(conn, ~p"/module_configurations/new")

      assert render(form_live) =~ "New Module configuration"

      assert form_live
             |> form("#module_configuration-form", module_configuration: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#module_configuration-form", module_configuration: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/module_configurations")

      html = render(index_live)
      assert html =~ "Module configuration created successfully"
      assert html =~ "some module_name"
    end

    test "updates module_configuration in listing", %{conn: conn, module_configuration: module_configuration} do
      {:ok, index_live, _html} = live(conn, ~p"/module_configurations")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#module_configurations-#{module_configuration.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/module_configurations/#{module_configuration}/edit")

      assert render(form_live) =~ "Edit Module configuration"

      assert form_live
             |> form("#module_configuration-form", module_configuration: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#module_configuration-form", module_configuration: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/module_configurations")

      html = render(index_live)
      assert html =~ "Module configuration updated successfully"
      assert html =~ "some updated module_name"
    end

    test "deletes module_configuration in listing", %{conn: conn, module_configuration: module_configuration} do
      {:ok, index_live, _html} = live(conn, ~p"/module_configurations")

      assert index_live |> element("#module_configurations-#{module_configuration.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#module_configurations-#{module_configuration.id}")
    end
  end

  describe "Show" do
    setup [:create_module_configuration]

    test "displays module_configuration", %{conn: conn, module_configuration: module_configuration} do
      {:ok, _show_live, html} = live(conn, ~p"/module_configurations/#{module_configuration}")

      assert html =~ "Show Module configuration"
      assert html =~ module_configuration.module_name
    end

    test "updates module_configuration and returns to show", %{conn: conn, module_configuration: module_configuration} do
      {:ok, show_live, _html} = live(conn, ~p"/module_configurations/#{module_configuration}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/module_configurations/#{module_configuration}/edit?return_to=show")

      assert render(form_live) =~ "Edit Module configuration"

      assert form_live
             |> form("#module_configuration-form", module_configuration: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#module_configuration-form", module_configuration: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/module_configurations/#{module_configuration}")

      html = render(show_live)
      assert html =~ "Module configuration updated successfully"
      assert html =~ "some updated module_name"
    end
  end
end
