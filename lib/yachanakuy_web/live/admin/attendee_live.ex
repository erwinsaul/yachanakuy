defmodule YachanakuyWeb.Admin.AttendeeLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Registration
  alias Yachanakuy.Events

  def mount(_params, _session, socket) do
    # Inicializar con filtros vacíos y página 1
    attendees = Registration.list_attendees_with_filters(%{})
    categories = Events.list_attendee_categories()

    changeset = Registration.change_attendee(%Yachanakuy.Registration.Attendee{})

    socket = assign(socket,
      attendees: attendees,
      categories: categories,
      changeset: changeset,
      editing_attendee: nil,
      selected_attendee: nil,
      show_detail_modal: false,
      show_reject_modal: false,
      show_edit_modal: false,
      reject_reason: "",
      search_query: "",
      selected_estado: "",
      selected_categoria: "",
      search_institucion: "",
      search_telefono: "",
      page: 1,
      page_size: 10,
      total_count: length(attendees),
      current_page_name: "admin_attendees",
      success_message: nil,
      error_message: nil,
      csv_upload_errors: []
    )
    |> allow_upload(:csv_file,
      accept: ~w(.csv),
      max_entries: 1,
      max_file_size: 5_000_000
    )

    {:ok, socket}
  end

  def handle_event("save", %{"attendee" => attendee_params}, socket) do
    result = if socket.assigns.editing_attendee do
      Registration.update_attendee(socket.assigns.editing_attendee, attendee_params)
    else
      Registration.create_attendee(attendee_params)
    end

    case result do
      {:ok, _attendee} ->
        # Actualizar con los filtros actuales
        filters = %{
          search: socket.assigns.search_query,
          estado: socket.assigns.selected_estado,
          categoria_id: socket.assigns.selected_categoria,
          page: socket.assigns.page,
          page_size: socket.assigns.page_size
        }
        
        attendees = Registration.list_attendees_with_filters(filters)
        total_count = Registration.count_attendees_filtered(filters)
        categories = Events.list_attendee_categories()
        changeset = Registration.change_attendee(%Yachanakuy.Registration.Attendee{})
        
        socket = assign(socket,
          attendees: attendees,
          categories: categories,
          changeset: changeset,
          editing_attendee: nil,
          total_count: total_count,
          success_message: if(socket.assigns.editing_attendee, do: "Participante actualizado", else: "Participante creado") <> " exitosamente"
        )
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket = assign(socket, changeset: changeset)
        {:noreply, socket}
    end
  end

  def handle_event("search", %{"search_query" => search_query}, socket) do
    socket = assign(socket, search_query: search_query)
    {:noreply, socket}
  end

  def handle_event("search", %{"selected_estado" => selected_estado}, socket) do
    socket = assign(socket, selected_estado: selected_estado)
    {:noreply, socket}
  end

  def handle_event("search", %{"selected_categoria" => selected_categoria}, socket) do
    socket = assign(socket, selected_categoria: selected_categoria)
    {:noreply, socket}
  end

  def handle_event("apply_filters", _params, socket) do
    filters = %{
      search: socket.assigns.search_query,
      estado: socket.assigns.selected_estado,
      categoria_id: socket.assigns.selected_categoria,
      page: 1,  # Reset to first page when searching
      page_size: socket.assigns.page_size
    }

    attendees = Registration.list_attendees_with_filters(filters)
    total_count = Registration.count_attendees_filtered(filters)

    socket = assign(socket,
      attendees: attendees,
      total_count: total_count,
      page: 1
    )
    {:noreply, socket}
  end

  def handle_event("paginate", %{"page" => page_str}, socket) do
    page = String.to_integer(page_str)
    
    filters = %{
      search: socket.assigns.search_query,
      estado: socket.assigns.selected_estado,
      categoria_id: socket.assigns.selected_categoria,
      page: page,
      page_size: socket.assigns.page_size
    }
    
    attendees = Registration.list_attendees_with_filters(filters)
    total_count = Registration.count_attendees_filtered(filters)
    
    socket = assign(socket,
      attendees: attendees,
      total_count: total_count,
      page: page
    )
    {:noreply, socket}
  end
  
  def handle_event("show_detail", %{"id" => id}, socket) do
    attendee = Registration.get_attendee_with_details!(String.to_integer(id))

    socket = assign(socket,
      selected_attendee: attendee,
      show_detail_modal: true
    )
    {:noreply, socket}
  end

  def handle_event("close_modal", _params, socket) do
    socket = assign(socket,
      show_detail_modal: false,
      show_reject_modal: false,
      selected_attendee: nil,
      reject_reason: ""
    )
    {:noreply, socket}
  end

  def handle_event("open_reject_modal", %{"id" => id}, socket) do
    attendee = Registration.get_attendee!(String.to_integer(id))
    socket = assign(socket,
      selected_attendee: attendee,
      show_reject_modal: true
    )
    {:noreply, socket}
  end

  def handle_event("update_reject_reason", %{"reason" => reason}, socket) do
    socket = assign(socket, reject_reason: reason)
    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    attendee = Registration.get_attendee!(String.to_integer(id))
    {:ok, _} = Registration.delete_attendee(attendee)
    
    attendees = Registration.list_attendees()
    categories = Events.list_attendee_categories()
    changeset = Registration.change_attendee(%Yachanakuy.Registration.Attendee{})
    
    socket = assign(socket, 
      attendees: attendees,
      categories: categories,
      changeset: changeset,
      editing_attendee: nil,
      success_message: "Participante eliminado exitosamente"
    )
    {:noreply, socket}
  end

  def handle_event("approve", %{"id" => id}, socket) do
    # Obteniendo el usuario actual del socket
    current_user = socket.assigns.current_user || get_mock_admin_user()

    if current_user do
      attendee = Registration.get_attendee!(String.to_integer(id))

      case Registration.approve_attendee(attendee, current_user) do
        {:ok, _updated_attendee} ->
          # Actualizar con filtros actuales
          filters = %{
            search: socket.assigns.search_query,
            estado: socket.assigns.selected_estado,
            categoria_id: socket.assigns.selected_categoria,
            page: socket.assigns.page,
            page_size: socket.assigns.page_size
          }

          attendees = Registration.list_attendees_with_filters(filters)
          total_count = Registration.count_attendees_filtered(filters)

          socket = assign(socket,
            attendees: attendees,
            total_count: total_count,
            show_detail_modal: false,
            selected_attendee: nil,
            success_message: "Participante aprobado exitosamente"
          )
          {:noreply, socket}
        {:error, changeset} ->
          socket = assign(socket,
            changeset: changeset,
            error_message: "Error al aprobar el participante"
          )
          {:noreply, socket}
      end
    else
      socket = assign(socket,
        error_message: "Usuario no autenticado"
      )
      {:noreply, socket}
    end
  end

  def handle_event("reject", _params, socket) do
    current_user = socket.assigns.current_user || get_mock_admin_user()

    if current_user && socket.assigns.selected_attendee do
      attendee = socket.assigns.selected_attendee
      reason = if socket.assigns.reject_reason != "", do: socket.assigns.reject_reason, else: "No cumple con los requisitos"

      case Registration.reject_attendee(attendee, current_user, reason) do
        {:ok, _updated_attendee} ->
          # Actualizar con filtros actuales
          filters = %{
            search: socket.assigns.search_query,
            estado: socket.assigns.selected_estado,
            categoria_id: socket.assigns.selected_categoria,
            page: socket.assigns.page,
            page_size: socket.assigns.page_size
          }

          attendees = Registration.list_attendees_with_filters(filters)
          total_count = Registration.count_attendees_filtered(filters)

          socket = assign(socket,
            attendees: attendees,
            total_count: total_count,
            show_detail_modal: false,
            show_reject_modal: false,
            selected_attendee: nil,
            reject_reason: "",
            success_message: "Participante rechazado exitosamente"
          )
          {:noreply, socket}
        {:error, changeset} ->
          socket = assign(socket,
            changeset: changeset,
            error_message: "Error al rechazar el participante"
          )
          {:noreply, socket}
      end
    else
      socket = assign(socket,
        error_message: "Usuario no autenticado o participante no seleccionado"
      )
      {:noreply, socket}
    end
  end

  def handle_event("cancel", _params, socket) do
    changeset = Registration.change_attendee(%Yachanakuy.Registration.Attendee{})

    socket = assign(socket,
      changeset: changeset,
      editing_attendee: nil,
      show_edit_modal: false
    )
    {:noreply, socket}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    attendee = Registration.get_attendee!(id)
    changeset = Registration.change_attendee(attendee)

    socket = assign(socket,
      editing_attendee: attendee,
      changeset: changeset,
      show_edit_modal: true
    )
    {:noreply, socket}
  end

  def handle_event("close_edit_modal", _params, socket) do
    changeset = Registration.change_attendee(%Yachanakuy.Registration.Attendee{})

    socket = assign(socket,
      show_edit_modal: false,
      editing_attendee: nil,
      changeset: changeset
    )
    {:noreply, socket}
  end

  def handle_event("download_csv_example", _params, socket) do
    csv_content = generate_csv_example()

    {:noreply,
     socket
     |> push_event("download_csv", %{
       filename: "ejemplo_participantes.csv",
       content: csv_content
     })}
  end

  def handle_event("upload_csv", _params, socket) do
    case consume_uploaded_entries(socket, :csv_file, fn %{path: path}, _entry ->
      process_csv_file(path, socket.assigns.categories)
    end) do
      [{:ok, results}] ->
        # Actualizar lista de participantes
        filters = %{
          search: socket.assigns.search_query,
          estado: socket.assigns.selected_estado,
          categoria_id: socket.assigns.selected_categoria,
          page: socket.assigns.page,
          page_size: socket.assigns.page_size
        }

        attendees = Registration.list_attendees_with_filters(filters)
        total_count = Registration.count_attendees_filtered(filters)

        socket = assign(socket,
          attendees: attendees,
          total_count: total_count,
          success_message: "Se procesaron #{results.success} registros correctamente. #{results.errors} errores.",
          csv_upload_errors: results.error_details
        )
        {:noreply, socket}

      _ ->
        socket = assign(socket, error_message: "Error al procesar el archivo CSV")
        {:noreply, socket}
    end
  end

  # Helper function to get mock admin user when not in session
  defp get_mock_admin_user do
    # In a real implementation, this should get the actual current user from session
    %{id: 1, nombre_completo: "Administrador", rol: "admin"}
  end

  defp generate_csv_example do
    """
    nombre_completo,numero_documento,email,telefono,institucion,category_id
    Juan Pérez,12345678,juan.perez@example.com,70123456,Universidad Mayor de San Andrés,1
    María González,87654321,maria.gonzalez@example.com,71234567,Universidad Católica Boliviana,2
    Pedro Rodríguez,11223344,pedro.rodriguez@example.com,72345678,Universidad Privada Boliviana,1
    """
  end

  defp process_csv_file(path, categories) do
    results = %{success: 0, errors: 0, error_details: []}

    File.stream!(path)
    |> CSV.decode(headers: true)
    |> Enum.reduce(results, fn
      {:ok, row}, acc ->
        case create_attendee_from_csv_row(row, categories) do
          {:ok, _attendee} ->
            %{acc | success: acc.success + 1}
          {:error, reason} ->
            error_detail = "Fila #{acc.success + acc.errors + 1}: #{inspect(reason)}"
            %{acc | errors: acc.errors + 1, error_details: acc.error_details ++ [error_detail]}
        end
      {:error, _reason}, acc ->
        %{acc | errors: acc.errors + 1}
    end)
    |> then(&{:ok, &1})
  end

  defp create_attendee_from_csv_row(row, _categories) do
    attendee_params = %{
      nombre_completo: Map.get(row, "nombre_completo", ""),
      numero_documento: Map.get(row, "numero_documento", ""),
      email: Map.get(row, "email", ""),
      telefono: Map.get(row, "telefono", ""),
      institucion: Map.get(row, "institucion", ""),
      category_id: parse_integer(Map.get(row, "category_id", "")),
      estado: "pendiente_revision"
    }

    Registration.create_attendee(attendee_params)
  end

  defp parse_integer(nil), do: nil
  defp parse_integer(""), do: nil
  defp parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> nil
    end
  end
  defp parse_integer(value) when is_integer(value), do: value

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8" phx-hook="CSVDownload" id="attendee-container">
      <h1 class="text-3xl font-bold mb-8 text-[#144D85]">Gestión de Participantes</h1>
      
      <%= if @success_message do %>
        <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-6">
          <%= @success_message %>
        </div>
      <% end %>
      
      <%= if @error_message do %>
        <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6">
          <%= @error_message %>
        </div>
      <% end %>
      
      <div class="bg-white rounded-lg shadow-md p-6 mb-6">
        <div class="flex justify-between items-center mb-4">
          <h2 class="text-xl font-semibold text-[#144D85]">Filtros de Búsqueda</h2>
          <div class="flex gap-2">
            <button
              phx-click="download_csv_example"
              class="bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-4 rounded-md transition duration-300 flex items-center gap-2"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"></path>
              </svg>
              Descargar Ejemplo CSV
            </button>
            <form phx-submit="upload_csv" phx-change="validate_csv">
              <label class="bg-purple-600 hover:bg-purple-700 text-white font-bold py-2 px-4 rounded-md transition duration-300 cursor-pointer flex items-center gap-2">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"></path>
                </svg>
                Subir CSV
                <.live_file_input upload={@uploads.csv_file} class="hidden" />
              </label>
            </form>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-6 gap-4">
          <div>
            <label class="block text-gray-700 font-medium mb-2">Buscar Nombre/Doc</label>
            <input
              type="text"
              name="search_query"
              value={@search_query}
              phx-change="search"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
              placeholder="Nombre, email, doc..."
            />
          </div>

          <div>
            <label class="block text-gray-700 font-medium mb-2">Institución</label>
            <input
              type="text"
              name="search_institucion"
              value={@search_institucion}
              phx-change="search"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
              placeholder="Institución..."
            />
          </div>

          <div>
            <label class="block text-gray-700 font-medium mb-2">Teléfono</label>
            <input
              type="text"
              name="search_telefono"
              value={@search_telefono}
              phx-change="search"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
              placeholder="Teléfono..."
            />
          </div>

          <div>
            <label class="block text-gray-700 font-medium mb-2">Estado</label>
            <select
              name="selected_estado"
              phx-change="search"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
            >
              <option value="">Todos</option>
              <option value="pendiente_revision" selected={@selected_estado == "pendiente_revision"}>Pendiente</option>
              <option value="aprobado" selected={@selected_estado == "aprobado"}>Aprobado</option>
              <option value="rechazado" selected={@selected_estado == "rechazado"}>Rechazado</option>
            </select>
          </div>

          <div>
            <label class="block text-gray-700 font-medium mb-2">Categoría</label>
            <select
              name="selected_categoria"
              phx-change="search"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
            >
              <option value="">Todas</option>
              <%= for category <- @categories do %>
                <option value={category.id} selected={@selected_categoria == to_string(category.id)}><%= category.nombre %></option>
              <% end %>
            </select>
          </div>

          <div class="flex items-end">
            <button
              phx-click="apply_filters"
              class="w-full bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-2 px-4 rounded-md transition duration-300"
            >
              Filtrar
            </button>
          </div>
        </div>

        <%= if length(@csv_upload_errors) > 0 do %>
          <div class="mt-4 bg-red-50 border border-red-200 rounded-md p-4">
            <h3 class="text-red-800 font-semibold mb-2">Errores en la subida CSV:</h3>
            <ul class="list-disc list-inside text-sm text-red-700">
              <%= for error <- Enum.take(@csv_upload_errors, 10) do %>
                <li><%= error %></li>
              <% end %>
              <%= if length(@csv_upload_errors) > 10 do %>
                <li class="font-semibold">... y <%= length(@csv_upload_errors) - 10 %> errores más</li>
              <% end %>
            </ul>
          </div>
        <% end %>
      </div>
      
      <div class="bg-white rounded-lg shadow-md p-6 mb-8">
        <div class="flex justify-between items-center mb-4">
          <h2 class="text-xl font-semibold text-[#144D85]">
            Lista de Participantes 
            <span class="text-gray-500 text-base font-normal">
              (<%= @total_count %> total)
            </span>
          </h2>
        </div>
        
        <%= if @attendees == [] do %>
          <p class="text-gray-500 text-center py-8">No se encontraron participantes con los filtros aplicados.</p>
        <% else %>
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Nombre</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Categoría</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Paquete</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Estado</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Acciones</th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <%= for attendee <- @attendees do %>
                  <tr>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <div class="text-sm font-medium text-gray-900"><%= attendee.nombre_completo %></div>
                      <div class="text-sm text-gray-500">#<%= attendee.numero_documento %></div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <div class="text-sm text-gray-500">
                        <%= Enum.find(@categories, &(to_string(&1.id) == to_string(attendee.category_id))).nombre %>
                      </div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <div class="text-sm text-gray-500">
                        <%= if attendee.attendee_package && attendee.attendee_package.package do %>
                          <%= attendee.attendee_package.package.titulo %>
                        <% else %>
                          <span class="text-gray-400">Sin paquete</span>
                        <% end %>
                      </div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <div class="text-sm text-gray-500"><%= attendee.email %></div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <span class={
                        "px-2 inline-flex text-xs leading-5 font-semibold rounded-full " <>
                        case attendee.estado do
                          "aprobado" -> "bg-green-100 text-green-800"
                          "rechazado" -> "bg-red-100 text-red-800"
                          _ -> "bg-yellow-100 text-yellow-800"
                        end
                      }>
                        <%= case attendee.estado do
                          "pendiente_revision" -> "Pendiente"
                          "aprobado" -> "Aprobado"
                          "rechazado" -> "Rechazado"
                          _ -> attendee.estado
                        end %>
                      </span>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <button
                        phx-click="show_detail"
                        phx-value-id={attendee.id}
                        class="text-indigo-600 hover:text-indigo-900 mr-3"
                      >
                        Ver Detalle
                      </button>
                      <button
                        phx-click="edit"
                        phx-value-id={attendee.id}
                        class="text-green-600 hover:text-green-900 mr-3"
                      >
                        Editar
                      </button>
                      <button
                        phx-click="delete"
                        phx-value-id={attendee.id}
                        class="text-red-600 hover:text-red-900"
                        data-confirm="¿Estás seguro de que deseas eliminar este participante?"
                      >
                        Eliminar
                      </button>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
          
          <!-- Paginación -->
          <div class="mt-6 flex items-center justify-between">
            <div class="text-sm text-gray-700">
              Mostrando <%= length(@attendees) %> de <%= @total_count %> participantes
            </div>
            
            <div class="flex space-x-2">
              <%= if @page > 1 do %>
                <button 
                  phx-click="paginate" 
                  phx-value-page={@page - 1}
                  class="px-3 py-1 rounded border border-gray-300 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  Anterior
                </button>
              <% end %>
              
              <span class="px-3 py-1 rounded border border-gray-300 bg-gray-100 text-sm font-medium text-gray-700">
                Página <%= @page %>
              </span>
              
              <%= if length(@attendees) == @page_size do %>
                <button 
                  phx-click="paginate" 
                  phx-value-page={@page + 1}
                  class="px-3 py-1 rounded border border-gray-300 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  Siguiente
                </button>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>

      <!-- Modal de Detalle del Participante -->
      <%= if @show_detail_modal && @selected_attendee do %>
        <div class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50" phx-click="close_modal">
          <div class="relative top-20 mx-auto p-5 border w-11/12 max-w-4xl shadow-lg rounded-md bg-white" phx-click="stop_propagation">
            <!-- Header del Modal -->
            <div class="flex justify-between items-center pb-3 border-b">
              <h3 class="text-2xl font-bold text-[#144D85]">Detalle del Participante</h3>
              <button phx-click="close_modal" class="text-gray-400 hover:text-gray-600">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>

            <!-- Contenido del Modal -->
            <div class="mt-4 max-h-[70vh] overflow-y-auto">
              <!-- Badge de Estado -->
              <div class="mb-4">
                <span class={
                  "px-3 py-1 inline-flex text-sm leading-5 font-semibold rounded-full " <>
                  case @selected_attendee.estado do
                    "aprobado" -> "bg-green-100 text-green-800"
                    "rechazado" -> "bg-red-100 text-red-800"
                    _ -> "bg-yellow-100 text-yellow-800"
                  end
                }>
                  <%= case @selected_attendee.estado do
                    "pendiente_revision" -> "Pendiente de Revisión"
                    "aprobado" -> "Aprobado"
                    "rechazado" -> "Rechazado"
                    _ -> @selected_attendee.estado
                  end %>
                </span>
              </div>

              <!-- Grid de Información -->
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <!-- Información Personal -->
                <div class="bg-gray-50 p-4 rounded-lg">
                  <h4 class="font-semibold text-lg text-[#144D85] mb-3">Información Personal</h4>
                  <div class="space-y-2">
                    <div>
                      <span class="text-sm font-medium text-gray-600">Nombre Completo:</span>
                      <p class="text-gray-900"><%= @selected_attendee.nombre_completo %></p>
                    </div>
                    <div>
                      <span class="text-sm font-medium text-gray-600">Documento:</span>
                      <p class="text-gray-900"><%= @selected_attendee.numero_documento %></p>
                    </div>
                    <div>
                      <span class="text-sm font-medium text-gray-600">Email:</span>
                      <p class="text-gray-900"><%= @selected_attendee.email %></p>
                    </div>
                    <div>
                      <span class="text-sm font-medium text-gray-600">Teléfono:</span>
                      <p class="text-gray-900"><%= @selected_attendee.telefono || "No proporcionado" %></p>
                    </div>
                    <div>
                      <span class="text-sm font-medium text-gray-600">Institución:</span>
                      <p class="text-gray-900"><%= @selected_attendee.institucion || "No proporcionada" %></p>
                    </div>
                  </div>
                </div>

                <!-- Información del Evento -->
                <div class="bg-gray-50 p-4 rounded-lg">
                  <h4 class="font-semibold text-lg text-[#144D85] mb-3">Información del Evento</h4>
                  <div class="space-y-2">
                    <div>
                      <span class="text-sm font-medium text-gray-600">Categoría:</span>
                      <p class="text-gray-900"><%= if @selected_attendee.category, do: @selected_attendee.category.nombre, else: "No asignada" %></p>
                    </div>
                    <div>
                      <span class="text-sm font-medium text-gray-600">Paquete:</span>
                      <p class="text-gray-900">
                        <%= if @selected_attendee.attendee_package && @selected_attendee.attendee_package.package do %>
                          <%= @selected_attendee.attendee_package.package.titulo %>
                        <% else %>
                          <span class="text-gray-400">Sin paquete asignado</span>
                        <% end %>
                      </p>
                    </div>
                    <div>
                      <span class="text-sm font-medium text-gray-600">Fecha de Inscripción:</span>
                      <p class="text-gray-900"><%= Calendar.strftime(@selected_attendee.inserted_at, "%d/%m/%Y %H:%M") %></p>
                    </div>
                    <%= if @selected_attendee.estado == "rechazado" && @selected_attendee.motivo_rechazo do %>
                      <div>
                        <span class="text-sm font-medium text-red-600">Motivo de Rechazo:</span>
                        <p class="text-gray-900"><%= @selected_attendee.motivo_rechazo %></p>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>

              <!-- Archivos Adjuntos -->
              <div class="mt-6">
                <h4 class="font-semibold text-lg text-[#144D85] mb-3">Archivos Adjuntos</h4>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <!-- Foto del Participante -->
                  <div class="bg-gray-50 p-4 rounded-lg">
                    <h5 class="font-medium text-gray-700 mb-2">Foto del Participante</h5>
                    <%= if @selected_attendee.foto && @selected_attendee.foto != "" do %>
                      <a href={@selected_attendee.foto} target="_blank" class="inline-block">
                        <img src={@selected_attendee.foto} alt="Foto" class="max-w-full h-48 object-cover rounded border" />
                      </a>
                      <a href={@selected_attendee.foto} target="_blank" class="text-blue-600 hover:text-blue-800 text-sm block mt-2">
                        Ver en tamaño completo
                      </a>
                    <% else %>
                      <p class="text-gray-400 text-sm">No se ha subido foto</p>
                    <% end %>
                  </div>

                  <!-- Comprobante de Pago -->
                  <div class="bg-gray-50 p-4 rounded-lg">
                    <h5 class="font-medium text-gray-700 mb-2">Comprobante de Pago</h5>
                    <%= if @selected_attendee.comprobante_pago && @selected_attendee.comprobante_pago != "" do %>
                      <%= if String.ends_with?(@selected_attendee.comprobante_pago, [".pdf", ".PDF"]) do %>
                        <a href={@selected_attendee.comprobante_pago} target="_blank" class="inline-flex items-center px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700">
                          <svg class="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
                            <path d="M4 4a2 2 0 012-2h4.586A2 2 0 0112 2.586L15.414 6A2 2 0 0116 7.414V16a2 2 0 01-2 2H6a2 2 0 01-2-2V4z"></path>
                          </svg>
                          Ver PDF
                        </a>
                      <% else %>
                        <a href={@selected_attendee.comprobante_pago} target="_blank" class="inline-block">
                          <img src={@selected_attendee.comprobante_pago} alt="Comprobante" class="max-w-full h-48 object-cover rounded border" />
                        </a>
                        <a href={@selected_attendee.comprobante_pago} target="_blank" class="text-blue-600 hover:text-blue-800 text-sm block mt-2">
                          Ver en tamaño completo
                        </a>
                      <% end %>
                    <% else %>
                      <p class="text-gray-400 text-sm">No se ha subido comprobante</p>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>

            <!-- Footer con Botones de Acción -->
            <div class="mt-6 pt-4 border-t flex justify-end space-x-3">
              <%= if @selected_attendee.estado == "pendiente_revision" do %>
                <button
                  phx-click="approve"
                  phx-value-id={@selected_attendee.id}
                  class="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 transition duration-300"
                >
                  Aprobar Inscripción
                </button>
                <button
                  phx-click="open_reject_modal"
                  phx-value-id={@selected_attendee.id}
                  class="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 transition duration-300"
                >
                  Rechazar Inscripción
                </button>
              <% end %>
              <button
                phx-click="close_modal"
                class="px-4 py-2 bg-gray-300 text-gray-700 rounded hover:bg-gray-400 transition duration-300"
              >
                Cerrar
              </button>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Modal de Rechazo -->
      <%= if @show_reject_modal do %>
        <div class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50" phx-click="close_modal">
          <div class="relative top-20 mx-auto p-5 border w-11/12 max-w-md shadow-lg rounded-md bg-white" phx-click="stop_propagation">
            <div class="flex justify-between items-center pb-3 border-b">
              <h3 class="text-xl font-bold text-[#144D85]">Rechazar Inscripción</h3>
              <button phx-click="close_modal" class="text-gray-400 hover:text-gray-600">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>

            <div class="mt-4">
              <label class="block text-gray-700 font-medium mb-2">Motivo del Rechazo <span class="text-red-500">*</span></label>
              <textarea
                phx-change="update_reject_reason"
                phx-value-reason={@reject_reason}
                name="reason"
                rows="4"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                placeholder="Describe el motivo del rechazo..."
              ><%= @reject_reason %></textarea>
              <p class="text-sm text-gray-500 mt-1">Este motivo será registrado y podría ser enviado al participante.</p>
            </div>

            <div class="mt-6 flex justify-end space-x-3">
              <button
                phx-click="close_modal"
                class="px-4 py-2 bg-gray-300 text-gray-700 rounded hover:bg-gray-400"
              >
                Cancelar
              </button>
              <button
                phx-click="reject"
                class="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
              >
                Confirmar Rechazo
              </button>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Modal de Edición -->
      <%= if @show_edit_modal && @editing_attendee do %>
        <div class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50" phx-click="close_edit_modal">
          <div class="relative top-10 mx-auto p-5 border w-11/12 max-w-3xl shadow-lg rounded-md bg-white" phx-click="stop_propagation">
            <div class="flex justify-between items-center pb-3 border-b">
              <h3 class="text-xl font-bold text-[#144D85]">Editar Participante</h3>
              <button phx-click="close_edit_modal" class="text-gray-400 hover:text-gray-600">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>

            <.form for={@changeset} phx-submit="save" class="mt-4">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-gray-700 font-medium mb-2">Nombre Completo <span class="text-red-500">*</span></label>
                  <input
                    type="text"
                    name="attendee[nombre_completo]"
                    value={if @editing_attendee, do: @editing_attendee.nombre_completo, else: ""}
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                    required
                  />
                </div>

                <div>
                  <label class="block text-gray-700 font-medium mb-2">Número de Documento <span class="text-red-500">*</span></label>
                  <input
                    type="text"
                    name="attendee[numero_documento]"
                    value={if @editing_attendee, do: @editing_attendee.numero_documento, else: ""}
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                    required
                  />
                </div>

                <div>
                  <label class="block text-gray-700 font-medium mb-2">Email <span class="text-red-500">*</span></label>
                  <input
                    type="email"
                    name="attendee[email]"
                    value={if @editing_attendee, do: @editing_attendee.email, else: ""}
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                    required
                  />
                </div>

                <div>
                  <label class="block text-gray-700 font-medium mb-2">Teléfono</label>
                  <input
                    type="text"
                    name="attendee[telefono]"
                    value={if @editing_attendee, do: @editing_attendee.telefono, else: ""}
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                  />
                </div>

                <div class="md:col-span-2">
                  <label class="block text-gray-700 font-medium mb-2">Institución</label>
                  <input
                    type="text"
                    name="attendee[institucion]"
                    value={if @editing_attendee, do: @editing_attendee.institucion, else: ""}
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                  />
                </div>

                <div>
                  <label class="block text-gray-700 font-medium mb-2">Categoría <span class="text-red-500">*</span></label>
                  <select
                    name="attendee[category_id]"
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                    required
                  >
                    <option value="">Selecciona una categoría</option>
                    <%= for category <- @categories do %>
                      <option value={category.id} selected={@editing_attendee && @editing_attendee.category_id == category.id}>
                        <%= category.nombre %>
                      </option>
                    <% end %>
                  </select>
                </div>

                <div>
                  <label class="block text-gray-700 font-medium mb-2">Estado</label>
                  <select
                    name="attendee[estado]"
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                  >
                    <option value="pendiente_revision" selected={@editing_attendee && @editing_attendee.estado == "pendiente_revision"}>Pendiente</option>
                    <option value="aprobado" selected={@editing_attendee && @editing_attendee.estado == "aprobado"}>Aprobado</option>
                    <option value="rechazado" selected={@editing_attendee && @editing_attendee.estado == "rechazado"}>Rechazado</option>
                  </select>
                </div>
              </div>

              <div class="mt-6 flex justify-end space-x-3">
                <button
                  type="button"
                  phx-click="close_edit_modal"
                  class="px-4 py-2 bg-gray-300 text-gray-700 rounded hover:bg-gray-400"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  class="px-4 py-2 bg-[#144D85] text-white rounded hover:bg-[#0d3a66]"
                >
                  Guardar Cambios
                </button>
              </div>
            </.form>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
