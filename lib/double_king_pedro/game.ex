defmodule DoubleKingPedro.Game do
  alias DoubleKingPedro.{Player, Card, Game}
  defstruct players: %{}, state: :lobby, state_content: %{}, teams: %{}

  @moduledoc """
  The Game module provides the logic for Double King Pedro
  """

  @type gameState :: :lobby | :bidding | :trump_select | :card_select | :tricks

  @doc """
  Adds a %Player{} to the provided game; if the game is full, returns :game_full
  """
  @spec join_game(%Game{}, %Player{}) :: %Game{} | :game_full
  def join_game(game, player)
  def join_game(%Game{players: players}, _player)
    when map_size(players) >= 4, do: :game_full
  def join_game(game, player) do
    cond do
      Map.has_key?(game.players, player.id) -> game
      true ->
        %{game | players: Map.put(game.players, player.id, player),
            teams: Map.put(game.teams, player.team, 0)}
    end
  end

  @doc """
  If the game is in a valid state to start playing, transitions to the playering state
  """
  def start(_game = %Game{players: players}) when map_size(players) < 4, do: :not_ready
  def start(game = %Game{state: :lobby}) do
    next_state(game, :tricks, :bidding, {})
  end

  defp deal_hands(game, players, deck)
  defp deal_hands(game, [], deck), do: {game, deck}
  defp deal_hands(game, [h | t], deck) do
    {hand, deck} = Card.deal(deck, 12)
    deal_hands(%{game | players: Map.put(game.players, h.id, %{h | hand: hand})}, t, deck)
  end

  @doc """
  The primary interface to the game; after the game has been started, all moves
    get sent to this function until the game ends.

    It accepts the following forms:

    * make_move(game, player, player_bid) - where bid is a number between 0 and 100
    * make_move(game, player, trump) - where trump is one of :hearts, :diamonds, :spades, or :clubs
    * make_move(game, player, {action, card}) - where action is either :drop or :pass, and card
        is a card in the players hand
    * make_mopve(game, player, %Card{}) - players a card from the players hand

  Each of these states can return: %Game (an updated game object), :not_your_turn, or :invalid_move.
  In general, :invalid_move means the player tried to something that wasn't valid, such as playering
    a non-trump card during a trick where trump is required, and :not_your_turn means the player
    attempted to make a move when it wasn't their turn.

  If a player who is not in the game attempts to make a move, it returns :not_your_turn
  """
  @spec make_move(%Game{}, String.t, any) :: %Game{} | :not_your_turn | :invalid_move
  def make_move(game = %Game{state: :bidding, state_content: sc = %{bid: bid, players: [cp | others]}}, player, move) do
    cond do
      player != cp ->
        :not_your_turn
      move == :pass ->
        [h | t] = others
        if t == [] do
          next_state(game, :bidding, :trump_select, {h, bid})
        else
          %{game | state_content: %{sc | players: others}}
        end
      !is_integer(move) ->
        :invalid_move
      bid >= move ->
        :invalid_move
      move > 100 ->
        :invalid_move
      move == 100 ->
        next_state(game, :bidding, :trump_select, {cp, move})
      true ->
        %{game | state_content: %{sc | bid: move, players: others ++ [cp]}}
    end
  end
  def make_move(game = %Game{state: :trump_select, state_content: %{winner: winner, bid: bid}}, player, move) do
    cond do
      player != winner ->
        :not_your_turn
      Enum.member?([:spades, :hearts, :diamonds, :clubs], move) ->
        next_state(game, :trump_select, :card_select, {winner, bid, move})
      true ->
        :invalid_move
    end
  end
  def make_move(game = %Game{state: :card_select, players: players,
      state_content: %{trump: trump, winner: winner, bid: bid}}, player, {action, card}) do
    player_list = Map.keys(players)
    game = cond do
      !Enum.member?(player_list, player) ->
        :not_your_turn
      action == :pass ->
        p = Map.get(players, player)
        if Enum.member?(p.hand, card) && is_trump?(card, trump) && count_trump(p.hand, trump) > 6 do
          team = game.players[player].team
          [partner] = Enum.filter(Map.values(game.players),
            fn (%Player{team: p_team, id: id}) -> team == p_team && id != player  end)
          partner = if count_trump(partner.hand, trump) > 6 do
            new_pos = rem(partner.position + 1, 4)
            [partner] = Enum.filter(Map.values(game.players),
              fn(p) -> p.position == new_pos end)
            partner
          else
            partner
          end
          my_hand = List.delete(p.hand, card)
          other_hand = [card | partner.hand]
          %{game | players: %{players | player => %{players[player] | hand: my_hand},
            partner.id => %{partner | hand: other_hand}}}
        else
          :invalid_move
        end
      action == :drop ->
        p = Map.get(players, player)
        if Enum.member?(p.hand, card) && !is_trump?(card, trump) do
          hand =  List.delete(p.hand, card)
          %{game | players: %{players | p.id => %{p | hand: hand}}}
        else
          :invalid_move
        end
      true ->
        :invalid_move
    end
    if !is_atom(game) && all_hands_ready(Map.values(game.players)) do
      next_state(game, :card_select, :tricks, {winner, bid, trump})
    else
      game
    end
  end
  def make_move(game = %Game{state: :tricks, state_content: %{players: [cp | others],
      winner: winner, on_table: on_table, trump: trump}}, player, move) do
    game = cond do
      cp != player ->
        :not_your_turn
      move == :pass ->
        %{game | state_content: %{game.state_content | players: others},
            players: %{game.players | cp => %{game.players[cp] | hand: []}}}
      !Enum.member?(game.players[cp].hand, move) ->
        :invalid_move
      game.state_content.trump_required && !is_trump?(move, trump) ->
        :invalid_move
      true ->
        on_table2 = [{move, cp} | on_table]
        players = others ++ [cp]
        trump_required = if cp == winner do
          is_trump?(move, trump)
        else
          game.state_content.trump_required
        end
        hand = List.delete(game.players[cp].hand, move)
        %{game | state_content: %{game.state_content | players: players,
            on_table: on_table2, trump_required: trump_required},
            players: %{game.players | cp => %{game.players[cp] | hand: hand}}}
    end
    cond do
      is_atom(game) ->
        game
      game.state_content.players == [] ->
        points = count_points(trump, game.players[cp].hand)
        game =
          %{game | teams: %{game.teams | winner.team => game.teams[winner.team] + points}}
        next_state(game, :tricks, :bidding, {})
      true ->
        [cp | _] = game.state_content.players
        on_table = game.state_content.on_table
        if cp == winner && on_table != [] do
          winner = game.players[select_winning_team(trump, on_table)]
          points = count_points(trump, on_table)
          player_ids = rotate(Map.keys(game.players), winner.id)
          if all_hands_empty(Map.values(game.players)) do
           next_state(game, :tricks, :bidding, {})
          else
           %{game | teams: %{game.teams | winner.team => game.teams[winner.team] + points},
               state_content: %{game.state_content | winner: winner, players: player_ids,
               trump_required: false}}
          end
        else
          game
        end
    end
  end

  @doc false
  def count_trump(hand, trump) do
    Enum.count(hand, fn(card) -> is_trump?(card, trump) end)
  end

  @doc false
  def next_state(game, phase1, phase2, params)
  def next_state(game, :bidding, :trump_select, {winner, bid}) do
    winner = Map.get(game.players, winner)
    winner = %Player{winner | hand: winner.hand ++ game.state_content.kiddie}
    players = Map.put(game.players, winner.id, winner)
    %{game | state: :trump_select, state_content: %{bid: bid, winner: winner.id}, players: players}
  end
  def next_state(game, :trump_select, :card_select, {winner, bid, trump}) do
    %{game | state: :card_select, state_content: %{bid: bid, winner: winner, trump: trump}}
  end
  def next_state(game, :card_select, :tricks, {winner, bid, trump}) do
    player_ids = Map.keys(game.players)
    |> rotate(winner)
    %{game | state: :tricks, state_content: %{bid: bid, winner: winner,
      trump: trump, players: player_ids, on_table: [],
      team_winner: game.players[winner].team, trump_required: false}}
  end
  @doc false
  def next_state(game, :tricks, :bidding, {}, shuffle \\ true) do
    deck = if shuffle, do: Card.deck |> Enum.shuffle, else: Card.deck
    {kiddie, deck} = Card.deal(deck, 5)
    players = Map.values(game.players)
    player_ids = Map.keys(game.players)
    {game, []} = deal_hands(game, players, deck)
    %{game | state: :bidding, state_content: %{kiddie: kiddie, bid: 0, players: player_ids}}
  end

  @doc false
  def is_trump?(%Card{suite: suite, value: value}, trump) do
    suite == trump || (Card.same_color(suite, trump) && Enum.member?([5, 9, 13], value))
        || suite == :joker
  end

  defp all_hands_ready(players)
  defp all_hands_ready([]), do: true
  defp all_hands_ready([%{hand: hand} | _]) when length(hand) != 6, do: false
  defp all_hands_ready([_ | t]), do: all_hands_ready(t)

  defp all_hands_empty(players)
  defp all_hands_empty([]), do: true
  defp all_hands_empty([%{hand: hand} | _ ]) when length(hand) != 0, do: false
  defp all_hands_empty([_ | t]), do: all_hands_empty(t)

  defp rotate(list_to_rotate, what_should_be_at_front)
  defp rotate(l = [h | _], f) when h == f, do: l
  defp rotate([h | t], f), do: rotate(t ++ [h], f)

  # Returns the index of the team that one
  defp select_winning_team(trump, cards, so_far \\ {nil, :no_player})
  defp select_winning_team(_trump, [], {_w_card, w_player}), do: w_player
  defp select_winning_team(trump, [h | t], {nil, _w_team}), do: select_winning_team(trump, t, h)
  defp select_winning_team(trump, [{card, player} | others], cur = {w_card, _}) do
    %Card{suite: w_suite, value: w_value} = w_card
    %Card{suite: c_suite, value: c_value} = card
    cond do
      !is_trump?(w_card, trump) && is_trump?(card, trump) ->
        select_winning_team(trump, others, {card, player})
      is_trump?(w_card, trump) && !is_trump?(card, trump) ->
        select_winning_team(trump, others, cur)
      w_suite != c_suite && w_value == c_value ->
        select_winning_team(trump, others, cur)
      c_value > w_value ->
        select_winning_team(trump, others, {card, player})
      true -> # NOTE: in cases of a tie between non-trump cards, this retains the current winner
        select_winning_team(trump, others, cur)
    end
  end

  defp count_points(trump, cards)
  defp count_points(_trump, []), do: 0
  defp count_points(trump, [{card, _} | others]) do
    cond do
      !is_trump?(card, trump) ->
        count_points(trump, others)
      true ->
        value = card.value
        value = case value do
          14 -> 1 # Ace
          13 -> 25 # King
          11 -> 1 # Jack
          10 -> 1
          9 -> 9
          5 -> 5
          2 -> 1
          1 -> 18  # Joker
          _ -> 0
        end
        value + count_points(trump, others)
    end
  end
end
