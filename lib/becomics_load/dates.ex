defmodule Becomics_load.Dates do
  @moduledoc """
  Write files with link to comics to read for particular dates.
  """

  def comics(%{start: start, stop: stop} = arguments) when start < stop,
    do:
      for(
        x <- start..stop,
        do: date_from_day(x) |> comics(arguments)
      )

  def comics(%{start: start, stop: stop} = arguments) do
    for(
      x <- dates(start, stop),
      do: comics(x, arguments)
    )
  end

  # Internal functions

  defp comics(date, arguments) do
    date |> download_webpages(arguments) |> download_webpages_write!(arguments)
  end

  defp date_from_day(day) do
    today = Date.utc_today()
    Date.new!(today.year, today.month, day)
  end

  defp dates(start, stop) do
    today = Date.utc_today()

    first_dates =
      for(
        x <- start..Calendar.ISO.days_in_month(today.year, today.month),
        do: Date.new!(today.year, today.month, x)
      )

    next = Date.shift(today, month: 1)

    last_dates =
      for(
        x <- 1..stop,
        do: Date.new!(next.year, next.month, x)
      )

    first_dates ++ last_dates
  end

  defp download_webpages(date, arguments) do
    {:ok, daily} = HTTPoison.get(arguments.http <> "/daily/" <> Date.to_iso8601(date))
    {date, daily.body}
  end

  defp download_webpages_write!({date, comics}, arguments) do
    file = arguments.file <> Date.to_iso8601(date) <> ".html"
    File.write!(file, comics)
  end

  if Mix.env() === :test do
    def test_date_from_day(day), do: date_from_day(day)
    def test_dates(start, stop), do: dates(start, stop)
  end
end
