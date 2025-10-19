defmodule YachanakuyWeb.Public.CertificateRequestLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Certificates

  def mount(_params, _session, socket) do
    socket = assign(socket,
      page: "certificado",
      certificate: nil,
      success_message: nil,
      error_message: nil
    )
    {:ok, socket}
  end

  def handle_event("request", %{"codigo_verificacion" => codigo_verificacion}, socket) do
    # Lógica para solicitar certificado basado en el código de verificación
    # En el sistema real, esto sería al revés - generar un certificado y obtener su código
    certificate = Certificates.get_certificate_by_verification_code(codigo_verificacion)

    if certificate do
      socket = assign(socket,
        certificate: certificate,
        success_message: "Certificado encontrado. Puedes descargarlo a continuación.",
        error_message: nil
      )
      {:noreply, socket}
    else
      socket = assign(socket,
        certificate: nil,
        error_message: "Certificado no encontrado con el código proporcionado.",
        success_message: nil
      )
      {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8 max-w-3xl">
      <h1 class="text-3xl font-bold mb-8 text-[#144D85]">Solicitud de Certificado</h1>

      <div class="bg-white rounded-lg shadow-md p-6 mb-8">
        <p class="text-gray-700 mb-6">
          Si has asistido al congreso y se ha verificado tu asistencia, puedes solicitar tu certificado de participación.
          Ingresa tu código de verificación o busca tu registro de asistencia.
        </p>

        <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
          <p class="text-blue-800">
            <strong>Nota:</strong> Los certificados se generan automáticamente después del evento para los participantes
            que hayan asistido a un número mínimo de sesiones. Ponte en contacto con el equipo organizador si tienes
            alguna duda sobre tu elegibilidad.
          </p>
        </div>

        <%= if @success_message do %>
          <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
            <%= @success_message %>
          </div>

          <%= if @certificate && @certificate.archivo_pdf do %>
            <div class="text-center">
              <a href={@certificate.archivo_pdf}
                 target="_blank"
                 class="bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-3 px-6 rounded-md transition duration-300 inline-block">
                Descargar Certificado
              </a>
            </div>
          <% end %>
        <% end %>

        <%= if @error_message do %>
          <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
            <%= @error_message %>
          </div>
        <% end %>

        <div class="mt-8">
          <h2 class="text-xl font-semibold mb-4 text-[#144D85]">Solicitar por código de verificación</h2>
          
          <.form
            :let={f}
            for={%{}}
            phx-submit="request"
            class="space-y-4"
          >
            <div>
              <.input
                field={f[:codigo_verificacion]}
                type="text"
                label="Código de verificación"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                placeholder="Ingresa tu código de verificación"
              />
            </div>

            <div>
              <button
                type="submit"
                class="w-full bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-3 px-4 rounded-md transition duration-300"
              >
                Solicitar Certificado
              </button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end
end
