defmodule DoubleKingPedro.GameRoomChannel do
  use DoubleKingPedro.Web, :channel

  alias DoubleKingPedro.{SocketNickServer, GameServer, Game, Player, Card}

  def join("game_room:lobby", payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (game_room:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    broadcast! socket, "new_msg", %{body: body, user: SocketNickServer.get(socket.assigns.user)}
    {:noreply, socket}
  end

  def handle_in("new_command", %{"body" => body}, socket) do
    parts = String.split(body)
      case parts do
        ["/nick", nickname] -> SocketNickServer.put(socket.assigns.user, nickname)
        ["/g", game | args] -> handle_game_command(socket, game, args)
      end
    {:noreply, socket}
  end

  defp handle_game_command(socket, game, args) do
    g = GameServer.get(game)
    player = socket.assigns.user
    result = case args do
      ["nick", nickname] -> SocketNickServer.put(socket.assigns.user, nickname)
      ["join", team] ->
        name = SocketNickServer.get(socket.assigns.user)
        uuid = socket.assigns.user
        Game.join_game(g, %Player{name: name, id: uuid, team: team})
      ["start"] ->
        Game.start(GameServer.get(game))
      ["move", action] ->
        Game.make_move(g, socket.assigns.user, action)
      ["drop" | cards] ->
        Enum.reduce(cards, g, fn(card, acc) ->
          r = Game.make_move(acc, socket.assigns.user, {"drop", card})
          if is_atom(r) do
            acc
          else
            r
          end
        end)
      ["autodrop"] ->
        Enum.reduce(g.players[socket.assigns.user].hand, g, fn(card, acc) ->
          if acc.state == :card_select do
            r = Game.make_move(acc, socket.assigns.user, {"drop", card})
            if is_atom(r) || acc.state != :card_select do
              acc
            else
              r
            end
          else
            acc
          end
        end)
      ["move", action, card] ->
        Game.make_move(g, socket.assigns.user, {action, card})
      ["state"] ->
        hand = Map.get(g.players, socket.assigns.user, %{hand: []}).hand
        hand = Enum.map(hand, fn(card) -> Card.to_string(card) end)
        players = Enum.map(Game.order_players(g, Map.keys(g.players)),
          fn(player) -> g.players[player].name <> "(" <> g.players[player].team <> ")" end)
        bid = Game.get_value(g, "bid")
        current_player = Game.get_value(g, "current_player")
        trump = Game.get_value(g, "trump")
        on_table = Game.get_value(g, "on_table")
        scores = Game.get_value(g, "scores")
        push(socket, "state", %{game: game, hand: hand, state: g.state, players: players,
          current_player: current_player, bid: bid, trump: trump, on_table: on_table,
          scores: scores})
      _ -> :invalid_command
    end
    cond do
      result == :ok ->
        push(socket, "game-update", %{game: game, body: "OK"})
      is_atom(result) && result != :ok ->
        push(socket, "game-update", %{game: game, body: result})
      true ->
        GameServer.put(game, result)
        push(socket, "game-update", %{game: game, body: "OK"})
        current_player = Game.get_value(g, "current_player")
        broadcast!(socket, "state", %{"Player" => result.players[player].name,
          "Action" => args, "Now waiting on" => current_player, game: game})
    end
    if !is_atom(result) && (result.state != g.state || result.state == :bidding) do
      bid = Game.get_value(result, "bid")
      broadcast!(socket, "state-change", %{game: game, state: result.state, players: result.players, bid: bid})
    else
      result = if is_atom(result), do: g, else: result
      bid = Game.get_value(result, "bid")
      handle_out("state-change", %{game: game, state: result.state, players: result.players, bid: bid},
        socket)
    end
  end

  intercept(["state-change"])

  def handle_out("state-change", msg, socket) do
    # Filter out so we have just this players hand
    player = socket.assigns.user
    if Enum.member?(Map.keys(msg.players), player) do
      push(socket, "state-change", %{state: msg.state, game: msg.game,
      hand: Enum.map(msg.players[player].hand, &Card.to_string/1), bid: msg.bid})
    end
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
