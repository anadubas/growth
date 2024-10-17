defmodule GrowthWeb.GrowthLive do
  use Phoenix.LiveView

  alias Growth

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, growth: %{}, loading: false)}
  end

  @impl true
  def handle_event("base_info", %{"growth" => growth_params}, socket) do
    case Growth.new(growth_params) do
      {:ok, growth} ->
        {:noreply, assign(socket, growth: growth, loading: false)}

      {:error, _reason} ->
        {:noreply, assign(socket, loading: false)}
    end
  end
end
