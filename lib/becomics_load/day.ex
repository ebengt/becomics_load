defmodule Becomics_load.Day do
  @moduledoc """
  Change Publish day from one to another.
  """
  def change(%{from: from, to: to, http: http} = arguments) do
    filter = fn publish -> from?(publish, from) end
    map = fn publish -> change(publish, to) end
    each = fn publish -> up(publish, http) end

    Becomics_load.Down.only_publishes(arguments)
    |> Enum.filter(filter)
    |> Enum.map(map)
    |> Enum.each(each)
  end

  # Private functions

  defp change(publish, to), do: Map.put(publish, :day, to)

  defp from?(publish, from), do: publish.day === from

  defp up(publish, http) do
    change = Map.take(publish, [:day])
    (http <> "/api/postpublish/" <> "#{publish.id}") |> Becomics_load.Up.post(change) |> IO.inspect()
  end
end
