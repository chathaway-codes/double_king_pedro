# DoubleKingPedro

To start your Phoenix app:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `npm install`
  * Start Phoenix endpoint with `mix phoenix.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

The Web-CLI supports the following commands:

  * /nick <nickname, one word>
  * /g <game name> join <team to join>
  * /g <game name> state
  * /g <game name> start
  * /g <game name> move <bid amount>
  * /g <game name> move pass
  * /g <game name> move <trump to select; hearts, spades, clubs, or diamonds>
  * /g <game name> move drop <Card to drop; H2, D13, J1, etc.>
  * /g <game name> move pass <Card to pass to your partner>
  * /g <game name> move <Card to play>

Most commands are context sensitive; that is, you can only pass during bidding or during tricks, and can only play a card when valid.
If you try to make invalid move, the game will tell you so.

Once you join a game and it is started, there are buttons for most things along the bottom.
The exception being selecting trump; use /g <game name> move <hearts|clubs|diamonds|spades>

Suites are:
  * H = hearts
  * D = diamonds
  * C = clubs
  * S = spades
  * J = jokes

2-10 represent card values; 11 means Jack, 12 means Queen, 13 means King, and 14 means Ace.
Joker is represented by "J1".
