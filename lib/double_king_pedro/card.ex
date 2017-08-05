defmodule DoubleKingPedro.Card do
  alias DoubleKingPedro.Card
  @type card :: %{suite: suite, value: integer}
  defstruct suite: :hearts, value: 14

  @type suite :: :hearts | :diamonds | :clubs | :spades | :joker

  @moduledoc """
  Represents a deck of cards
  """

  @doc """
  Constructs a new, unshuffled, deck
  """
  @spec deck() :: [card, ...]
  def deck() do
    gen_suite(:hearts, 2) ++ gen_suite(:diamonds, 2) ++
      gen_suite(:clubs, 2) ++ gen_suite(:spades, 2) ++ [%Card{suite: :joker, value: 1}]
  end

  @doc """
  Generates a single suite of cards
  """
  @spec gen_suite(suite, where_to_start :: integer) :: [card, ...]
  def gen_suite(suite, value \\ 2)
  def gen_suite(_suite, 15), do: []
  def gen_suite(suite, n) do
    [%Card{suite: suite, value: n} | gen_suite(suite, n+1)]
  end

  @doc """
  Deals cards out <number> of cards to a hand (either empty or a list of %Card)
  """
  @spec deal(deck :: [card], number :: integer, hand :: [card]) :: {hand :: [card], deck :: [card]} | :deck_empty
  def deal(deck, number, hand \\ [])
  def deal([], number, _hand) when number > 0, do: :deck_empty
  def deal(deck, 0, hand), do: {hand, deck}
  def deal([h = %Card{} | t], n, hand), do: deal(t, n-1, [h | hand])

  @doc """
  If the two given suites are of the same color, returns true, else, false.
  """
  @spec same_color(any, any) :: boolean
  def same_color(suite1, suite2)
  def same_color(:hearts, :diamonds), do: true
  def same_color(:diamonds, :hearts), do: true
  def same_color(:clubs, :spades), do: true
  def same_color(:spades, :clubs), do: true
  def same_color(_, _), do: false
end
