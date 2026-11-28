defmodule GrowthWeb.ResultsComponent do
  @moduledoc """
  A LiveComponent responsible for displaying child growth assessment results.

  This component renders a detailed view of one or more anthropometric
  measures and their corresponding Z-scores and percentiles, including:

  * A card for the latest measure with the value, percentile and Z-score of
    each indicator, plus the percent change relative to the previous measure.
  * A history table with one row per measure (sorted by `measure_date`), with
    the value, percentile, Z-score and percent change between consecutive
    measures for each indicator.
  * One growth chart per indicator, plotting every measure's point against the
    WHO reference curves (height, weight, BMI and head circumference for age).

  Z-scores carry a visual indicator showing the assessment level:

    * "ótimo" (optimal) - green badge for Z-scores between -1 and 1
    * "bom" (good) - blue badge for Z-scores between -2 and -1 or 1 and 2
    * "cuidado" (caution) - yellow badge for Z-scores between -3 and -2 or 2 and 3
    * "alerta" (alert) - red badge for Z-scores below -3 or above 3

  ## Required assigns

  * `:child` - Map containing child information (name and birthday)
  * `:measures` - List of `Growth.Measure` structs with calculated results
  * `:charts` - Map of chart payloads per indicator, as built by the LiveView

  An empty `:measures` list is tolerated: the results card and history table
  are omitted and only the child card and reset button render.
  """
  use GrowthWeb, :live_component

  @indicators [
    {"Altura", :height, "cm"},
    {"Peso", :weight, "kg"},
    {"IMC", :bmi, "kg/m<sup>2</sup>"},
    {"Perímetro Cefálico", :head_circumference, "cm"}
  ]

  @charts [
    {"Altura / Idade", "chart-height", :height},
    {"Peso / Idade", "chart-weight", :weight},
    {"IMC / Idade", "chart-bmi", :bmi},
    {"Perímetro Cefálico / Idade", "chart-hc", :head_circumference}
  ]

  def render(assigns) do
    sorted_measures = Enum.sort_by(assigns.measures, & &1.measure_date, Date)
    latest_measure = List.last(sorted_measures)

    assigns =
      assign(assigns,
        sorted_measures: sorted_measures,
        latest_measure: latest_measure,
        indicators: @indicators,
        charts_meta: @charts
      )

    ~H"""
    <div class="space-y-4">
      <div class="card max-w-lg mx-auto bg-base-300 shadow-md rounded-lg p-6">
        <h2 class="text-lg font-bold mb-4">Criança</h2>
        <p><strong>Nome:</strong> {@child.name}</p>
        <p><strong>Data de nascimento:</strong> {format_date(@child.birthday)}</p>
      </div>

      <div
        :if={@latest_measure}
        class="card max-w-lg mx-auto bg-base-300 shadow-md rounded-lg p-6"
      >
        <h2 class="text-lg font-bold mb-4">
          Resultados
          <span class="text-sm font-normal">({format_date(@latest_measure.measure_date)})</span>
        </h2>

        <div class="grid grid-cols-2 gap-4">
          <%= for {label, key, _unit} <- @indicators do %>
            <% result = @latest_measure.results[key] %>
            <div class="card bg-base-200 rounded-box p-3">
              <p><strong>{label}:</strong> {format_score(Map.get(@latest_measure, key))}</p>
              <%= if result.available? do %>
                <p><strong>Percentil:</strong> {format_score(result.percentile)}%</p>
                <p><strong>Z-score:</strong> {format_score(result.zscore)}</p>
              <% else %>
                <p class="text-sm text-error"><em>Indisponível para a idade</em></p>
              <% end %>
              <p :if={change = change_for(@sorted_measures, length(@sorted_measures) - 1, key)}>
                <strong>Variação:</strong> {change}
              </p>
            </div>
          <% end %>
        </div>
      </div>

      <div
        :if={length(@sorted_measures) > 1}
        class="card w-full mx-auto bg-base-300 shadow-md rounded-lg p-6"
      >
        <h2 class="text-lg font-bold mb-4">Histórico de medidas</h2>

        <div class="overflow-x-auto">
          <table class="table table-zebra table-sm">
            <thead>
              <tr>
                <th>Data</th>
                <th>Idade (meses)</th>
                <th :for={{label, _key, _unit} <- @indicators}>{label}</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={{measure, index} <- Enum.with_index(@sorted_measures)}>
                <td>{format_date(measure.measure_date)}</td>
                <td>{measure.age_in_months}</td>
                <td :for={{_label, key, unit} <- @indicators}>
                  <% result = measure.results[key] %>
                  <% value = Map.get(measure, key) %>
                  <%= if is_nil(value) do %>
                    ---
                  <% else %>
                    <div>{format_score(value)}{unit}</div>
                    <%= if result.available? do %>
                      <div class="text-xs">
                        P{format_score(result.percentile)}% · z {format_score(result.zscore)}
                      </div>
                    <% else %>
                      <div class="text-xs text-error"><em>Indisponível para a idade</em></div>
                    <% end %>
                    <div :if={change = change_for(@sorted_measures, index, key)} class="text-xs">
                      {change}
                    </div>
                  <% end %>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <%= if any_chart_available?(@charts) do %>
        <div class="card w-full mx-auto bg-base-300 shadow-md rounded-lg p-6">
          <%= for {title, chart_id, key} <- @charts_meta do %>
            <%= if chart_available?(@charts[key]) do %>
              <div class="w-full text-center mb-4">
                <h3 class="text-lg font-bold">{title}</h3>
                <canvas
                  id={chart_id}
                  class="w-full h-96"
                  phx-hook="GrowthChart"
                  data-chart={Jason.encode!(@charts[key])}
                ></canvas>
              </div>
            <% end %>
          <% end %>
        </div>
      <% end %>

      <div class="text-center">
        <.button id="reset-btn" class="btn btn-primary" phx-click="reset">Reiniciar</.button>
      </div>
    </div>
    """
  end

  # Relative percent change of an indicator between a measure and the previous
  # one (sorted by `measure_date`); nil when there is no previous measure or
  # either value is missing/zero.
  @spec change_for([Growth.Measure.t()], non_neg_integer(), atom()) :: String.t() | nil
  defp change_for(_sorted_measures, 0, _key), do: nil

  defp change_for(sorted_measures, index, key) do
    previous = sorted_measures |> Enum.at(index - 1) |> Map.get(key)
    current = sorted_measures |> Enum.at(index) |> Map.get(key)

    case percent_change(previous, current) do
      nil -> nil
      change -> format_change(change)
    end
  end

  defp percent_change(previous, current)
       when is_number(previous) and is_number(current) and previous != 0 do
    Float.round((current - previous) / previous * 100, 1)
  end

  defp percent_change(_previous, _current), do: nil

  # A tiny decrease can round to negative zero; normalize it to "0.0%".
  defp format_change(change) when change > 0, do: "+#{change}%"
  defp format_change(change) when change == 0, do: "0.0%"
  defp format_change(change), do: "#{change}%"

  defp chart_available?(chart), do: chart.labels != []

  defp any_chart_available?(charts) do
    Enum.any?(charts, fn {_key, chart} -> chart_available?(chart) end)
  end

  defp format_date(%Date{} = date), do: Calendar.strftime(date, "%d/%m/%Y")

  defp format_score(score) when is_number(score) do
    Float.round(score / 1, 2)
  end

  defp format_score(nil) do
    "---"
  end
end
