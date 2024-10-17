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
    child_params
    |> map_keys_to_atom()
    |> child_transforms()
    |> Growth.create_child()
    |> case do
      {:ok, child} ->
        {:noreply, assign(socket, child: child, step: :measure_info)}

      {:error, _reason} ->
        {:noreply, assign(socket, step: :child_info)}
    end
  end

  @impl true
  def handle_event("save_measure", %{"measure" => measure_params}, socket) do
    measure_params
    |> map_keys_to_atom()
    |> Growth.child_measure(socket.assigns.child)
    |> case do
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

  def map_keys_to_atom(attrs) do
    # NOTE: (jpd) this is kind of a risk, because one can exploit it and exhaust all atoms
    Enum.into(attrs, %{}, fn {key, value} -> {String.to_atom(key), value} end)
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
