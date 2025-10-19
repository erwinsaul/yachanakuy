defmodule Yachanakuy.LogsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Yachanakuy.Logs` context.
  """

  alias Yachanakuy.Logs

  def valid_email_log_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      tipo_email: "confirmacion_registro",
      destinatario: "test#{System.unique_integer()}@example.com",
      fecha_envio: DateTime.utc_now(),
      estado: "enviado",
      asunto: "Confirmación de Registro",
      mensaje_id: "MSG_#{System.unique_integer()}_#{:rand.uniform(999999)}"
    })
  end

  def email_log_fixture(attrs \\ %{}) do
    {:ok, email_log} =
      attrs
      |> valid_email_log_attributes()
      |> Logs.create_email_log()

    email_log
  end

  def valid_audit_log_attributes(attrs \\ %{}) do
    user = Yachanakuy.AccountsFixtures.user_fixture()
    
    Enum.into(attrs, %{
      user_id: user.id,
      accion: "crear",
      tipo_recurso: "participante",
      id_recurso: System.unique_integer([positive: true]),
      fecha_accion: DateTime.utc_now(),
      cambios: "{\"nombre_completo\": \"Test User\"}",
      ip_address: "192.168.1.#{:rand.uniform(254)}",
      user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
      metadata: %{
        browser: "Chrome",
        os: "Windows 10",
        device: "Desktop"
      }
    })
  end

  def audit_log_fixture(attrs \\ %{}) do
    {:ok, audit_log} =
      attrs
      |> valid_audit_log_attributes()
      |> Logs.create_audit_log()

    audit_log
  end

  def invalid_email_log_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      tipo_email: nil,
      destinatario: nil,
      fecha_envio: nil,
      estado: nil,
      asunto: nil
    })
  end

  def invalid_audit_log_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      accion: nil,
      fecha_accion: nil
    })
  end

  def valid_sign_in_attributes(attrs \\ %{}) do
    user = Yachanakuy.AccountsFixtures.user_fixture()
    attendee = Yachanakuy.RegistrationFixtures.attendee_fixture()
    
    Enum.into(attrs, %{
      user_id: user.id,
      attendee_id: attendee.id,
      email: "signin#{System.unique_integer()}@example.com",
      success: true,
      ip_address: "192.168.1.#{:rand.uniform(254)}",
      user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
      failure_reason: nil
    })
  end

  def sign_in_fixture(attrs \\ %{}) do
    attrs = valid_sign_in_attributes(attrs)
    Logs.log_sign_in_attempt(attrs.email, attrs.success, %{
      user_id: attrs.user_id,
      ip_address: attrs.ip_address,
      user_agent: attrs.user_agent,
      failure_reason: attrs.failure_reason
    })
  end

  def valid_email_sent_attributes(attrs \\ %{}) do
    attendee = Yachanakuy.RegistrationFixtures.attendee_fixture()
    
    Enum.into(attrs, %{
      tipo_email: "confirmacion_registro",
      destinatario: "email#{System.unique_integer()}@example.com",
      attendee_id: attendee.id,
      asunto: "Confirmación de Registro",
      plantilla: "confirmation_email.html",
      estado: "enviado",
      fecha_envio: DateTime.utc_now(),
      mensaje_id: "MSG_#{System.unique_integer()}_#{:rand.uniform(999999)}"
    })
  end

  def email_sent_fixture(attrs \\ %{}) do
    attrs = valid_email_sent_attributes(attrs)
    Logs.log_email_sent(attrs.tipo_email, attrs.destinatario, attrs.attendee_id, %{
      asunto: attrs.asunto,
      plantilla: attrs.plantilla
    })
  end
end