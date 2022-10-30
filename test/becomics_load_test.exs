defmodule Becomics_loadTest do
  use ExUnit.Case
  doctest Becomics_load

  test "greets the world" do
    assert Becomics_load.hello() == :world
  end

  describe "arguments interpretation" do
    test "empty aka help" do
      a = Becomics_load.arguments([])
      assert a.action === :help
    end

    test "upload file" do
      a = Becomics_load.arguments(["up", "afile"])
      assert a.action === :upload
      assert a.file === "afile"
      assert a.http === "http://localhost:4000"
    end

    test "download file" do
      a = Becomics_load.arguments(["down", "bfile", "http://something.com:8080"])
      assert a.action === :download
      assert a.file === "bfile"
      assert a.http === "http://something.com:8080"
    end

    test "lost in file" do
      afile = "cfile"
      File.write!(afile, "content")
      a = Becomics_load.arguments(["lost", afile])
      assert a.action === :lostfile
      assert a.file === afile
      File.rm!(afile)
    end

    test "lost in http" do
      afile = "dfile"
      File.rm(afile)
      a = Becomics_load.arguments(["lost", afile])
      assert a.action === :losthttp
      assert a.file === afile
    end
  end

  test "content from comics" do
    {_, content} =
      Becomics_load.content_from_comics(
        {:ignore,
         [
           %Becomics_load.Comic{name: "Sun", url: "http://sun.com", days: ["Mon", "Tue"]},
           %Becomics_load.Comic{name: "Megatokyo", url: "http://megatokyo.com", days: ["Mon"]}
         ]}
      )

    assert content ===
             "http://megatokyo.com\t# Megatokyo\tcomic_update_day\tMon\n" <>
               "http://sun.com\t# Sun\tcomic_update_day\tMon,Tue\n"
  end

  test "comics from content" do
    {_, cs} = Becomics_load.comics_from_content({:ignore, content()})
    assert Enum.count(cs) === 6

    assert Enum.member?(cs, %Becomics_load.Comic{
             name: "Megatokyo",
             url: "http://megatokyo.com",
             days: ["Mon", "Tue"]
           })

    assert Enum.member?(cs, %Becomics_load.Comic{
             name: "Sun",
             url: "http://www.sun.com",
             days: ["Wed", "Thu"]
           })

    assert Enum.member?(cs, %Becomics_load.Comic{
             name: "Acomic",
             url: "https://www.gocomics.com/acomic",
             days: ["x"]
           })

    assert Enum.member?(cs, %Becomics_load.Comic{
             name: "Manga Name",
             url: "https://tumangaonline.com/lector/Manga-Name",
             days: ["x"]
           })

    assert Enum.member?(cs, %Becomics_load.Comic{
             name: "Biblioteca Name",
             url: "https://www.tumangaonline.com/biblioteca/mangas/123/Biblioteca-Name",
             days: ["x"]
           })

    assert Enum.member?(cs, %Becomics_load.Comic{
             name: "gustav",
             url: "http://kalle.com",
             days: ["x"]
           })
  end

  defp content,
    do: """
    http://megatokyo.com\t#\tcomic_update_day\tMon,Tue
    http://www.sun.com\t#\tcomic_update_day\tWed,Thu
    https://www.gocomics.com/acomic\t#\tcomic_update_day\tx
    https://tumangaonline.com/lector/Manga-Name\t#\tcomic_update_day\tx
    https://www.tumangaonline.com/biblioteca/mangas/123/Biblioteca-Name\t#\tcomic_update_day\tx
    http://kalle.com\t# gustav\tcomic_update_day\tx
    """
end
