defmodule YachanakuyWeb.Admin.CommissionLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Commissions
  alias Yachanakuy.Accounts

  def mount(_params, _session, socket) do
    commissions = Commissions.list_commissions()
    users = Accounts.list_users()  # Esta función necesitaría existir en el contexto de Accounts
    
    changeset = Commissions.change_commission(%Yachanakuy.Commissions.Commission{})
    
    socket = assign(socket,
      commissions: commissions,
      users: users,
      changeset: changeset,
      editing_commission: nil,
      page: "admin_commissions",
      success_message: nil
    )

    {:ok, socket}
  end

  def handle_event("save", %{"commission" => commission_params}, socket) do
    result = if socket.assigns.editing_commission do
      Commissions.update_commission(socket.assigns.editing_commission, commission_params)
    else
      Commissions.create_commission(commission_params)
    end
  
    case result do
      {:ok, _commission} ->
        commissions = Commissions.list_commissions()
        users = Accounts.list_users()
        changeset = Commissions.change_commission(%Yachanakuy.Commissions.Commission{})
  
        socket = assign(socket,
          commissions: commissions,
          users: users,
          changeset: changeset,
          editing_commission: nil,
          success_message: if(socket.assigns.editing_commission, do: "Comisión actualizada", else: "Comisión creada") <> " exitosamente"
        )
        {:noreply, socket}
  
      {:error, %Ecto.Changeset{} = changeset} ->
        socket = assign(socket, changeset: changeset)
        {:noreply, socket}
    end
  end

  def handle_event("edit", %{"id" => id}, socket) do
    commission = Commissions.get_commission!(String.to_integer(id))
    changeset = Commissions.change_commission(commission)
    
    socket = assign(socket, 
      changeset: changeset,
      editing_commission: commission
    )
    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    commission = Commissions.get_commission!(String.to_integer(id))
    {:ok, _} = Commissions.delete_commission(commission)
    
    commissions = Commissions.list_commissions()
    users = Accounts.list_users()  # Esta función debe estar implementada
    changeset = Commissions.change_commission(%Yachanakuy.Commissions.Commission{})
    
    socket = assign(socket, 
      commissions: commissions,
      users: users,
      changeset: changeset,
      editing_commission: nil,
      success_message: "Comisión eliminada exitosamente"
    )
    {:noreply, socket}
  end

  def handle_event("cancel", _params, socket) do
    changeset = Commissions.change_commission(%Yachanakuy.Commissions.Commission{})
    
    socket = assign(socket, 
      changeset: changeset,
      editing_commission: nil
    )
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-8 text-[#144D85]">Gestión de Comisiones</h1>
      
      <%= if @success_message do %>
        <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-6">
          <%= @success_message %>
        </div>
      <% end %>
      
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <!-- Formulario -->
        <div class="lg:col-span-1">
          <div class="bg-white rounded-lg shadow-md p-6">
            <h2 class="text-xl font-semibold mb-4 text-[#144D85]">
              <%= if @editing_commission, do: "Editar Comisión", else: "Nueva Comisión" %>
            </h2>
            
            <.form
              :let={f}
              for={@changeset}
              phx-submit="save"
              class="space-y-4"
            >
              <div>
                <.input field={f[:nombre]} type="text" label="Nombre"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                />
              </div>
              
              <div>
                <.input field={f[:codigo]} type="text" label="Código"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                />
              </div>
              
              <div>
                <.input field={f[:encargado_id]} type="select" label="Encargado"
                  options={ [{"No asignado", nil}] ++ Enum.map(@users, fn user -> {user.nombre_completo, user.id} end) }
                  prompt="Selecciona un encargado"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                />
              </div>
              
              <div class="pt-4">
                <button 
                  type="submit" 
                  class="w-full bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-2 px-4 rounded-md transition duration-300"
                >
                  <%= if @editing_commission, do: "Actualizar", else: "Crear" %>
                </button>
                
                <%= if @editing_commission do %>
                  <button 
                    phx-click="cancel"
                    type="button"
                    class="w-full mt-2 bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-4 rounded-md transition duration-300"
                  >
                    Cancelar
                  </button>
                <% end %>
              </div>
            </.form>
          </div>
        </div>
        
        <!-- Lista de Comisiones -->
        <div class="lg:col-span-2">
          <div class="bg-white rounded-lg shadow-md p-6">
            <h2 class="text-xl font-semibold mb-4 text-[#144D85]">Lista de Comisiones</h2>
            
            <%= if @commissions == [] do %>
              <p class="text-gray-500 text-center py-8">No hay comisiones registradas aún.</p>
            <% else %>
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Nombre</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Código</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Encargado</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Acciones</th>
                    </tr>
                  </thead>
                  <tbody class="bg-white divide-y divide-gray-200">
                    <%= for commission <- @commissions do %>
                      <tr>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="text-sm font-medium text-gray-900"><%= commission.nombre %></div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="text-sm text-gray-500"><%= commission.codigo %></div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="text-sm text-gray-500">
                            <%= if commission.encargado_id do %>
                              <%= get_user_name(@users, commission.encargado_id) %>
                            <% else %>
                              No asignado
                            <% end %>
                          </div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                          <button 
                            phx-click="edit" 
                            phx-value-id={commission.id}
                            class="text-indigo-600 hover:text-indigo-900 mr-3"
                          >
                            Editar
                          </button>
                          <button 
                            phx-click="delete" 
                            phx-value-id={commission.id}
                            class="text-red-600 hover:text-red-900"
                            phx-confirm="¿Estás seguro de que deseas eliminar esta comisión?"
                          >
                            Eliminar
                          </button>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp get_user_name(users, user_id) do
    user = Enum.find(users, &(&1.id == user_id))
    if user, do: user.nombre_completo, else: "Usuario no encontrado"
  end
end
