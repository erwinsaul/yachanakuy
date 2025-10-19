defmodule YachanakuyWeb.Public.HomeLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Events
  alias Yachanakuy.Program

  def mount(_params, _session, socket) do
    # Get congress settings
    settings = Events.get_congress_settings()

    # Get sessions and speakers for display
    sessions = Program.list_sessions()
    speakers = Program.list_speakers_with_sessions()
    
    socket = assign(socket,
      settings: settings,
      sessions: sessions,
      speakers: speakers,
      page: "home"
    )
    
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen">
      <!-- Hero Banner -->
      <section class="bg-gradient-to-r from-[#144D85] to-[#B33536] text-white py-20">
        <div class="container mx-auto px-4 text-center">
          <h1 class="text-4xl md:text-6xl font-bold mb-4">
            <%= if @settings, do: @settings.nombre, else: "CCBOL - 2025" %>
          </h1>
          <p class="text-xl md:text-2xl mb-6">
            <%= if @settings && @settings.fecha_inicio && @settings.fecha_fin do %>
              <%= Date.to_string(@settings.fecha_inicio) %> - <%= Date.to_string(@settings.fecha_fin) %>
            <% else %>
              Fechas por confirmar
            <% end %>
          </p>
          <p class="text-lg mb-8 max-w-2xl mx-auto">
            <%= if @settings, do: @settings.descripcion, else: "Bienvenidos al congreso académico más importante del año" %>
          </p>
          <div class="space-x-4">
            <.link navigate="/inscripcion" class="bg-white text-[#144D85] hover:bg-gray-100 font-bold py-3 px-6 rounded-full text-lg transition duration-300">
              Inscribirse ahora
            </.link>
            <.link navigate="/programa" class="bg-transparent border-2 border-white hover:bg-white/10 font-bold py-3 px-6 rounded-full text-lg transition duration-300">
              Ver programa
            </.link>
          </div>
        </div>
      </section>

      <!-- Sobre el Congreso -->
      <section class="py-16 bg-gray-50">
        <div class="container mx-auto px-4">
          <h2 class="text-3xl font-bold text-center mb-12 text-[#144D85]">Sobre el Congreso</h2>
          <div class="max-w-4xl mx-auto text-center">
            <p class="text-lg text-gray-700">
              <%= if @settings, do: @settings.descripcion, else: "Este congreso reúne a los principales expertos del área para compartir conocimientos, experiencias y nuevas perspectivas sobre los temas más relevantes del sector." %>
            </p>
          </div>
        </div>
      </section>

      <!-- Programa -->
      <section class="py-16">
        <div class="container mx-auto px-4">
          <h2 class="text-3xl font-bold text-center mb-12 text-[#144D85]">Programa del Congreso</h2>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <%= for session <- Enum.take(@sessions, 6) do %>
              <div class="bg-white rounded-lg shadow-md p-6 border border-gray-200 hover:shadow-lg transition duration-300">
                <h3 class="text-xl font-bold mb-2 text-[#144D85]"><%= session.titulo %></h3>
                <p class="text-gray-600 mb-2">
                  <%= Timex.format!(Timex.to_datetime(session.fecha), "{WDfull}, {0D} de {Mfull} de {YYYY}" ) %>
                  | <%= Time.to_string(session.hora_inicio) %> - <%= Time.to_string(session.hora_fin) %>
                </p>
                <%= if session.room do %>
                  <p class="text-sm text-gray-500">Lugar: <%= session.room.nombre %></p>
                <% end %>
              </div>
            <% end %>
          </div>
          <%= if length(@sessions) > 6 do %>
            <div class="text-center mt-8">
              <.link navigate="/programa" class="bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-2 px-6 rounded-full transition duration-300">
                Ver todo el programa
              </.link>
            </div>
          <% end %>
        </div>
      </section>

      <!-- Expositores -->
      <section class="py-16 bg-gray-50">
        <div class="container mx-auto px-4">
          <h2 class="text-3xl font-bold text-center mb-12 text-[#144D85]">Nuestros Expositores</h2>
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-8">
            <%= for speaker <- Enum.take(@speakers, 8) do %>
              <div class="bg-white rounded-lg shadow-md overflow-hidden text-center hover:shadow-lg transition duration-300">
                <%= if speaker.foto do %>
                  <img src={speaker.foto} alt={speaker.nombre_completo} class="w-full h-48 object-cover">
                <% else %>
                  <div class="bg-gray-200 border-2 border-dashed rounded-t-lg w-full h-48 flex items-center justify-center text-gray-500">
                    Foto
                  </div>
                <% end %>
                <div class="p-6">
                  <h3 class="text-xl font-bold mb-1 text-[#144D85]"><%= speaker.nombre_completo %></h3>
                  <p class="text-gray-600 mb-2"><%= speaker.institucion %></p>
                  <%= if speaker.biografia && String.length(speaker.biografia) > 100 do %>
                    <p class="text-sm text-gray-700 truncate"><%= speaker.biografia %></p>
                  <% else %>
                    <p class="text-sm text-gray-700"><%= speaker.biografia %></p>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
          <%= if length(@speakers) > 8 do %>
            <div class="text-center mt-8">
              <.link navigate="/expositores" class="bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-2 px-6 rounded-full transition duration-300">
                Ver todos los expositores
              </.link>
            </div>
          <% end %>
        </div>
      </section>

      <!-- Salas -->
      <section class="py-16">
        <div class="container mx-auto px-4">
          <h2 class="text-3xl font-bold text-center mb-12 text-[#144D85]">Salas del Evento</h2>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <!-- Salas se cargarán dinámicamente -->
            <%= for room <- Program.list_rooms() |> Enum.take(3) do %>
              <div class="bg-white rounded-lg shadow-md p-6 border border-gray-200">
                <h3 class="text-xl font-bold mb-2 text-[#144D85]"><%= room.nombre %></h3>
                <p class="text-gray-600 mb-1">Capacidad: <%= room.capacidad %> personas</p>
                <p class="text-gray-600"><%= room.ubicacion %></p>
              </div>
            <% end %>
          </div>
        </div>
      </section>

      <!-- Turismo -->
      <%= if @settings && @settings.info_turismo do %>
        <section class="py-16 bg-gray-50">
          <div class="container mx-auto px-4">
            <h2 class="text-3xl font-bold text-center mb-12 text-[#144D85]">Información Turística</h2>
            <div class="max-w-4xl mx-auto bg-white rounded-lg shadow-md p-8">
              <p class="text-lg text-gray-700 whitespace-pre-wrap"><%= @settings.info_turismo %></p>
            </div>
          </div>
        </section>
      <% end %>
    </div>
    """
  end
end