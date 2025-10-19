defmodule YachanakuyWeb.RequireStaff do
  @moduledoc """
  Plug to require staff (operador) role for accessing routes.
  Redirects non-staff users to login page with error message.
  """
  import Plug.Conn
  import Phoenix.Controller

  def init(options), do: options

  def call(conn, _options) do
    case get_session_user_role(conn) do
      "operador" ->
        conn
      "admin" ->
        conn  # Admins can access staff routes
      _ ->
        conn
        |> put_flash(:error, "Acceso denegado. Se requiere rol de operador.")
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