defmodule YachanakuyWeb.Public.SpaLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Events
  alias Yachanakuy.Program
  alias Yachanakuy.Tourism
  alias Yachanakuy.Settings

  def mount(_params, _session, socket) do
    settings = Events.get_congress_settings()

    # Verificar módulos habilitados
    event_info_enabled = Settings.is_module_enabled("event_info")
    speakers_enabled = Settings.is_module_enabled("speakers")
    sessions_enabled = Settings.is_module_enabled("sessions")
    rooms_enabled = Settings.is_module_enabled("rooms")
    packages_enabled = Settings.is_module_enabled("packages")
    tourist_info_enabled = Settings.is_module_enabled("tourist_info")

    # Cargar datos según módulos habilitados (solo registros activos cuando aplique)
    event_info = if event_info_enabled do
      Events.list_event_info() |> Enum.filter(fn e -> e.activo == true end)
    else
      []
    end

    sessions = if sessions_enabled, do: Program.list_sessions_with_details(), else: []
    speakers = if speakers_enabled, do: Program.list_speakers_with_sessions(), else: []
    rooms = if rooms_enabled, do: Program.list_rooms(), else: []
    packages = if packages_enabled, do: Tourism.list_packages(), else: []

    tourist_info = if tourist_info_enabled do
      Tourism.list_tourist_info() |> Enum.filter(fn t -> t.estado == "activo" end)
    else
      []
    end

    categories = Events.list_attendee_categories()

    # Generar secciones dinámicamente (solo si hay datos)
    sections = generate_dynamic_sections(
      event_info_enabled && length(event_info) > 0,
      speakers_enabled && length(speakers) > 0,
      sessions_enabled && length(sessions) > 0,
      rooms_enabled && length(rooms) > 0,
      packages_enabled && length(packages) > 0,
      tourist_info_enabled && length(tourist_info) > 0
    )

    socket =
      socket
      |> assign(:page, "spa")
      |> assign(:settings, settings)
      |> assign(:event_info, event_info)
      |> assign(:event_info_enabled, event_info_enabled)
      |> assign(:sessions, sessions)
      |> assign(:sessions_enabled, sessions_enabled)
      |> assign(:speakers, speakers)
      |> assign(:speakers_enabled, speakers_enabled)
      |> assign(:rooms, rooms)
      |> assign(:rooms_enabled, rooms_enabled)
      |> assign(:packages, packages)
      |> assign(:packages_enabled, packages_enabled)
      |> assign(:tourist_info, tourist_info)
      |> assign(:tourist_info_enabled, tourist_info_enabled)
      |> assign(:categories, categories)
      |> assign(:sections, sections)
      |> assign(:active_section, "inicio")
      |> assign(:inner_content, nil)

    {:ok, socket}
  end

  # Generar secciones dinámicas basadas en módulos habilitados y datos disponibles
  defp generate_dynamic_sections(show_event_info, show_speakers, show_sessions, show_rooms, show_packages, show_tourist_info) do
    base_sections = [
      %{id: "inicio", name: "Inicio", layout: "full-center", bg_color: "#F0F8FF"}
    ]

    dynamic_sections = []

    # Agregar sección de información del evento
    dynamic_sections = if show_event_info do
      dynamic_sections ++ [%{id: "evento", name: "Información del Evento", layout: "horizontal-slides", bg_color: "#E6E6FA"}]
    else
      dynamic_sections
    end

    # Agregar sección de sesiones/programa
    dynamic_sections = if show_sessions do
      dynamic_sections ++ [%{id: "sesiones", name: "Sesiones", layout: "horizontal-slides", bg_color: "#ADD8E6"}]
    else
      dynamic_sections
    end

    # Agregar sección de expositores
    dynamic_sections = if show_speakers do
      dynamic_sections ++ [%{id: "expositores", name: "Expositores", layout: "horizontal-slides", bg_color: "#98FB98"}]
    else
      dynamic_sections
    end

    # Agregar sección de salas
    dynamic_sections = if show_rooms do
      dynamic_sections ++ [%{id: "salas", name: "Salas", layout: "horizontal-slides", bg_color: "#FFE4B5"}]
    else
      dynamic_sections
    end

    # Agregar sección de paquetes
    dynamic_sections = if show_packages do
      dynamic_sections ++ [%{id: "paquetes", name: "Paquetes", layout: "horizontal-slides", bg_color: "#DDA0DD"}]
    else
      dynamic_sections
    end

    # Agregar sección de información turística
    dynamic_sections = if show_tourist_info do
      dynamic_sections ++ [%{id: "turismo", name: "Información Turística", layout: "horizontal-slides", bg_color: "#FFB6C1"}]
    else
      dynamic_sections
    end

    base_sections ++ dynamic_sections
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

  defp _generate_test_speakers() do
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
    <div class="section full-center" id="inicio" data-background-color="#F0F8FF">
      <div class="content">
        <h1><%= if @settings, do: @settings.nombre, else: "Yachanakuy - Congreso" %></h1>
        <p><%= if @settings && @settings.fecha_inicio && @settings.fecha_fin do %>
          <%= Date.to_string(@settings.fecha_inicio) %> - <%= Date.to_string(@settings.fecha_fin) %>
        <% else %>
          Fechas por confirmar
        <% end %></p>
        <p><%= if @settings && @settings.descripcion, do: @settings.descripcion, else: "Bienvenidos al congreso académico más importante del año." %></p>
      </div>
    </div>

    <!-- Sección Información del Evento (dinámica) -->
    <%= if @event_info_enabled && length(@event_info) > 0 do %>
      <div class="section horizontal-slides" id="evento" data-background-color="#E6E6FA">
        <%= for info <- @event_info do %>
          <div class="slide">
            <%= if info.imagen do %>
              <div class="mb-4">
                <img src={info.imagen} alt={info.titulo} class="w-full max-h-48 object-cover rounded-lg mx-auto">
              </div>
            <% end %>
            <h2><%= info.titulo %></h2>
            <%= if info.descripcion do %>
              <p class="text-sm"><%= info.descripcion %></p>
            <% end %>
          </div>
        <% end %>
      </div>
    <% end %>

    <!-- Sección Sesiones (dinámica) -->
    <%= if @sessions_enabled && length(@sessions) > 0 do %>
      <div class="section horizontal-slides" id="sesiones" data-background-color="#ADD8E6">
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
              <p class="text-sm"><%= session.descripcion %></p>
            <% end %>
          </div>
        <% end %>
      </div>
    <% end %>

    <!-- Sección Expositores (dinámica) -->
    <%= if @speakers_enabled && length(@speakers) > 0 do %>
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
              <p class="text-sm"><%= speaker.email %></p>
            <% end %>
            <%= if speaker.biografia do %>
              <p class="text-sm"><%= String.slice(speaker.biografia, 0..200) %><%= if String.length(speaker.biografia) > 200, do: "..." %></p>
            <% end %>
          </div>
        <% end %>
      </div>
    <% end %>

    <!-- Sección Salas (dinámica) -->
    <%= if @rooms_enabled && length(@rooms) > 0 do %>
      <div class="section horizontal-slides" id="salas" data-background-color="#FFE4B5">
        <%= for room <- @rooms do %>
          <div class="slide">
            <h2><%= room.nombre %></h2>
            <%= if room.ubicacion do %>
              <p><strong>Ubicación:</strong> <%= room.ubicacion %></p>
            <% end %>
            <%= if room.capacidad do %>
              <p><strong>Capacidad:</strong> <%= room.capacidad %> personas</p>
            <% end %>
          </div>
        <% end %>
      </div>
    <% end %>

    <!-- Sección Paquetes (dinámica) -->
    <%= if @packages_enabled && length(@packages) > 0 do %>
      <div class="section horizontal-slides" id="paquetes" data-background-color="#DDA0DD">
        <%= for package <- @packages do %>
          <div class="slide">
            <h2><%= package.titulo %></h2>
            <%= if package.descripcion do %>
              <p class="text-sm whitespace-pre-line"><%= package.descripcion %></p>
            <% end %>
          </div>
        <% end %>
      </div>
    <% end %>

    <!-- Sección Información Turística (dinámica) -->
    <%= if @tourist_info_enabled && length(@tourist_info) > 0 do %>
      <div class="section horizontal-slides" id="turismo" data-background-color="#FFB6C1">
        <%= for info <- @tourist_info do %>
          <div class="slide">
            <%= if info.imagen do %>
              <div class="mb-4">
                <img src={info.imagen} alt={info.titulo} class="w-full max-h-48 object-cover rounded-lg mx-auto">
              </div>
            <% end %>
            <h2><%= info.titulo %></h2>
            <%= if info.descripcion do %>
              <p class="text-sm"><%= info.descripcion %></p>
            <% end %>
            <%= if info.direccion do %>
              <p class="text-xs mt-2"><strong>Dirección:</strong> <%= info.direccion %></p>
            <% end %>
          </div>
        <% end %>
      </div>
    <% end %>
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
