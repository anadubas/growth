defmodule GrowthWeb.GrowthLive do
  use Phoenix.LiveView

  alias Growth

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, child: %{}, loading: false)}
  end

  @impl true
  def handle_event("base_info", %{"child" => child_params}, socket) do
    case Growth.create_child(child_params) do
      {:ok, child} ->
        {:noreply, assign(socket, child: child, loading: false)}
      {:error, _reason} ->
        {:noreply, assign(socket, loading: false)}
    end
  end

  @impl true
  def handle_event("measure_info", %{"child" => child, "measure" => measure_params}, socket) do
    case Growth.child_measure(measure_params, child) do
      {:ok, measure} ->
        {:noreply, assign(socket, %{child: child, measure: measure}, loading: false)}
      {:error, _reason} ->
        {:noreply, assign(socket, child: child, loading: false)}
    end
  end
end
