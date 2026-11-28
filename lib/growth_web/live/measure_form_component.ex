defmodule GrowthWeb.MeasureFormComponent do
  @moduledoc """
  Renders a single measure row inside the multi-measure form.

  Stateless function component: add/remove/validate are handled by the parent
  LiveView's single `<form>`. The per-row `form` already carries an indexed
  `name` (`measure[\#{index}]`), so field names resolve to e.g.
  `measure[0][height]`.

  The remove button is a *named* `type="button"` inside the parent form that
  dispatches a JS `change` event (`phx-click={JS.dispatch("change")}`): the drop
  request rides along with the full current form state, avoiding any race with
  debounced inputs and requiring no custom JavaScript.
  """

  use GrowthWeb, :html

  attr :form, :any, required: true, doc: "the per-row Phoenix.HTML.Form"
  attr :index, :integer, required: true

  def measure_row(assigns) do
    ~H"""
    <fieldset
      data-measure-index={@index}
      class="fieldset card-body w-full max-w-lg mx-auto bg-base-300 shadow-md rounded-lg p-6 relative"
    >
      <legend class="fieldset-legend card-title">Medida {@index + 1}</legend>
      <%!-- TODO: (jpd) fix the styling of this button --%>
      <button
        type="button"
        name={"_drop_measure[#{@index}]"}
        value="1"
        phx-click={JS.dispatch("change")}
        class="btn btn-circle btn-xs btn-ghost absolute top-3 right-3"
        aria-label="Remover medida"
      >
        <.icon name="hero-x-mark" class="h-4 w-4" />
      </button>
      <.measure_input field={@form[:measure_date]} label="Data" type="date" focus={true} />
      <.measure_input field={@form[:height]} label="Altura (cm)" type="number" step="0.01" />
      <.measure_input field={@form[:weight]} label="Peso (kg)" type="number" step="0.001" />
      <.measure_input
        field={@form[:head_circumference]}
        label="C. Cabeça (cm)"
        type="number"
        step="0.01"
      />
    </fieldset>
    """
  end

  attr :field, :any, required: true
  attr :label, :string, required: true
  attr :type, :string, default: "text"
  attr :step, :string, default: nil
  attr :focus, :boolean, required: false, default: false

  defp measure_input(assigns) do
    ~H"""
    <div>
      <label class="input input-primary w-full" for={@field.id}>
        <span class="label w-1/3">{@label}</span>
        <input
          type={@type}
          step={@step}
          id={@field.id}
          name={@field.name}
          value={@field.value}
          class="w-full"
          phx-debounce="blur"
          phx-mounted={@focus && JS.focus()}
        />
      </label>
      <p :for={error <- errors_for(@field)} class="text-sm text-error mt-1">
        {translate_error(error)}
      </p>
    </div>
    """
  end

  @spec errors_for(Phoenix.HTML.FormField.t()) :: [{String.t(), keyword()}]
  defp errors_for(field) do
    if Phoenix.Component.used_input?(field), do: field.errors, else: []
  end
end
