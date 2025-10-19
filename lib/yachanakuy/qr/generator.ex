defmodule Yachanakuy.QR.Generator do
  @moduledoc """
  Módulo para generar códigos QR únicos para los participantes del congreso.
  Estos códigos se usarán para identificar a los participantes durante el 
  proceso de verificación en credenciales, materiales, refrigerios y asistencia.
  """

  alias QRCode
  
  @doc """
  Genera un código QR único para un participante basado en su ID y otros datos.
  
  ## Parámetros
  - attendee_id: ID del participante
  - extra_data: Mapa adicional con información para enriquecer el código QR
  
  ## Ejemplo
      iex> QR.Generator.generate_attendee_qr(123, %{nombre: "Juan Pérez"})
      {:ok, qr_data}
  """
  def generate_attendee_qr(attendee_id, extra_data \\ %{}) do
    # Generar un código único que combine el ID del participante y datos relevantes
    qr_data = %{
      id: attendee_id,
      timestamp: DateTime.utc_now() |> DateTime.to_unix(),
      data: extra_data
    }
    
    # Convertir a string para el QR
    qr_text = Jason.encode!(qr_data)
    
    # Generar el código QR
    case QRCode.create(qr_text) do
      {:ok, qr_code} -> 
        # Convertir a imagen SVG para uso en web
        svg_content = QRCode.Svg.create(qr_code)
        {:ok, svg_content}
      error -> 
        error
    end
  end
  
  @doc """
  Genera un código QR con el texto especificado.
  
  ## Parámetros
  - text: Texto a codificar en el QR
  
  ## Ejemplo
      iex> QR.Generator.generate_qr("https://yachanakuy.com/attendee/123")
      {:ok, qr_svg_content}
  """
  def generate_qr(text) when is_binary(text) do
    case QRCode.create(text) do
      {:ok, qr_code} -> 
        svg_content = QRCode.Svg.create(qr_code)
        {:ok, svg_content}
      error -> 
        error
    end
  end
  
  @doc """
  Genera un código QR para descarga de credencial usando token único.
  
  ## Parámetros
  - token: Token único para descargar la credencial
  
  ## Ejemplo
      iex> QR.Generator.generate_credential_qr("abc123")
      {:ok, qr_svg_content}
  """
  def generate_credential_qr(token) when is_binary(token) do
    url = "#{Application.get_env(:yachanakuy, YachanakuyWeb.Endpoint)[:url][:host]}/credencial/#{token}"
    generate_qr(url)
  end
  
  @doc """
  Genera un código QR con contenido específico para el escaneo en el evento.
  
  ## Parámetros
  - attendee_id: ID del participante
  - action: Tipo de acción ("credencial", "material", "refrigerio", "asistencia")
  
  ## Ejemplo
      iex> QR.Generator.generate_event_qr(123, "credencial")
      {:ok, qr_svg_content}
  """
  def generate_event_qr(attendee_id, action) when is_integer(attendee_id) and is_binary(action) do
    event_data = %{
      attendee_id: attendee_id,
      action: action,
      event_type: "yachanakuy_event_verification",
      timestamp: DateTime.utc_now() |> DateTime.to_unix()
    }
    
    qr_text = Jason.encode!(event_data)
    generate_qr(qr_text)
  end
  
  @doc """
  Valida que un código QR sea válido para el sistema.
  
  ## Parámetros
  - qr_data: Datos decodificados del código QR
  
  ## Ejemplo
      iex> QR.Generator.validate_qr(%{attendee_id: 123, action: "credencial"})
      {:ok, validated_data}
  """
  def validate_qr(qr_data) when is_map(qr_data) do
    # Validar estructura básica del QR
    cond do
      not Map.has_key?(qr_data, :attendee_id) ->
        {:error, "Falta el campo attendee_id en el código QR"}
        
      not is_integer(qr_data.attendee_id) ->
        {:error, "attendee_id debe ser un número entero"}
        
      Map.has_key?(qr_data, :event_type) and qr_data.event_type != "yachanakuy_event_verification" ->
        {:error, "Tipo de evento no válido"}
        
      true ->
        {:ok, qr_data}
    end
  end
end