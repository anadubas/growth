defmodule GrowthWeb.MeasureFormComponent do
  @moduledoc """
  A LiveComponent that renders a form for inputting child anthropometric measurements.

  This component provides a user interface for collecting three key measurements:

  * Height (in centimeters)
  * Weight (in kilograms)
  * Head circumference (in centimeters)

  The form includes:

  * Numeric inputs with appropriate step values for precision
    * Height: 0.01 cm precision
    * Weight: 0.001 kg precision
    * Head circumference: 0.01 cm precision
  * All fields are required
  * Input validation for numeric values
  * A submit button that triggers the "save_measure" event

  The form uses DaisyUI styling classes for consistent appearance:

  * Card layout with shadow and rounded corners
  * Primary-colored input fields
  * Responsive design with max-width constraints

  When submitted, the form data is structured as:

      %{
        "measure" => %{
          "height" => "...",
          "weight" => "...",
          "head_circumference" => "..."
        }
      }
  """
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <form class="card" phx-submit="save_measure">
      <fieldset class="fieldset card-body w-full max-w-lg mx-auto bg-base-300 shadow-md rounded-lg p-6">
        <legend class="fieldset-legend card-title">Medidas:</legend>

        <label class="input input-primary w-full">
          <span class="label w-1/3">Altura (cm)</span>
          <input
            type="number"
            step="0.01"
            name="measure[height]"
            class="w-full"
            placeholder="Altura"
            required
          />
        </label>

        <label class="input input-primary w-full">
          <span class="label w-1/3">Peso (kg)</span>
          <input
            type="number"
            step="0.001"
            name="measure[weight]"
            class="w-full"
            placeholder="Peso"
            required
          />
        </label>

        <label class="input input-primary w-full">
          <span class="label w-1/3"><abbr title="Circunferência">C.</abbr> Cabeça (cm)</span>
          <input
            type="number"
            step="0.01"
            name="measure[head_circumference]"
            class="w-full"
            placeholder="Circunferência da Cabeça"
            required
          />
        </label>

        <div class="card-actions justify-center">
          <button type="submit" class="btn btn-primary">Calcular</button>
        </div>
      </fieldset>
    </form>
    """
  end
end
