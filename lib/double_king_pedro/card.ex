defmodule DoubleKingPedro.Card do
  alias DoubleKingPedro.Card
  defstruct suite: :hearts, value: 14

  @type suite :: :hearts | :diamonds | :clubs | :spades | :joker

  @spec deck() :: [%Card{}, ...]
  def deck() do
    gen_suite(:hearts, 2) ++ gen_suite(:diamonds, 2) ++
      gen_suite(:clubs, 2) ++ gen_suite(:spades, 2) ++ [%Card{suite: :joker, value: 1}]
  end

  def gen_suite(suite, value)
  def gen_suite(_suite, 15), do: []
  def gen_suite(suite, n) do
    [%Card{suite: suite, value: n} | gen_suite(suite, n+1)]
  end

  @spec deal(deck :: [%Card{}], number :: integer, hand :: [%Card{}]) :: {hand :: [%Card{}], deck :: [%Card{}]}
  def deal(deck, number, hand \\ [])
  def deal([], number, _hand) when number > 0, do: :deck_empty
  def deal(deck, 0, hand), do: {hand, deck}
  def deal([h | t], n, hand), do: deal(t, n-1, [h | hand])

  def same_color(suite1, suite2)
  def same_color(:hearts, :diamonds), do: true
  def same_color(:diamonds, :hearts), do: true
  def same_color(:clubs, :spades), do: true
  def same_color(:spades, :clubs), do: true
  def same_color(_, _), do: false
end
