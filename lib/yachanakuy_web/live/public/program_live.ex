defmodule YachanakuyWeb.Public.ProgramLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Program

  def mount(_params, _session, socket) do
    sessions = Program.list_sessions()
    speakers = Program.list_speakers_with_sessions()
    rooms = Program.list_rooms()
    
    socket = assign(socket,
      sessions: sessions,
      speakers: speakers,
      rooms: rooms,
      page: "programa"
    )
    
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-8 text-[#144D85]">Programa del Congreso</h1>
      
      <div class="bg-white rounded-lg shadow-md p-6 mb-8">
        <h2 class="text-2xl font-semibold mb-4 text-[#144D85]">Calendario de Sesiones</h2>
        
        <%= for {date, sessions_by_date} <- group_sessions_by_date(@sessions) do %>
          <div class="mb-8">
            <h3 class="text-xl font-bold mb-4 text-[#B33536]">
              <%= Timex.format!(Timex.to_datetime(date), "{WDfull}, {0D} de {Mfull} de {YYYY}") %>
            </h3>
            
            <div class="space-y-4">
              <%= for session <- sessions_by_date do %>
                <div class="border-l-4 border-[#144D85] pl-4 py-2 hover:bg-gray-50">
                  <div class="flex flex-col md:flex-row md:justify-between md:items-center">
                    <div>
                      <h4 class="font-bold text-lg"><%= session.titulo %></h4>
                      <p class="text-gray-600">
                        <%= Time.to_string(session.hora_inicio) %> - <%= Time.to_string(session.hora_fin) %>
                      </p>
                      <%= if session.speaker do %>
                        <p class="text-gray-700">Expositor: <%= session.speaker.nombre_completo %></p>
                      <% end %>
                    </div>
                    <%= if session.room do %>
                      <div class="mt-2 md:mt-0">
                        <span class="bg-gray-100 text-gray-800 px-3 py-1 rounded-full text-sm">
                          <%= session.room.nombre %>
                        </span>
                      </div>
                    <% end %>
                  </div>
                  
                  <%= if session.descripcion do %>
                    <p class="mt-2 text-gray-700"><%= session.descripcion %></p>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp group_sessions_by_date(sessions) do
    sessions
    |> Enum.group_by(fn session -> session.fecha end)
    |> Enum.sort_by(fn {date, _sessions} -> date end)
  end
end