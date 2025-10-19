defmodule YachanakuyWeb.Public.RegistrationLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Registration
  alias Yachanakuy.Events
  alias Yachanakuy.Uploads.Handler

  def mount(_params, _session, socket) do
    # Verificar si las inscripciones están abiertas
    settings = Events.get_congress_settings()

    if settings && !settings.inscripciones_abiertas do
      socket = assign(socket, error: "Las inscripciones no están abiertas en este momento.")
      {:ok, socket}
    else
      categories = Events.list_attendee_categories()

      socket = socket
      |> assign(
        current_step: 1,
        registration_data: %{
          institucion: "",
          comprobante_pago: nil,
          cantidad_personas: 1,
          participantes: []
        },
        categories: categories,
        settings: settings,
        page: "inscripcion",
        error: nil,
        success: nil
      )
      |> allow_upload(:comprobante_pago,
        accept: ~w(.jpg .jpeg .png .pdf),
        max_entries: 1,
        max_file_size: 10_000_000
      )

      {:ok, socket}
    end
  end

  def handle_event("next_step", _params, socket) do
    current_step = socket.assigns.current_step
    
    case current_step do
      1 -> 
        # Validar Paso 1
        registration_data = socket.assigns.registration_data
        if registration_data.institucion != "" and registration_data.cantidad_personas > 0 and has_comprobante_pago?(socket) do
          new_step = current_step + 1
          socket = assign(socket, current_step: new_step)
          {:noreply, socket}
        else
          socket = assign(socket, error: "Por favor completa todos los campos requeridos en el Paso 1.")
          {:noreply, socket}
        end
      2 -> 
        # Validar Paso 2
        registration_data = socket.assigns.registration_data
        if validate_participantes_data(registration_data) do
          new_step = current_step + 1
          socket = assign(socket, current_step: new_step)
          {:noreply, socket}
        else
          socket = assign(socket, error: "Por favor completa todos los campos requeridos para cada participante en el Paso 2.")
          {:noreply, socket}
        end
      _ ->
        new_step = current_step + 1
        socket = assign(socket, current_step: new_step)
        {:noreply, socket}
    end
  end

  def handle_event("prev_step", _params, socket) do
    current_step = socket.assigns.current_step
    new_step = max(1, current_step - 1)

    socket = assign(socket, current_step: new_step)

    {:noreply, socket}
  end

  defp has_comprobante_pago?(socket) do
    # Verificar si hay un archivo subido o si ya se había subido previamente
    comprobante_pago = socket.assigns.registration_data.comprobante_pago
    length(socket.assigns.uploads.comprobante_pago.entries) > 0 or comprobante_pago != nil
  end

  defp validate_participantes_data(registration_data) do
    # Verificar que cada participante tenga los campos requeridos
    required_fields = [:nombre_completo, :numero_documento, :email, :category_id]
    
    registration_data.participantes
    |> Enum.all?(fn participante ->
      Enum.all?(required_fields, fn field ->
        value = Map.get(participante, field)
        value != nil and value != ""
      end)
    end)
  end

  def handle_event("update_registration_data", %{"registration" => params}, socket) do
    registration_data = socket.assigns.registration_data

    updated_registration_data = 
      registration_data
      |> Map.put(:institucion, Map.get(params, "institucion", ""))
      |> Map.put(:cantidad_personas, String.to_integer(Map.get(params, "cantidad_personas", "1")))

    # Ajustar la longitud de la lista de participantes según la cantidad
    participantes = adjust_participantes_list(updated_registration_data.participantes, updated_registration_data.cantidad_personas)

    updated_registration_data = Map.put(updated_registration_data, :participantes, participantes)
    
    socket = assign(socket, registration_data: updated_registration_data)

    {:noreply, socket}
  end

  def handle_event("update_participante_data", %{"participante_index" => index_str, "participante" => params}, socket) do
    index = String.to_integer(index_str)
    participante_data = %{
      nombre_completo: Map.get(params, "nombre_completo", ""),
      numero_documento: Map.get(params, "numero_documento", ""),
      email: Map.get(params, "email", ""),
      telefono: Map.get(params, "telefono", ""),
      foto: Map.get(params, "foto", ""),
      category_id: Map.get(params, "category_id", "")
    }

    registration_data = socket.assigns.registration_data
    updated_participantes = List.update_at(registration_data.participantes, index, fn _ -> participante_data end)
    updated_registration_data = Map.put(registration_data, :participantes, updated_participantes)
    
    socket = assign(socket, registration_data: updated_registration_data)

    {:noreply, socket}
  end

  defp adjust_participantes_list(participantes, cantidad_personas) do
    current_length = length(participantes)
    
    if current_length < cantidad_personas do
      # Agregar participantes vacíos
      empty_participante = %{
        nombre_completo: "",
        numero_documento: "",
        email: "",
        telefono: "",
        foto: "",
        category_id: ""
      }
      participantes ++ List.duplicate(empty_participante, cantidad_personas - current_length)
    else
      # Quitar participantes extras
      Enum.take(participantes, cantidad_personas)
    end
  end

  def handle_event("register_attendees", _params, socket) do
    # Procesar el comprobante de pago
    comprobante_pago_path = case consume_uploaded_entries(socket, :comprobante_pago, fn (entry, _entry_data) ->
      Handler.upload_document(%{filename: Path.basename(entry.client_name), path: entry.path}, "comprobante_pago")
    end) do
      [{:ok, path} | _] -> path
      _ -> nil
    end

    registration_data = socket.assigns.registration_data
    updated_registration_data = Map.put(registration_data, :comprobante_pago, comprobante_pago_path)

    # Registrar a todos los participantes
    results = for participante <- updated_registration_data.participantes do
      attendee_params = %{
        nombre_completo: participante.nombre_completo,
        numero_documento: participante.numero_documento,
        email: participante.email,
        telefono: participante.telefono,
        institucion: updated_registration_data.institucion,
        foto: participante.foto,
        category_id: participante.category_id,
        comprobante_pago: updated_registration_data.comprobante_pago,
        estado: "pendiente_revision"
      }

      Registration.create_attendee(attendee_params)
    end

    # Verificar si todos se registraron correctamente
    case Enum.find(results, fn {status, _} -> status == :error end) do
      nil -> 
        # Todos los registros fueron exitosos
        socket = socket
        |> assign(
          success: "¡Inscripciones completadas exitosamente! Revisa tu correo para más instrucciones.",
          current_step: nil
        )
        |> put_flash(:info, "¡Inscripciones completadas exitosamente! Revisa tu correo para más instrucciones.")
        
        {:noreply, push_navigate(socket, to: "/")}
      _ -> 
        # Hubo al menos un error
        _error_changeset = 
          results
          |> Enum.find(fn {status, _} -> status == :error end)
          |> elem(1)
        
        socket = assign(socket, error: "Hubo un error al registrar a uno o más participantes.")
        {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-blue-900 to-indigo-900 py-8">
      <div class="container mx-auto px-4 py-8 max-w-4xl">
        <%= if @error do %>
          <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6">
            <%= @error %>
          </div>
        <% else %>
          <%= if @current_step do %>
            <div class="bg-white rounded-lg shadow-lg p-6">
              <!-- Indicador de pasos -->
              <div class="mb-8">
                <h1 class="text-3xl font-bold mb-4 text-[#144D85]">Formulario de Inscripción</h1>
                
                <!-- Barra de progreso -->
                <div class="flex items-center justify-between mb-6">
                  <div class="flex flex-col items-center">
                    <div class={"w-8 h-8 rounded-full flex items-center justify-center " <> 
                      if(@current_step >= 1, do: "bg-[#144D85] text-white", else: "bg-gray-400 text-white")}>
                      1
                    </div>
                    <span class="text-xs mt-1 text-center text-white">Información General</span>
                  </div>
                  
                  <div class="flex-1 h-1 bg-gray-400 mx-2">
                    <div class={"h-full " <> if(@current_step >= 2, do: "bg-[#144D85]", else: "bg-gray-400")}></div>
                  </div>
                  
                  <div class="flex flex-col items-center">
                    <div class={"w-8 h-8 rounded-full flex items-center justify-center " <> 
                      if(@current_step >= 2, do: "bg-[#144D85] text-white", else: "bg-gray-400 text-white")}>
                      2
                    </div>
                    <span class="text-xs mt-1 text-center text-white">Datos de Participantes</span>
                  </div>
                  
                  <div class="flex-1 h-1 bg-gray-400 mx-2">
                    <div class={"h-full " <> if(@current_step >= 3, do: "bg-[#144D85]", else: "bg-gray-400")}></div>
                  </div>
                  
                  <div class="flex flex-col items-center">
                    <div class={"w-8 h-8 rounded-full flex items-center justify-center " <> 
                      if(@current_step >= 3, do: "bg-[#144D85] text-white", else: "bg-gray-400 text-white")}>
                      3
                    </div>
                    <span class="text-xs mt-1 text-center text-white">Resumen</span>
                  </div>
                </div>
              </div>

              <!-- Contenido del paso actual -->
              <div class="step-content">
                <%= case @current_step do %>
                  <% 1 -> %>
                    <%= render_step1(assigns) %>
                  <% 2 -> %>
                    <%= render_step2(assigns) %>
                  <% 3 -> %>
                    <%= render_step3(assigns) %>
                <% end %>
              </div>
            </div>
          <% else %>
            <!-- Vista de éxito -->
            <div class="bg-white rounded-lg shadow-lg p-6">
              <h1 class="text-3xl font-bold mb-4 text-[#144D85]">¡Inscripción completa!</h1>
              <p class="text-green-600">Tus participantes han sido registrados exitosamente.</p>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  defp render_step1(assigns) do
    ~H"""
    <div>
      <h2 class="text-xl font-semibold mb-4 text-[#144D85]">Paso 1: Información General</h2>
      <p class="text-gray-600 mb-6">Por favor, completa la información general de la inscripción.</p>
      
      <form phx-change="update_registration_data" class="space-y-4">
        <div>
          <label class="block text-gray-700 font-medium mb-2">Institución <span class="text-red-500">*</span></label>
          <input 
            type="text" 
            name="registration[institucion]" 
            value={@registration_data.institucion}
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
            required
          />
        </div>

        <div>
          <label class="block text-gray-700 font-medium mb-2">Cantidad de personas a registrar <span class="text-red-500">*</span></label>
          <input 
            type="number" 
            name="registration[cantidad_personas]" 
            value={@registration_data.cantidad_personas}
            min="1" 
            max="50"
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
            required
          />
          <p class="text-sm text-gray-500 mt-1">Indica cuántas personas se registrarán en esta inscripción</p>
        </div>

        <div class="mt-6">
          <label class="block text-gray-700 font-medium mb-2">Comprobante de pago <span class="text-red-500">*</span></label>
          <.live_file_input upload={@uploads.comprobante_pago} 
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
          />
          <p class="text-sm text-gray-500 mt-1">Adjunta el comprobante de pago (JPG, PNG, PDF, máximo 10MB)</p>
          <div :for={err <- upload_errors(@uploads.comprobante_pago)} class="text-sm text-red-600 mt-1"><%= err %></div>
        </div>

        <div class="flex justify-end mt-8">
          <button
            type="button"
            phx-click="next_step"
            class="bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-2 px-6 rounded-md transition duration-300"
          >
            Siguiente
          </button>
        </div>
      </form>
    </div>
    """
  end

  defp render_step2(assigns) do
    ~H"""
    <div>
      <h2 class="text-xl font-semibold mb-4 text-[#144D85]">Paso 2: Datos de los Participantes</h2>
      <p class="text-gray-600 mb-6">Ingresa los datos de las <%= @registration_data.cantidad_personas %> persona(s) a registrar.</p>
      
      <div class="space-y-6">
        <%= for {participante, index} <- Enum.with_index(@registration_data.participantes) do %>
          <div class="border border-gray-200 rounded-lg p-4 bg-gray-50">
            <h3 class="text-lg font-medium mb-3 text-[#144D85]">Participante <%= index + 1 %></h3>
            
            <form phx-change={"update_participante_data"} phx-target={index} class="space-y-4">
              <input type="hidden" name="participante_index" value={index} />
              
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-gray-700 font-medium mb-2">Nombre completo <span class="text-red-500">*</span></label>
                  <input 
                    type="text" 
                    name="participante[nombre_completo]" 
                    value={participante.nombre_completo}
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                    required
                  />
                </div>

                <div>
                  <label class="block text-gray-700 font-medium mb-2">Número de documento <span class="text-red-500">*</span></label>
                  <input 
                    type="text" 
                    name="participante[numero_documento]" 
                    value={participante.numero_documento}
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                    required
                  />
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-gray-700 font-medium mb-2">Email <span class="text-red-500">*</span></label>
                  <input 
                    type="email" 
                    name="participante[email]" 
                    value={participante.email}
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                    required
                  />
                  <p class="text-sm text-gray-500 mt-1">Es importante que proporciones un email válido, ya que allí recibirás tus credenciales y otros datos importantes.</p>
                </div>

                <div>
                  <label class="block text-gray-700 font-medium mb-2">Teléfono</label>
                  <input 
                    type="text" 
                    name="participante[telefono]" 
                    value={participante.telefono}
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                  />
                </div>
              </div>

              <div>
                <label class="block text-gray-700 font-medium mb-2">Foto (opcional)</label>
                <input 
                  type="text" 
                  name="participante[foto]" 
                  value={participante.foto}
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                  placeholder="URL de la foto o dejar vacío"
                />
              </div>

              <div>
                <label class="block text-gray-700 font-medium mb-2">Categoría de participante <span class="text-red-500">*</span></label>
                <select 
                  name="participante[category_id]" 
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                  value={participante.category_id}
                  required
                >
                  <option value="">Selecciona una categoría</option>
                  <%= for category <- @categories do %>
                    <option value={category.id} selected={participante.category_id == category.id}><%= category.nombre %></option>
                  <% end %>
                </select>
              </div>
            </form>
          </div>
        <% end %>

        <div class="flex justify-between mt-8">
          <button
            type="button"
            phx-click="prev_step"
            class="bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-6 rounded-md transition duration-300"
          >
            Anterior
          </button>
          
          <button
            type="button"
            phx-click="next_step"
            class="bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-2 px-6 rounded-md transition duration-300"
          >
            Siguiente
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp render_step3(assigns) do
    ~H"""
    <div>
      <h2 class="text-xl font-semibold mb-4 text-[#144D85]">Paso 3: Resumen y Confirmación</h2>
      <p class="text-gray-600 mb-6">Revisa los datos antes de completar la inscripción.</p>
      
      <div class="space-y-6">
        <div class="border border-gray-200 rounded-lg p-4">
          <h3 class="text-lg font-medium mb-3 text-[#144D85]">Información General</h3>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <p class="font-medium">Institución:</p>
              <p><%= @registration_data.institucion %></p>
            </div>
            <div>
              <p class="font-medium">Número de participantes:</p>
              <p><%= @registration_data.cantidad_personas %></p>
            </div>
          </div>
        </div>

        <%= for {participante, index} <- Enum.with_index(@registration_data.participantes) do %>
          <div class="border border-gray-200 rounded-lg p-4">
            <h3 class="text-lg font-medium mb-3 text-[#144D85]">Participante <%= index + 1 %></h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <p class="font-medium">Nombre completo:</p>
                <p><%= participante.nombre_completo %></p>
              </div>
              <div>
                <p class="font-medium">Número de documento:</p>
                <p><%= participante.numero_documento %></p>
              </div>
              <div>
                <p class="font-medium">Email:</p>
                <p><%= participante.email %></p>
              </div>
              <div>
                <p class="font-medium">Teléfono:</p>
                <p><%= participante.telefono %></p>
              </div>
              <div>
                <p class="font-medium">Categoría:</p>
                <p>
                  <%= case Enum.find(@categories, fn c -> c.id == participante.category_id end) do %>
                    <% nil -> %>
                      <%= "No seleccionada" %>
                    <% category -> %>
                      <%= category.nombre %>
                  <% end %>
                </p>
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <div class="flex justify-between mt-8">
        <button
          type="button"
          phx-click="prev_step"
          class="bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-6 rounded-md transition duration-300"
        >
          Anterior
        </button>
        
        <button
          type="button"
          phx-click="register_attendees"
          class="bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-6 rounded-md transition duration-300"
        >
          Registrar Participantes
        </button>
      </div>
    </div>
    """
  end

end