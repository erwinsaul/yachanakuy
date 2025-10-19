defmodule YachanakuyWeb.RequireSupervisor do
  @moduledoc """
  Plug to require supervisor (encargado_comision) role for accessing routes.
  Redirects non-supervisor users to login page with error message.
  """
  import Plug.Conn
  import Phoenix.Controller

  def init(options), do: options

  def call(conn, _options) do
    case get_session_user_role(conn) do
      "encargado_comision" ->
        conn
      "admin" ->
        conn  # Admins can access supervisor routes
      _ ->
        conn
        |> put_flash(:error, "Acceso denegado. Se requiere rol de encargado de comisión.")
        |> redirect(to: "/users/log-in")
        |> halt()
    end
  end

  defp get_session_user_role(conn) do
    case conn.assigns[:current_user] do
      nil -> nil
      user -> user.rol
    end
  end
end