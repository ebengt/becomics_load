defmodule ComicTest do
  use ExUnit.Case

  test "comic from json" do
    c =
      Becomics_load.Comic.from_jsons([
        %{"url" => "http://megatokyo.com", "name" => "Megatokyo", "id" => "anid"}
      ])

    assert c === [
             %Becomics_load.Comic{id: "anid", name: "Megatokyo", url: "http://megatokyo.com"}
           ]
  end

  test "zip" do
    cs = [
      %Becomics_load.Comic{name: "Megatokyo", url: "http://megatokyo.com", id: "m_id"},
      %Becomics_load.Comic{name: "weekly", url: "http://weekly.com", id: "w_id"},
      %Becomics_load.Comic{name: "Sun", url: "http://www.sun.com", id: "s_id"}
    ]

    # id is not used so I do not give it a value.
    ps = [
      %{"day" => "Mon", "comic_id" => "m_id"},
      %{"day" => "Tue", "comic_id" => "m_id"},
      %{"day" => "Fri", "comic_id" => "m_id"},
      %{"day" => "Sun", "comic_id" => "s_id"},
      %{"day" => "weekly", "comic_id" => "w_id"},
      %{"day" => "Sat", "comic_id" => "s_id"},
      %{"day" => "Thu", "comic_id" => "s_id"},
      %{"day" => "Wed", "comic_id" => "s_id"}
    ]

    comics = Becomics_load.Comic.zip(cs, ps)
    assert Enum.count(comics) === 3

    assert Enum.member?(comics, %Becomics_load.Comic{
             name: "Megatokyo",
             url: "http://megatokyo.com",
             days: ["Mon", "Tue", "Fri"],
             id: "m_id"
           })

    assert Enum.member?(comics, %Becomics_load.Comic{
             name: "weekly",
             url: "http://weekly.com",
             days: ["weekly"],
             id: "w_id"
           })

    assert Enum.member?(comics, %Becomics_load.Comic{
             name: "Sun",
             url: "http://www.sun.com",
             days: ["Wed", "Thu", "Sat", "Sun"],
             id: "s_id"
           })
  end
end
