defmodule YachanakuyWeb.AuthorizationPlug do
  import Plug.Conn
  import Phoenix.Controller

  def require_admin_role(conn, _opts) do
    case get_session_user_role(conn) do
      "admin" ->
        conn
      _ ->
        conn
        |> put_flash(:error, "Acceso denegado. Se requiere rol de administrador.")
        |> redirect(to: "/users/log-in")
        |> halt()
    end
  end

  def require_staff_role(conn, _opts) do
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

  def require_supervisor_role(conn, _opts) do
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
    case conn.assigns[:current_scope] do
      nil -> nil
      %{user: nil} -> nil
      %{user: user} -> user.rol
      _ -> nil
    end
  end
end