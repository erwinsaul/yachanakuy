defmodule YachanakuyWeb.Public.SpeakersLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Program

  def mount(_params, _session, socket) do
    speakers = Program.list_speakers_with_sessions()
    
    socket = assign(socket,
      speakers: speakers,
      page: "expositores"
    )
    
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-8 text-[#144D85]">Nuestros Expositores</h1>
      
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-8">
        <%= for speaker <- @speakers do %>
          <div class="bg-white rounded-lg shadow-md overflow-hidden hover:shadow-lg transition duration-300">
            <%= if speaker.foto do %>
              <img src={speaker.foto} alt={speaker.nombre_completo} class="w-full h-48 object-cover">
            <% else %>
              <div class="bg-gray-200 border-2 border-dashed w-full h-48 flex items-center justify-center text-gray-500">
                Foto de <%= speaker.nombre_completo %>
              </div>
            <% end %>
            <div class="p-6">
              <h3 class="text-xl font-bold mb-2 text-[#144D85]"><%= speaker.nombre_completo %></h3>
              <p class="text-gray-600 mb-2"><%= speaker.institucion %></p>
              <%= if speaker.email do %>
                <p class="text-sm text-gray-500 mb-2"><%= speaker.email %></p>
              <% end %>
              <%= if speaker.biografia do %>
                <p class="text-sm text-gray-700 mb-3"><%= speaker.biografia %></p>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end