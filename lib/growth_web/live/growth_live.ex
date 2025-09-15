defmodule GrowthWeb.GrowthLive do
  use Phoenix.LiveView

  alias Growth.{Child, Measure}

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

    IO.inspect(chart_height, label: "Chart Data")
    IO.inspect(chart_weight, label: "Chart Data")
    IO.inspect(chart_bmi, label: "Chart Data")
    IO.inspect(chart_hc, label: "Chart Data")

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

  defp build_chart_data(type, child, value) do
    age_range = 0..24 |> Enum.to_list()
    child_age = Growth.Calculate.in_months_decimal(child.birthday, Date.utc_today())

    Enum.reduce(
      age_range,
      %{
        labels: [],
        child: [],
        sd3neg: [],
        sd2neg: [],
        sd1neg: [],
        m: [],
        sd1: [],
        sd2: [],
        sd3: []
      },
      fn age, acc ->
        case Growth.LoadReference.load_data(type, %Growth.Child{
               gender: child.gender,
               age_in_months: child_age,
               name: child.name,
               birthday: child.birthday
             }) do
          {:ok, data} ->
            %{
              acc
              | labels: acc.labels ++ [age],
                sd3neg: acc.sd3neg ++ [%{x: age, y: data.sd3neg}],
                sd2neg: acc.sd2neg ++ [%{x: age, y: data.sd2neg}],
                sd1neg: acc.sd1neg ++ [%{x: age, y: data.sd1neg}],
                m: acc.m ++ [%{x: age, y: data.m}],
                sd1: acc.sd1 ++ [%{x: age, y: data.sd1}],
                sd2: acc.sd2 ++ [%{x: age, y: data.sd2}],
                sd3: acc.sd3 ++ [%{x: age, y: data.sd3}]
            }

          {:error, _} ->
            acc
        end
      end
    )
    |> Map.put(:child, [%{x: child.age_in_months, y: value}])
  end
end
