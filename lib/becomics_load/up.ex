defmodule Becomics_load.Up do
  @moduledoc """
    Upload each comic to two JSON interfaces. One for URL and Name, the other for Days.
    Days need the result (id) of the first, and has to be called once per day in Days.
    No tests, yet! Will need a running becomics server to be useful.
    Working on it.
  """
  def comics(arguments),
    do: file_read!(arguments) |> Becomics_load.Comic.from_content() |> up(arguments)

  def post(url, content), do: upload_json(url, content, 200)

  # Private functions

  defp file_read!(arguments), do: File.read!(arguments.file)

  def up(comics, arguments) do
    uc_async = fn comic ->
      Task.async(fn ->
        # days: will be ignored
        c = upload_json(arguments.http <> "/api/comic", %{comic: comic}, 201)
        comic_id = c["id"]

        f = fn day ->
          upload_json(
            arguments.http <> "/api/publish",
            %{publish: %{comic_id: comic_id, day: day}},
            201
          )
        end

        Enum.map(comic.days, f)
      end)
    end

    comics |> Enum.map(uc_async) |> Enum.map(&Task.await(&1))
  end

  defp upload_json(url, body, status) do
    {:ok, j} = Poison.encode(body)
    {:ok, r} = HTTPoison.post(url, j, [{"Content-Type", "application/json"}])
    # see what any crash is about
    {^status, ^body} = {r.status_code, body}
    {:ok, data} = Poison.decode(r.body)
    data["data"]
  end
end
