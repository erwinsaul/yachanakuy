defmodule Yachanakuy.Certificates do
  @moduledoc """
  The Certificates context.
  """
  import Ecto.Query, warn: false
  alias Yachanakuy.Repo

  alias Yachanakuy.Certificates.Certificate

  def list_certificates do
    Repo.all(Certificate)
  end

  def get_certificate!(id) do
    Repo.get!(Certificate, id)
  end

  def get_certificate_by_attendee(attendee_id) do
    Repo.get_by(Certificate, attendee_id: attendee_id)
  end

  def create_certificate(attrs \\ %{}) do
    %Certificate{}
    |> Certificate.changeset(attrs)
    |> Repo.insert()
  end

  def update_certificate(%Certificate{} = certificate, attrs) do
    certificate
    |> Certificate.changeset(attrs)
    |> Repo.update()
  end

  def delete_certificate(%Certificate{} = certificate) do
    Repo.delete(certificate)
  end

  def change_certificate(%Certificate{} = certificate, attrs \\ %{}) do
    Certificate.changeset(certificate, attrs)
  end

  def get_certificate_by_verification_code(code) do
    Repo.get_by(Certificate, codigo_verificacion: code)
  end

  @doc """
  Genera un certificado para un participante basado en su asistencia a sesiones.
  
  ## Parámetros
  - attendee_id: ID del participante
  - opts: Opciones adicionales
  
  ## Retorna
  - {:ok, certificate} o {:error, reason}
  """
  def generate_certificate_for_attendee(attendee_id, _opts \\ []) do
    # Obtener el participante
    attendee = Yachanakuy.Registration.get_attendee!(attendee_id)
    
    # Verificar que esté aprobado
    if attendee.estado != "aprobado" do
      {:error, "Solo se pueden generar certificados para participantes aprobados"}
    else
      # Calcular porcentaje de asistencia
      total_sessions = Yachanakuy.Program.list_sessions() |> length
      sessions_attended = attendee.sesiones_asistidas || 0
      percentage = calculate_attendance_percentage(sessions_attended, total_sessions)
      
      # Generar código de verificación único
      verification_code = generate_verification_code()
      
      # Verificar que no exista otro certificado para este participante
      existing_certificate = get_certificate_by_attendee(attendee_id)
      if existing_certificate do
        {:error, "El participante ya tiene un certificado generado"}
      else
        # Crear atributos para el certificado
        certificate_attrs = %{
          attendee_id: attendee_id,
          codigo_verificacion: verification_code,
          porcentaje_asistencia: percentage,
          sesiones_asistidas: sessions_attended,
          total_sesiones: total_sessions,
          fecha_generacion: DateTime.utc_now()
        }
        
        # Generar PDF del certificado
        with {:ok, pdf_binary} <- generate_certificate_pdf(attendee, certificate_attrs),
             {:ok, pdf_path} <- save_certificate_pdf(pdf_binary, attendee_id) do
          
          # Actualizar los atributos con la ruta del PDF
          final_attrs = Map.put(certificate_attrs, :archivo_pdf, pdf_path)
          
          # Crear el certificado en la base de datos
          case create_certificate(final_attrs) do
            {:ok, certificate} ->
              # Registrar en logs de auditoría
              audit_log = %{
                user_id: nil,  # Generado automáticamente
                accion: "generar_certificado",
                tipo_recurso: "Certificate",
                id_recurso: certificate.id,
                cambios: Jason.encode!(%{
                  attendee_id: attendee_id,
                  verification_code: verification_code,
                  percentage: percentage
                })
              }
              
              Yachanakuy.Logs.create_audit_log(audit_log)
              
              {:ok, certificate}
            error ->
              error
          end
        else
          error -> error
        end
      end
    end
  end

  @doc """
  Verifica la validez de un código de verificación de certificado.
  
  ## Parámetros
  - verification_code: Código a verificar
  
  ## Retorna
  - {:ok, certificate} o {:error, reason}
  """
  def verify_certificate_code(verification_code) do
    certificate = get_certificate_by_verification_code(verification_code)
    
    if certificate do
      # Obtener información adicional para la verificación
      attendee = Yachanakuy.Registration.get_attendee!(certificate.attendee_id)
      settings = Yachanakuy.Events.get_congress_settings()
      
      {:ok, %{certificate: certificate, attendee: attendee, settings: settings}}
    else
      {:error, "Código de verificación no válido"}
    end
  end

  # Función auxiliar para calcular porcentaje de asistencia
  defp calculate_attendance_percentage(0, 0), do: 0.0
  defp calculate_attendance_percentage(sessions_attended, total_sessions) do
    (sessions_attended / total_sessions) * 100
    |> Float.round(2)
  end

  # Función auxiliar para generar código de verificación único
  defp generate_verification_code do
    # Generar un código aleatorio único
    :crypto.strong_rand_bytes(32)
    |> Base.url_encode64()
    |> binary_part(0, 16)
    |> String.replace(~r/[^A-Z0-9]/, "")
    |> String.upcase()
    |> (&("YACH-#{&1}")).()
  end

  # Función auxiliar para generar PDF del certificado
  defp generate_certificate_pdf(attendee, certificate_attrs) do
    # Obtener settings del congreso
    settings = Yachanakuy.Events.get_congress_settings()
    
    # Crear un certificado temporal con los attrs
    temp_certificate = %Yachanakuy.Certificates.Certificate{
      id: 0,
      attendee_id: certificate_attrs.attendee_id,
      codigo_verificacion: certificate_attrs.codigo_verificacion,
      archivo_pdf: "",
      porcentaje_asistencia: certificate_attrs.porcentaje_asistencia,
      sesiones_asistidas: certificate_attrs.sesiones_asistidas,
      total_sesiones: certificate_attrs.total_sesiones,
      fecha_generacion: certificate_attrs.fecha_generacion,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
    
    # Generar PDF usando el generador de certificados
    Yachanakuy.Pdf.CertificateGenerator.generate_certificate(temp_certificate, attendee, settings)
  end

  # Función auxiliar para guardar PDF del certificado
  defp save_certificate_pdf(pdf_binary, attendee_id) do
    # Crear directorio si no existe
    directory = "priv/static/uploads/certificados"
    File.mkdir_p!(directory)
    
    # Generar nombre único para el archivo
    filename = "certificado_#{attendee_id}_#{System.system_time(:second)}.pdf"
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
end