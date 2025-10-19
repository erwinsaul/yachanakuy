defmodule YachanakuyWeb.Public.SpaLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Events
  alias Yachanakuy.Program

  def mount(_params, _session, socket) do
    settings = Events.get_congress_settings()
    sessions = Program.list_sessions_with_details()
    speakers = Program.list_speakers_with_sessions()
    rooms = Program.list_rooms()
    categories = Events.list_attendee_categories()

    # Use real data from database, no test content needed
    sessions = if Enum.empty?(sessions), do: generate_test_sessions(), else: sessions

    sections = [
      %{id: "inicio", name: "Inicio", layout: "full-center", bg_color: "#F0F8FF"},
      %{id: "sobre", name: "Acerca", layout: "horizontal-slides", bg_color: "#E6E6FA"},
      %{id: "programa", name: "Programa", layout: "horizontal-slides", bg_color: "#ADD8E6"},
      %{id: "expositores", name: "Expositores", layout: "horizontal-slides", bg_color: "#98FB98"},
      %{id: "turismo", name: "Turismo", layout: "full-center", bg_color: "#FFB6C1"}
    ]

    socket =
      socket
      |> assign(:page, "spa")
      |> assign(:settings, settings)
      |> assign(:sessions, sessions)
      |> assign(:speakers, speakers)
      |> assign(:rooms, rooms)
      |> assign(:categories, categories)
      |> assign(:sections, sections)
      |> assign(:active_section, "inicio")
      |> assign(:inner_content, nil)

    {:ok, socket}
  end

  defp generate_test_sessions() do
    [
      %{
        titulo: "Introducción a la Computación",
        fecha: Date.utc_today(),
        hora_inicio: ~T[09:00:00],
        hora_fin: ~T[10:30:00],
        descripcion: "Clase introductoria sobre fundamentos de computación.",
        speaker: %{
          nombre_completo: "Expositor 1",
          institucion: "UTO"
        },
        room: %{
          nombre: "Aula 101"
        }
      },
      %{
        titulo: "Programación Web",
        fecha: Date.utc_today(),
        hora_inicio: ~T[10:45:00],
        hora_fin: ~T[12:15:00],
        descripcion: "Desarrollo de aplicaciones web modernas.",
        speaker: %{
          nombre_completo: "Expositor 2",
          institucion: "UTO"
        },
        room: %{
          nombre: "Laboratorio 2"
        }
      },
      %{
        titulo: "Bases de Datos",
        fecha: Date.utc_today() |> Date.add(1),
        hora_inicio: ~T[14:00:00],
        hora_fin: ~T[15:30:00],
        descripcion: "Fundamentos y diseño de bases de datos relacionales.",
        speaker: %{
          nombre_completo: "Expositor 3",
          institucion: "UTO"
        },
        room: %{
          nombre: "Aula 205"
        }
      },
      %{
        titulo: "Inteligencia Artificial",
        fecha: Date.utc_today() |> Date.add(1),
        hora_inicio: ~T[15:45:00],
        hora_fin: ~T[17:15:00],
        descripcion: "Conceptos básicos de IA y machine learning.",
        speaker: %{
          nombre_completo: "Expositor 4",
          institucion: "UTO"
        },
        room: %{
          nombre: "Sala de Conferencias"
        }
      }
    ]
  end

  defp generate_test_speakers() do
    [
      %{
        nombre_completo: "Expositor 1",
        institucion: "Universidad Técnica Oruro",
        email: "expositor1@uto.edu.bo",
        biografia: "Docente de la carrera de Ingeniería de Sistemas, especialista en computación.",
        foto: nil
      },
      %{
        nombre_completo: "Expositor 2",
        institucion: "Universidad Técnica Oruro",
        email: "expositor2@uto.edu.bo",
        biografia: "Investigador y docente en el área de desarrollo web.",
        foto: nil
      },
      %{
        nombre_completo: "Expositor 3",
        institucion: "Universidad Técnica Oruro",
        email: "expositor3@uto.edu.bo",
        biografia: "Experto en bases de datos y sistemas informáticos.",
        foto: nil
      },
      %{
        nombre_completo: "Expositor 4",
        institucion: "Universidad Técnica Oruro",
        email: "expositor4@uto.edu.bo",
        biografia: "Especialista en inteligencia artificial y aprendizaje automático.",
        foto: nil
      }
    ]
  end

  def render(assigns) do
  ~H"""
  <div phx-hook="FreePage" id="freepage-container">
  <nav class="menu" id="main-menu">
    <%= for {section, index} <- Enum.with_index(@sections) do %>
      <a href={"##{section.id}"}
         data-index={index}
         class={if @active_section == section.id, do: "active", else: ""}>
        <%= section.name %>
      </a>
    <% end %>
  </nav>

  <div id="fullscreen-container">
    <!-- Sección Inicio -->
    <div class="section full-center" id="inicio" data-background-color="#F0F8FF" data-video="https://www.youtube.com/embed/4UYxB_UhJ9A?list=PL7qvgzv-R8_EG5yZp7PLhHXr93zrkxUj8&index=5&autoplay=1&loop=1&mute=1&controls=0">
      <div class="content">
        <h1><%= if @settings, do: @settings.nombre, else: "Yachanakuy - Congreso" %></h1>
        <p><%= if @settings && @settings.fecha_inicio && @settings.fecha_fin do %>
          <%= Date.to_string(@settings.fecha_inicio) %> - <%= Date.to_string(@settings.fecha_fin) %>
        <% else %>
          Fechas por confirmar
        <% end %></p>
        <p>Bienvenidos al congreso académico más importante del año.</p>
      </div>
    </div>

    <!-- Sección Sobre -->
    <div class="section horizontal-slides" id="sobre" data-background-color="#E6E6FA">
      <div class="slide">
        <h2>Facultad Nacional de Ingeniería</h2>
        <p>La FNI es una de las facltades de ingeniería más importantes del país, formando profesionales desde 1891. Con más de 130 años de historis.</p>
      </div>
      <div class="slide">
        <h2>Universidad Técnica Oruro (UTO)</h2>
        <p>La UTO es una universidad pública fundada en 1892, reconocida por su calidad académica y contribución al desarrollo técnico-científico del país.</p>
      </div>
      <div class="slide">
        <h2>Carrera de Ingeniería de Sistemas</h2>
        <p>Formamos profesionales en tecnología de la información, desarrollo de software, inteligencia artificial y ciberseguridad, comprometidos con el desarrollo tecnológico del país.</p>
      </div>
      <div class="slide">
        <h2>Redes Sociales</h2>
        <div class="flex flex-wrap gap-2 justify-center mt-4">
          <a href="#" class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors">Facebook</a>
          <a href="#" class="bg-blue-400 text-white px-4 py-2 rounded-lg hover:bg-blue-500 transition-colors">Twitter</a>
          <a href="#" class="bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 transition-colors">Instagram</a>
          <a href="#" class="bg-blue-700 text-white px-4 py-2 rounded-lg hover:bg-blue-800 transition-colors">LinkedIn</a>
        </div>
      </div>
    </div>

    <!-- Sección Programa -->
    <div class="section horizontal-slides" id="programa" data-background-color="#ADD8E6">
      <%= for session <- @sessions do %>
        <div class="slide">
          <h2><%= session.titulo %></h2>
          <p><%= Timex.format!(Timex.to_datetime(session.fecha), "{WDfull}, {0D} de {Mfull} de {YYYY}" ) %></p>
          <p><%= Time.to_string(session.hora_inicio) %> - <%= Time.to_string(session.hora_fin) %></p>
          <%= if session.speaker do %>
            <p>Expositor: <%= session.speaker.nombre_completo %></p>
          <% end %>
          <%= if session.room do %>
            <p>Lugar: <%= session.room.nombre %></p>
          <% end %>
          <%= if session.descripcion do %>
            <p><%= session.descripcion %></p>
          <% end %>
        </div>
      <% end %>
    </div>

    <!-- Sección Expositores -->
    <div class="section horizontal-slides" id="expositores" data-background-color="#98FB98">
      <%= for speaker <- @speakers do %>
        <div class="slide">
          <%= if speaker.foto do %>
            <div class="mb-4">
              <img src={speaker.foto} alt={speaker.nombre_completo} class="w-32 h-32 object-cover rounded-full mx-auto">
            </div>
          <% end %>
          <h2><%= speaker.nombre_completo %></h2>
          <p><%= speaker.institucion %></p>
          <%= if speaker.email do %>
            <p><%= speaker.email %></p>
          <% end %>
          <%= if speaker.biografia do %>
            <p><%= String.slice(speaker.biografia, 0..150) %><%= if String.length(speaker.biografia) > 150, do: "..." %></p>
          <% end %>
        </div>
      <% end %>
    </div>

    <!-- Sección Turismo -->
    <div class="section full-center" id="turismo" data-background-color="#FFB6C1">
      <div class="content">
        <h2>Información Turística</h2>
        <%= if @settings && @settings.info_turismo do %>
          <p class="text-sm"><%= @settings.info_turismo %></p>
        <% else %>
          <p>Información turística disponible próximamente.</p>
        <% end %>
      </div>
    </div>
  </div>

  <div class="arrow arrow-up" id="arrow-up">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <polyline points="18 15 12 9 6 15"></polyline>
    </svg>
  </div>
  <div class="arrow arrow-down" id="arrow-down">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <polyline points="6 9 12 15 18 9"></polyline>
    </svg>
  </div>

  <div class="arrow arrow-left" id="arrow-left">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <polyline points="15 18 9 12 15 6"></polyline>
    </svg>
  </div>
  <div class="arrow arrow-right" id="arrow-right">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <polyline points="9 18 15 12 9 6"></polyline>
    </svg>
  </div>
  </div>
  """
  end
end
