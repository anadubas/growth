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
    <div class="card bg-base-300 shadow-md rounded-lg p-6">
      <form phx-submit="save_measure">
        <label class="form-control w-full max-w-xs">
          <div class="label">
            <span class="label-text">Altura (cm)</span>
          </div>
          <input
            type="number"
            step="0.01"
            name="measure[height]"
            class="input input-bordered input-primary"
            placeholder="Altura"
            required
          />
        </label>

        <label class="form-control w-full max-w-xs">
          <div class="label">
            <span class="label-text">Peso (kg)</span>
          </div>
          <input
            type="number"
            step="0.001"
            name="measure[weight]"
            class="input input-bordered input-primary"
            placeholder="Peso"
            required
          />
        </label>

        <label class="form-control w-full max-w-xs">
          <div class="label">
            <span class="label-text">Circunferência da Cabeça (cm)</span>
          </div>
          <input
            type="number"
            step="0.01"
            name="measure[head_circumference]"
            class="input input-bordered input-primary"
            placeholder="Circunferência da Cabeça"
            required
          />
        </label>

        <div class="text-center mt-4">
          <button type="submit" class="btn btn-primary">Calcular</button>
        </div>
      </form>
    </div>
    """
  end
end
