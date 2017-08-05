defmodule DoubleKingPedro.Player do
  alias DoubleKingPedro.Player
  defstruct name: "", hand: [], id: nil, team: 0, position: 0

  @moduledoc """
  Represents a player in a double king pedro game
  """

  def new(name, team \\ 0, position \\ 0, uuid \\ nil) do
    uuid = if uuid == nil, do: Ecto.UUID.generate(), else: uuid
    %Player{name: name, id: uuid, team: team, position: position}
  end
end
