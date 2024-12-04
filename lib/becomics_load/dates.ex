defmodule Becomics_load.Dates do
  @moduledoc """
  Write files with link to comics to read for particular dates.
  """

  def comics(%{start: start, stop: stop} = arguments) when start < stop,
    do: for(x <- start..stop, do: comics(x, arguments))

  # Internal functions

  defp comics(date, arguments) do
    date |> download_webpages(arguments) |> download_webpages_write!(arguments)
  end

  defp download_webpages(date, arguments) do
    {:ok, daily} = HTTPoison.get(arguments.http <> "/daily/" <> Integer.to_string(date))
    {date, daily.body}
  end

  defp download_webpages_write!({date, comics}, arguments) do
    file = arguments.file <> Integer.to_string(date) <> ".html"
    File.write!(file, comics)
  end
end
