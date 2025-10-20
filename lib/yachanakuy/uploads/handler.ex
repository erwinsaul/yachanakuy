defmodule Yachanakuy.Uploads.Handler do
  @moduledoc """
  Módulo para manejar subidas de archivos (fotos de participantes y comprobantes de pago)
  con validaciones de seguridad, tipos de archivos permitidos y almacenamiento en el sistema de archivos.
  """

  @allowed_image_types ~w(.jpg .jpeg .png .gif .webp)
  @allowed_document_types ~w(.pdf .jpg .jpeg .png)
  @max_image_size 5_000_000  # 5MB
  @max_document_size 10_000_000  # 10MB
  @upload_path "priv/static/uploads"

  @doc """
  Sube una imagen (foto de participante).
  
  ## Parámetros
  - upload: Upload struct de Phoenix
  - type: Tipo de archivo ("foto", "comprobante_pago", "logo", "speaker")
  
  ## Ejemplo
      iex> Uploads.Handler.upload_image(upload, "foto")
      {:ok, "uploads/fotos/filename.jpg"}
  """
  def upload_image(upload, type) when type in ["foto", "logo", "speaker"] do
    allowed_types = @allowed_image_types
    max_size = if type == "logo", do: @max_document_size, else: @max_image_size
    
    upload_file(upload, type, allowed_types, max_size)
  end

  @doc """
  Sube un documento (comprobante de pago).
  
  ## Parámetros
  - upload: Upload struct de Phoenix
  - type: Tipo de archivo ("comprobante_pago")
  
  ## Ejemplo
      iex> Uploads.Handler.upload_document(upload, "comprobante_pago")
      {:ok, "uploads/comprobantes/filename.pdf"}
  """
  def upload_document(upload, type) when type in ["comprobante_pago"] do
    allowed_types = @allowed_document_types
    max_size = @max_document_size
    
    upload_file(upload, type, allowed_types, max_size)
  end

  defp upload_file(%{filename: filename} = upload, type, allowed_types, max_size) do
    # Validar tipo de archivo
    case validate_file_type(filename, allowed_types) do
      :ok -> 
        # Validar tamaño
        case validate_file_size(upload.path, max_size) do
          :ok -> 
            # Generar nombre de archivo único
            unique_filename = generate_unique_filename(filename)
            
            # Determinar directorio según tipo
            directory = get_upload_directory(type)
            
            # Crear directorio si no existe
            create_directory_if_not_exists(directory)
            
            # Ruta final
            destination = Path.join(directory, unique_filename)
            
            # Copiar archivo
            case File.copy(upload.path, destination) do
              {:ok, _bytes_copied} ->
                # Verificar que la copia sea segura
                case validate_file_security(destination) do
                  :ok ->
                    # Devolver ruta relativa para almacenar en la base de datos
                    relative_path = Path.relative_to(destination, "priv/static")
                    {:ok, relative_path}
                  error ->
                    # Eliminar archivo si hay problemas de seguridad
                    File.rm(destination)
                    error
                end
              {:error, reason} ->
                {:error, "Error al copiar archivo: #{reason}"}
            end
          error -> 
            error
        end
      error -> 
        error
    end
  end

  defp validate_file_type(filename, allowed_types) do
    extension = Path.extname(filename) |> String.downcase()
    
    if extension in allowed_types do
      :ok
    else
      {:error, "Tipo de archivo no permitido: #{extension}. Tipos permitidos: #{inspect(allowed_types)}"}
    end
  end

  defp validate_file_size(temp_path, max_size) do
    case File.stat(temp_path) do
      {:ok, %File.Stat{size: size}} when size <= max_size -> 
        :ok
      {:ok, %File.Stat{size: size}} -> 
        {:error, "Archivo demasiado grande: #{size} bytes. Máximo permitido: #{max_size} bytes"}
      {:error, reason} -> 
        {:error, "Error al leer archivo: #{reason}"}
    end
  end

  defp generate_unique_filename(filename) do
    extension = Path.extname(filename)
    name = Path.basename(filename, extension)
    timestamp = System.system_time(:second)
    random = :rand.uniform(999999)
    
    "#{name}_#{timestamp}_#{random}#{extension}"
  end

  defp get_upload_directory("foto"), do: Path.join(@upload_path, "fotos")
  defp get_upload_directory("comprobante_pago"), do: Path.join(@upload_path, "comprobantes")
  defp get_upload_directory("logo"), do: Path.join(@upload_path, "logos")
  defp get_upload_directory("speaker"), do: Path.join(@upload_path, "speakers")
  defp get_upload_directory(_), do: @upload_path

  defp create_directory_if_not_exists(directory) do
    unless File.dir?(directory) do
      File.mkdir_p!(directory)
    end
  end

  @doc """
  Elimina un archivo subido.
  
  ## Parámetros
  - file_path: Ruta del archivo a eliminar
  
  ## Ejemplo
      iex> Uploads.Handler.delete_file("uploads/fotos/filename.jpg")
      :ok
  """
  def delete_file(file_path) when is_binary(file_path) do
    absolute_path = Path.join("priv/static", file_path)
    File.rm(absolute_path)
  end

  # Valida que un archivo sea seguro para procesar.
  defp validate_file_security(file_path) do
    # Verificar que no sea un archivo ejecutable
    extension = Path.extname(file_path) |> String.downcase()
    
    # Validar contenido del archivo para prevenir inyección
    case File.read(file_path) do
      {:ok, content} ->
        # Para imágenes, verificar que tengan firma válida
        if extension in [".jpg", ".jpeg", ".png", ".gif"] do
          case validate_image_content(content, extension) do
            :ok -> :ok
            error -> error
          end
        else
          # Para otros tipos, solo verificar que no esté vacío
          if byte_size(content) > 0 do
            :ok
          else
            {:error, "Archivo vacío o corrupto"}
          end
        end
      {:error, reason} ->
        {:error, "No se pudo leer el archivo para validación: #{reason}"}
    end
  end

  defp validate_image_content(content, ".jpg"), do: validate_jpg_content(content)
  defp validate_image_content(content, ".jpeg"), do: validate_jpg_content(content)
  defp validate_image_content(content, ".png"), do: validate_png_content(content)
  defp validate_image_content(content, ".gif"), do: validate_gif_content(content)
  defp validate_image_content(_, _), do: :ok

  defp validate_jpg_content(<<255, 216, _rest::binary>>), do: :ok
  defp validate_jpg_content(_), do: {:error, "Archivo JPG no válido"}

  defp validate_png_content(<<137, 80, 78, 71, 13, 10, 26, 10, _rest::binary>>), do: :ok
  defp validate_png_content(_), do: {:error, "Archivo PNG no válido"}

  defp validate_gif_content(<<"GIF87a", _rest::binary>>), do: :ok
  defp validate_gif_content(<<"GIF89a", _rest::binary>>), do: :ok
  defp validate_gif_content(_), do: {:error, "Archivo GIF no válido"}

  @doc """
  Valida los parámetros de subida para Phoenix LiveView.
  
  ## Parámetros
  - _entry: Entrada de subida de Phoenix LiveView
  - _socket: Socket de Phoenix LiveView
  
  ## Ejemplo
      iex> Uploads.Handler.allow_upload?(:entry, :socket)
      true
  """
  def allow_upload?(:entry, _socket) do
    # Aquí podrías implementar lógica adicional de validación
    true
  end

  @doc """
  Configura las subidas para Phoenix LiveView.
  
  ## Ejemplo
      iex> Uploads.Handler.configure_upload()
      upload_config
  """
  def configure_upload do
    [
      max_file_size: @max_image_size,
      accept: Enum.join(@allowed_image_types, ",")
    ]
  end

  @doc """
  Limpia archivos temporales subidos.
  """
  def cleanup_temp_uploads do
    temp_dir = "tmp/uploads"
    if File.dir?(temp_dir) do
      File.rm_rf(temp_dir)
    end
  end
end