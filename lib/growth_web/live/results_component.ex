defmodule GrowthWeb.ResultsComponent do
  @moduledoc """
  A LiveComponent responsible for displaying child growth assessment results.

  This component renders a detailed view of anthropometric measurements and their
  corresponding Z-scores and percentiles, including:

  * Head circumference
  * Height
  * Weight
  * BMI (Body Mass Index)

  For each measurement, it displays:

  * The raw measurement value
  * The percentile value
  * The Z-score with a visual indicator showing the assessment level:
    * "ótimo" (optimal) - green badge for Z-scores between -1 and 1
    * "bom" (good) - blue badge for Z-scores between -2 and -1 or 1 and 2
    * "cuidado" (caution) - yellow badge for Z-scores between -3 and -2 or 2 and 3
    * "alerta" (alert) - red badge for Z-scores below -3 or above 3

  ## Required assigns

  * `:child` - Map containing child information (name and birthday)
  * `:measure` - Map containing measurements and their calculated results

  If no results are available, it displays a "Resultados Indisponíveis" message.
  """
  use GrowthWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="card max-w-lg mx-auto bg-base-300 shadow-md rounded-lg p-6">
        <h2 class="text-lg font-bold mb-4">Criança</h2>
        <p><strong>Nome:</strong> {@child.name}</p>
        <p><strong>Data de nascimento:</strong> {@child.birthday}</p>
      </div>

      <div class="card max-w-lg mx-auto bg-base-300 shadow-md rounded-lg p-6">
        <h2 class="text-lg font-bold mb-4">Resultados</h2>

        <div class="grid grid-cols-2 gap-4">
          <%= for {label, key} <- [
            {"Altura", :height},
            {"Peso", :weight},
            {"IMC", :bmi},
            {"Perímetro Cefálico", :head_circumference}
          ] do %>
            <% result = @measure.results[key] %>
            <div class="card bg-base-200 rounded-box p-3">
              <p><strong>{label}:</strong> {format_score(Map.get(@measure, key))}</p>
              <%= if result.available? do %>
                <p><strong>Percentil:</strong> {format_score(result.percentile)}%</p>
                <p><strong>Z-score:</strong> {format_score(result.zscore)}</p>
              <% else %>
                <p class="text-sm text-error"><em>Indisponível para a idade</em></p>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>

      <%= if any_result_available?(@measure.results) do %>
        <div class="card w-full mx-auto bg-base-300 shadow-md rounded-lg p-6">
          <%= for {title, chart_id, key} <- [
            {"Altura / Idade", "chart-height", :height},
            {"Peso / Idade", "chart-weight", :weight},
            {"IMC / Idade", "chart-bmi", :bmi},
            {"Perímetro Cefálico / Idade", "chart-hc", :head_circumference}
          ] do %>
            <% result = @measure.results[key] %>
            <%= if result.available? do %>
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

  defp any_result_available?(results) do
    Enum.any?(results, fn {_key, result} -> result.available? end)
  end

  defp format_score(score) when is_number(score) do
    Float.round(score / 1, 2)
  end

  defp format_score(nil) do
    "---"
  end
end
