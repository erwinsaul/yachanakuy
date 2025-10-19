defmodule Yachanakuy.Registration.Attendee do
  @moduledoc """
  Schema para representar a los participantes del congreso.

  ## Campos principales

  - `nombre_completo`: Nombre completo del participante
  - `numero_documento`: Número de documento de identidad (único en todo el sistema)
  - `email`: Correo electrónico (único en todo el sistema)
  - `telefono`: Número de teléfono de contacto
  - `institucion`: Institución a la que pertenece
  - `foto`: URL o ruta a la foto del participante
  - `comprobante_pago`: URL o ruta al comprobante de pago
  - `codigo_qr`: Código QR único generado para el participante
  - `imagen_qr`: URL o ruta a la imagen del código QR
  - `credencial_digital`: URL o ruta al PDF de la credencial digital
  - `token_descarga`: Token único para descargar la credencial digital
  - `estado`: Estado actual de la inscripción (`pendiente_revision`, `aprobado`, `rechazado`)
  - `fecha_revision`: Fecha y hora de la última revisión
  - `motivo_rechazo`: Motivo del rechazo si aplica
  - `credencial_entregada`: Indica si la credencial física fue entregada
  - `fecha_entrega_credencial`: Fecha y hora de entrega de la credencial
  - `quien_entrego_credencial`: ID del usuario que entregó la credencial
  - `material_entregado`: Indica si el material fue entregado
  - `fecha_entrega_material`: Fecha y hora de entrega del material
  - `quien_entrego_material`: ID del usuario que entregó el material
  - `sesiones_asistidas`: Contador de sesiones a las que asistió el participante

  ## Estados posibles

  - `pendiente_revision`: El participante ha enviado su inscripción pero aún no ha sido revisada
  - `aprobado`: El participante ha sido aprobado y puede participar en el congreso
  - `rechazado`: El participante ha sido rechazado y no puede participar

  ## Validaciones

  - `email` debe ser único en todo el sistema
  - `numero_documento` debe ser único en todo el sistema
  - `codigo_qr` debe ser único en todo el sistema
  - `token_descarga` debe ser único
  - `estado` debe ser uno de: `pendiente_revision`, `aprobado`, `rechazado`
  - `nombre_completo` es obligatorio (máximo 200 caracteres)
  - `numero_documento` es obligatorio (máximo 50 caracteres)
  - `telefono` tiene máximo 20 caracteres
  - `institucion` tiene máximo 100 caracteres
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "attendees" do
    field :nombre_completo, :string
    field :numero_documento, :string
    field :email, :string
    field :telefono, :string
    field :institucion, :string
    field :foto, :string
    field :comprobante_pago, :string
    field :codigo_qr, :string
    field :imagen_qr, :string
    field :credencial_digital, :string
    field :token_descarga, :string
    field :estado, :string
    field :fecha_revision, :utc_datetime
    field :motivo_rechazo, :string
    field :credencial_entregada, :boolean, default: false
    field :fecha_entrega_credencial, :utc_datetime
    field :material_entregado, :boolean, default: false
    field :fecha_entrega_material, :utc_datetime
    field :sesiones_asistidas, :integer, default: 0

    # Associations (category_id, revisado_por, etc. are created automatically by belongs_to)
    belongs_to :category, Yachanakuy.Events.AttendeeCategory
    belongs_to :reviewed_by_user, Yachanakuy.Accounts.User, foreign_key: :revisado_por
    belongs_to :credential_delivered_by, Yachanakuy.Accounts.User, foreign_key: :quien_entrego_credencial
    belongs_to :material_delivered_by, Yachanakuy.Accounts.User, foreign_key: :quien_entrego_material
    
    # Delivery associations
    has_many :meal_deliveries, Yachanakuy.Deliveries.MealDelivery
    has_many :session_attendances, Yachanakuy.Deliveries.SessionAttendance
    has_one :certificate, Yachanakuy.Certificates.Certificate

    timestamps(type: :utc_datetime)
  end

  @doc """
  Crea un changeset para validar y preparar un participante para ser guardado.

  Este changeset aplica todas las validaciones necesarias para garantizar la integridad
  de los datos del participante, incluyendo unicidad de campos sensibles como email
  y número de documento.

  ## Parámetros

  - `attendee`: Struct `%Attendee{}` existente o nuevo
  - `attrs`: Mapa con los atributos a aplicar al changeset

  ## Validaciones aplicadas

  - `email`: Debe ser único y tener formato válido de correo electrónico
  - `numero_documento`: Debe ser único en todo el sistema
  - `codigo_qr`: Debe ser único en todo el sistema
  - `token_descarga`: Debe ser único
  - `estado`: Debe ser uno de los valores permitidos
  - Longitudes máximas para todos los campos de texto

  ## Ejemplo

      iex> Attendee.changeset(%Attendee{}, %{
        nombre_completo: "Juan Pérez",
        numero_documento: "123456789",
        email: "juan@example.com",
        estado: "pendiente_revision"
      })
      %Ecto.Changeset{valid?: true}

  ## Retorna

  - `%Ecto.Changeset{}` con las validaciones aplicadas
  """
  def changeset(attendee, attrs) do
    attendee
    |> cast(attrs, [:nombre_completo, :numero_documento, :email, :telefono, :institucion, :foto, :comprobante_pago, :codigo_qr, :imagen_qr, :credencial_digital, :token_descarga, :estado, :fecha_revision, :motivo_rechazo, :credencial_entregada, :fecha_entrega_credencial, :material_entregado, :fecha_entrega_material, :sesiones_asistidas, :category_id, :revisado_por, :quien_entrego_credencial, :quien_entrego_material])
    |> validate_required([:nombre_completo, :numero_documento, :email, :estado])
    |> unique_constraint(:token_descarga)
    |> unique_constraint(:codigo_qr)
    |> unique_constraint(:email)
    |> unique_constraint(:numero_documento)
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:nombre_completo, min: 1, max: 200)
    |> validate_length(:numero_documento, min: 1, max: 50)
    |> validate_length(:telefono, max: 20)
    |> validate_length(:institucion, max: 100)
    |> validate_inclusion(:estado, ["pendiente_revision", "aprobado", "rechazado"])
  end

  @doc """
  Crea un changeset específico para validar operaciones de entrega de credenciales y materiales.

  Este changeset se utiliza cuando se van a registrar entregas de credenciales físicas o materiales
  a los participantes aprobados. Incluye validaciones para asegurar que solo se puedan realizar
  entregas a participantes en estado `aprobado`.

  ## Parámetros

  - `attendee`: Struct `%Attendee{}` del participante
  - `attrs`: Mapa con los atributos de entrega a aplicar

  ## Validaciones aplicadas

  - El participante debe estar en estado `aprobado`
  - Las entregas solo pueden registrarse una vez (no duplicadas)

  ## Ejemplo

      iex> Attendee.delivery_changeset(attendee, %{
        credencial_entregada: true,
        fecha_entrega_credencial: DateTime.utc_now(),
        quien_entrego_credencial: user_id
      })
      %Ecto.Changeset{valid?: true}

  ## Retorna

  - `%Ecto.Changeset{}` con las validaciones de entrega aplicadas
  """
  def delivery_changeset(attendee, attrs) do
    attendee
    |> cast(attrs, [:credencial_entregada, :fecha_entrega_credencial, :quien_entrego_credencial, :material_entregado, :fecha_entrega_material, :quien_entrego_material])
    |> validate_approved_status()
  end

  defp validate_approved_status(changeset) do
    # Validate that the attendee is approved before allowing deliveries
    estado = get_field(changeset, :estado)
    
    if estado == "aprobado" do
      changeset
    else
      add_error(changeset, :estado, "Solo se pueden entregar credenciales o materiales a participantes aprobados")
    end
  end
end
