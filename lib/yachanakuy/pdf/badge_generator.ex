defmodule Yachanakuy.Pdf.BadgeGenerator do
  @moduledoc """
  Módulo para generar credenciales digitales en PDF para los participantes del congreso.
  """

  alias Yachanakuy.Registration.Attendee
  alias Yachanakuy.Events.Settings
  alias Yachanakuy.Events.AttendeeCategory

  @doc """
  Genera una credencial digital en PDF para un participante.
  
  ## Parámetros
  - attendee: Estructura del participante
  - settings: Configuración del congreso (nombre, logo, etc.)
  - category: Categoría del participante para obtener color
  
  ## Ejemplo
      iex> BadgeGenerator.generate_badge(attendee, settings, category)
      {:ok, pdf_binary}
  """
  def generate_badge(%Attendee{} = attendee, %Settings{} = settings, %AttendeeCategory{} = category) do
    # Generar el contenido HTML del PDF usando los colores de CCBOL.pdf
    html_content = build_badge_html(attendee, settings, category)
    
    # Generar el PDF con pdf_generator
    options = [
      page_size: "A4",
      margin_top: "0.5in",
      margin_right: "0.5in",
      margin_bottom: "0.5in",
      margin_left: "0.5in"
    ]
    
    case PdfGenerator.generate(html_content, options) do
      {:ok, pdf_binary} -> 
        {:ok, pdf_binary}
      {:error, reason} -> 
        {:error, reason}
    end
  end

  defp build_badge_html(attendee, settings, category) do
    # Usar colores corporativos (estos vendrían de CCBOL.pdf)
    primary_color = category.color || "#1f2937"  # Color por defecto
    secondary_color = "#f9fafb"
    
    """
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8">
        <style>
          body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #{secondary_color};
          }
          .badge-container {
            width: 80mm;
            height: 120mm;
            background: linear-gradient(135deg, #{primary_color}, #{secondary_color});
            border: 2px solid #{primary_color};
            border-radius: 10px;
            padding: 15px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            display: flex;
            flex-direction: column;
            justify-content: space-between;
          }
          .header {
            text-align: center;
            margin-bottom: 10px;
          }
          .logo {
            width: 80px;
            height: auto;
            margin: 0 auto 10px;
          }
          .congress-name {
            font-size: 14px;
            font-weight: bold;
            color: #{primary_color};
            margin: 0;
          }
          .attendee-info {
            text-align: center;
            margin: 15px 0;
          }
          .attendee-name {
            font-size: 16px;
            font-weight: bold;
            color: #{primary_color};
            margin: 5px 0;
          }
          .attendee-category {
            font-size: 12px;
            background-color: #{primary_color};
            color: white;
            padding: 3px 8px;
            border-radius: 12px;
            display: inline-block;
            margin: 5px 0;
          }
          .qr-section {
            text-align: center;
            margin: 10px 0;
          }
          .qr-code {
            width: 60px;
            height: 60px;
            margin: 0 auto;
          }
          .footer {
            text-align: center;
            font-size: 10px;
            color: #6b7280;
          }
        </style>
      </head>
      <body>
        <div class="badge-container">
          <div class="header">
            <img src="#{settings.logo}" class="logo" alt="Logo">
            <h2 class="congress-name">#{settings.nombre}</h2>
          </div>
          
          <div class="attendee-info">
            <div class="attendee-name">#{attendee.nombre_completo}</div>
            <div class="attendee-category">#{category.nombre}</div>
            <div>ID: #{attendee.id}</div>
          </div>
          
          <div class="qr-section">
            <div>#{attendee.codigo_qr}</div>
          </div>
          
          <div class="footer">
            <div>#{settings.fecha_inicio} - #{settings.fecha_fin}</div>
            <div>#{settings.ubicacion}</div>
          </div>
        </div>
      </body>
    </html>
    """
  end
  
  @doc """
  Genera un PDF de credencial temporal sin información sensible para preview.
  
  ## Parámetros
  - settings: Configuración del congreso
  
  ## Ejemplo
      iex> BadgeGenerator.generate_preview_badge(settings)
      {:ok, pdf_binary}
  """
  def generate_preview_badge(%Settings{} = settings) do
    html_content = """
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8">
        <style>
          body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f9fafb;
          }
          .badge-container {
            width: 80mm;
            height: 120mm;
            background: linear-gradient(135deg, #1f2937, #f9fafb);
            border: 2px solid #1f2937;
            border-radius: 10px;
            padding: 15px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            display: flex;
            flex-direction: column;
            justify-content: space-between;
          }
          .header {
            text-align: center;
            margin-bottom: 10px;
          }
          .logo {
            width: 80px;
            height: auto;
            margin: 0 auto 10px;
          }
          .congress-name {
            font-size: 14px;
            font-weight: bold;
            color: #1f2937;
            margin: 0;
          }
          .attendee-info {
            text-align: center;
            margin: 15px 0;
          }
          .attendee-name {
            font-size: 16px;
            font-weight: bold;
            color: #1f2937;
            margin: 5px 0;
          }
          .attendee-category {
            font-size: 12px;
            background-color: #1f2937;
            color: white;
            padding: 3px 8px;
            border-radius: 12px;
            display: inline-block;
            margin: 5px 0;
          }
          .qr-section {
            text-align: center;
            margin: 10px 0;
          }
          .qr-code {
            width: 60px;
            height: 60px;
            margin: 0 auto;
          }
          .footer {
            text-align: center;
            font-size: 10px;
            color: #6b7280;
          }
        </style>
      </head>
      <body>
        <div class="badge-container">
          <div class="header">
            <img src="#{settings.logo}" class="logo" alt="Logo">
            <h2 class="congress-name">#{settings.nombre}</h2>
          </div>
          
          <div class="attendee-info">
            <div class="attendee-name">Nombre del Participante</div>
            <div class="attendee-category">Categoría</div>
            <div>ID: 000</div>
          </div>
          
          <div class="qr-section">
            <div>CÓDIGO QR</div>
          </div>
          
          <div class="footer">
            <div>#{settings.fecha_inicio} - #{settings.fecha_fin}</div>
            <div>#{settings.ubicacion}</div>
          </div>
        </div>
      </body>
    </html>
    """
    
    options = [
      page_size: "A4",
      margin_top: "0.5in",
      margin_right: "0.5in",
      margin_bottom: "0.5in",
      margin_left: "0.5in"
    ]
    
    case PdfGenerator.generate(html_content, options) do
      {:ok, pdf_binary} -> 
        {:ok, pdf_binary}
      {:error, reason} -> 
        {:error, reason}
    end
  end
end