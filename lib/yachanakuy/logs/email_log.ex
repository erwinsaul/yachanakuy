defmodule Yachanakuy.Logs.EmailLog do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  Schema para registrar todos los correos electrónicos enviados por el sistema.

  ## Campos principales

  - `tipo_email`: Tipo de correo (confirmacion_registro, credencial_digital, certificado, rechazo)
  - `destinatario`: Dirección de correo electrónico del destinatario
  - `fecha_envio`: Fecha y hora de envío del correo
  - `estado`: Estado del envío (enviado, fallido)
  - `attendee_id`: ID del participante relacionado (cuando aplica)
  - `mensaje_id`: ID único del mensaje para seguimiento
  - `asunto`: Asunto del correo enviado
  - `plantilla`: Plantilla utilizada para el correo
  - `contenido`: Contenido del correo (opcional, para auditoría)

  ## Estados posibles

  - `enviado`: Correo enviado exitosamente
  - `fallido`: Error en el envío del correo
  - `pendiente`: Correo en cola para envío
  - `reintentando`: Intentando reenviar el correo

  ## Tipos de correos soportados

  - `confirmacion_registro`: Confirmación de inscripción
  - `credencial_digital`: Envío de credencial digital
  - `certificado`: Envío de certificado de participación
  - `rechazo`: Notificación de rechazo de inscripción
  - `recordatorio_pago`: Recordatorio de pago pendiente
  - `bienvenida`: Bienvenida al congreso
  - `programa_actualizado`: Notificación de cambios en el programa
  - `recordatorio_evento`: Recordatorio del día del evento
  """

  schema "email_logs" do
    field :tipo_email, :string
    field :destinatario, :string
    field :fecha_envio, :utc_datetime
    field :estado, :string
    field :attendee_id, :id
    field :mensaje_id, :string
    field :asunto, :string
    field :plantilla, :string
    field :contenido, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(email_log, attrs) do
    email_log
    |> cast(attrs, [
      :tipo_email, 
      :destinatario, 
      :fecha_envio, 
      :estado, 
      :attendee_id,
      :mensaje_id,
      :asunto,
      :plantilla,
      :contenido
    ])
    |> validate_required([
      :tipo_email, 
      :destinatario, 
      :fecha_envio, 
      :estado
    ])
    |> validate_format(:destinatario, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/, message: "must have the @ sign and no spaces")
    |> validate_inclusion(:estado, ["enviado", "fallido", "pendiente", "reintentando"])
    |> validate_inclusion(:tipo_email, [
      "confirmacion_registro", 
      "credencial_digital", 
      "certificado", 
      "rechazo",
      "recordatorio_pago",
      "bienvenida",
      "programa_actualizado",
      "recordatorio_evento"
    ])
    |> validate_length(:destinatario, max: 255)
    |> validate_length(:mensaje_id, max: 100)
    |> validate_length(:asunto, max: 200)
    |> validate_length(:plantilla, max: 100)
    |> unique_constraint(:mensaje_id)
  end

  @doc """
  Construye un changeset para crear un registro de envío de correo electrónico.

  ## Parámetros

  - `attrs`: Mapa con los atributos del registro de correo
    - `tipo_email`: Tipo de correo a enviar
    - `destinatario`: Dirección de correo electrónico del destinatario
    - `fecha_envio`: Fecha y hora de envío
    - `estado`: Estado del envío
    - `attendee_id`: ID del participante relacionado (opcional)
    - `mensaje_id`: ID único del mensaje (opcional)
    - `asunto`: Asunto del correo (opcional)
    - `plantilla`: Plantilla utilizada (opcional)
    - `contenido`: Contenido del correo (opcional)

  ## Ejemplo

      iex> EmailLog.email_changeset(%{
        tipo_email: "confirmacion_registro",
        destinatario: "juan@example.com",
        fecha_envio: DateTime.utc_now(),
        estado: "enviado",
        asunto: "Confirmación de Registro - Congreso 2025"
      })
      %Ecto.Changeset{valid?: true}

  ## Retorna

  - `%Ecto.Changeset{}` con las validaciones aplicadas
  """
  def email_changeset(email_log \\ %__MODULE__{}, attrs) do
    email_log
    |> cast(attrs, [
      :tipo_email, 
      :destinatario, 
      :fecha_envio, 
      :estado, 
      :attendee_id,
      :mensaje_id,
      :asunto,
      :plantilla,
      :contenido
    ])
    |> validate_required([
      :tipo_email, 
      :destinatario, 
      :fecha_envio, 
      :estado
    ])
    |> validate_format(:destinatario, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/, message: "must have the @ sign and no spaces")
    |> validate_inclusion(:estado, ["enviado", "fallido", "pendiente", "reintentando"])
    |> validate_inclusion(:tipo_email, [
      "confirmacion_registro", 
      "credencial_digital", 
      "certificado", 
      "rechazo",
      "recordatorio_pago",
      "bienvenida",
      "programa_actualizado",
      "recordatorio_evento"
    ])
    |> validate_length(:destinatario, max: 255)
    |> validate_length(:mensaje_id, max: 100)
    |> validate_length(:asunto, max: 200)
    |> validate_length(:plantilla, max: 100)
    |> unique_constraint(:mensaje_id)
  end

  @doc """
  Crea un registro de envío de correo electrónico.

  ## Parámetros

  - `attrs`: Mapa con los atributos del registro de correo

  ## Ejemplo

      iex> EmailLog.create_email_log(%{
        tipo_email: "confirmacion_registro",
        destinatario: "juan@example.com",
        fecha_envio: DateTime.utc_now(),
        estado: "enviado",
        attendee_id: 123,
        asunto: "Confirmación de Registro - Congreso 2025"
      })
      {:ok, %EmailLog{}}

  ## Retorna

  - `{:ok, %EmailLog{}}`: Éxito
  - `{:error, %Ecto.Changeset{}}`: Error de validación
  """
  def create_email_log(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Yachanakuy.Repo.insert()
  end
end
