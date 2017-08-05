defmodule DoubleKingPedro.GameTests do
  use ExUnit.Case
  doctest DoubleKingPedro.Game

  alias DoubleKingPedro.{Game, Player, Card}

  test "can join game with 0 players" do
    %Game{}
    |> Game.join_game(Player.new("Jojo"))
  end
  test "can join game 3 players" do
    game = %Game{}
    |> Game.join_game(Player.new("Jojo"))
    |> Game.join_game(Player.new("Max"))
    |> Game.join_game(Player.new("Zia"))
    |> Game.join_game(Player.new("Poe"))
    assert map_size(game.players) == 4
  end
  test "can't join game with 4 players" do
    :game_full = %Game{}
    |> Game.join_game(Player.new("Jojo"))
    |> Game.join_game(Player.new("Max"))
    |> Game.join_game(Player.new("Zia"))
    |> Game.join_game(Player.new("Poe"))
    |> Game.join_game(Player.new("Simba"))
  end
  test "can't start game without four players" do
    :not_ready = %Game{}
    |> Game.join_game(Player.new("Jojo"))
    |> Game.join_game(Player.new("Max"))
    |> Game.join_game(Player.new("Zia"))
    |> Game.start
  end
  test "can start game with four players" do
    game = %Game{}
    |> Game.join_game(Player.new("Jojo"))
    |> Game.join_game(Player.new("Max"))
    |> Game.join_game(Player.new("Zia"))
    |> Game.join_game(Player.new("Poe"))
    |> Game.start
    for player <- Map.values(game.players) do
      assert length(player.hand) == 12
    end
    assert length(game.state_content.kiddie) == 5
  end

  defp make_game() do
    [player1, player2, player3, player4] = ["1", "2", "3", "4"]
    %Game{}
    |> Game.join_game(Player.new("Jojo", 0, 0, player1))
    |> Game.join_game(Player.new("Max", 1, 1, player2))
    |> Game.join_game(Player.new("Zia", 0, 2, player3))
    |> Game.join_game(Player.new("Poe", 1, 3, player4))
    |> Game.start
  end

  test "only correct player can make move" do
    game = make_game()
    [_, player2, _, _] = Map.values(game.players) # Select 2nd player
    assert game.state == :bidding
    assert Game.make_move(game, player2.id, 15) == :not_your_turn
  end
  test "correct player can make move" do
    game = make_game()
    [player1, _, _, _] = Map.values(game.players) # Select 1st player
    assert game.state == :bidding
    %Game{state_content: %{bid: 15}} = Game.make_move(game, player1.id, 15)
  end
  test "phase 1 bidding" do
    game = make_game()
    [player1, player2, player3, player4] = Map.values(game.players)
    assert game.state == :bidding
    game = %Game{state_content: %{bid: 15}} = Game.make_move(game, player1.id, 15)
    assert Game.make_move(game, player2.id, 15) == :invalid_move
    game = Game.make_move(game, player2.id, 45)
    |> Game.make_move(player3.id, :pass)
    |> Game.make_move(player4.id, 100)
    assert game.state == :trump_select
  end
  test "phase 2 select trump" do
    game = make_game()
    [player1, player2, _player3, _player4] = Map.keys(game.players)
    game = Game.next_state(game, :bidding, :trump_select, {player1, 100})
    game2 = Game.make_move(game, player1, :hearts)
    assert game2.state == :card_select
    assert :not_your_turn == Game.make_move(game, player2, :diamonds)
  end
  test "phase 3 card select" do
    game = make_game()
    [player1, _player2, _player3, _player4] = Map.keys(game.players)
    game = Game.next_state(game, :bidding, :trump_select, {player1, 100})
    |> Game.next_state(:trump_select, :card_select, {player1, 100, :hearts})
    card = get_non_trump_card(Map.get(game.players, player1).hand, :hearts)
    game = Game.make_move(game, player1, {:drop, card})
    assert length(Map.get(game.players, player1).hand) == 16
    card = get_trump_card(game.players[player1].hand, :hearts)
    assert :invalid_move == Game.make_move(game, player1, {:drop, card})
  end
  test "can pass card" do
    game = make_game()
    [player1, _player2, _player3, _player4] = ["1", "2", "3", "4"]
    game = Game.next_state(game, :bidding, :trump_select, {player1, 100})
    |> Game.next_state(:trump_select, :card_select, {player1, 100, :hearts})
    game = %{game | players: %{game.players | player1 =>
      %{game.players[player1] | hand: Card.gen_suite(:hearts, 2)}}}
    card = get_trump_card(game.players[player1].hand, :hearts)
    length1 = length(game.players[player1].hand)
    game = Game.make_move(game, player1, {:pass, card})
    team = game.players[player1].team
    [partner] = Enum.filter(Map.values(game.players),
      fn (%Player{team: p_team, id: id}) -> team == p_team && id != player1  end)
    assert length(game.players[player1].hand) == length1-1
    [h | _] = partner.hand
    assert h == %Card{suite: :hearts, value: 2}
  end
  test "phase 4 trick" do
  end
  test "complete round" do
    [player1, player2, player3, player4] = ["1", "2", "3", "4"]
    game = %Game{}
    |> Game.join_game(Player.new("Jojo", "0", 0, player1))
    |> Game.join_game(Player.new("Max", "1", 1, player2))
    |> Game.join_game(Player.new("Zia", "0", 2, player3))
    |> Game.join_game(Player.new("Poe", "1", 3, player4))
    # Force the deck so we can control things
    game = Game.next_state(game, :tricks, :bidding, {})
    # Bidding
    game = game
    |> Game.make_move(player1, 25)
    |> Game.make_move(player2, 50)
    |> Game.make_move(player3, :pass)
    |> Game.make_move(player4, :pass)
    |> Game.make_move(player1, 69)
    |> Game.make_move(player2, :pass)
    assert game.state == :trump_select
    # Select trump
    game = game
    |> Game.make_move(player1, :hearts)
    assert game.state == :card_select
    # Select the cards
    game = game
    |> drop_hand_to_six(player1)
    |> drop_hand_to_six(player2)
    |> drop_hand_to_six(player3)
    |> drop_hand_to_six(player4)
    |> drop_hand_to_six(player1)
    |> drop_hand_to_six(player2)
    |> drop_hand_to_six(player3)
    |> drop_hand_to_six(player4)
    assert game.state == :tricks
    assert length(game.players[player1].hand) == 6
    assert length(game.players[player2].hand) == 6
    assert length(game.players[player3].hand) == 6
    assert length(game.players[player4].hand) == 6
    # Play some tricks
    [card | _] = game.players[player2].hand
    :not_your_turn = Game.make_move(game, player2, card)
     game = game
     |> Game.make_move(player1, get_trump_card(game.players[player1].hand, :hearts))
     |> Game.make_move(player2, get_trump_card(game.players[player2].hand, :hearts))
     |> Game.make_move(player3, get_trump_card(game.players[player3].hand, :hearts))
     |> Game.make_move(player4, get_trump_card(game.players[player4].hand, :hearts))
     play_trick(game)
  end
  test "complete game" do
  end

  test "test is_trump?" do
    assert true == Game.is_trump?(%Card{suite: :hearts, value: 3}, :hearts)
    assert true == Game.is_trump?(%Card{suite: :hearts, value: 5}, :hearts)
    assert true == Game.is_trump?(%Card{suite: :hearts, value: 13}, :hearts)
  end

  defp play_trick(game)
  defp play_trick(game = %Game{state: :tricks, state_content: %{players: [cp | _], trump: trump}}) do
    card = get_trump_card(game.players[cp].hand, trump)
    game = Game.make_move(game, cp, card)
    if game.state == :bidding do
      game
    else
      play_trick(game)
    end
  end

  defp get_trump_card(hand, trump)
  defp get_trump_card([], _trump), do: :pass
  defp get_trump_card([card | t], trump) do
    if Game.is_trump?(card, trump) do
      card
    else
      get_trump_card(t, trump)
    end
  end

  defp get_non_trump_card(hand, trump)
  defp get_non_trump_card([], _trump), do: :none
  defp get_non_trump_card([card | t], trump) do
    if !Game.is_trump?(card, trump) do
      card
    else
      get_non_trump_card(t, trump)
    end
  end

  # Dropd the players hand to six by dropping/passing
  defp drop_hand_to_six(game, player) do
    drop_hand_to_six(game, player, game.players[player].hand)
  end
  defp drop_hand_to_six(game, _player, hand) when length(hand) == 6, do: game
  defp drop_hand_to_six(game, player, hand) do
    card = get_non_trump_card(hand, game.state_content.trump)
    #IO.puts("Cards:")
    #IO.inspect(hand)
    if card == :none do
      #IO.puts("pass trump")
      card = get_trump_card(hand, game.state_content.trump)
      game = Game.make_move(game, player, {:pass, card})
      drop_hand_to_six(game, player, game.players[player].hand)
    else
      #IO.puts("drop non-trump")
      game = Game.make_move(game, player, {:drop, card})
      drop_hand_to_six(game, player, game.players[player].hand)
    end
  end
end
