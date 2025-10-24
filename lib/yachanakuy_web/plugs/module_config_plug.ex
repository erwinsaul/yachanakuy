defmodule YachanakuyWeb.ModuleConfigPlug do
  import Plug.Conn

  alias YachanakuyWeb.ModuleConfigHelper

  def init(default), do: default

  def call(conn, _default) do
    # Get module configurations and make them available in assigns for LiveViews
    conn
    |> assign(:enabled_modules, ModuleConfigHelper.get_enabled_modules())
    |> assign(:module_config_helper, ModuleConfigHelper)
  end
end