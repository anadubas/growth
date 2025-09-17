defmodule GrowthWeb.GrowthLive do
  use Phoenix.LiveView

  alias Growth.Child
  alias Growth.LoadReferenceChart
  alias Growth.Measure

  @impl true
  def mount(_params, _session, socket) do
    default_child = %Child{
      name: "",
      gender: "",
      birthday: ~D[2000-01-01]
    }

    {:ok, assign(socket, child: default_child, measure: %Measure{}, step: :child_info)}
  end

  @impl true
  def handle_event("save_child", %{"child" => child_params}, socket) do
    {:ok, child} =
      child_params
      |> map_keys_to_atom()
      |> child_transforms()
      |> Growth.create_child()

    {:noreply, assign(socket, child: child, step: :measure_info)}
  end

  @impl true
  def handle_event("save_measure", %{"measure" => measure_params}, socket) do
    {:ok, measure} =
      measure_params
      |> map_keys_to_atom()
      |> measure_transforms()
      |> Growth.child_measure(socket.assigns.child)

    chart_height = build_chart_data(:height, socket.assigns.child, measure.height)
    chart_weight = build_chart_data(:weight, socket.assigns.child, measure.weight)
    chart_bmi = build_chart_data(:bmi, socket.assigns.child, measure.bmi)

    chart_hc =
      build_chart_data(:head_circumference, socket.assigns.child, measure.head_circumference)

    {:noreply,
     assign(socket,
       measure: measure,
       step: :results,
       charts: %{
         height: chart_height,
         weight: chart_weight,
         bmi: chart_bmi,
         head_circ: chart_hc
       },
       child: socket.assigns.child
     )}
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

  def measure_transforms(attrs) do
    Enum.into(attrs, %{}, fn {key, value} ->
      case Float.parse(value) do
        {converted_value, _} ->
          {key, converted_value}

        _ ->
          {key, nil}
      end
    end)
  end

  defp build_chart_data(
         type,
         %Child{gender: gender, age_in_months: reference_age_in_months},
         value
       ) do
    age_range_in_months = 5
    age_subdivisions = 10

    default_data = %{
      child: [%{x: reference_age_in_months, y: value}],
      labels: [],
      sd3: [],
      sd2: [],
      sd1: [],
      sd3neg: [],
      sd2neg: [],
      sd1neg: [],
      m: []
    }

    case LoadReferenceChart.load_data(
           type,
           gender,
           reference_age_in_months,
           age_range_in_months,
           age_subdivisions
         ) do
      {:ok, data} ->
        Enum.reduce(data, default_data, fn point, acc ->
          %{
            acc
            | labels: [point.age | acc.labels],
              sd3neg: [%{x: point.age, y: point.sd3neg} | acc.sd3neg],
              sd2neg: [%{x: point.age, y: point.sd2neg} | acc.sd2neg],
              sd1neg: [%{x: point.age, y: point.sd1neg} | acc.sd1neg],
              m: [%{x: point.age, y: point.m} | acc.m],
              sd1: [%{x: point.age, y: point.sd1} | acc.sd1],
              sd2: [%{x: point.age, y: point.sd2} | acc.sd2],
              sd3: [%{x: point.age, y: point.sd3} | acc.sd3]
          }
        end)

      {:error, _} ->
        default_data
    end
  end
end
