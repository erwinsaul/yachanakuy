defmodule YachanakuyWeb.ModuleConfigHelper do
  @moduledoc """
  Helper functions for module configuration functionality.
  """
  
  alias Yachanakuy.Settings

  @module_menus %{
    "attendees" => "/admin/attendees",
    "speakers" => "/admin/speakers", 
    "sessions" => "/admin/sessions",
    "rooms" => "/admin/rooms",
    "commissions" => "/admin/commissions",
    "event_info" => "/admin/event_info",
    "tourist_info" => "/admin/tourist_info",
    "packages" => "/admin/packages"
  }

  @doc """
  Checks if a module is enabled by name.
  """
  def is_module_enabled(module_name) do
    Settings.is_module_enabled(module_name)
  end

  @doc """
  Returns the URL for a module if it is enabled.
  """
  def enabled_module_url(module_name) do
    if is_module_enabled(module_name) do
      Map.get(@module_menus, module_name)
    end
  end

  @doc """
  Returns all enabled modules.
  """
  def get_enabled_modules do
    @module_menus
    |> Enum.filter(fn {module_name, _url} -> is_module_enabled(module_name) end)
    |> Enum.map(fn {module_name, url} -> {module_name, url, humanize_module_name(module_name)} end)
  end

  defp humanize_module_name("attendees"), do: "Participantes"
  defp humanize_module_name("speakers"), do: "Expositores"
  defp humanize_module_name("sessions"), do: "Sesiones"
  defp humanize_module_name("rooms"), do: "Salas"
  defp humanize_module_name("commissions"), do: "Comisiones"
  defp humanize_module_name("event_info"), do: "Información del Evento"
  defp humanize_module_name("tourist_info"), do: "Información Turística"
  defp humanize_module_name("packages"), do: "Paquetes"
  defp humanize_module_name(name), do: String.capitalize(name)
end