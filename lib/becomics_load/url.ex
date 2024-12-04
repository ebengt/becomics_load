defmodule Becomics_load.URL do
  @moduledoc """
  Change URL from one domain to another.
  """
  def change(%{from: from, to: to, http: http} = arguments) do
    filter = fn comic -> from?(comic, from) end
    map = fn comic -> change(comic, to) end
    each = fn comic -> up(comic, http) end

    Becomics_load.Down.only_comics(arguments)
    |> Enum.filter(filter)
    |> Enum.map(map)
    |> Enum.each(each)
  end

  # Private functions

  defp change(comic, to) do
    uri = URI.parse(comic.url)
    new_url = %URI{uri | host: to} |> URI.to_string()
    Map.put(comic, :url, new_url)
  end

  defp from?(comic, from) do
    uri = comic.url |> URI.parse()
    uri.host === from
  end

  defp up(comic, http) do
    change = Map.take(comic, [:url])
    (http <> "/api/postcomic/" <> "#{comic.id}") |> Becomics_load.Up.post(change) |> IO.inspect()
  end
end
