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
    if Map.has_key?(assigns.measure, :results) do
      ~H"""
      <div>
        <div class="card bg-base-300 shadow-md rounded-lg p-6">
          <h2 class="text-lg font-bold mb-4">Criança</h2>

          <div class="card bg-base-200 rounded-box grid flex-grow place-items-center">
            <strong>Nome:</strong> {@child.name}
            <strong>Data de nascimento:</strong> {@child.birthday}
          </div>
        </div>

        <div class="divider"></div>

        <div class="card bg-base-300 shadow-md rounded-lg p-6 gap-2">
          <h2 class="text-lg font-bold mb-4">Resultados</h2>

          <div class="card bg-base-200 rounded-box grid flex-grow place-items-center gap-1 p-3">
            <strong>Perímetro Cefálico:</strong> {@measure.head_circumference}
            <strong>Perímetro Cefálico Percentil:</strong> {@measure.results.head_circumference_result.percentile}% <% czscore =
              Float.round(@measure.results.head_circumference_result.zscore, 2) %>

            <% indicator_class =
              cond do
                czscore <= 1 and czscore >= -1 ->
                  "badge badge-success"

                (czscore > 1 and czscore <= 2) or (czscore < -1 and czscore >= -2) ->
                  "badge badge-info"

                (czscore > 2 and czscore <= 3) or (czscore < -2 and czscore >= -3) ->
                  "badge badge-warning"

                czscore > 3 or czscore < -3 ->
                  "badge badge-error"

                true ->
                  "badge badge-secondary"
              end %>

            <% indicator_text =
              cond do
                czscore <= 1 and czscore >= -1 -> "ótimo"
                (czscore > 1 and czscore <= 2) or (czscore < -1 and czscore >= -2) -> "bom"
                (czscore > 2 and czscore <= 3) or (czscore < -2 and czscore >= -3) -> "cuidado"
                czscore > 3 or czscore < -3 -> "alerta"
                true -> "-"
              end %>

            <strong>
              Perímetro Cefálico Zscore:
            </strong>
            <div class="inline-block ml-2">
              <span class={indicator_class}>{indicator_text}</span>
              {czscore}
            </div>
          </div>

          <div class="card bg-base-200 rounded-box grid flex-grow place-items-center gap-1 p-3">
            <strong>Altura:</strong> {@measure.height}
            <strong>Altura Percentil:</strong> {@measure.results.height_result.percentile}% <% hzscore =
              Float.round(@measure.results.height_result.zscore, 2) %>

            <% indicator_class =
              cond do
                hzscore <= 1 and hzscore >= -1 ->
                  "badge badge-success"

                (hzscore > 1 and hzscore <= 2) or (hzscore < -1 and hzscore >= -2) ->
                  "badge badge-info"

                (hzscore > 2 and hzscore <= 3) or (hzscore < -2 and hzscore >= -3) ->
                  "badge badge-warning"

                hzscore > 3 or hzscore < -3 ->
                  "badge badge-error"

                true ->
                  "badge badge-secondary"
              end %>

            <% indicator_text =
              cond do
                hzscore <= 1 and hzscore >= -1 -> "ótimo"
                (hzscore > 1 and hzscore <= 2) or (hzscore < -1 and hzscore >= -2) -> "bom"
                (hzscore > 2 and hzscore <= 3) or (hzscore < -2 and hzscore >= -3) -> "cuidado"
                hzscore > 3 or hzscore < -3 -> "alerta"
                true -> "-"
              end %>

            <strong>
              Altura Zscore:
            </strong>
            <div class="inline-block ml-2">
              <span class={indicator_class}>{indicator_text}</span>
              {hzscore}
            </div>
          </div>

          <div class="card bg-base-200 rounded-box grid flex-grow place-items-center gap-1 p-3">
            <strong>Peso:</strong> {@measure.weight}
            <strong>Peso Percentil:</strong> {@measure.results.weight_result.percentile}% <% wzscore =
              Float.round(@measure.results.weight_result.zscore, 2) %>

            <% indicator_class =
              cond do
                wzscore <= 1 and wzscore >= -1 ->
                  "badge badge-success"

                (wzscore > 1 and wzscore <= 2) or (wzscore < -1 and wzscore >= -2) ->
                  "badge badge-info"

                (wzscore > 2 and wzscore <= 3) or (wzscore < -2 and wzscore >= -3) ->
                  "badge badge-warning"

                wzscore > 3 or wzscore < -3 ->
                  "badge badge-error"

                true ->
                  "badge badge-secondary"
              end %>

            <% indicator_text =
              cond do
                wzscore <= 1 and wzscore >= -1 -> "ótimo"
                (wzscore > 1 and wzscore <= 2) or (wzscore < -1 and wzscore >= -2) -> "bom"
                (wzscore > 2 and wzscore <= 3) or (wzscore < -2 and wzscore >= -3) -> "cuidado"
                wzscore > 3 or wzscore < -3 -> "alerta"
                true -> "-"
              end %>
            <strong>
              Peso Zscore:
            </strong>
            <div class="inline-block ml-2">
              <span class={indicator_class}>{indicator_text}</span>
              {wzscore}
            </div>
          </div>

          <div class="card bg-base-200 rounded-box grid flex-grow place-items-center gap-1 p-3">
            <strong><abbr title="Índice de massa corporal">IMC</abbr>:</strong> {@measure.bmi}
            <strong><abbr title="Índice de massa corporal">IMC</abbr> Percentil:</strong> {@measure.results.bmi_result.percentile}% <% izscore =
              Float.round(@measure.results.bmi_result.zscore, 2) %>

            <% indicator_class =
              cond do
                izscore <= 1 and izscore >= -1 ->
                  "badge badge-success"

                (izscore > 1 and izscore <= 2) or (izscore < -1 and izscore >= -2) ->
                  "badge badge-info"

                (izscore > 2 and izscore <= 3) or (izscore < -2 and izscore >= -3) ->
                  "badge badge-warning"

                izscore > 3 or izscore < -3 ->
                  "badge badge-error"

                true ->
                  "badge badge-secondary"
              end %>

            <% indicator_text =
              cond do
                izscore <= 1 and izscore >= -1 -> "ótimo"
                (izscore > 1 and izscore <= 2) or (izscore < -1 and izscore >= -2) -> "bom"
                (izscore > 2 and izscore <= 3) or (izscore < -2 and izscore >= -3) -> "cuidado"
                izscore > 3 or izscore < -3 -> "alerta"
                true -> "-"
              end %>

            <strong>
              <abbr title="Índice de massa corporal">IMC</abbr> Zscore:
            </strong>
            <div class="inline-block ml-2">
              <span class={indicator_class}>{indicator_text}</span>
              {izscore}
            </div>
          </div>
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
