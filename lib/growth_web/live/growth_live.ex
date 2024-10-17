defmodule GrowthWeb.GrowthLive do
  use Phoenix.LiveView

  alias Growth.{Child, Measure}

  @impl true
  def mount(_params, _session, socket) do
    deafult_child = %Child{
      name: "",
      gender: "",
      birthday: ~D[2000-01-01]
    }

    {:ok, assign(socket, child: deafult_child, measure: %Measure{}, step: :child_info)}
  end

  @impl true
  def handle_event("save_child", %{"child" => child_params}, socket) do
    case Child.new(child_params) do
      {:ok, child} ->
        {:noreply, assign(socket, child: child, step: :measure_info)}

      {:error, _reason} ->
        {:noreply, assign(socket, step: :child_info)}
    end
  end

  @impl true
  def handle_event("save_measure", %{"measure" => measure_params}, socket) do
    case Measure.new(measure_params, socket.assigns.child) do
      {:ok, measure} ->
        {:noreply, assign(socket, measure: measure, step: :results)}

      {:error, _reason} ->
        {:noreply, assign(socket, step: :measure_info)}
    end
  end

  @impl true
  def handle_event("reset", _params, socket) do
    default_child = %Child{
      name: "",
      gender: "",
      birthday: ~D[2000-01-01]
    }

    {:noreply, assign(socket, child: default_child, measure: %Measure{}, step: :child_info)}
  end
end
