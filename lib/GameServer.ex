defmodule DoubleKingPedro.GameServer do
  use GenServer

  alias DoubleKingPedro.Game

  def handle_call({:get, game}, _from, map) do
    game = Map.get(map, game, %Game{})
    {:reply, game, map}
  end

  def handle_cast({:put, game, game_state}, map) do
    {:noreply, Map.put(map, game, game_state)}
  end

  def start_link(cache \\ %{}) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get(game), do: GenServer.call(__MODULE__, {:get, game})
  def put(game, game_state), do: GenServer.cast(__MODULE__, {:put, game, game_state})
end
