defmodule Yachanakuy.Logs do
  @moduledoc """
  El contexto de Logs gestiona todos los registros de auditoría y envío de correos
  para el sistema Yachanakuy.

  ## Funcionalidades principales

  ### Auditoría
  - Registro completo de todas las acciones del sistema
  - Seguimiento de cambios en registros sensibles
  - Auditoría de acceso y seguridad
  - Generación de informes de actividad

  ### Registro de correos
  - Historial de todos los correos electrónicos enviados
  - Estado de envío y posibles errores
  - Seguimiento de entregas por participante
  - Archivo de contenido para auditoría

  ## Ejemplos de uso

      # Registrar una acción de auditoría
      Logs.audit_action(user_id, "crear", "participante", participant_id, %{
        cambios: "{\\"nombre_completo\\": \\"Juan Pérez\\"}",
        ip_address: "192.168.1.100"
      })

      # Registrar un envío de correo
      Logs.log_email_sent("confirmacion_registro", participant_email, participant_id, %{
        asunto: "Confirmación de Registro",
        plantilla: "confirmation_email.html"
      })

  ## Tipos de acciones auditadas

  - `crear`: Creación de nuevos registros
  - `actualizar`: Modificación de registros existentes
  - `eliminar`: Eliminación de registros
  - `aprobar`: Aprobación de registros (por ejemplo, inscripciones)
  - `rechazar`: Rechazo de registros
  - `entregar`: Entrega de credenciales, materiales o refrigerios
  - `registrar_asistencia`: Registro de asistencia a sesiones
  - `generar_certificado`: Generación de certificados
  - `escanear_qr`: Escaneo de códigos QR
  - `iniciar_sesion`: Inicio de sesión de usuarios
  - `cerrar_sesion`: Cierre de sesión de usuarios
  - `cambiar_contraseña`: Cambio de contraseña
  - `enviar_email`: Envío de correos electrónicos
  """

  import Ecto.Query, warn: false
  alias Yachanakuy.Repo

  alias Yachanakuy.Logs.EmailLog
  alias Yachanakuy.Logs.AuditLog

  @doc """
  Obtiene una lista de todos los registros de correo electrónico.

  ## Ejemplo

      iex> Logs.list_email_logs()
      [%EmailLog{}, ...]

  ## Retorna

  - Lista de structs `%EmailLog{}`
  """
  def list_email_logs do
    Repo.all(EmailLog)
  end

  @doc """
  Obtiene un registro de correo electrónico específico por ID.

  ## Parámetros

  - `id`: ID numérico del registro de correo

  ## Ejemplo

      iex> Logs.get_email_log!(123)
      %EmailLog{}

      iex> Logs.get_email_log!(999)
      ** (Ecto.NoResultsError)

  ## Retorna

  - Struct `%EmailLog{}` con los datos del registro
  """
  def get_email_log!(id) do
    Repo.get!(EmailLog, id)
  end

  @doc """
  Crea un nuevo registro de correo electrónico.

  ## Parámetros

  - `attrs`: Mapa con los atributos del registro de correo

  ## Ejemplo

      iex> Logs.create_email_log(%{
        tipo_email: "confirmacion_registro",
        destinatario: "juan@example.com",
        fecha_envio: DateTime.utc_now(),
        estado: "enviado",
        asunto: "Confirmación de Registro"
      })
      {:ok, %EmailLog{}}

      iex> Logs.create_email_log(%{})
      {:error, %Ecto.Changeset{}}

  ## Retorna

  - `{:ok, %EmailLog{}}`: Éxito
  - `{:error, %Ecto.Changeset{}}`: Error de validación
  """
  def create_email_log(attrs \\ %{}) do
    %EmailLog{}
    |> EmailLog.email_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Actualiza un registro de correo electrónico existente.

  ## Parámetros

  - `email_log`: Struct `%EmailLog{}` existente
  - `attrs`: Mapa con los atributos a actualizar

  ## Ejemplo

      iex> Logs.update_email_log(email_log, %{estado: "fallido"})
      {:ok, %EmailLog{}}

      iex> Logs.update_email_log(email_log, %{estado: "invalid"})
      {:error, %Ecto.Changeset{}}

  ## Retorna

  - `{:ok, %EmailLog{}}`: Éxito
  - `{:error, %Ecto.Changeset{}}`: Error de validación
  """
  def update_email_log(%EmailLog{} = email_log, attrs) do
    email_log
    |> EmailLog.email_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Elimina un registro de correo electrónico.

  ## Parámetros

  - `email_log`: Struct `%EmailLog{}` a eliminar

  ## Ejemplo

      iex> Logs.delete_email_log(email_log)
      {:ok, %EmailLog{}}

  ## Retorna

  - `{:ok, %EmailLog{}}`: Éxito
  - `{:error, %Ecto.Changeset{}}`: Error de validación
  """
  def delete_email_log(%EmailLog{} = email_log) do
    Repo.delete(email_log)
  end

  @doc """
  Crea un changeset para un registro de correo electrónico existente.

  ## Parámetros

  - `email_log`: Struct `%EmailLog{}` existente
  - `attrs`: Mapa con los atributos a aplicar

  ## Ejemplo

      iex> Logs.change_email_log(email_log)
      %Ecto.Changeset{}

  ## Retorna

  - `%Ecto.Changeset{}` para validaciones
  """
  def change_email_log(%EmailLog{} = email_log, attrs \\ %{}) do
    EmailLog.email_changeset(email_log, attrs)
  end

  @doc """
  Obtiene una lista de todos los registros de auditoría.

  ## Ejemplo

      iex> Logs.list_audit_logs()
      [%AuditLog{}, ...]

  ## Retorna

  - Lista de structs `%AuditLog{}`
  """
  def list_audit_logs do
    Repo.all(AuditLog)
  end

  @doc """
  Obtiene un registro de auditoría específico por ID.

  ## Parámetros

  - `id`: ID numérico del registro de auditoría

  ## Ejemplo

      iex> Logs.get_audit_log!(123)
      %AuditLog{}

      iex> Logs.get_audit_log!(999)
      ** (Ecto.NoResultsError)

  ## Retorna

  - Struct `%AuditLog{}` con los datos del registro
  """
  def get_audit_log!(id) do
    Repo.get!(AuditLog, id)
  end

  @doc """
  Crea un nuevo registro de auditoría.

  ## Parámetros

  - `attrs`: Mapa con los atributos del registro de auditoría

  ## Ejemplo

      iex> Logs.create_audit_log(%{
        accion: "crear",
        tipo_recurso: "participante",
        id_recurso: 123,
        fecha_accion: DateTime.utc_now(),
        user_id: 456
      })
      {:ok, %AuditLog{}}

      iex> Logs.create_audit_log(%{})
      {:error, %Ecto.Changeset{}}

  ## Retorna

  - `{:ok, %AuditLog{}}`: Éxito
  - `{:error, %Ecto.Changeset{}}`: Error de validación
  """
  def create_audit_log(attrs \\ %{}) do
    %AuditLog{}
    |> AuditLog.audit_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Actualiza un registro de auditoría existente.

  ## Parámetros

  - `audit_log`: Struct `%AuditLog{}` existente
  - `attrs`: Mapa con los atributos a actualizar

  ## Ejemplo

      iex> Logs.update_audit_log(audit_log, %{cambios: "{\\"nombre\\": \\"Nuevo nombre\\"}"})
      {:ok, %AuditLog{}}

      iex> Logs.update_audit_log(audit_log, %{accion: "invalid"})
      {:error, %Ecto.Changeset{}}

  ## Retorna

  - `{:ok, %AuditLog{}}`: Éxito
  - `{:error, %Ecto.Changeset{}}`: Error de validación
  """
  def update_audit_log(%AuditLog{} = audit_log, attrs) do
    audit_log
    |> AuditLog.audit_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Elimina un registro de auditoría.

  ## Parámetros

  - `audit_log`: Struct `%AuditLog{}` a eliminar

  ## Ejemplo

      iex> Logs.delete_audit_log(audit_log)
      {:ok, %AuditLog{}}

  ## Retorna

  - `{:ok, %AuditLog{}}`: Éxito
  - `{:error, %Ecto.Changeset{}}`: Error de validación
  """
  def delete_audit_log(%AuditLog{} = audit_log) do
    Repo.delete(audit_log)
  end

  @doc """
  Crea un changeset para un registro de auditoría existente.

  ## Parámetros

  - `audit_log`: Struct `%AuditLog{}` existente
  - `attrs`: Mapa con los atributos a aplicar

  ## Ejemplo

      iex> Logs.change_audit_log(audit_log)
      %Ecto.Changeset{}

  ## Retorna

  - `%Ecto.Changeset{}` para validaciones
  """
  def change_audit_log(%AuditLog{} = audit_log, attrs \\ %{}) do
    AuditLog.audit_changeset(audit_log, attrs)
  end

  @doc """
  Registra una acción de auditoría completa con contexto adicional.

  Esta función es la interfaz principal para registrar acciones de auditoría
  en el sistema, incluyendo información del cliente y metadatos.

  ## Parámetros

  - `user_id`: ID del usuario que realizó la acción (puede ser nil)
  - `accion`: Tipo de acción realizada
  - `tipo_recurso`: Tipo de recurso afectado
  - `id_recurso`: ID del recurso afectado
  - `opts`: Opciones adicionales
    - `:cambios`: Cambios realizados en formato JSON/string
    - `:ip_address`: Dirección IP del cliente
    - `:user_agent`: User agent del cliente
    - `:metadata`: Metadatos adicionales como mapa

  ## Ejemplo

      iex> Logs.audit_action(123, "crear", "participante", 456, %{
        cambios: "{\\"nombre_completo\\": \\"Juan Pérez\\"}",
        ip_address: "192.168.1.100",
        user_agent: "Mozilla/5.0...",
        metadata: %{
          browser: "Chrome",
          os: "Windows 10"
        }
      })
      {:ok, %AuditLog{}}

  ## Retorna

  - `{:ok, %AuditLog{}}`: Éxito
  - `{:error, %Ecto.Changeset{}}`: Error de validación
  """
  def audit_action(user_id, accion, tipo_recurso, id_recurso, opts \\ []) do
    changes = Keyword.get(opts, :cambios, nil)
    ip_address = Keyword.get(opts, :ip_address, nil)
    user_agent = Keyword.get(opts, :user_agent, nil)
    metadata = Keyword.get(opts, :metadata, nil)
    
    attrs = %{
      user_id: user_id,
      accion: accion,
      tipo_recurso: tipo_recurso,
      id_recurso: id_recurso,
      cambios: changes,
      ip_address: ip_address,
      user_agent: user_agent,
      metadata: metadata,
      fecha_accion: DateTime.utc_now()
    }
    
    create_audit_log(attrs)
  end

  @doc """
  Registra un intento de inicio de sesión, exitoso o fallido.

  ## Parámetros

  - `email`: Correo electrónico del usuario que intenta iniciar sesión
  - `success`: Boolean indicando si el inicio fue exitoso
  - `opts`: Opciones adicionales
    - `:user_id`: ID del usuario si el inicio fue exitoso
    - `:ip_address`: Dirección IP del cliente
    - `:user_agent`: User agent del cliente
    - `:failure_reason`: Razón del fallo si no fue exitoso

  ## Ejemplo

      iex> Logs.log_sign_in_attempt("juan@example.com", true, %{
        user_id: 123,
        ip_address: "192.168.1.100",
        user_agent: "Mozilla/5.0..."
      })
      {:ok, %AuditLog{}}

      iex> Logs.log_sign_in_attempt("juan@example.com", false, %{
        failure_reason: "invalid_password",
        ip_address: "192.168.1.100"
      })
      {:ok, %AuditLog{}}

  ## Retorna

  - `{:ok, %AuditLog{}}`: Éxito
  - `{:error, %Ecto.Changeset{}}`: Error de validación
  """
  def log_sign_in_attempt(email, success, opts \\ []) do
    user_id = Keyword.get(opts, :user_id, nil)
    ip_address = Keyword.get(opts, :ip_address, nil)
    user_agent = Keyword.get(opts, :user_agent, nil)
    failure_reason = Keyword.get(opts, :failure_reason, nil)
    
    metadata = %{
      email: email,
      success: success
    }
    
    metadata = 
      if failure_reason do
        Map.put(metadata, :failure_reason, failure_reason)
      else
        metadata
      end
    
    audit_action(
      user_id,
      "iniciar_sesion",
      "usuario",
      user_id || 0,
      cambios: if(success, do: "Inicio de sesión exitoso", else: "Intento de inicio de sesión fallido"),
      ip_address: ip_address,
      user_agent: user_agent,
      metadata: metadata
    )
  end

  @doc """
  Registra el envío de un correo electrónico.

  ## Parámetros

  - `tipo_email`: Tipo de correo enviado
  - `destinatario`: Dirección de correo del destinatario
  - `attendee_id`: ID del participante relacionado (opcional)
  - `opts`: Opciones adicionales
    - `:asunto`: Asunto del correo
    - `:plantilla`: Plantilla utilizada
    - `:estado`: Estado del envío (por defecto "enviado")
    - `:contenido`: Contenido del correo (opcional, para auditoría)

  ## Ejemplo

      iex> Logs.log_email_sent("confirmacion_registro", "juan@example.com", 123, %{
        asunto: "Confirmación de Registro - Congreso 2025",
        plantilla: "confirmation_email.html"
      })
      {:ok, %EmailLog{}}

  ## Retorna

  - `{:ok, %EmailLog{}}`: Éxito
  - `{:error, %Ecto.Changeset{}}`: Error de validación
  """
  def log_email_sent(tipo_email, destinatario, attendee_id \\ nil, opts \\ []) do
    asunto = Keyword.get(opts, :asunto, nil)
    plantilla = Keyword.get(opts, :plantilla, nil)
    estado = Keyword.get(opts, :estado, "enviado")
    contenido = Keyword.get(opts, :contenido, nil)
    
    create_email_log(%{
      tipo_email: tipo_email,
      destinatario: destinatario,
      attendee_id: attendee_id,
      asunto: asunto,
      plantilla: plantilla,
      contenido: contenido,
      estado: estado,
      fecha_envio: DateTime.utc_now(),
      mensaje_id: generate_unique_message_id()
    })
  end

  @doc """
  Busca registros de auditoría por usuario.

  ## Parámetros

  - `user_id`: ID del usuario a buscar
  - `opts`: Opciones de búsqueda
    - `:limit`: Número máximo de registros a devolver (por defecto 50)
    - `:order`: Orden de resultados (:asc o :desc, por defecto :desc)

  ## Ejemplo

      iex> Logs.get_audit_logs_by_user(123, %{limit: 10})
      [%AuditLog{}, ...]

  ## Retorna

  - Lista de structs `%AuditLog{}`
  """
  def get_audit_logs_by_user(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    order = Keyword.get(opts, :order, :desc)
    
    query = from al in AuditLog,
      where: al.user_id == ^user_id,
      limit: ^limit,
      order_by: [{^order, al.fecha_accion}]
    
    Repo.all(query)
  end

  @doc """
  Busca registros de auditoría por tipo de acción.

  ## Parámetros

  - `accion`: Tipo de acción a buscar
  - `opts`: Opciones de búsqueda
    - `:limit`: Número máximo de registros a devolver (por defecto 50)
    - `:order`: Orden de resultados (:asc o :desc, por defecto :desc)
    - `:fecha_desde`: Fecha desde la que buscar (opcional)
    - `:fecha_hasta`: Fecha hasta la que buscar (opcional)

  ## Ejemplo

      iex> Logs.get_audit_logs_by_action("crear", %{limit: 10, fecha_desde: ~D[2025-01-01]})
      [%AuditLog{}, ...]

  ## Retorna

  - Lista de structs `%AuditLog{}`
  """
  def get_audit_logs_by_action(accion, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    order = Keyword.get(opts, :order, :desc)
    fecha_desde = Keyword.get(opts, :fecha_desde, nil)
    fecha_hasta = Keyword.get(opts, :fecha_hasta, nil)
    
    query = from al in AuditLog,
      where: al.accion == ^accion,
      limit: ^limit,
      order_by: [{^order, al.fecha_accion}]
    
    query = 
      if fecha_desde do
        where(query, [al], al.fecha_accion >= ^fecha_desde)
      else
        query
      end
    
    query = 
      if fecha_hasta do
        where(query, [al], al.fecha_accion <= ^fecha_hasta)
      else
        query
      end
    
    Repo.all(query)
  end

  @doc """
  Busca registros de correo por tipo de correo y estado.

  ## Parámetros

  - `tipo_email`: Tipo de correo a buscar (opcional)
  - `estado`: Estado del correo (opcional)
  - `opts`: Opciones de búsqueda
    - `:limit`: Número máximo de registros a devolver (por defecto 50)
    - `:order`: Orden de resultados (:asc o :desc, por defecto :desc)
    - `:fecha_desde`: Fecha desde la que buscar (opcional)
    - `:fecha_hasta`: Fecha hasta la que buscar (opcional)

  ## Ejemplo

      iex> Logs.get_email_logs_by_type_and_status("enviado", "confirmacion_registro", %{limit: 10})
      [%EmailLog{}, ...]

  ## Retorna

  - Lista de structs `%EmailLog{}`
  """
  def get_email_logs_by_type_and_status(estado \\ nil, tipo_email \\ nil, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    order = Keyword.get(opts, :order, :desc)
    fecha_desde = Keyword.get(opts, :fecha_desde, nil)
    fecha_hasta = Keyword.get(opts, :fecha_hasta, nil)
    
    query = from el in EmailLog,
      limit: ^limit,
      order_by: [{^order, el.fecha_envio}]
    
    query = 
      if estado do
        where(query, [el], el.estado == ^estado)
      else
        query
      end
    
    query = 
      if tipo_email do
        where(query, [el], el.tipo_email == ^tipo_email)
      else
        query
      end
    
    query = 
      if fecha_desde do
        where(query, [el], el.fecha_envio >= ^fecha_desde)
      else
        query
      end
    
    query = 
      if fecha_hasta do
        where(query, [el], el.fecha_envio <= ^fecha_hasta)
      else
        query
      end
    
    Repo.all(query)
  end

  # Genera un ID único para mensajes de correo.
  # Retorna: String con ID único para el mensaje
  defp generate_unique_message_id do
    "MSG_#{System.system_time(:millisecond)}_#{:rand.uniform(999999)}"
  end
end