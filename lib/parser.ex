defmodule GenReport.Parser do
  @months %{
    "1" => "janeiro",
    "2" => "fevereiro",
    "3" => "março",
    "4" => "abril",
    "5" => "maio",
    "6" => "junho",
    "7" => "julho",
    "8" => "agosto",
    "9" => "setembro",
    "10" => "outubro",
    "11" => "novembro",
    "12" => "dezembro"
  }

  def parse_file(filename) do
    split_and_trim = &(String.trim(&1) |> String.split(","))

    File.stream!(filename)
    |> Stream.map(fn line -> split_and_trim.(line) end)
    |> map_attrs()
  end

  defp map_attrs(parsed_file) do
    transform_line = fn [name, hours, day, month, year] ->
      [
        String.downcase(name),
        String.to_integer(hours),
        String.to_integer(day),
        Map.get(@months, month),
        String.to_integer(year)
      ]
    end

    Enum.map(parsed_file, &transform_line.(&1))
  end
end
