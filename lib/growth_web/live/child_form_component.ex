defmodule GrowthWeb.ChildFormComponent do
  @moduledoc """
  A LiveComponent that renders a form for collecting basic child information.

  This component provides a user interface for collecting essential child data:

  * Name (text input)
  * Birthday (date input)
  * Gender (select input with options for "Menina" and "Menino")

  The form features:

  * Required field validation
  * DaisyUI styled inputs and layout
  * Responsive design with max-width constraints
  * Card layout with shadow and rounded corners

  When submitted, the form triggers a "save_child" event with data structured as:

      %{
        "child" => %{
          "name" => "...",
          "birthday" => "YYYY-MM-DD",
          "gender" => "female" | "male"
        }
      }

  The component is typically the first step in the child growth assessment process,
  collecting the basic information needed for subsequent measurements and calculations.
  """
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div class="card max-w-lg mx-auto bg-base-300 shadow-md rounded-lg p-6">
      <form phx-submit="save_child">
        <label class="form-control w-full">
          <div class="label">
            <span class="label-text">Nome</span>
          </div>
          <input
            type="text"
            name="child[name]"
            class="input input-bordered input-primary w-full"
            placeholder="Nome"
            required
          />
        </label>

        <label class="form-control w-full">
          <div class="label">
            <span class="label-text">Data de nascimento</span>
          </div>
          <input
            type="date"
            name="child[birthday]"
            class="input input-bordered input-primary w-full"
            required
          />
        </label>

        <label class="form-control w-full">
          <div class="label">
            <span class="label-text">Sexo</span>
          </div>
          <select name="child[gender]" class="select select-bordered select-primary w-full" required>
            <option value="female">Menina</option>
            <option value="male">Menino</option>
          </select>
        </label>

        <div class="text-center mt-4">
          <button type="submit" class="btn btn-primary">Próximo</button>
        </div>
      </form>
    </div>
    """
  end
end
