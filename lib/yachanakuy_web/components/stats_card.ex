defmodule YachanakuyWeb.StatsCardComponent do
  use Phoenix.Component
  import Phoenix.HTML

  attr :title, :string, required: true
  attr :value, :string, required: true
  attr :icon, :string, default: nil
  attr :change, :string, default: nil
  attr :change_type, :string, default: nil # positive or negative
  attr :class, :string, default: ""

  def stats_card(assigns) do
    ~H"""
    <div class={["card bg-base-100 shadow-xl", @class]}>
      <div class="card-body">
        <div class="flex items-center">
          <div :if={@icon} class="mr-4 text-3xl">
            <%= raw("<i class='#{@icon}'></i>") %>
          </div>
          <div>
            <h3 class="text-sm font-medium text-base-content/80"><%= @title %></h3>
            <div class="mt-1 flex items-baseline">
              <p class="text-2xl font-semibold text-base-content"><%= @value %></p>
              <span :if={@change} class={["ml-2 text-sm", @change_type == "positive" && "text-success", @change_type == "negative" && "text-error"]}>
                <%= @change %>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
