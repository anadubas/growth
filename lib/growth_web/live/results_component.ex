defmodule GrowthWeb.ResultsComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    if Map.has_key?(assigns.measure, :results) do
      ~H"""
      <div class="card bg-white shadow-md rounded-lg p-6">
        <h2 class="text-lg font-bold mb-4">Resultados</h2>

        <div class="mb-2">
          <strong>Perímetro Cefálico Percentil:</strong> <%= @measure.results.head_circumference_result.percentile %>%
        </div>

        <div class="mb-2">
          <strong>Altura Percentil:</strong> <%= @measure.results.height_result.percentile %>%
        </div>

        <div class="mb-2">
          <strong>Peso Percentil:</strong> <%= @measure.results.weight_result.percentile %>%
        </div>

        <div class="mb-2">
          <strong><abbr title="Índice de massa corporal">IMC</abbr> Percentil:</strong> <%= @measure.results.bmi_result.percentile %>%
        </div>
      </div>
      """
    else
      ~H"""
      <div class="card bg-white shadow-md rounded-lg p-6">
        <h2 class="text-lg font-bold mb-4">Resultados Indisponíveis</h2>
      </div>
      """
    end
  end
end
