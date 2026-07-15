defmodule GrowthWeb.MeasureFormComponent do
  @moduledoc """
  A LiveComponent that renders a DaisyUI-styled form for inputting child
  anthropometric measurements with Zoi-based validation.

  Fields:

  * Height in centimeters (number, 0.01 precision)
  * Weight in kilograms (number, 0.001 precision)
  * Head circumference in centimeters (number, 0.01 precision)

  Validation fires on blur (via `phx-debounce`) and on submit through the
  `validate_measure` / `save_measure` events handled by the parent LiveView.
  Per-field errors render only after the field has been visited.
  """

  use GrowthWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <form id="measure-form" class="card" phx-change="validate_measure" phx-submit="save_measure">
      <fieldset class="fieldset card-body w-full max-w-lg mx-auto bg-base-300 shadow-md rounded-lg p-6">
        <legend class="fieldset-legend card-title">Medidas:</legend>

        <label class="input input-primary w-full" for={@form[:height].id}>
          <span class="label w-1/3">Altura (cm)</span>
          <input
            type="number"
            step="0.01"
            id={@form[:height].id}
            name={@form[:height].name}
            value={@form[:height].value}
            class="w-full"
            placeholder="Altura"
            phx-debounce="blur"
          />
        </label>
        <p :for={error <- errors_for(@form[:height])} class="text-sm text-error mt-1">
          {translate_error(error)}
        </p>

        <label class="input input-primary w-full" for={@form[:weight].id}>
          <span class="label w-1/3">Peso (kg)</span>
          <input
            type="number"
            step="0.001"
            id={@form[:weight].id}
            name={@form[:weight].name}
            value={@form[:weight].value}
            class="w-full"
            placeholder="Peso"
            phx-debounce="blur"
          />
        </label>
        <p :for={error <- errors_for(@form[:weight])} class="text-sm text-error mt-1">
          {translate_error(error)}
        </p>

        <label class="input input-primary w-full" for={@form[:head_circumference].id}>
          <span class="label w-1/3"><abbr title="Circunferência">C.</abbr> Cabeça (cm)</span>
          <input
            type="number"
            step="0.01"
            id={@form[:head_circumference].id}
            name={@form[:head_circumference].name}
            value={@form[:head_circumference].value}
            class="w-full"
            placeholder="Circunferência da Cabeça"
            phx-debounce="blur"
          />
        </label>
        <p :for={error <- errors_for(@form[:head_circumference])} class="text-sm text-error mt-1">
          {translate_error(error)}
        </p>

        <div class="card-actions justify-center">
          <button type="submit" class="btn btn-primary">Calcular</button>
        </div>
      </fieldset>
    </form>
    """
  end

  @spec errors_for(Phoenix.HTML.FormField.t()) :: [{String.t(), keyword()}]
  defp errors_for(field) do
    if Phoenix.Component.used_input?(field), do: field.errors, else: []
  end
end
