defmodule GrowthWeb.MeasureFormComponent do
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