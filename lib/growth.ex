defmodule Growth do
  @moduledoc """
  Growth keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias Growth.Child
  alias Growth.Measure

  # Maximum number of measures a child can have.
  @max_measures 12

  @doc """
  Returns the maximum number of measures accepted per child.
  """
  @spec max_measures() :: pos_integer()
  def max_measures, do: @max_measures

  @doc """
  Create a child
  """
  @spec create_child(map()) :: {:ok, Child.t()} | {:error, [Zoi.Error.t()]}
  def create_child(attrs) do
    Child.new(attrs)
  end

  @doc """
  Create child measures results
  """
  @spec child_measure(map(), Child.t()) :: {:ok, Measure.t()} | {:error, [Zoi.Error.t()]}
  def child_measure(attrs, child) do
    Measure.new(attrs, child)
  end

  @doc """
  Create child measures results for a list of measure attrs.

  Maps `child_measure/2` over the list, aggregating per-row errors into
  `{:error, %{index => errors}}`, so every invalid row is reported at once. Rows
  sharing the same `measure_date` are rejected as duplicates, and lists longer
  than `max_measures/0` are rejected outright.
  """
  @spec child_measures([map()], Child.t()) ::
          {:ok, [Measure.t()]} | {:error, %{(atom() | non_neg_integer()) => [Zoi.Error.t()]}}
  def child_measures(attrs_list, %Child{} = child)
      when is_list(attrs_list) and length(attrs_list) <= @max_measures do
    attrs_list
    |> Enum.map(&child_measure(&1, child))
    |> aggregate_results()
  end

  def child_measures(attrs_list, _) when is_list(attrs_list) do
    {:error,
     %{
       max_measures: [
         Zoi.Error.new(code: :custom, message: "máximo de #{@max_measures} medidas por criança")
       ]
     }}
  end

  def child_measures(_, _) do
    {:error,
     %{
       measures: [Zoi.Error.new(code: :custom, message: "medidas por criança deve ser uma lista")]
     }}
  end

  @spec aggregate_results([{:ok, Measure.t()} | {:error, [Zoi.Error.t()]}]) ::
          {:ok, [Measure.t()]} | {:error, %{non_neg_integer() => [Zoi.Error.t()]}}
  defp aggregate_results(results) do
    results =
      results
      |> Enum.with_index()
      |> Enum.group_by(fn {{key, _}, _} -> key end, fn {{_, value}, index} -> {index, value} end)

    row_errors = results |> Map.get(:error, []) |> Enum.into(%{})

    measures = Map.get(results, :ok, [])

    errors = Map.merge(row_errors, duplicate_date_errors(measures), fn _index, a, b -> a ++ b end)

    if map_size(errors) == 0 do
      {:ok, Enum.map(measures, fn {_index, measure} -> measure end)}
    else
      {:error, errors}
    end
  end

  # TODO: (jpd) move this to zoi validation
  @spec duplicate_date_errors([{non_neg_integer(), Measure.t()}]) :: %{
          non_neg_integer() => [Zoi.Error.t()]
        }
  defp duplicate_date_errors(measures) do
    measures
    |> Enum.group_by(fn {_index, measure} -> measure.measure_date end, fn {index, _measure} ->
      index
    end)
    |> Enum.flat_map(fn
      {_date, [_single]} ->
        []

      {_date, [_first | duplicates]} ->
        Enum.map(duplicates, fn index ->
          {index,
           [
             Zoi.Error.new(
               code: :custom,
               message: "data da medida duplicada",
               path: [:measure_date]
             )
           ]}
        end)
    end)
    |> Map.new()
  end
end
