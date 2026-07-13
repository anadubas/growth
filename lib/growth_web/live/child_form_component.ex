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

  alias Phoenix.HTML.Form

  def render(assigns) do
    ~H"""
    <form class="card" phx-submit="save_child">
      <fieldset class="fieldset card-body w-full max-w-lg mx-auto bg-base-300 shadow-md rounded-lg p-6">
        <legend class="fieldset-legend card-title">A criança:</legend>

        <label class="input input-primary w-full" for={@form[:name].id}>
          <span class="label w-1/3">Nome</span>
          <input
            type="text"
            id={@form[:name].id}
            name={@form[:name].name}
            value={@form[:name].value}
            class="w-full"
            placeholder="Nome"
            required
          />
        </label>

        <label class="input input-primary w-full" for={@form[:birthday].id}>
          <span class="label w-1/3">Nascimento</span>
          <input
            type="date"
            id={@form[:birthday].id}
            name={@form[:birthday].name}
            value={Form.normalize_value("date", @form[:birthday].value)}
            class="w-full"
            required
          />
        </label>

        <label class="select select-primary w-full" for={@form[:gender].id}>
          <span class="label w-1/3">Sexo</span>
          <select id={@form[:gender].id} name={@form[:gender].name} class="w-full" required>
            <option value="">Selecione...</option>
            {Form.options_for_select(gender_options(), @form[:gender].value)}
          </select>
        </label>

        <div class="card-actions justify-center">
          <button type="submit" class="btn btn-primary">Próximo</button>
        </div>
      </fieldset>
    </form>
    """
  end

  defp gender_options, do: [{"Menina", "female"}, {"Menino", "male"}]
end
