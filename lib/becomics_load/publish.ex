defmodule Becomics_load.Publish do
  @moduledoc """
    Publish data structure functions.
  """
  @enforce_keys [:id, :day, :comic_id]
  defstruct [:id, :day, :comic_id]

  def from_jsons(jsons) do
    Enum.map(jsons, &from_one_json/1)
  end

  # Private functions

  defp from_one_json(json) do
    %__MODULE__{id: json["id"], day: json["day"], comic_id: json["comic_id"]}
  end

end
