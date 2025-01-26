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
  arguments/1 exported for test.
  """
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

  def arguments(["urlchange", from, to | t]) do
    ac = arguments_common(t)
    Enum.into(%{action: :urlchange, from: from, to: to}, ac)
  end

  def arguments(["daychange", from, to | t]) do
    ac = arguments_common(t)
    Enum.into(%{action: :daychange, from: from, to: to}, ac)
  end

  def arguments(_), do: %{action: :help}

  def main(argv) do
    arguments(argv) |> Map.pop!(:action) |> action()
  end

  # Private functions

  defp action({:upload, arguments}), do: Becomics_load.Up.comics(arguments)
  defp action({:download, arguments}), do: Becomics_load.Down.comics(arguments)
  defp action({:dates, arguments}), do: Becomics_load.Dates.comics(arguments)
  defp action({:lostfile, arguments}), do: Becomics_load.Lost.file(arguments)
  defp action({:losthttp, arguments}), do: Becomics_load.Lost.http(arguments)
  defp action({:urlchange, arguments}), do: Becomics_load.URL.change(arguments)
  defp action({:daychange, arguments}), do: Becomics_load.Day.change(arguments)
  defp action({:help, _}), do: IO.puts("#{:escript.script_name()}" <> " " <> @moduledoc)

  defp arguments_lost_file(true), do: :lostfile
  defp arguments_lost_file(false), do: :losthttp

  # Crash if too may arguments. The user probably is confused and need to think about things.
  defp arguments_common([]), do: %{file: "http.comics", http: "http://localhost:4000"}
  defp arguments_common([file]), do: %{file: file, http: "http://localhost:4000"}
  defp arguments_common([file, http]), do: %{file: file, http: http}

  # Internal functions
end
