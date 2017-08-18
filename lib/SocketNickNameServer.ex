defmodule DoubleKingPedro.SocketNickServer do
  use GenServer

  def handle_call({:get, socket}, _from, map) do
    name = Map.get(map, socket, "Anonymous")
    {:reply, name, map}
  end

  def handle_cast({:put, socket, name}, map) do
    {:noreply, Map.put(map, socket, name)}
  end

  def start_link(cache \\ %{}) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get(socket), do: GenServer.call(__MODULE__, {:get, socket})
  def put(socket, name), do: GenServer.cast(__MODULE__, {:put, socket, name})
end
