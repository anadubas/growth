defmodule Growth.Child do
  @moduledoc """
  Represents a child whose growth metrics are evaluated against WHO growth standards.

  This module defines the `Growth.Child` struct, which holds core demographic and temporal data
  required for growth assessments, such as the child's name, gender, birth date, and calculated
  age in months.

  It also includes helper functions to construct a child struct, calculate their age at the time
  of measurement, and set the current measurement date.

  ## Fields

    * `:name` - The child's full name (optional for calculations, required for UI display).
    * `:gender` - Gender as a string (`"male"` or `"female"`).
    * `:birthday` - The child's birth date (`Date.t()`).
    * `:measure_date` - The date when the anthropometric measurement was taken (defaults to today).
    * `:age_in_months` - Calculated age in months based on birthday and measurement date.

  ## Example

      iex> {:ok, child} = Growth.Child.new(%{name: "Alice", gender: "female", birthday: ~D[2022-01-15]})
      iex> child.age_in_months
      40  # Example, depending on the current date

  """

  alias Growth.Calculate
  require :telemetry

  @type t :: %__MODULE__{
          name: String.t() | nil,
          gender: String.t() | nil,
          birthday: Date.t() | nil,
          measure_date: Date.t() | nil,
          age_in_months: number() | nil
        }

  @enforce_keys [:name, :gender, :birthday]

  defstruct [
    :name,
    :gender,
    :birthday,
    :measure_date,
    :age_in_months
  ]

  @doc """
  Create child
  """
  @spec new(map()) :: {:ok, t()}
  def new(attrs) do
    result =
      attrs
      |> create_struct()
      |> add_measure_date()
      |> add_age_in_months()

    # Emit telemetry for successful child creation
    case result do
      {:ok, child} ->
        :telemetry.execute([:growth, :child, :created], %{count: 1}, %{
          age_in_months: child.age_in_months,
          gender: child.gender
        })

        {:ok, child}
    end
  end

  defp create_struct(attrs) do
    %__MODULE__{
      name: attrs.name,
      birthday: attrs.birthday,
      gender: attrs.gender
    }
  end

  defp add_measure_date(child) do
    %{child | measure_date: Date.utc_today()}
  end

  def add_age_in_months(%__MODULE__{birthday: birthday, measure_date: measure_date} = child)
      when not is_nil(birthday) and not is_nil(measure_date) do
    {:ok, %{child | age_in_months: Calculate.age_in_months(birthday, measure_date)}}
  end
end
