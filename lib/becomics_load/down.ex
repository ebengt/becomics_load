defmodule Becomics_load.Down do
  @moduledoc """
    Download each comic from two JSON interfaces. One for URL and Name, the other for Days.
    Merge before writing to file.
    No tests, yet! Will need a running becomics server to be useful.
    Working on it.
  """

  def comics(arguments),
    do: down(arguments) |> Becomics_load.Comic.to_content() |> file_write!(arguments)

  def only_comics(arguments),
    do: download_json(arguments.http <> "/api/comic") |> Becomics_load.Comic.from_jsons()

  # Private functions

  defp down(arguments) do
    t = Task.async(fn -> download_json(arguments.http <> "/api/publish") end)
    cs = only_comics(arguments)
    ps = Task.await(t)
    Becomics_load.Comic.zip(cs, ps)
  end

  defp download_json(url) do
    {:ok, r} = HTTPoison.get(url)
    200 = r.status_code
    {:ok, data} = Poison.decode(r.body)
    data["data"]
  end

  defp file_write!(content, arguments),
    do: File.write!(arguments.file, content, [:exclusive, :raw])
end
