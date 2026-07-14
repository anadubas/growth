defmodule GrowthWeb.ChildFormComponent do
  @moduledoc """
  A LiveComponent that renders a DaisyUI-styled form for collecting basic
  child information with Zoi-based validation.

  Fields:

  * Name (text input)
  * Birthday (date input)
  * Gender (select input with options for "Menina" and "Menino")

  Validation fires on blur (via `phx-debounce`) and on submit through the
  `validate_child` / `save_child` events handled by the parent LiveView.
  Per-field errors render only after the field has been visited.
  """

  use GrowthWeb, :live_component

  alias Phoenix.HTML.Form

  @impl true
  def render(assigns) do
    ~H"""
    <form id="child-form" class="card" phx-change="validate_child" phx-submit="save_child">
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
            phx-debounce="blur"
          />
        </label>
        <p :for={error <- errors_for(@form[:name])} class="text-sm text-error mt-1">
          {translate_error(error)}
        </p>

        <label class="input input-primary w-full" for={@form[:birthday].id}>
          <span class="label w-1/3">Nascimento</span>
          <input
            type="date"
            id={@form[:birthday].id}
            name={@form[:birthday].name}
            value={Form.normalize_value("date", @form[:birthday].value)}
            class="w-full"
            phx-debounce="blur"
          />
        </label>
        <p :for={error <- errors_for(@form[:birthday])} class="text-sm text-error mt-1">
          {translate_error(error)}
        </p>

        <label class="select select-primary w-full" for={@form[:gender].id}>
          <span class="label w-1/3">Sexo</span>
          <select id={@form[:gender].id} name={@form[:gender].name} class="w-full">
            <option value="">Selecione...</option>
            {Form.options_for_select(gender_options(), @form[:gender].value)}
          </select>
        </label>
        <p :for={error <- errors_for(@form[:gender])} class="text-sm text-error mt-1">
          {translate_error(error)}
        </p>

        <div class="card-actions justify-center">
          <button type="submit" class="btn btn-primary">Próximo</button>
        </div>
      </fieldset>
    </form>
    """
  end

  defp errors_for(field) do
    if Phoenix.Component.used_input?(field), do: field.errors, else: []
  end

  defp gender_options, do: [{"Menina", "female"}, {"Menino", "male"}]
end
