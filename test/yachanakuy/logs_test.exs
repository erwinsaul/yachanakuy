defmodule Yachanakuy.LogsTest do
  use Yachanakuy.DataCase

  alias Yachanakuy.Logs
  alias Yachanakuy.Logs.EmailLog
  alias Yachanakuy.Logs.AuditLog

  import Yachanakuy.LogsFixtures
  import Yachanakuy.AccountsFixtures
  import Yachanakuy.RegistrationFixtures

  describe "email_logs" do
    alias Yachanakuy.Logs.EmailLog

    @valid_attrs %{
      tipo_email: "confirmacion_registro",
      destinatario: "test@example.com",
      fecha_envio: DateTime.utc_now(),
      estado: "enviado",
      asunto: "Confirmación de Registro"
    }
    @update_attrs %{
      tipo_email: "credencial_digital",
      destinatario: "updated@example.com",
      estado: "fallido"
    }
    @invalid_attrs %{
      tipo_email: nil,
      destinatario: nil,
      fecha_envio: nil,
      estado: nil
    }

    def email_log_fixture(attrs \\ %{}) do
      {:ok, email_log} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Logs.create_email_log()

      email_log
    end

    test "list_email_logs/0 returns all email logs" do
      email_log = email_log_fixture()
      assert Logs.list_email_logs() == [email_log]
    end

    test "get_email_log!/1 returns the email log with given id" do
      email_log = email_log_fixture()
      assert Logs.get_email_log!(email_log.id) == email_log
    end

    test "create_email_log/1 with valid data creates a email log" do
      assert {:ok, %EmailLog{} = email_log} = Logs.create_email_log(@valid_attrs)
      assert email_log.tipo_email == "confirmacion_registro"
      assert email_log.destinatario == "test@example.com"
      assert email_log.estado == "enviado"
      assert email_log.asunto == "Confirmación de Registro"
    end

    test "create_email_log/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Logs.create_email_log(@invalid_attrs)
    end

    test "email_log destinatario must be valid email format" do
      attrs_with_invalid_email = Map.put(@valid_attrs, :destinatario, "invalid_email")
      assert {:error, %Ecto.Changeset{}} = Logs.create_email_log(attrs_with_invalid_email)
    end

    test "email_log tipo_email must be one of valid values" do
      valid_types = [
        "confirmacion_registro", 
        "credencial_digital", 
        "certificado", 
        "rechazo",
        "recordatorio_pago",
        "bienvenida",
        "programa_actualizado",
        "recordatorio_evento"
      ]
      
      Enum.each(valid_types, fn type ->
        attrs = Map.put(@valid_attrs, :tipo_email, type)
        assert {:ok, %EmailLog{}} = Logs.create_email_log(attrs)
      end)
      
      attrs_with_invalid_type = Map.put(@valid_attrs, :tipo_email, "invalid_type")
      assert {:error, %Ecto.Changeset{}} = Logs.create_email_log(attrs_with_invalid_type)
    end

    test "email_log estado must be one of valid values" do
      valid_states = ["enviado", "fallido", "pendiente", "reintentando"]
      
      Enum.each(valid_states, fn state ->
        attrs = Map.put(@valid_attrs, :estado, state)
        assert {:ok, %EmailLog{}} = Logs.create_email_log(attrs)
      end)
      
      attrs_with_invalid_state = Map.put(@valid_attrs, :estado, "invalid_state")
      assert {:error, %Ecto.Changeset{}} = Logs.create_email_log(attrs_with_invalid_state)
    end

    test "update_email_log/2 with valid data updates the email log" do
      email_log = email_log_fixture()
      assert {:ok, %EmailLog{} = email_log} = Logs.update_email_log(email_log, @update_attrs)
      assert email_log.tipo_email == "credencial_digital"
      assert email_log.destinatario == "updated@example.com"
      assert email_log.estado == "fallido"
    end

    test "update_email_log/2 with invalid data returns error changeset" do
      email_log = email_log_fixture()
      assert {:error, %Ecto.Changeset{}} = Logs.update_email_log(email_log, @invalid_attrs)
      assert email_log == Logs.get_email_log!(email_log.id)
    end

    test "delete_email_log/1 deletes the email log" do
      email_log = email_log_fixture()
      assert {:ok, %EmailLog{}} = Logs.delete_email_log(email_log)
      assert_raise Ecto.NoResultsError, fn -> Logs.get_email_log!(email_log.id) end
    end

    test "change_email_log/1 returns a email log changeset" do
      email_log = email_log_fixture()
      assert %Ecto.Changeset{} = Logs.change_email_log(email_log)
    end
  end

  describe "audit_logs" do
    alias Yachanakuy.Logs.AuditLog

    @valid_attrs %{
      accion: "crear",
      tipo_recurso: "participante",
      id_recurso: 123,
      fecha_accion: DateTime.utc_now()
    }
    @update_attrs %{
      accion: "actualizar",
      tipo_recurso: "usuario"
    }
    @invalid_attrs %{
      accion: nil,
      fecha_accion: nil
    }

    def audit_log_fixture(attrs \\ %{}) do
      user = user_fixture()
      attrs = Map.put(attrs, :user_id, user.id)
      
      {:ok, audit_log} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Logs.create_audit_log()

      audit_log
    end

    test "list_audit_logs/0 returns all audit logs" do
      audit_log = audit_log_fixture()
      assert Logs.list_audit_logs() == [audit_log]
    end

    test "get_audit_log!/1 returns the audit log with given id" do
      audit_log = audit_log_fixture()
      assert Logs.get_audit_log!(audit_log.id) == audit_log
    end

    test "create_audit_log/1 with valid data creates a audit log" do
      user = user_fixture()
      attrs = Map.put(@valid_attrs, :user_id, user.id)
      
      assert {:ok, %AuditLog{} = audit_log} = Logs.create_audit_log(attrs)
      assert audit_log.accion == "crear"
      assert audit_log.tipo_recurso == "participante"
      assert audit_log.id_recurso == 123
    end

    test "create_audit_log/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Logs.create_audit_log(@invalid_attrs)
    end

    test "audit_log accion must be one of valid values" do
      valid_actions = [
        "crear", 
        "actualizar", 
        "eliminar", 
        "aprobar", 
        "rechazar", 
        "entregar", 
        "registrar_asistencia", 
        "generar_certificado", 
        "escanear_qr", 
        "iniciar_sesion", 
        "cerrar_sesion", 
        "cambiar_contraseña", 
        "enviar_email",
        "asignar_rol",
        "generar_qr",
        "validar_qr"
      ]
      
      Enum.each(valid_actions, fn action ->
        attrs = Map.put(@valid_attrs, :accion, action)
        assert {:ok, %AuditLog{}} = Logs.create_audit_log(attrs)
      end)
      
      attrs_with_invalid_action = Map.put(@valid_attrs, :accion, "invalid_action")
      assert {:error, %Ecto.Changeset{}} = Logs.create_audit_log(attrs_with_invalid_action)
    end

    test "audit_log tipo_recurso must be one of valid values" do
      valid_resource_types = [
        "participante", 
        "usuario", 
        "sesion", 
        "credencial", 
        "material", 
        "refrigerio", 
        "asistencia", 
        "certificado", 
        "comision", 
        "categoria", 
        "configuracion",
        "sala",
        "expositor"
      ]
      
      Enum.each(valid_resource_types, fn resource_type ->
        attrs = Map.put(@valid_attrs, :tipo_recurso, resource_type)
        assert {:ok, %AuditLog{}} = Logs.create_audit_log(attrs)
      end)
      
      attrs_with_invalid_resource_type = Map.put(@valid_attrs, :tipo_recurso, "invalid_resource_type")
      assert {:error, %Ecto.Changeset{}} = Logs.create_audit_log(attrs_with_invalid_resource_type)
    end

    test "update_audit_log/2 with valid data updates the audit log" do
      audit_log = audit_log_fixture()
      assert {:ok, %AuditLog{} = audit_log} = Logs.update_audit_log(audit_log, @update_attrs)
      assert audit_log.accion == "actualizar"
      assert audit_log.tipo_recurso == "usuario"
    end

    test "update_audit_log/2 with invalid data returns error changeset" do
      audit_log = audit_log_fixture()
      assert {:error, %Ecto.Changeset{}} = Logs.update_audit_log(audit_log, @invalid_attrs)
      assert audit_log == Logs.get_audit_log!(audit_log.id)
    end

    test "delete_audit_log/1 deletes the audit log" do
      audit_log = audit_log_fixture()
      assert {:ok, %AuditLog{}} = Logs.delete_audit_log(audit_log)
      assert_raise Ecto.NoResultsError, fn -> Logs.get_audit_log!(audit_log.id) end
    end

    test "change_audit_log/1 returns a audit log changeset" do
      audit_log = audit_log_fixture()
      assert %Ecto.Changeset{} = Logs.change_audit_log(audit_log)
    end
  end

  describe "audit actions" do
    alias Yachanakuy.Logs.AuditLog

    test "audit_action/5 creates an audit log entry" do
      user = user_fixture()
      attendee = attendee_fixture()
      
      assert {:ok, %AuditLog{} = audit_log} = Logs.audit_action(
        user.id, 
        "crear", 
        "participante", 
        attendee.id, 
        %{
          cambios: "{\\"nombre_completo\\": \\"Juan Pérez\\"}",
          ip_address: "192.168.1.100",
          user_agent: "Mozilla/5.0...",
          metadata: %{
            browser: "Chrome",
            os: "Windows 10"
          }
        }
      )
      
      assert audit_log.user_id == user.id
      assert audit_log.accion == "crear"
      assert audit_log.tipo_recurso == "participante"
      assert audit_log.id_recurso == attendee.id
      assert audit_log.ip_address == "192.168.1.100"
      assert audit_log.user_agent == "Mozilla/5.0..."
      assert audit_log.metadata != nil
    end

    test "log_sign_in_attempt/3 logs successful sign in" do
      user = user_fixture()
      
      assert {:ok, %AuditLog{} = audit_log} = Logs.log_sign_in_attempt(
        user.email, 
        true, 
        %{
          user_id: user.id,
          ip_address: "192.168.1.100",
          user_agent: "Mozilla/5.0..."
        }
      )
      
      assert audit_log.accion == "iniciar_sesion"
      assert audit_log.tipo_recurso == "usuario"
      assert audit_log.user_id == user.id
      assert audit_log.metadata["success"] == true
      assert audit_log.metadata["email"] == user.email
    end

    test "log_sign_in_attempt/3 logs failed sign in" do
      assert {:ok, %AuditLog{} = audit_log} = Logs.log_sign_in_attempt(
        "test@example.com", 
        false, 
        %{
          failure_reason: "invalid_password",
          ip_address: "192.168.1.100"
        }
      )
      
      assert audit_log.accion == "iniciar_sesion"
      assert audit_log.tipo_recurso == "usuario"
      assert audit_log.metadata["success"] == false
      assert audit_log.metadata["email"] == "test@example.com"
      assert audit_log.metadata["failure_reason"] == "invalid_password"
    end

    test "get_audit_logs_by_user/2 returns audit logs for specific user" do
      user1 = user_fixture()
      user2 = user_fixture()
      
      # Create audit logs for user1
      assert {:ok, %AuditLog{}} = Logs.audit_action(user1.id, "crear", "participante", 123, %{})
      assert {:ok, %AuditLog{}} = Logs.audit_action(user1.id, "actualizar", "participante", 124, %{})
      
      # Create audit log for user2
      assert {:ok, %AuditLog{}} = Logs.audit_action(user2.id, "eliminar", "participante", 125, %{})
      
      # Get audit logs for user1
      user1_logs = Logs.get_audit_logs_by_user(user1.id)
      assert length(user1_logs) == 2
      
      # Get audit logs for user2
      user2_logs = Logs.get_audit_logs_by_user(user2.id)
      assert length(user2_logs) == 1
      
      # Verify all logs belong to the correct user
      Enum.each(user1_logs, fn log -> 
        assert log.user_id == user1.id 
      end)
      
      Enum.each(user2_logs, fn log -> 
        assert log.user_id == user2.id 
      end)
    end

    test "get_audit_logs_by_action/2 returns audit logs for specific action" do
      user = user_fixture()
      
      # Create different types of audit logs
      assert {:ok, %AuditLog{}} = Logs.audit_action(user.id, "crear", "participante", 123, %{})
      assert {:ok, %AuditLog{}} = Logs.audit_action(user.id, "actualizar", "participante", 124, %{})
      assert {:ok, %AuditLog{}} = Logs.audit_action(user.id, "crear", "usuario", 125, %{})
      
      # Get audit logs for "crear" action
      crear_logs = Logs.get_audit_logs_by_action("crear")
      assert length(crear_logs) >= 2
      
      # Get audit logs for "actualizar" action
      actualizar_logs = Logs.get_audit_logs_by_action("actualizar")
      assert length(actualizar_logs) >= 1
      
      # Verify all logs have the correct action
      Enum.each(crear_logs, fn log -> 
        assert log.accion == "crear" 
      end)
      
      Enum.each(actualizar_logs, fn log -> 
        assert log.accion == "actualizar" 
      end)
    end
  end

  describe "email logging" do
    alias Yachanakuy.Logs.EmailLog

    test "log_email_sent/4 creates an email log entry" do
      attendee = attendee_fixture()
      
      assert {:ok, %EmailLog{} = email_log} = Logs.log_email_sent(
        "confirmacion_registro", 
        "test@example.com", 
        attendee.id, 
        %{
          asunto: "Confirmación de Registro",
          plantilla: "confirmation_email.html"
        }
      )
      
      assert email_log.tipo_email == "confirmacion_registro"
      assert email_log.destinatario == "test@example.com"
      assert email_log.attendee_id == attendee.id
      assert email_log.asunto == "Confirmación de Registro"
      assert email_log.plantilla == "confirmation_email.html"
      assert email_log.estado == "enviado"
      assert email_log.mensaje_id != nil
      assert email_log.fecha_envio != nil
    end

    test "get_email_logs_by_type_and_status/3 returns email logs filtered by type and status" do
      attendee = attendee_fixture()
      
      # Create different types of email logs
      assert {:ok, %EmailLog{}} = Logs.log_email_sent("confirmacion_registro", "test1@example.com", attendee.id, %{asunto: "Confirmación 1"})
      assert {:ok, %EmailLog{}} = Logs.log_email_sent("credencial_digital", "test2@example.com", attendee.id, %{asunto: "Credencial 1"})
      assert {:ok, %EmailLog{}} = Logs.log_email_sent("confirmacion_registro", "test3@example.com", attendee.id, %{asunto: "Confirmación 2"})
      
      # Get email logs for "confirmacion_registro" type
      confirmation_logs = Logs.get_email_logs_by_type_and_status("enviado", "confirmacion_registro")
      assert length(confirmation_logs) >= 2
      
      # Get email logs for "credencial_digital" type
      credential_logs = Logs.get_email_logs_by_type_and_status("enviado", "credencial_digital")
      assert length(credential_logs) >= 1
      
      # Verify all logs have the correct type
      Enum.each(confirmation_logs, fn log -> 
        assert log.tipo_email == "confirmacion_registro" 
      end)
      
      Enum.each(credential_logs, fn log -> 
        assert log.tipo_email == "credencial_digital" 
      end)
    end
  end
end