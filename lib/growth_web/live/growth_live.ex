defmodule GrowthWeb.GrowthLive do
  use Phoenix.LiveView

  alias Growth.Child
  alias Growth.LoadReferenceChart
  alias Growth.Measure
  alias GrowthWeb.Form

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       child: default_child(),
       measure: %Measure{},
       charts: nil,
       child_form: Form.child_form(%{}, :child),
       measure_form: Form.measure_form(%{}, :measure),
       step: :child_info
     )}
  end

  @impl true
  def handle_event("validate_child", %{"child" => params}, socket) do
    form = Form.child_form(params, :child)

    {:noreply, assign(socket, child_form: form)}
  end

  @impl true
  def handle_event("validate_measure", %{"measure" => params}, socket) do
    form = Form.measure_form(params, :measure)

    {:noreply, assign(socket, measure_form: form)}
  end

  @impl true
  def handle_event("save_child", %{"child" => params}, socket) do
    with %Zoi.Context{valid?: true} = ctx <- Form.child_parse(params),
         {:ok, child} <- Growth.create_child(ctx.parsed) do
      {:noreply,
       assign(
         socket,
         child: child,
         child_form: Form.child_form(ctx, :child),
         step: :measure_info
       )}
    else
      %Zoi.Context{} = ctx ->
        {:noreply, assign(socket, child_form: Form.child_form(ctx, :child, action: :validate))}

      {:error, errors} ->
        ctx =
          params
          |> Form.child_parse()
          |> then(
            &Enum.reduce(errors, &1, fn error, ctx -> Zoi.Context.add_error(ctx, error) end)
          )

        {:noreply, assign(socket, child_form: Form.child_form(ctx, :child, action: :validate))}
    end
  end

  @impl true
  def handle_event("save_measure", %{"measure" => params}, socket) do
    with %Zoi.Context{valid?: true} = ctx <- Form.measure_parse(params),
         {:ok, measure} <- Growth.child_measure(ctx.parsed, socket.assigns.child) do
      charts = build_all_charts(measure)

      {:noreply,
       assign(socket,
         measure: measure,
         measure_form: Form.measure_form(ctx, :measure),
         charts: charts,
         step: :results
       )}
    else
      %Zoi.Context{} = ctx ->
        {:noreply,
         assign(socket, measure_form: Form.measure_form(ctx, :measure, action: :validate))}

      {:error, errors} ->
        ctx =
          params
          |> Form.measure_parse()
          |> then(
            &Enum.reduce(errors, &1, fn error, ctx -> Zoi.Context.add_error(ctx, error) end)
          )

        {:noreply,
         assign(socket, measure_form: Form.measure_form(ctx, :measure, action: :validate))}
    end
  end

  @impl true
  def handle_event("reset", _params, socket) do
    {:noreply,
     assign(socket,
       child: default_child(),
       measure: %Measure{},
       charts: nil,
       child_form: Form.child_form(%{}, :child),
       measure_form: Form.measure_form(%{}, :measure),
       step: :child_info
     )}
  end

  defp default_child, do: %Child{name: "", gender: "", birthday: Date.utc_today()}

  defp build_all_charts(%Measure{} = measure) do
    height = build_chart_data(:height, measure)
    weight = build_chart_data(:weight, measure)
    bmi = build_chart_data(:bmi, measure)
    head_circumference = build_chart_data(:head_circumference, measure)

    %{
      height: height,
      weight: weight,
      bmi: bmi,
      head_circumference: head_circumference
    }
  end

  defp build_chart_data(
         type,
         %Measure{
           child: %Child{gender: gender, age_in_months: reference_age_in_months},
           results: results
         } = measure
       ) do
    age_range_in_months = 5
    age_subdivisions = 10

    value = Map.get(measure, type)

    default_data = %{
      child: [%{x: reference_age_in_months, y: value}],
      labels: [],
      sd3: [],
      sd2: [],
      sd1: [],
      sd3neg: [],
      sd2neg: [],
      sd1neg: [],
      sd0: []
    }

    with true <- results |> Map.get(type, %{}) |> Map.get(:available?, false),
         {:ok, data} <-
           LoadReferenceChart.load_data(
             type,
             gender,
             reference_age_in_months,
             age_range_in_months,
             age_subdivisions
           ) do
      Enum.reduce(data, default_data, fn point, acc ->
        %{
          acc
          | labels: [point.age | acc.labels],
            sd3neg: [%{x: point.age, y: point.sd3neg} | acc.sd3neg],
            sd2neg: [%{x: point.age, y: point.sd2neg} | acc.sd2neg],
            sd1neg: [%{x: point.age, y: point.sd1neg} | acc.sd1neg],
            sd0: [%{x: point.age, y: point.sd0} | acc.sd0],
            sd1: [%{x: point.age, y: point.sd1} | acc.sd1],
            sd2: [%{x: point.age, y: point.sd2} | acc.sd2],
            sd3: [%{x: point.age, y: point.sd3} | acc.sd3]
        }
      end)
    else
      false ->
        default_data

      {:error, _} ->
        default_data
    end
  end
end
