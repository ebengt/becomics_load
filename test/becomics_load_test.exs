defmodule Becomics_loadTest do
  use ExUnit.Case

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
      assert a.http === "http://localhost:4000"
      File.rm!(afile)
    end

    test "lost in http" do
      afile = "dfile"
      File.rm(afile)
      a = Becomics_load.arguments(["lost", afile, "http://something.com:8080"])
      assert a.action === :losthttp
      assert a.file === afile
      assert a.http === "http://something.com:8080"
    end

    test "dates" do
      start = "10"
      stop = "20"
      a = Becomics_load.arguments(["dates", start, stop])
      assert a.action === :dates
      assert a.start === 10
      assert a.stop === 20
      assert a.http === "http://localhost:4000"
    end

    test "urlhostchange" do
      start = "10"
      stop = "20"
      a = Becomics_load.arguments(["urlhostchange", start, stop])
      assert a.action === :urlhostchange
      assert a.from === start
      assert a.to === stop
      assert a.http === "http://localhost:4000"
    end
  end
end
