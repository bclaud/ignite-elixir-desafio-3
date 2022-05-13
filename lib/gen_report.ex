defmodule GenReport do
  alias GenReport.Parser

  def build, do: {:error, "Insira o nome de um arquivo"}

  def build(filename) do
    report_map =
      filename
      |> Parser.parse_file()
      |> to_map()

    %{
      "all_hours" => all_hours(report_map),
      "hours_per_month" => hours_per_month(report_map),
      "hours_per_year" => hours_per_year(report_map)
    }
  end

  def build_from_many(filenames) do
    filenames
    |> Task.async_stream(&build/1)
    |> merge_reports()
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
      Map.update(acc, name, %{month => hours}, fn existing_map ->
        Map.update(existing_map, month, hours, &(&1 + hours))
      end)
    end)
  end

  defp hours_per_year(map) do
    Enum.reduce(map, %{}, fn %{name: name, hours: hours, year: year}, acc ->
      Map.update(acc, name, %{year => hours}, fn existing_map ->
        Map.update(existing_map, year, hours, &(&1 + hours))
      end)
    end)
  end

  defp merge_reports(reports) do
    merge_value = fn report1, report2 ->
      Map.merge(report1, report2, fn _k, v1, v2 -> v1 + v2 end)
    end

    merge_nested = fn report1, report2 ->
      Map.merge(report1, report2, fn _k, v1, v2 -> merge_value.(v1, v2) end)
    end

    merged_all_hours =
      Enum.reduce(reports, %{}, fn {:ok,
                                    %{
                                      "all_hours" => all_hours
                                    }},
                                   acc ->
        merge_value.(acc, all_hours)
      end)

    merged_hours_month =
      Enum.reduce(reports, %{}, fn {:ok,
                                    %{
                                      "hours_per_month" => hours_per_month
                                    }},
                                   acc ->
        merge_nested.(acc, hours_per_month)
      end)

    merged_hours_year =
      Enum.reduce(reports, %{}, fn {:ok,
                                    %{
                                      "hours_per_year" => hours_per_year
                                    }},
                                   acc ->
        merge_nested.(acc, hours_per_year)
      end)

    %{
      "all_hours" => merged_all_hours,
      "hours_per_month" => merged_hours_month,
      "hours_per_year" => merged_hours_year
    }
  end
end
