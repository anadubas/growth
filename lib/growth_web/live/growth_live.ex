defmodule GrowthWeb.GrowthLive do
  use Phoenix.LiveView

  alias Growth

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, child: %{}, loading: false)}
  end

  @impl true
  def handle_event("base_info", %{"child" => child_params}, socket) do
    child_params
    |> map_keys_to_atom()
    |> child_transforms()
    |> Growth.create_child()
    |> case do
      {:ok, child} ->
        {:noreply, assign(socket, child: child, loading: false)}

      {:error, _reason} ->
        {:noreply, assign(socket, loading: false)}
    end
  end

  @impl true
  def handle_event("measure_info", %{"measure" => measure_params}, socket) do
    measure_params
    |> map_keys_to_atom()
    |> Growth.child_measure(Map.get(socket, :child))
    |> case do
      {:ok, measure} ->
        {:noreply, assign(socket, measure: measure, loading: false)}

      {:error, _reason} ->
        {:noreply, assign(socket, loading: false)}
    end
  end

  def map_keys_to_atom(attrs) do
    Enum.into(attrs, %{}, fn {key, value} -> {String.to_existing_atom(key), value} end)
  end

  def child_transforms(attrs) do
    Enum.into(attrs, %{}, fn
      {:birthday, value} ->
        {:birthday, Date.from_iso8601!(value)}

      {key, value} ->
        {key, value}
    end)
  end
end
