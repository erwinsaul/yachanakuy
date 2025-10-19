defmodule YachanakuyWeb.TableComponent do
  use Phoenix.Component
  alias YachanakuyWeb.CoreComponents

  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :columns, :list, required: true
  attr :row_id, :any, default: nil
  attr :row_click, :any, default: nil
  attr :searchable, :boolean, default: false
  attr :sortable, :boolean, default: false
  attr :class, :string, default: ""
  attr :row_class, :any, default: nil

  def table(assigns) do
    ~H"""
    <div class={@class}>
      <div :if={@searchable} class="mb-4">
        <input
          type="text"
          placeholder="Buscar..."
          class="input input-bordered w-full max-w-xs"
          phx-debounce="300"
          phx-target={@id}
          phx-change="search"
        />
      </div>
      
      <CoreComponents.table id={@id} rows={@rows} row_id={@row_id} row_click={@row_click}>
        <:col :let={row} :for={column <- @columns} label={column[:label]}>
          <%= if column[:format] do %>
            <%= column[:format].(row) %>
          <% else %>
            <%= Map.get(row, column[:key]) %>
          <% end %>
        </:col>
      </CoreComponents.table>
    </div>
    """
  end
end
