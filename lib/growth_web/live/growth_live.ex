defmodule GrowthWeb.GrowthLive do
  use Phoenix.LiveView

  import GrowthWeb.CoreComponents, only: [icon: 1]
  import GrowthWeb.MeasureFormComponent, only: [measure_row: 1]

  alias Growth.Child
  alias Growth.LoadReferenceChart
  alias GrowthWeb.Form
  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, initial_assigns())}
  end

  # --- child step -------------------------------------------------------------

  @impl true
  def handle_event("validate_child", %{"child" => params}, socket) do
    {:noreply, assign(socket, child_form: Form.child_form(params, :child))}
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

  # --- measure step: ONE handler does validate + add + remove ------------------
  #
  # The single <form> submits on every change. Add/remove are *named*
  # type="button" elements that dispatch a `change` event, so their name/value
  # ride along inside the same payload as all current row values (no race with
  # phx-debounce inputs, no separate events, no custom JS). Because they are
  # type="button", they are excluded from phx-submit, so saving never
  # accidentally adds/removes a row.

  @impl true
  def handle_event("validate_measure", params, socket) do
    forms =
      params
      |> measure_rows()
      |> apply_add_remove(params)
      |> Form.measures_parse()
      |> Form.measures_forms()

    {:noreply, assign(socket, measures_forms: forms)}
  end

  @impl true
  def handle_event("save_measure", params, socket) do
    contexts = params |> measure_rows() |> Form.measures_parse()

    if contexts != [] and Enum.all?(contexts, & &1.valid?) do
      save_measures(contexts, socket)
    else
      forms =
        case contexts do
          [] -> [Form.measure_new(0)]
          contexts -> Form.measures_forms(contexts, action: :validate)
        end

      {:noreply, assign(socket, measures_forms: forms)}
    end
  end

  @impl true
  def handle_event("reset", _params, socket) do
    {:noreply, assign(socket, initial_assigns())}
  end

  # --- add/remove + row extraction helpers ------------------------------------

  defp save_measures(contexts, socket) do
    parsed_list = Enum.map(contexts, & &1.parsed)

    case Growth.child_measures(parsed_list, socket.assigns.child) do
      {:ok, measures} ->
        {:noreply,
         assign(socket,
           measures: measures,
           measures_forms: Form.measures_forms(contexts),
           charts: build_all_charts(measures),
           step: :results
         )}

      {:error, errors} ->
        socket = assign(socket, measures_forms: errored_forms(contexts, errors))

        socket =
          case errors do
            %{max_measures: [%{message: message} | _]} -> put_flash(socket, :error, message)
            _other -> socket
          end

        {:noreply, socket}
    end
  end

  defp initial_assigns do
    [
      child: default_child(),
      measures: [],
      charts: nil,
      child_form: Form.child_form(%{}, :child),
      measures_forms: [Form.measure_new(0)],
      step: :child_info
    ]
  end

  # params["measure"] arrives as %{"0" => %{...}, "1" => %{...}}; sort to a list.
  defp measure_rows(%{"measure" => rows}) when is_map(rows) do
    rows
    |> Enum.sort_by(fn {key, _row} -> parse_index(key) end)
    |> Enum.map(fn {_key, row} -> row end)
  end

  defp measure_rows(_params), do: []

  defp parse_index(key) when is_binary(key) do
    case Integer.parse(key) do
      {n, ""} -> n
      _other -> 0
    end
  end

  # TODO: (jpd) the logic to add/remove items seems complex.
  #             I am not sure what is the best way to make this, yet.
  defp apply_add_remove(rows, params) do
    drop = drop_set(params)

    rows
    |> Enum.with_index()
    |> Enum.reject(fn {_row, index} -> MapSet.member?(drop, index) end)
    |> Enum.map(fn {row, _index} -> row end)
    |> maybe_add_row(add?(params))
    |> ensure_min_one_row()
  end

  defp add?(%{"_add_measure" => _value}), do: true
  defp add?(_params), do: false

  defp drop_set(%{"_drop_measure" => indices}) when is_map(indices) do
    indices |> Map.keys() |> Enum.map(&parse_index/1) |> MapSet.new()
  end

  defp drop_set(_params), do: MapSet.new()

  # Cap the rows at Growth.max_measures/0; the domain enforces the same limit.
  defp maybe_add_row(rows, true) do
    if length(rows) < Growth.max_measures() do
      rows ++ [%{"measure_date" => Date.utc_today() |> to_string()}]
    else
      rows
    end
  end

  defp maybe_add_row(rows, false), do: rows

  defp ensure_min_one_row([]), do: [%{"measure_date" => Date.utc_today() |> to_string()}]
  defp ensure_min_one_row(rows), do: rows

  # Maps `%{index => errors}` from Growth.child_measures/2 back onto each row's
  # context so the offending fields render their errors.
  defp errored_forms(contexts, errors) do
    contexts
    |> Enum.with_index()
    |> Enum.map(fn {ctx, index} ->
      errors
      |> Map.get(index, [])
      |> Enum.reduce(ctx, fn error, acc -> Zoi.Context.add_error(acc, error) end)
    end)
    |> Form.measures_forms(action: :validate)
  end

  # TODO: (jpd) remove references to requirement and decision from the implementation plan.
  # --- charts (Requirement 5 — multi-point, decision 6 range) ------------------

  defp default_child, do: %Child{name: "", gender: "", birthday: Date.utc_today()}

  defp build_all_charts(measures) when is_list(measures) do
    [:height, :weight, :bmi, :head_circumference]
    |> Map.new(fn type -> {type, build_chart_data(type, measures)} end)
  end

  defp build_chart_data(type, measures) do
    %Child{gender: gender} = hd(measures).child

    child_points =
      measures
      |> Enum.filter(fn measure ->
        not is_nil(Map.get(measure, type)) and
          measure.results |> Map.get(type, %{}) |> Map.get(:available?, false)
      end)
      |> Enum.map(&%{x: &1.age_in_months, y: Map.get(&1, type)})

    default_data = %{
      child: child_points,
      labels: [],
      sd3: [],
      sd2: [],
      sd1: [],
      sd3neg: [],
      sd2neg: [],
      sd1neg: [],
      sd0: []
    }

    with [_ | _] <- child_points,
         {center, range} <- chart_range(measures),
         {:ok, data} <- LoadReferenceChart.load_data(type, gender, center, range, 10) do
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
      _no_chart -> default_data
    end
  end

  # Decision 6: centre the reference curve on the measures' age span and grow
  # the edges to cover every point (nil when no measure has an age, so the
  # caller falls back to `default_data`). The 5-month floor preserves the
  # previous single-measure behaviour; the 2-month margin keeps points off the
  # chart edges.
  defp chart_range(measures) do
    measures
    |> Enum.map(& &1.age_in_months)
    |> Enum.reject(&is_nil/1)
    |> case do
      [] ->
        nil

      ages ->
        min_age = Enum.min(ages)
        max_age = Enum.max(ages)
        center = div(min_age + max_age, 2)
        half_span = max_age - center
        {center, max(half_span + 2, 5)}
    end
  end
end
