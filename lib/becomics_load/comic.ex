defmodule Becomics_load.Comic do
  @enforce_keys [:url, :name]
  defstruct [:url, :name, :id, days: []]

  # content is a string used to represent Comic in a file.
  def from_content(content) do
    content |> String.split("\n") |> Enum.filter(&comic?/1) |> List.foldl([], &from_line/2)
  end

  def from_jsons(jsons) do
    Enum.map(jsons, &from_one_json/1)
  end

  def to_content(comics) do
    (comics |> Enum.sort(&first_precedes_second?/2) |> Enum.map(&to_line/1) |> Enum.join("\n")) <>
      "\n"
  end

  # A list of Comics and one of publishes %{"day", "comic_id"}
  # Any "day" in publish will added to "days" in Comic where Comic.id == "comic_id".
  def zip(comics, publishes) do
    map_of_comics = List.foldl(comics, %{}, &comic_key_id/2)

    publishes
    |> List.foldl(map_of_comics, &zip_add_days/2)
    |> Map.values()
    |> Enum.map(&sort_days/1)
  end

  # Private functions

  defp comic?(line), do: String.contains?(line, "\tcomic_update_day\t")

  # Access comic with id, instead of linear search.
  defp comic_key_id(comic, acc) do
    Enum.into(acc, %{comic.id => comic})
  end

  defp first_precedes_second?(first, second) do
    first.name <= second.name
  end

  defp from_line(line, acc) do
    parts = String.split(line, "\t")
    [url | _] = parts
    uri = URI.parse(url)
    days = parts |> List.last() |> String.split(",")
    name = from_line_name(parts, uri)
    [%__MODULE__{url: url, name: name, days: days} | acc]
  end

  # Hard coded position for name.
  defp from_line_name([_, "#" | _], uri), do: name_from_uri(uri)

  defp from_line_name([_, "#" <> name | _], uri),
    do: from_line_name_present(String.trim(name), uri)

  defp from_line_name_present("", uri), do: name_from_uri(uri)
  defp from_line_name_present(name, _uri), do: name

  defp from_one_json(json) do
    %__MODULE__{id: json["id"], url: json["url"], name: json["name"]}
  end

  # Historical function from when # Name did not have Name.
  defp name_from_uri(uri), do: uri.host |> String.split(".") |> name_from_host(uri)

  defp name_from_host(["www" | t], uri), do: name_from_host(t, uri)
  defp name_from_host(["gocomics" | _t], uri), do: name_from_gocomics(Path.split(uri.path))
  defp name_from_host(["tumangaonline" | _t], uri), do: name_from_tumanga(Path.split(uri.path))

  defp name_from_host([name | _], _uri),
    do: name |> String.replace_suffix("comic", "") |> String.capitalize()

  defp name_from_gocomics(["/", name | _t]), do: name |> String.capitalize()

  defp name_from_tumanga(["/", "lector", manga | _t]),
    do: manga |> String.split("-") |> Enum.join(" ")

  defp name_from_tumanga(["/", "biblioteca", "mangas", _id, manga | _t]),
    do: manga |> String.split("-") |> Enum.join(" ")

  defp name_from_tumanga(["/", "library", "manhwa", _id, manga | _t]),
    do: manga |> String.split("-") |> Enum.join(" ")

  defp sort_days(comic), do: %{comic | days: Enum.sort(comic.days, &sort_days?/2)}

  defp sort_days?(day1, day2), do: sort_days_n(day1) <= sort_days_n(day2)
  defp sort_days_n("Mon"), do: 0
  defp sort_days_n("Tue"), do: 1
  defp sort_days_n("Wed"), do: 2
  defp sort_days_n("Thu"), do: 3
  defp sort_days_n("Fri"), do: 4
  defp sort_days_n("Sat"), do: 5
  defp sort_days_n("Sun"), do: 6

  defp to_line(comic) do
    comic.url <> "\t# " <> comic.name <> "\tcomic_update_day\t" <> Enum.join(comic.days, ",")
  end

  defp zip_add_days(publish, acc) do
    f = fn comic ->
      %{comic | days: [publish["day"] | comic.days]}
    end

    Map.update!(acc, publish["comic_id"], f)
  end
end
