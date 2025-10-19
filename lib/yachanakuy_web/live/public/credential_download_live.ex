defmodule YachanakuyWeb.Public.CredentialDownloadLive do
  use YachanakuyWeb, :live_view
  alias Yachanakuy.Registration

  def mount(%{"token" => token}, _session, socket) do
    attendee = Registration.get_attendee_by_token(token)
    
    if attendee do
      socket = assign(socket,
        attendee: attendee,
        token: token,
        error: nil,
        page: "credencial"
      )
      {:ok, socket}
    else
      socket = assign(socket, 
        attendee: nil,
        error: "Credencial no encontrada o token inválido.",
        page: "credencial"
      )
      {:ok, socket}
    end
  end

  def mount(_params, _session, socket) do
    # Si hay usuario autenticado en socket.assigns (viene del router/plug)
    current_user = Map.get(socket.assigns, :current_user)
    
    if current_user do
      # Usuario autenticado puede descargar su credencial
      attendee = get_attendee_by_user(current_user)
      socket = assign(socket,
        attendee: attendee,
        error: nil,
        page: "credencial"
      )
      {:ok, socket}
    else
      socket = assign(socket, 
        attendee: nil,
        error: "Debes iniciar sesión para descargar tu credencial.",
        page: "credencial"
      )
      {:ok, socket}
    end
  end

  defp get_attendee_by_user(_user) do
    # Esta función necesitaría una implementación para encontrar al participante
    # asociado al usuario, lo cual podría depender del diseño específico
    nil
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8 max-w-3xl">
      <h1 class="text-3xl font-bold mb-8 text-[#144D85]">Descarga de Credencial</h1>

      <%= if @error do %>
        <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6">
          <%= @error %>
        </div>
      <% end %>

      <%= if @attendee do %>
        <div class="bg-white rounded-lg shadow-md p-6">
          <div class="flex flex-col items-center">
            <div class="w-64 h-64 mb-6">
              <%= if @attendee.codigo_qr do %>
                <!-- QR code would be generated here -->
                <div class="bg-gray-100 border-2 border-dashed rounded-xl w-full h-full flex items-center justify-center text-gray-500">
                  QR: <%= @attendee.codigo_qr %>
                </div>
              <% else %>
                <div class="bg-gray-100 border-2 border-dashed rounded-xl w-full h-full flex items-center justify-center text-gray-500">
                  Credencial digital
                </div>
              <% end %>
            </div>

            <h2 class="text-2xl font-bold text-center mb-2"><%= @attendee.nombre_completo %></h2>
            <p class="text-gray-600 mb-1">Categoría: <%= get_category_name(@attendee.category_id) %></p>
            <p class="text-gray-600 mb-4">#<%= @attendee.numero_documento %></p>

            <%= if @attendee.credencial_digital do %>
              <a href={@attendee.credencial_digital}
                 target="_blank"
                 class="bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-2 px-6 rounded-md transition duration-300 inline-block">
                Descargar Credencial
              </a>
            <% else %>
              <p class="text-gray-600">Tu credencial digital está siendo generada. Por favor, vuelve más tarde.</p>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp get_category_name(category_id) do
    # Esta es una implementación simple, en la práctica se debería obtener de la base de datos
    case category_id do
      1 -> "Estudiante"
      2 -> "Profesional"
      3 -> "Ponente"
      _ -> "Otro"
    end
  end
end
