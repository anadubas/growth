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
    * `:age_in_decimal` - Calculate age in months, with decimal precision, based on birthday and measure date.

  ## Example

      iex> {:ok, child} = Growth.Child.new(%{name: "Alice", gender: "female", birthday: ~D[2022-01-15]})
      iex> child.age_in_months
      40  # Example, depending on the current date

  """

  alias Growth.Calculate

  @schema Zoi.struct(
            __MODULE__,
            %{
              name: Zoi.string() |> Zoi.required(),
              gender: Zoi.enum(["male", "female"]) |> Zoi.required(),
              birthday: Zoi.date() |> Zoi.required(),
              measure_date: Zoi.date() |> Zoi.nullish(),
              age_in_months: Zoi.integer() |> Zoi.min(0) |> Zoi.nullish(),
              age_in_decimal: Zoi.float() |> Zoi.min(0.0) |> Zoi.nullish()
            },
            coerce: true
          )

  @type t :: unquote(Zoi.type_spec(@schema))

  @enforce_keys Zoi.Struct.enforce_keys(@schema)

  defstruct Zoi.Struct.struct_fields(@schema)

  @doc """
  Create child
  """
  @spec new(map()) :: {:ok, t()} | {:error, [Zoi.Error.t()]}
  def new(attrs) do
    case Zoi.parse(schema(), attrs) do
      {:ok, child} ->
        :telemetry.execute([:growth, :child, :created], %{count: 1}, %{
          age_in_months: child.age_in_months,
          age_in_decimal: child.age_in_decimal,
          gender: child.gender,
          measure_date: child.measure_date
        })

        {:ok, child}

      error ->
        error
    end
  end

  @spec schema :: Zoi.schema()
  def schema do
    Zoi.transform(@schema, fn %__MODULE__{measure_date: measure_date, birthday: birthday} = child ->
      measure_date = (is_nil(measure_date) && Date.utc_today()) || measure_date
      age_in_months = Calculate.age_in_months(birthday, measure_date)
      age_in_decimal = Calculate.in_months_decimal(birthday, measure_date)

      child =
        %__MODULE__{
          child
          | measure_date: measure_date,
            age_in_months: age_in_months,
            age_in_decimal: age_in_decimal
        }

      {:ok, child}
    end)
  end
end
