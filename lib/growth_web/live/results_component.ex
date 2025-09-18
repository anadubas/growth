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
  use Phoenix.LiveComponent

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
          <%= for {label, result} <- [
            {"Altura", @measure.results.height},
            {"Peso", @measure.results.weight},
            {"IMC", @measure.results.bmi},
            {"Perímetro Cefálico", @measure.results.head_circumference}
          ] do %>
            <div class="card bg-base-200 rounded-box p-3">
              <p>
                <strong>{label}:</strong> {Map.get(@measure, String.to_atom(String.downcase(label)))}
              </p>
              <p><strong>Percentil:</strong> {result.percentile}%</p>
              <% zscore = Float.round(result.zscore, 2) %>
              <p>
                <strong>Z-score:</strong>
                {zscore}
              </p>
            </div>
          <% end %>
        </div>
      </div>

      <div class="card w-full mx-auto bg-base-300 shadow-md rounded-lg p-6">
        <div class="w-full text-center mb-4">
          <h3 class="text-lg font-bold">Altura / Idade</h3>
          <canvas
            id="chart-height"
            class="w-full h-96"
            phx-hook="GrowthChart"
            data-chart={Jason.encode!(@charts.height)}
          >
          </canvas>
        </div>

        <div class="w-full text-center mb-4">
          <h3 class="text-lg font-bold">Peso / Idade</h3>
          <canvas
            id="chart-weight"
            class="w-full h-96"
            phx-hook="GrowthChart"
            data-chart={Jason.encode!(@charts.weight)}
          >
          </canvas>
        </div>

        <div class="w-full text-center mb-4">
          <h3 class="text-lg font-bold">IMC / Idade</h3>
          <canvas
            id="chart-bmi"
            class="w-full h-96"
            phx-hook="GrowthChart"
            data-chart={Jason.encode!(@charts.bmi)}
          >
          </canvas>
        </div>

        <div class="w-full text-center mb-4">
          <h3 class="text-lg font-bold">Perímetro Cefálico / Idade</h3>
          <canvas
            id="chart-hc"
            class="w-full h-96"
            phx-hook="GrowthChart"
            data-chart={Jason.encode!(@charts.head_circ)}
          >
          </canvas>
        </div>
      </div>
    </div>
    """
  end
end
