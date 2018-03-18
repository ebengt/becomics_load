defmodule Becomics_load do
  @moduledoc """
  up | down [file [url]]

  Load (up or down) becomics from/to a file.

  Positional arguments.
  First "up" or "down".
  Second the file name. Default: http.comics
  Third is becomics URL. Default: http://localhost:4000
  If you want to change the URL you must give a file name.
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

	# Documentation mentions that the module can be defined after use, but I got an error.
	defmodule Comic do

		@enforce_keys [:url, :name]
		defstruct [:url, :name, :id, days: []]

		# content is a string used to represent Comic in a file.
		def from_content content do
			content |> (String.split "\n") |> (Enum.filter &comic?/1) |> (List.foldl [], &from_line/2)
		end

		def from_jsons jsons do
			Enum.map jsons, &from_one_json/1
		end
	
		def to_content comics do
			(comics |> (Enum.sort &first_precedes_second?/2) |> (Enum.map &to_line/1) |> (Enum.join "\n")) <> "\n"
		end

		# A list of Comics and one of publishes %{"day", "comic_id"}
		# Any "day" in publish will added to "days" in Comic where Comic.id == "comic_id".
		def zip comics, publishes do
			map_of_comics = List.foldl comics, %{}, &comic_key_id/2
			publishes |> (List.foldl map_of_comics, &zip_add_days/2) |> Map.values |> (Enum.map &sort_days/1)
		end

		# Private functions

		defp (comic? line), do: String.contains? line, "\tcomic_update_day\t"


		# Access comic with id, instead of linear search.
		defp comic_key_id comic, acc do
			Enum.into acc, %{comic.id => comic}
		end


		defp first_precedes_second? first, second do
			first_uri = URI.parse first.url
			second_uri = URI.parse second.url
			(first_precedes_second_join first_uri.host, first_uri.path) <= (first_precedes_second_join second_uri.host, second_uri.path)
		end

		defp (first_precedes_second_join host, nil), do: host
		defp (first_precedes_second_join host, path), do: host <> path


		def from_one_json json do
			%Comic{id: json["id"], url: json["url"], name: json["name"]}
		end

	
		defp from_line line, acc do
			parts = String.split line, "\t"
			[url | _] = parts
			uri = URI.parse url
			days = parts |> List.last |> (String.split ",")
			name = from_line_name parts, uri
			[%Comic{url: url, name: name, days: days} | acc]
		end

		# Hard coded position for name.
		defp (from_line_name [_, "#" | _], uri), do: name_from_uri uri
		defp (from_line_name [_, "#"<>name | _], uri), do: from_line_name_present (String.trim name), uri

		defp (from_line_name_present "", uri), do: name_from_uri uri
		defp (from_line_name_present name, _uri), do: name


		# Historical function from when # Name did not have Name.
		defp (name_from_uri uri), do: uri.host |> (String.split ".") |> (name_from_host uri)

		defp (name_from_host ["www" | t], uri), do: name_from_host t, uri
		defp (name_from_host ["gocomics" | _t], uri), do: name_from_gocomics (Path.split uri.path)
		defp (name_from_host ["tumangaonline" | _t], uri), do: name_from_tumanga (Path.split uri.path)
		defp (name_from_host [name |_], _uri), do: name |> (String.replace_suffix "comic", "") |> String.capitalize

		defp (name_from_gocomics ["/", name | _t]), do: name |> String.capitalize

		defp (name_from_tumanga ["/", "lector", manga | _t]), do: manga |> (String.split "-") |> (Enum.join " ")
		defp (name_from_tumanga ["/", "biblioteca", "mangas", _id, manga | _t]), do: manga |> (String.split "-") |> (Enum.join " ")


		defp (sort_days comic), do: %{comic | days: (Enum.sort comic.days, &sort_days?/2)}

		defp (sort_days? day1, day2 ), do: (sort_days_n day1) <= (sort_days_n day2)
		defp (sort_days_n "Mon"), do: 0
		defp (sort_days_n "Tue"), do: 1
		defp (sort_days_n "Wed"), do: 2
		defp (sort_days_n "Thu"), do: 3
		defp (sort_days_n "Fri" ), do: 4
		defp (sort_days_n "Sat"), do: 5
		defp (sort_days_n "Sun"), do: 6


		defp to_line comic do
			comic.url <> "\t# " <> comic.name <> "\tcomic_update_day\t" <> (Enum.join comic.days, ",")
		end


		defp zip_add_days publish, acc do
			f = fn comic ->
					%{comic | days: [publish["day"] | comic.days]}
			end
			Map.update! acc, publish["comic_id"], f
		end

	end

	def (arguments ["up" | t]), do: Enum.into %{action: :upload}, (arguments_common t)
	def (arguments ["down" | t]), do: Enum.into %{action: :download}, (arguments_common t)
	def (arguments _), do: %{action: :help}

	def comics_from_content {arguments, content} do
		{arguments, Comic.from_content content}
	end

	def content_from_comics {arguments, comics} do
		{arguments, Comic.to_content comics}
	end

	def main argv do
		(arguments argv) |> action 
	end

	# Private functions

	defp (action %{action: :upload}=arguments), do: action_upload arguments
	defp (action %{action: :download}=arguments), do: action_download arguments
	defp (action %{action: :help}), do: IO.puts "#{:escript.script_name}" <> " " <> @moduledoc

	# arguments will be going all they way in the pipe, together with any added items.
	defp (action_download arguments), do: arguments |> download_comics |> content_from_comics |> download_write!
	defp (action_upload arguments), do: arguments |> upload_read! |> comics_from_content |> upload_comics


	# Crash if too may arguments. The user probably is confused and need to think about things.
	defp (arguments_common []), do: %{file: "http.comics", http: "http://localhost:4000"}
	defp (arguments_common [file]), do: %{file: file, http: "http://localhost:4000"}
	defp (arguments_common [file, http]), do: %{file: file, http: http}


	# No tests, yet! Will need a running becomics server to be useful.
	# Working on it.
	def download_comics arguments do
		t = Task.async fn -> (download_json arguments.http <> "/api/comics") |> Comic.from_jsons end
		ps = download_json arguments.http <> "/api/publishes"
		cs = Task.await t
		{arguments, (Comic.zip cs, ps)}
	end

	def download_json url do
		{:ok, r} = HTTPoison.get url
		200 = r.status_code
		{:ok, data} = Poison.decode r.body
		data["data"]
	end


	defp download_write! {arguments, content} do
		File.write! arguments.file, content, [:exclusive, :raw]
	end


	# Upload each comic to two JSON interfaces. One for URL and Name, the other for Days.
	# Days need the result (id) of the first, and has to be called once per day in Days.
	# No tests, yet! Will need a running becomics server to be useful.
	# Working on it.
	defp upload_comics {arguments, comics} do
		uc_async = fn comic ->
			Task.async fn ->
				c = upload_json arguments.http <> "/api/comics", %{comic: comic} # days: will be ignored
				comic_id = c["id"]
				f = fn day -> upload_json arguments.http <> "/api/publishes" , %{publish: %{comic_id: comic_id, day: day}} end
				Enum.map comic.days, f
			end
		end
		comics |> (Enum.map uc_async) |> (Enum.map (&Task.await &1))
	end

	defp upload_json url, body do
		{:ok, j} = Poison.encode body
		{:ok, r} = HTTPoison.post url, j, [{"Content-Type", "application/json"}]
		{201, ^body} = {r.status_code, body} # see what any crash is about
		{:ok, data} = Poison.decode r.body
		data["data"]
	end


	defp (upload_read! arguments), do: {arguments, File.read! arguments.file}

end
