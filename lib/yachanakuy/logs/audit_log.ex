defmodule Yachanakuy.Logs.AuditLog do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  Schema para registrar todas las acciones importantes en el sistema de auditoría.

  ## Campos principales

  - `accion`: Tipo de acción realizada (crear, actualizar, eliminar, aprobar, rechazar, etc.)
  - `tipo_recurso`: Tipo de recurso afectado (participante, usuario, sesión, etc.)
  - `id_recurso`: ID del recurso afectado
  - `cambios`: Cambios realizados en formato JSON
  - `ip_address`: Dirección IP desde la que se realizó la acción
  - `user_agent`: Información del navegador/cliente
  - `fecha_accion`: Fecha y hora exacta de la acción

  ## Tipos de acciones soportadas

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

  ## Tipos de recursos soportados

  - `participante`: Registro de participantes
  - `usuario`: Usuarios del sistema
  - `sesion`: Sesiones del programa
  - `credencial`: Credenciales de participantes
  - `material`: Materiales entregados
  - `refrigerio`: Refrigerios entregados
  - `asistencia`: Registro de asistencia
  - `certificado`: Certificados generados
  - `comision`: Comisiones del congreso
  - `categoria`: Categorías de participantes
  - `configuracion`: Configuración del congreso
  """

  schema "audit_logs" do
    field :accion, :string
    field :tipo_recurso, :string
    field :id_recurso, :integer
    field :cambios, :string
    field :ip_address, :string
    field :user_agent, :string
    field :fecha_accion, :utc_datetime
    
    # Extra metadata for detailed auditing
    field :metadata, :map

    # Associations (user_id field is created automatically by belongs_to)
    belongs_to :user, Yachanakuy.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(audit_log, attrs) do
    audit_log
    |> cast(attrs, [
      :accion, 
      :tipo_recurso, 
      :id_recurso, 
      :cambios, 
      :fecha_accion, 
      :user_id,
      :ip_address,
      :user_agent,
      :metadata
    ])
    |> validate_required([
      :accion, 
      :fecha_accion
    ])
    |> validate_length(:accion, min: 1, max: 50)
    |> validate_length(:tipo_recurso, max: 50)
    |> validate_length(:ip_address, max: 45) # IPv6 max length
    |> validate_length(:user_agent, max: 500)
    |> validate_inclusion(:accion, [
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
    ])
    |> validate_inclusion(:tipo_recurso, [
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
    ])
  end

  @doc """
  Construye un changeset para crear un registro de auditoría con información adicional.

  ## Parámetros

  - `attrs`: Mapa con los atributos del registro de auditoría
    - `accion`: Acción realizada
    - `tipo_recurso`: Tipo de recurso afectado
    - `id_recurso`: ID del recurso
    - `cambios`: Cambios realizados (opcional)
    - `user_id`: ID del usuario que realizó la acción (opcional)
    - `ip_address`: Dirección IP (opcional)
    - `user_agent`: User agent (opcional)
    - `metadata`: Metadatos adicionales (opcional)

  ## Ejemplo

      iex> AuditLog.audit_changeset(%{
        accion: "crear",
        tipo_recurso: "participante",
        id_recurso: 123,
        cambios: "{\\"nombre_completo\\": \\"Juan Pérez\\"}",
        user_id: 456
      })
      %Ecto.Changeset{valid?: true}

  ## Retorna

  - `%Ecto.Changeset{}` con las validaciones aplicadas
  """
  def audit_changeset(audit_log \\ %__MODULE__{}, attrs) do
    audit_log
    |> cast(attrs, [
      :accion, 
      :tipo_recurso, 
      :id_recurso, 
      :cambios, 
      :user_id,
      :ip_address,
      :user_agent,
      :metadata,
      :fecha_accion
    ])
    |> validate_required([
      :accion, 
      :fecha_accion
    ])
    |> validate_length(:accion, min: 1, max: 50)
    |> validate_length(:tipo_recurso, max: 50)
    |> validate_length(:ip_address, max: 45) # IPv6 max length
    |> validate_length(:user_agent, max: 500)
    |> validate_inclusion(:accion, [
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
    ])
    |> validate_inclusion(:tipo_recurso, [
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
    ])
  end

  @doc """
  Crea un registro de auditoría con información completa del contexto.

  ## Parámetros

  - `user_id`: ID del usuario que realizó la acción (puede ser nil)
  - `accion`: Tipo de acción realizada
  - `tipo_recurso`: Tipo de recurso afectado
  - `id_recurso`: ID del recurso afectado
  - `opts`: Opciones adicionales
    - `:cambios`: Cambios realizados en formato JSON
    - `:ip_address`: Dirección IP del cliente
    - `:user_agent`: User agent del cliente
    - `:metadata`: Metadatos adicionales

  ## Ejemplo

      iex> AuditLog.create_audit_entry(123, "crear", "participante", 456, %{
        cambios: "{\\"nombre_completo\\": \\"Juan Pérez\\"}",
        ip_address: "192.168.1.100",
        user_agent: "Mozilla/5.0..."
      })
      {:ok, %AuditLog{}}

  ## Retorna

  - `{:ok, %AuditLog{}}`: Éxito
  - `{:error, %Ecto.Changeset{}}`: Error de validación
  """
  def create_audit_entry(user_id, accion, tipo_recurso, id_recurso, opts \\ []) do
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
    
    audit_changeset(attrs)
    |> Yachanakuy.Repo.insert()
  end
end
