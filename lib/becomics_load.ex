defmodule Becomics_load do
  @moduledoc """
  up | down | lost [file [url]]
  dates start stop [url]

  Load (up or down) becomics from/to a file.
  Or find which comics that have become lost. If file exists the comics are read from it.
  The lost comcis are written to file".lost" and the found ones to file".found". In case of
  a redirect (301) the found file contains the target of the redirect. If file does not exist
  comics are read from url.

  Positional arguments.
  First "up", "down" or "lost".
  Second the file name. Default: http.comics
  Third is becomics URL. Default: http://localhost:4000
  If you want to change the URL you must give a file name.
  When first argument is "dates":
  Second is start date.
  Third is stop date.
  Fourth is becomics URL. Default: http://localhost:4000
  """

  @doc """
  Hello world.

  ## Examples

      iex> Becomics_load.hello
      :world

  """
  def hello do
    :world
  end

  def arguments(["up" | t]), do: Enum.into(%{action: :upload}, arguments_common(t))
  def arguments(["down" | t]), do: Enum.into(%{action: :download}, arguments_common(t))

  # Override default file name
  def arguments(["dates", start, stop]), do: arguments(["dates", start, stop, "dates_"])

  def arguments(["dates", start, stop | t]) do
    ac = arguments_common(t)

    Enum.into(
      %{action: :dates, start: String.to_integer(start), stop: String.to_integer(stop)},
      ac
    )
  end

  def arguments(["lost" | t]) do
    ac = arguments_common(t)
    action = arguments_lost_file(File.exists?(ac.file))
    Enum.into(%{action: action}, ac)
  end

  def arguments(_), do: %{action: :help}

  def comics_from_content({arguments, content}) do
    {arguments, Becomics_load.Comic.from_content(content)}
  end

  def content_from_comics({arguments, comics}) do
    {arguments, Becomics_load.Comic.to_content(comics)}
  end

  def main(argv) do
    argv |> arguments() |> action()
  end

  # Private functions

  defp action(%{action: :upload} = arguments), do: action_upload(arguments)
  defp action(%{action: :download} = arguments), do: action_download(arguments)
  defp action(%{action: :dates} = arguments), do: action_dates(arguments)
  defp action(%{action: :lostfile} = arguments), do: action_lostfile(arguments)
  defp action(%{action: :losthttp} = arguments), do: action_losthttp(arguments)
  defp action(%{action: :help}), do: IO.puts("#{:escript.script_name()}" <> " " <> @moduledoc)

  # arguments will be going all they way in the pipe, together with any added items.
  defp action_download(arguments),
    do: arguments |> download_comics |> content_from_comics |> download_write!

  defp action_upload(arguments),
    do: arguments |> upload_read! |> comics_from_content |> upload_comics

  defp action_dates(%{start: start, stop: stop} = arguments) when start < stop,
    do: for(x <- start..stop, do: date_comics(x, arguments))

  defp action_lostfile(arguments),
    do: arguments |> upload_read! |> comics_from_content |> lost_comics |> lost_write!

  defp action_losthttp(arguments),
    do: arguments |> download_comics |> lost_comics |> lost_write!

  defp arguments_lost_file(true), do: :lostfile
  defp arguments_lost_file(false), do: :losthttp

  # Crash if too may arguments. The user probably is confused and need to think about things.
  defp arguments_common([]), do: %{file: "http.comics", http: "http://localhost:4000"}
  defp arguments_common([file]), do: %{file: file, http: "http://localhost:4000"}
  defp arguments_common([file, http]), do: %{file: file, http: http}

  # No tests, yet! Will need a running becomics server to be useful.
  # Working on it.
  def download_comics(arguments) do
    t =
      Task.async(fn ->
        download_json(arguments.http <> "/api/comic") |> Becomics_load.Comic.from_jsons()
      end)

    ps = download_json(arguments.http <> "/api/publish")
    cs = Task.await(t)
    {arguments, Becomics_load.Comic.zip(cs, ps)}
  end

  def download_json(url) do
    {:ok, r} = HTTPoison.get(url)
    200 = r.status_code
    {:ok, data} = Poison.decode(r.body)
    data["data"]
  end

  # Internal functions

  defp date_comics(date, arguments) do
    date |> download_webpages(arguments) |> download_webpages_write!(arguments)
  end

  defp download_webpages(date, arguments) do
    day = download_webpages_day(date)
    {:ok, comics} = HTTPoison.get(arguments.http <> "/comic/" <> day)
    {:ok, sample} = HTTPoison.get(arguments.http <> "/sample/" <> Integer.to_string(date))
    {date, comics.body, sample.body}
  end

  defp download_webpages_day(date) do
    now = DateTime.utc_now()
    day_number = Calendar.ISO.day_of_week(now.year, now.month, date, :monday)
    Enum.at(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], day_number)
  end

  defp download_webpages_write!({date, comics, sample}, arguments) do
    file = arguments.file <> Integer.to_string(date) <> ".html"
    File.write!(file, comics <> sample)
  end

  defp download_write!({arguments, content}) do
    File.write!(arguments.file, content, [:exclusive, :raw])
  end

  defp lost_comics({arguments, comics}) do
    f = fn comic ->
      lost_comics(HTTPoison.get(comic.url), comic)
    end

    {arguments, Enum.map(comics, f)}
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

  defp lost_write!({arguments, lost_and_found}) do
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

  # Upload each comic to two JSON interfaces. One for URL and Name, the other for Days.
  # Days need the result (id) of the first, and has to be called once per day in Days.
  # No tests, yet! Will need a running becomics server to be useful.
  # Working on it.
  defp upload_comics({arguments, comics}) do
    uc_async = fn comic ->
      Task.async(fn ->
        # days: will be ignored
        c = upload_json(arguments.http <> "/api/comic", %{comic: comic})
        comic_id = c["id"]

        f = fn day ->
          upload_json(arguments.http <> "/api/publish", %{
            publish: %{comic_id: comic_id, day: day}
          })
        end

        Enum.map(comic.days, f)
      end)
    end

    comics |> Enum.map(uc_async) |> Enum.map(&Task.await(&1))
  end

  defp upload_json(url, body) do
    {:ok, j} = Poison.encode(body)
    {:ok, r} = HTTPoison.post(url, j, [{"Content-Type", "application/json"}])
    # see what any crash is about
    {201, ^body} = {r.status_code, body}
    {:ok, data} = Poison.decode(r.body)
    data["data"]
  end

  defp upload_read!(arguments), do: {arguments, File.read!(arguments.file)}
end
