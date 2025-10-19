defmodule YachanakuyWeb.Public.CertificateVerificationLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Certificates
  alias Yachanakuy.Registration

  def mount(_params, _session, socket) do
    socket = assign(socket,
      page: "verificacion_certificado",
      certificate: nil,
      attendee: nil,
      success_message: nil,
      error_message: nil
    )
    {:ok, socket}
  end

  def handle_event("verify", %{"codigo_verificacion" => codigo_verificacion}, socket) do
    certificate = Certificates.get_certificate_by_verification_code(codigo_verificacion)

    if certificate do
      attendee = Registration.get_attendee!(certificate.attendee_id)

      socket = assign(socket,
        certificate: certificate,
        attendee: attendee,
        success_message: "Certificado verificado exitosamente.",
        error_message: nil
      )
      {:noreply, socket}
    else
      socket = assign(socket,
        certificate: nil,
        attendee: nil,
        error_message: "Certificado no encontrado con el código proporcionado.",
        success_message: nil
      )
      {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8 max-w-3xl">
      <h1 class="text-3xl font-bold mb-8 text-[#144D85]">Verificación de Certificado</h1>

      <div class="bg-white rounded-lg shadow-md p-6">
        <p class="text-gray-700 mb-6">
          Ingresa el código de verificación del certificado para verificar su autenticidad.
          Este código se encuentra en la parte inferior del certificado emitido.
        </p>

        <%= if @success_message do %>
          <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
            <%= @success_message %>
          </div>

          <%= if @certificate && @attendee do %>
            <div class="border border-gray-200 rounded-lg p-6 mb-6 bg-gray-50">
              <h2 class="text-xl font-bold mb-4 text-center text-[#144D85]">Información del Certificado</h2>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                <div>
                  <p class="font-semibold">Nombre del participante:</p>
                  <p><%= @attendee.nombre_completo %></p>
                </div>

                <div>
                  <p class="font-semibold">Código de verificación:</p>
                  <p><%= @certificate.codigo_verificacion %></p>
                </div>

                <div>
                  <p class="font-semibold">Fecha de generación:</p>
                  <p><%= if @certificate.fecha_generacion, do: Date.to_string(@certificate.fecha_generacion), else: "N/A" %></p>
                </div>

                <div>
                  <p class="font-semibold">Asistencia verificada:</p>
                  <p><%= @certificate.sesiones_asistidas %> de <%= @certificate.total_sesiones %> sesiones</p>
                </div>
              </div>

              <div class="mt-4">
                <p class="font-semibold">Porcentaje de asistencia:</p>
                <div class="w-full bg-gray-200 rounded-full h-4 mt-1">
                  <div
                    class="bg-[#144D85] h-4 rounded-full"
                    style={"width: #{(@certificate.porcentaje_asistencia || 0) * 100}%"}
                  ></div>
                </div>
                <p class="text-center mt-1"><%= @certificate.porcentaje_asistencia * 100 %>%</p>
              </div>
            </div>
          <% end %>
        <% end %>

        <%= if @error_message do %>
          <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
            <%= @error_message %>
          </div>
        <% end %>

        <div class="mt-8">
          <h2 class="text-xl font-semibold mb-4 text-[#144D85]">Verificar certificado</h2>
          <.form
            :let={f}
            for={%{}}
            phx-submit="verify"
            class="space-y-4"
          >
            <div>
              <.input
                field={f[:codigo_verificacion]}
                type="text"
                label="Código de verificación"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                placeholder="Ingresa el código de verificación del certificado"
              />
            </div>

            <div>
              <button
                type="submit"
                class="w-full bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-3 px-4 rounded-md transition duration-300"
              >
                Verificar Certificado
              </button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end
end
