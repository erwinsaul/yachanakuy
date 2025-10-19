defmodule Yachanakuy.Pdf.CertificateGenerator do
  @moduledoc """
  Módulo para generar certificados de participación en PDF para los participantes del congreso.
  """

  alias Yachanakuy.Certificates.Certificate
  alias Yachanakuy.Registration.Attendee
  alias Yachanakuy.Events.Settings

  @doc """
  Genera un certificado de participación en PDF para un participante.
  
  ## Parámetros
  - certificate: Estructura del certificado
  - attendee: Estructura del participante
  - settings: Configuración del congreso
  
  ## Ejemplo
      iex> CertificateGenerator.generate_certificate(certificate, attendee, settings)
      {:ok, pdf_binary}
  """
  def generate_certificate(%Certificate{} = certificate, %Attendee{} = attendee, %Settings{} = settings) do
    # Generar el contenido HTML del PDF usando los colores de CCBOL.pdf
    html_content = build_certificate_html(certificate, attendee, settings)
    
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

  defp build_certificate_html(certificate, attendee, settings) do
    # Usar colores corporativos (estos vendrían de CCBOL.pdf)
    primary_color = "#1f2937"
    secondary_color = "#f9fafb"
    
    """
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8">
        <style>
          body {
            font-family: 'Times New Roman', serif;
            margin: 0;
            padding: 0;
            background-color: #{secondary_color};
          }
          .certificate-container {
            width: 210mm;
            height: 297mm;
            background: linear-gradient(135deg, #{secondary_color}, #ffffff);
            padding: 30px;
            box-sizing: border-box;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            position: relative;
          }
          .certificate-border {
            width: 100%;
            height: 100%;
            border: 3px solid #{primary_color};
            padding: 40px 60px;
            box-sizing: border-box;
            text-align: center;
          }
          .certificate-header {
            margin-bottom: 30px;
          }
          .congress-logo {
            width: 120px;
            height: auto;
            margin: 0 auto 10px;
          }
          .certificate-title {
            font-size: 24px;
            font-weight: bold;
            color: #{primary_color};
            margin: 20px 0;
            letter-spacing: 2px;
            text-transform: uppercase;
          }
          .certificate-body {
            margin: 30px 0;
          }
          .certificate-text {
            font-size: 16px;
            line-height: 1.6;
            margin-bottom: 30px;
          }
          .attendee-name {
            font-size: 28px;
            font-weight: bold;
            color: #{primary_color};
            margin: 20px 0;
            text-transform: uppercase;
            letter-spacing: 1px;
          }
          .certificate-details {
            font-size: 14px;
            margin: 20px 0;
          }
          .certificate-footer {
            margin-top: 40px;
          }
          .signature-section {
            display: flex;
            justify-content: space-around;
            width: 100%;
            margin-top: 50px;
          }
          .signature {
            text-align: center;
            width: 30%;
          }
          .signature-line {
            border-top: 1px solid #{primary_color};
            margin: 40px auto 10px;
            width: 80%;
          }
          .verification-code {
            font-size: 12px;
            color: #6b7280;
            margin-top: 30px;
            font-style: italic;
          }
        </style>
      </head>
      <body>
        <div class="certificate-container">
          <div class="certificate-border">
            <div class="certificate-header">
              <img src="#{settings.logo}" class="congress-logo" alt="Logo">
              <h1 class="certificate-title">Certificado de Participación</h1>
            </div>
            
            <div class="certificate-body">
              <div class="certificate-text">
                Se otorga el presente certificado a
              </div>
              <div class="attendee-name">
                #{attendee.nombre_completo}
              </div>
              <div class="certificate-text">
                en reconocimiento por su participación activa en el
              </div>
              <div class="certificate-text">
                <strong>#{settings.nombre}</strong>
              </div>
              <div class="certificate-details">
                Fecha del evento: #{format_date(settings.fecha_inicio)} - #{format_date(settings.fecha_fin)}<br>
                Lugar: #{settings.ubicacion}<br>
                Sesiones asistidas: #{certificate.sesiones_asistidas} de #{certificate.total_sesiones}<br>
                Porcentaje de asistencia: #{certificate.porcentaje_asistencia}%
              </div>
            </div>
            
            <div class="certificate-footer">
              <div class="signature-section">
                <div class="signature">
                  <div class="signature-line"></div>
                  <div>Firma</div>
                </div>
                <div class="signature">
                  <div class="signature-line"></div>
                  <div>Organización</div>
                </div>
                <div class="signature">
                  <div class="signature-line"></div>
                  <div>Sello</div>
                </div>
              </div>
              <div class="verification-code">
                Código de verificación: #{certificate.codigo_verificacion}
              </div>
            </div>
          </div>
        </div>
      </body>
    </html>
    """
  end
  
  @doc """
  Genera un PDF de certificado para preview.
  
  ## Parámetros
  - settings: Configuración del congreso
  
  ## Ejemplo
      iex> CertificateGenerator.generate_preview_certificate(settings)
      {:ok, pdf_binary}
  """
  def generate_preview_certificate(%Settings{} = settings) do
    html_content = """
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8">
        <style>
          body {
            font-family: 'Times New Roman', serif;
            margin: 0;
            padding: 0;
            background-color: #f9fafb;
          }
          .certificate-container {
            width: 210mm;
            height: 297mm;
            background: linear-gradient(135deg, #f9fafb, #ffffff);
            padding: 30px;
            box-sizing: border-box;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            position: relative;
          }
          .certificate-border {
            width: 100%;
            height: 100%;
            border: 3px solid #1f2937;
            padding: 40px 60px;
            box-sizing: border-box;
            text-align: center;
          }
          .certificate-header {
            margin-bottom: 30px;
          }
          .congress-logo {
            width: 120px;
            height: auto;
            margin: 0 auto 10px;
          }
          .certificate-title {
            font-size: 24px;
            font-weight: bold;
            color: #1f2937;
            margin: 20px 0;
            letter-spacing: 2px;
            text-transform: uppercase;
          }
          .certificate-body {
            margin: 30px 0;
          }
          .certificate-text {
            font-size: 16px;
            line-height: 1.6;
            margin-bottom: 30px;
          }
          .attendee-name {
            font-size: 28px;
            font-weight: bold;
            color: #1f2937;
            margin: 20px 0;
            text-transform: uppercase;
            letter-spacing: 1px;
          }
          .certificate-details {
            font-size: 14px;
            margin: 20px 0;
          }
          .certificate-footer {
            margin-top: 40px;
          }
          .signature-section {
            display: flex;
            justify-content: space-around;
            width: 100%;
            margin-top: 50px;
          }
          .signature {
            text-align: center;
            width: 30%;
          }
          .signature-line {
            border-top: 1px solid #1f2937;
            margin: 40px auto 10px;
            width: 80%;
          }
          .verification-code {
            font-size: 12px;
            color: #6b7280;
            margin-top: 30px;
            font-style: italic;
          }
        </style>
      </head>
      <body>
        <div class="certificate-container">
          <div class="certificate-border">
            <div class="certificate-header">
              <img src="#{settings.logo}" class="congress-logo" alt="Logo">
              <h1 class="certificate-title">Certificado de Participación</h1>
            </div>
            
            <div class="certificate-body">
              <div class="certificate-text">
                Se otorga el presente certificado a
              </div>
              <div class="attendee-name">
                NOMBRE DEL PARTICIPANTE
              </div>
              <div class="certificate-text">
                en reconocimiento por su participación activa en el
              </div>
              <div class="certificate-text">
                <strong>#{settings.nombre}</strong>
              </div>
              <div class="certificate-details">
                Fecha del evento: #{format_date(settings.fecha_inicio)} - #{format_date(settings.fecha_fin)}<br>
                Lugar: #{settings.ubicacion}<br>
                Sesiones asistidas: 0 de 0<br>
                Porcentaje de asistencia: 0.00%
              </div>
            </div>
            
            <div class="certificate-footer">
              <div class="signature-section">
                <div class="signature">
                  <div class="signature-line"></div>
                  <div>Firma</div>
                </div>
                <div class="signature">
                  <div class="signature-line"></div>
                  <div>Organización</div>
                </div>
                <div class="signature">
                  <div class="signature-line"></div>
                  <div>Sello</div>
                </div>
              </div>
              <div class="verification-code">
                Código de verificación: PREVIEW_CODE_12345
              </div>
            </div>
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
  
  defp format_date(date) do
    case date do
      %Date{} -> 
        "#{date.day}/#{date.month}/#{date.year}"
      _ -> 
        date
    end
  end
end