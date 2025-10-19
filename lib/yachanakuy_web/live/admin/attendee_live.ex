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
      search_query: "",
      selected_estado: "",
      selected_categoria: "",
      page: 1,
      page_size: 10,
      total_count: length(attendees),
      page: "admin_attendees",
      success_message: nil,
      error_message: nil
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
  
  def handle_event("edit", %{"id" => id}, socket) do
    attendee = Registration.get_attendee!(String.to_integer(id))
    changeset = Registration.change_attendee(attendee)
    
    socket = assign(socket, 
      changeset: changeset,
      editing_attendee: attendee
    )
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
          attendees = Registration.list_attendees()
          
          socket = assign(socket, 
            attendees: attendees,
            success_message: "Participante aprobado exitosamente"
          )
          {:noreply, socket}
        {:error, changeset} ->
          attendees = Registration.list_attendees()
          
          socket = assign(socket, 
            attendees: attendees,
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

  def handle_event("reject", %{"id" => id}, socket) do
    current_user = socket.assigns.current_user || get_mock_admin_user()
    
    if current_user do
      attendee = Registration.get_attendee!(String.to_integer(id))
      
      # Para rechazar, necesitamos un motivo - en un formulario real, esto vendría de un modal o formulario
      # Por ahora, pondremos un motivo predeterminado, pero idealmente se debe pedir al usuario
      case Registration.reject_attendee(attendee, current_user, "No cumple con los requisitos") do
        {:ok, _updated_attendee} ->
          attendees = Registration.list_attendees()
          
          socket = assign(socket, 
            attendees: attendees,
            success_message: "Participante rechazado exitosamente"
          )
          {:noreply, socket}
        {:error, changeset} ->
          attendees = Registration.list_attendees()
          
          socket = assign(socket, 
            attendees: attendees,
            changeset: changeset,
            error_message: "Error al rechazar el participante"
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

  def handle_event("cancel", _params, socket) do
    changeset = Registration.change_attendee(%Yachanakuy.Registration.Attendee{})
    
    socket = assign(socket, 
      changeset: changeset,
      editing_attendee: nil
    )
    {:noreply, socket}
  end

  # Helper function to get mock admin user when not in session
  defp get_mock_admin_user do
    # In a real implementation, this should get the actual current user from session
    %{id: 1, nombre_completo: "Administrador", rol: "admin"}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
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
        <h2 class="text-xl font-semibold mb-4 text-[#144D85]">Filtros de Búsqueda</h2>
        
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div>
            <label class="block text-gray-700 font-medium mb-2">Buscar</label>
            <input
              type="text"
              name="search_query"
              value={@search_query}
              phx-change="search"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
              placeholder="Nombre, email, documento..."
            />
          </div>
          
          <div>
            <label class="block text-gray-700 font-medium mb-2">Estado</label>
            <select
              name="selected_estado"
              phx-change="search"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
            >
              <option value="">Todos los estados</option>
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
              <option value="">Todas las categorías</option>
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
                        phx-click="edit" 
                        phx-value-id={attendee.id}
                        class="text-indigo-600 hover:text-indigo-900 mr-3"
                      >
                        Editar
                      </button>
                      <%= if attendee.estado == "pendiente_revision" do %>
                        <button 
                          phx-click="approve" 
                          phx-value-id={attendee.id}
                          class="text-green-600 hover:text-green-900 mr-3"
                        >
                          Aprobar
                        </button>
                        <button 
                          phx-click="reject" 
                          phx-value-id={attendee.id}
                          class="text-red-600 hover:text-red-900"
                        >
                          Rechazar
                        </button>
                      <% end %>
                      <button 
                        phx-click="delete" 
                        phx-value-id={attendee.id}
                        class="text-red-600 hover:text-red-900 ml-3"
                        phx-confirm="¿Estás seguro de que deseas eliminar este participante?"
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
    </div>
    """
  end
end
