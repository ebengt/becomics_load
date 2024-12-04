defmodule Becomics_load.Lost do
  @moduledoc """
  Write files with info about lost comics.
  """

  def file(arguments),
    do:
      arguments.file
      |> File.read!()
      |> Becomics_load.Comic.from_content()
      |> lost_comics()
      |> lost_write!(arguments)

  def http(arguments),
    do: Becomics_load.Down.comics(arguments) |> lost_comics() |> lost_write!(arguments)

  # Internal functions

  defp lost_comics(comics) do
    f = fn comic ->
      lost_comics(HTTPoison.get(comic.url), comic)
    end

    Enum.map(comics, f)
  end

  defp lost_comics({:ok, result}, comic), do: lost_comics(result.status_code, result, comic)
  defp lost_comics({:error, _}, comic), do: {:lost, comic}

  defp lost_comics(200, _result, comic), do: {:found, comic}
  defp lost_comics(302, _result, comic), do: {:found, comic}

  defp lost_comics(301, result, comic),
    do: lost_comics_301(List.keyfind(result.headers, "Location", 1), comic)

  defp lost_comics(status, _result, comic),
    do: {:lost, %{comic | name: Integer.to_string(status)}}

  defp lost_comics_301(nil, comic), do: {:lost, %{comic | name: "301"}}
  defp lost_comics_301({_location, url}, comic), do: {:found, %{comic | url: url}}

  defp lost_write!(lost_and_found, arguments) do
    {lost, found} = Enum.reduce(lost_and_found, {[], []}, &lost_and_found/2)

    File.write!(arguments.file <> ".lost", Becomics_load.Comic.to_content(lost), [
      :exclusive,
      :raw
    ])

    File.write!(arguments.file <> ".found", Becomics_load.Comic.to_content(found), [
      :exclusive,
      :raw
    ])
  end

  defp lost_and_found({:lost, lost}, {lost_acc, found_acc}), do: {[lost | lost_acc], found_acc}
  defp lost_and_found({:found, found}, {lost_acc, found_acc}), do: {lost_acc, [found | found_acc]}
end
