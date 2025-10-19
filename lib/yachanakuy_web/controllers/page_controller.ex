defmodule YachanakuyWeb.PageController do
  use YachanakuyWeb, :controller

  def home(conn, _params) do
    # Redirect to the LiveView home page
    redirect(conn, to: ~p"/")
  end
end
