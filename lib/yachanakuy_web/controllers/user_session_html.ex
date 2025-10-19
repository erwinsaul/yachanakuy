defmodule YachanakuyWeb.UserSessionHTML do
  use YachanakuyWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:yachanakuy, Yachanakuy.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
