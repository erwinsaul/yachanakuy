defmodule Yachanakuy.Registration do
  @moduledoc """
  El contexto de Registro gestiona todas las operaciones relacionadas con los participantes
  del congreso, incluyendo inscripciones, aprobaciones, rechazos y generación de credenciales.

  ## Funcionalidades principales

  - Gestión completa del ciclo de vida de los participantes
  - Generación automática de credenciales digitales con códigos QR
  - Aprobación y rechazo de inscripciones por parte del personal administrativo
  - Control de estados (pendiente de revisión, aprobado, rechazado)
  - Generación de tokens únicos para descarga de credenciales

  ## Ejemplos de uso

      # Crear un nuevo participante
      {:ok, attendee} = Registration.create_attendee(%{
        nombre_completo: "Juan Pérez",
        numero_documento: "123456789",
        email: "juan@example.com",
        telefono: "789456123",
        institucion: "Universidad Mayor de San Andrés",
        category_id: 1
      })

      # Aprobar una inscripción
      {:ok, attendee} = Registration.approve_attendee(attendee, current_user)

      # Rechazar una inscripción
      {:ok, attendee} = Registration.reject_attendee(attendee, current_user, "Documentación incompleta")

  ## Estados de los participantes

  - `pendiente_revision`: El participante ha enviado su inscripción pero aún no ha sido revisada
  - `aprobado`: El participante ha sido aprobado y puede participar en el congreso
  - `rechazado`: El participante ha sido rechazado y no puede participar

  ## Campos importantes

  - `codigo_qr`: Código único generado para identificar al participante en el evento
  - `token_descarga`: Token único para descargar la credencial digital
  - `credencial_digital`: Ruta al archivo PDF de la credencial generada
  """
  import Ecto.Query, warn: false
  alias Yachanakuy.Repo
  alias Yachanakuy.Registration.Attendee

  @doc """
  Obtiene una lista de todos los participantes registrados en el sistema.

  ## Ejemplo

      iex> Registration.list_attendees()
      [%Attendee{}, ...]

  ## Retorna

  - Lista de structs `%Attendee{}` con todos los participantes registrados
  """
  def list_attendees do
    Repo.all(Attendee)
  end

  def list_attendees_with_details do
    from(a in Attendee,
      left_join: cat in assoc(a, :category),
      left_join: user in assoc(a, :revisor),
      preload: [category: cat, revisor: user]
    )
    |> Repo.all()
  end

  def get_attendee_with_details!(id) do
    from(a in Attendee,
      left_join: cat in assoc(a, :category),
      left_join: user in assoc(a, :revisor),
      where: a.id == ^id,
      preload: [category: cat, revisor: user]
    )
    |> Repo.one!()
  end

  def get_attendee_by_qr_with_details(qr_code) do
    from(a in Attendee,
      left_join: cat in assoc(a, :category),
      left_join: user in assoc(a, :revisor),
      where: a.codigo_qr == ^qr_code,
      preload: [category: cat, revisor: user]
    )
    |> Repo.one()
  end

  @doc """
  Obtiene un participante específico por su ID.

  Arroja una excepción `Ecto.NoResultsError` si no se encuentra el participante.

  ## Parámetros

  - `id`: ID numérico del participante

  ## Ejemplo

      iex> Registration.get_attendee!(123)
      %Attendee{}

      iex> Registration.get_attendee!(999)
      ** (Ecto.NoResultsError)

  ## Retorna

  - Struct `%Attendee{}` con los datos del participante
  """
  def get_attendee!(id) do
    Repo.get!(Attendee, id)
  end

  def get_attendee_by_token(token) do
    Repo.get_by(Attendee, token_descarga: token)
  end

  @doc """
  Crea un nuevo participante en el sistema.

  ## Parámetros

  - `attrs`: Mapa con los atributos del participante
    - `nombre_completo` (string, obligatorio): Nombre completo del participante
    - `numero_documento` (string, obligatorio): Número de documento de identidad
    - `email` (string, obligatorio): Correo electrónico único
    - `telefono` (string, opcional): Número de teléfono
    - `institucion` (string, opcional): Institución a la que pertenece
    - `foto` (string, opcional): URL o ruta a la foto del participante
    - `comprobante_pago` (string, opcional): URL o ruta al comprobante de pago
    - `category_id` (integer, obligatorio): ID de la categoría del participante

  ## Ejemplo

      iex> Registration.create_attendee(%{
        nombre_completo: "María González",
        numero_documento: "987654321",
        email: "maria@example.com",
        telefono: "654987321",
        institucion: "Universidad Católica Boliviana",
        category_id: 2
      })
      {:ok, %Attendee{}}

      iex> Registration.create_attendee(%{nombre_completo: nil})
      {:error, %Ecto.Changeset{}}

  ## Retorna

  - `{:ok, %Attendee{}}`: Éxito, con el participante creado
  - `{:error, %Ecto.Changeset{}}`: Error de validación
  """
  def create_attendee(attrs \\ %{}) do
    %Attendee{}
    |> Attendee.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, attendee} ->
        # Trigger real-time update notification
        Yachanakuy.Dashboard.Broadcast.handle_attendee_registration(attendee)
        {:ok, attendee}
      error ->
        error
    end
  end

  def update_attendee(%Attendee{} = attendee, attrs) do
    attendee
    |> Attendee.changeset(attrs)
    |> Repo.update()
  end

  def delete_attendee(%Attendee{} = attendee) do
    Repo.delete(attendee)
  end

  def change_attendee(%Attendee{} = attendee, attrs \\ %{}) do
    Attendee.changeset(attendee, attrs)
  end

  @doc """
  Aprueba la inscripción de un participante.

  Esta función cambia el estado del participante de `pendiente_revision` a `aprobado`,
  genera su código QR único, token de descarga y credencial digital en PDF.

  ## Parámetros

  - `attendee`: Struct `%Attendee{}` del participante a aprobar
  - `user`: Struct `%User{}` del usuario que realiza la aprobación

  ## Ejemplo

      iex> Registration.approve_attendee(attendee, current_user)
      {:ok, %Attendee{}}

      iex> Registration.approve_attendee(rejected_attendee, current_user)
      {:error, "Solo se pueden aprobar inscripciones en estado pendiente de revisión"}

  ## Retorna

  - `{:ok, %Attendee{}}`: Éxito, con el participante aprobado
  - `{:error, String.t()}`: Error si el participante no está en estado pendiente
  """
  def approve_attendee(%Attendee{} = attendee, user) do
    # Generar valores únicos necesarios
    codigo_qr = "YACHANAKUY_#{attendee.id}_#{System.system_time(:second)}_#{:rand.uniform(999999)}"
    token_descarga = generate_unique_token()
    
    # Generar credencial digital en PDF
    with {:ok, pdf_binary} <- generate_badge_pdf(attendee, codigo_qr),
         {:ok, pdf_path} <- save_badge_pdf(pdf_binary, attendee.id) do
      
      attendee
      |> Attendee.changeset(%{
        estado: "aprobado",
        revisado_por: user.id,
        fecha_revision: DateTime.utc_now(),
        codigo_qr: codigo_qr,
        token_descarga: token_descarga,
        credencial_digital: pdf_path
      })
      |> Repo.update()
      |> case do
        {:ok, updated_attendee} ->
          # Registrar en logs de auditoría
          audit_log = %{
            user_id: user.id,
            accion: "aprobar_inscripcion",
            tipo_recurso: "Participante",
            id_recurso: updated_attendee.id,
            cambios: Jason.encode!(%{
              anterior_estado: attendee.estado,
              nuevo_estado: "aprobado",
              codigo_qr_generado: true,
              token_descarga_generado: true
            })
          }
          
          # Registrar en logs de email
          email_log = %{
            attendee_id: updated_attendee.id,
            tipo_email: "confirmacion_registro",
            destinatario: updated_attendee.email,
            estado: "enviado"
          }
          
          # TODO: Implementar envío de email real aquí
          # send_confirmation_email(updated_attendee)
          
          # Registrar en logs
          Yachanakuy.Logs.create_audit_log(audit_log)
          Yachanakuy.Logs.create_email_log(email_log)
          
          # Trigger real-time update notification
          Yachanakuy.Dashboard.Broadcast.handle_attendee_approval(updated_attendee, user)
          
          {:ok, updated_attendee}
        error ->
          error
      end
    else
      error -> error
    end
  end

  @doc """
  Rechaza la inscripción de un participante.

  Esta función cambia el estado del participante a `rechazado` y registra el motivo del rechazo.

  ## Parámetros

  - `attendee`: Struct `%Attendee{}` del participante a rechazar
  - `user`: Struct `%User{}` del usuario que realiza el rechazo
  - `reason`: String con el motivo del rechazo

  ## Ejemplo

      iex> Registration.reject_attendee(attendee, current_user, "Documentación incompleta")
      {:ok, %Attendee{}}

  ## Retorna

  - `{:ok, %Attendee{}}`: Éxito, con el participante rechazado
  - `{:error, %Ecto.Changeset{}}`: Error de validación
  """
  def reject_attendee(%Attendee{} = attendee, user, reason) do
    attendee
    |> Attendee.changeset(%{
      estado: "rechazado",
      revisado_por: user.id,
      fecha_revision: DateTime.utc_now(),
      motivo_rechazo: reason
    })
    |> Repo.update()
    |> case do
      {:ok, updated_attendee} ->
        # Registrar en logs de auditoría
        audit_log = %{
          user_id: user.id,
          accion: "rechazar_inscripcion",
          tipo_recurso: "Participante",
          id_recurso: updated_attendee.id,
          cambios: Jason.encode!(%{
            anterior_estado: attendee.estado,
            nuevo_estado: "rechazado",
            motivo_rechazo: reason
          })
        }
        
        # Registrar en logs de email
        email_log = %{
          attendee_id: updated_attendee.id,
          tipo_email: "rechazo",
          destinatario: updated_attendee.email,
          estado: "enviado"
        }
        
        # TODO: Implementar envío de email de rechazo real aquí
        # send_rejection_email(updated_attendee, reason)
        
        # Registrar en logs
        Yachanakuy.Logs.create_audit_log(audit_log)
        Yachanakuy.Logs.create_email_log(email_log)
        
        {:ok, updated_attendee}
      error ->
        error
    end
  end

  # Función auxiliar para generar PDF de credencial
  defp generate_badge_pdf(attendee, codigo_qr) do
    # Obtener settings del congreso
    settings = Yachanakuy.Events.get_congress_settings()
    
    # Obtener categoría del participante
    category = Yachanakuy.Events.get_attendee_category!(attendee.category_id)
    
    # Actualizar el attendee con el código QR temporalmente para la generación
    attendee_with_qr = Map.put(attendee, :codigo_qr, codigo_qr)
    
    # Generar PDF
    Yachanakuy.Pdf.BadgeGenerator.generate_badge(attendee_with_qr, settings, category)
  end

  # Función auxiliar para guardar PDF
  defp save_badge_pdf(pdf_binary, attendee_id) do
    # Crear directorio si no existe
    directory = "priv/static/uploads/credenciales"
    File.mkdir_p!(directory)
    
    # Generar nombre único para el archivo
    filename = "credencial_#{attendee_id}_#{System.system_time(:second)}.pdf"
    filepath = Path.join(directory, filename)
    
    # Guardar archivo
    case File.write(filepath, pdf_binary) do
      :ok ->
        # Devolver ruta relativa
        {:ok, Path.relative_to(filepath, "priv/static")}
      error ->
        error
    end
  end

  # Función para generar tokens únicos
  defp generate_unique_token do
    :crypto.strong_rand_bytes(32)
    |> Base.url_encode64()
    |> binary_part(0, 32)
    |> String.replace(~r/[^a-zA-Z0-9]/, "")
  end

  def get_attendee_by_qr_code(qr_code) do
    Repo.get_by(Attendee, codigo_qr: qr_code)
  end

  def get_attendee_by_documento(numero_documento) do
    Repo.get_by(Attendee, numero_documento: numero_documento)
  end

  def get_attendee_by_email(email) do
    Repo.get_by(Attendee, email: email)
  end

  def count_attendees do
    Repo.aggregate(Attendee, :count, :id)
  end

  def count_pending_reviews do
    import Ecto.Query

    query = from a in Attendee,
      where: a.estado == "pendiente_revision",
      select: count(a.id)

    Repo.one(query) || 0
  end

  def list_attendees_with_filters(filters \\ %{}) do
    search = Map.get(filters, :search, "")
    estado = Map.get(filters, :estado, "")
    categoria_id = Map.get(filters, :categoria_id, "")
    page = Map.get(filters, :page, 1)
    page_size = Map.get(filters, :page_size, 10)

    offset = (page - 1) * page_size

    query = from a in Attendee,
      left_join: cat in assoc(a, :category),
      where: ^build_search_filter(search),
      where: ^build_estado_filter(estado),
      where: ^build_categoria_filter(categoria_id),
      limit: ^page_size,
      offset: ^offset,
      order_by: [desc: a.inserted_at]

    Repo.all(query)
  end

  def count_attendees_filtered(filters \\ %{}) do
    search = Map.get(filters, :search, "")
    estado = Map.get(filters, :estado, "")
    categoria_id = Map.get(filters, :categoria_id, "")

    query = from a in Attendee,
      left_join: cat in assoc(a, :category),
      where: ^build_search_filter(search),
      where: ^build_estado_filter(estado),
      where: ^build_categoria_filter(categoria_id)

    Repo.aggregate(query, :count, :id)
  end

  defp build_search_filter(""), do: true
  defp build_search_filter(search) when is_binary(search) do
    search_pattern = "%#{search}%"
    dynamic([a, cat], ilike(a.nombre_completo, ^search_pattern) or 
                           ilike(a.email, ^search_pattern) or 
                           ilike(a.numero_documento, ^search_pattern) or
                           ilike(cat.nombre, ^search_pattern))
  end

  defp build_estado_filter(""), do: true
  defp build_estado_filter(estado) do
    dynamic([a, _cat], a.estado == ^estado)
  end

  defp build_categoria_filter(""), do: true
  defp build_categoria_filter(categoria_id) when is_binary(categoria_id) do
    categoria_id_int = case Integer.parse(categoria_id) do
      {int_val, _} -> int_val
      :error -> nil
    end

    if categoria_id_int do
      dynamic([a, _cat], a.category_id == ^categoria_id_int)
    else
      true
    end
  end
end
