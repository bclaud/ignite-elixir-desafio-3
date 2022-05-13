defmodule GenReport do
  alias GenReport.Parser

  def build, do: {:error, "Insira o nome de um arquivo"}

  def build(filename) do
    report_map =
      filename
      |> Parser.parse_file()
      |> to_map()

    %{
      all_hours: all_hours(report_map),
      hours_per_month: hours_per_month(report_map),
      hours_per_year: hours_per_year(report_map)
    }
  end

  defp to_map(parsed_report) do
    to_map = fn [name, hours, day, month, year] ->
      %{
        name: name,
        hours: hours,
        day: day,
        month: month,
        year: year
      }
    end

    Enum.map(parsed_report, &to_map.(&1))
  end

  defp all_hours(map) do
    Enum.reduce(map, %{}, fn %{name: name, hours: hours}, acc ->
      Map.update(acc, name, hours, &(&1 + hours))
    end)
  end

  defp hours_per_month(map) do
    Enum.reduce(map, %{}, fn %{name: name, hours: hours, month: month}, acc ->
      Map.update(acc, name, %{}, fn existing_map ->
        Map.update(existing_map, month, hours, &(&1 + hours))
      end)
    end)
  end

  defp hours_per_year(map) do
    Enum.reduce(map, %{}, fn %{name: name, hours: hours, year: year}, acc ->
      Map.update(acc, name, %{}, fn existing_map ->
        Map.update(existing_map, year, hours, &(&1 + hours))
      end)
    end)
  end
end
