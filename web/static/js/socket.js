// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "web/static/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":
import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: window.userToken}})

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/2" function
// in "web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, pass the token on connect as below. Or remove it
// from connect if you don't care about authentication.

socket.connect()

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("game_room:lobby", {})
let chatInput         = document.querySelector("#command-input")
let messagesContainer = document.querySelector("#messages")
let buttonContainer = document.querySelector("#actions")

chatInput.addEventListener("keypress", event => {
  if(event.keyCode === 13){
    let v = chatInput.value;
    if (v[0] == "/") {
      channel.push("new_command", {body: v})
    } else
      channel.push("new_msg", {body: v})
    chatInput.value = ""
  }
})

channel.on("new_msg", payload => {
  let messageItem = document.createElement("li");
  messageItem.innerText = `[${payload.user}] ${payload.body}`
  messagesContainer.appendChild(messageItem)
  messageItem.scrollIntoView();
})

channel.on("game-update", payload => {
  let messageItem = document.createElement("li");
  messageItem.innerText = `[Game: ${payload.game}] ${payload.body}`
  messagesContainer.appendChild(messageItem)
  messageItem.scrollIntoView();
})

channel.on("state", payload => {
  let messageItem = document.createElement("li");
  for (var name in payload) {
    if(payload[name] != "N/A") {
      messageItem = document.createElement("li");
      messageItem.innerText = `[Game: ${payload.game}] ${name}: ${payload[name]}`
      messagesContainer.appendChild(messageItem)
    }
  }
  messageItem.scrollIntoView();
})

channel.on("state-change", payload => {
  console.log(payload);
  while(buttonContainer.firstChild)
    buttonContainer.removeChild(buttonContainer.firstChild);
  if(payload.state == "bidding") {
    let bidButton = document.createElement("input");
    bidButton.setAttribute("type", "button");
    bidButton.setAttribute("class", "btn btn-primary");
    bidButton.setAttribute("value", "Pass");
    bidButton.setAttribute("onClick", `bidValue("pass", "${payload.game}")`);
    buttonContainer.appendChild(bidButton);
    let values = ["1", "5", "10"];
    for(var i in values) {
      bidButton = document.createElement("input");
      bidButton.setAttribute("type", "button");
      bidButton.setAttribute("class", "btn btn-primary");
      bidButton.setAttribute("value", `+${values[i]}`);
      bidButton.setAttribute("onClick", `bidValue(${payload.bid}+${values[i]}, "${payload.game}")`);
      buttonContainer.appendChild(bidButton);
    }
  }
  let deleteButton = document.createElement("span");
  if(payload.state == "card_select")
    deleteButton.innerText = "Select a card to drop";
  else if(payload.state == "tricks")
    deleteButton.innerText = "Select a card to play";
  else
    deleteButton.innerText = "Your Hand";
  buttonContainer.appendChild(deleteButton)
  if(payload.state == "tricks") {
    deleteButton = document.createElement("input");
    deleteButton.setAttribute("type", "button");
    deleteButton.setAttribute("class", "btn btn-primary");
    deleteButton.setAttribute("value", "Pass");
    deleteButton.setAttribute("onClick", `playCard("pass", "${payload.game}")`);
    buttonContainer.appendChild(deleteButton)
  }
  for(var card in payload.hand) {
    deleteButton = document.createElement("input");
    deleteButton.setAttribute("type", "button");
    if(payload.state == "card_select")
      deleteButton.setAttribute("class", "btn btn-danger");
    else
      deleteButton.setAttribute("class", "btn btn-primary");
    deleteButton.setAttribute("value", payload.hand[card]);
    if(payload.state == "card_select")
      deleteButton.setAttribute("onClick", `dropCard("${payload.hand[card]}", "${payload.game}")`);
    else if(payload.state == "tricks")
      deleteButton.setAttribute("onClick", `playCard("${payload.hand[card]}", "${payload.game}")`);
    else
      deleteButton.setAttribute("disabled", true);
    buttonContainer.appendChild(deleteButton)
  }
})

channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

function dropCard(card, game) {
  channel.push("new_command", {body: `/g ${game} move drop ${card}`});
}

function playCard(card, game) {
  channel.push("new_command", {body: `/g ${game} move ${card}`});
}

function bidValue(value, game) {
  channel.push("new_command", {body: `/g ${game} move ${value}`});
}

window.dropCard = dropCard;
window.playCard = playCard;
window.bidValue = bidValue;

export default socket
