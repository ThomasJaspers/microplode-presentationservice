module Main (main) where


import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Encode
import Signal
import SocketIO
import Task exposing (Task, andThen)

import MicroPlode.Move as Move exposing (Move)
import MicroPlode.Board as Board
import MicroPlode.Screen as Screen exposing (Screen)


type alias Model =
  { board : Board.Model
  }


type alias Context =
  { screen : Screen
  }


type Action
  = StartGame
  | BoardAction Board.Action
  | WebSocketMessageAction String
  | NoOp


{-|
Initializes the model and the context.
-}
init : (Model, Context)
init =
  ( { board = Board.init }
  , { screen = Screen.Welcome }
  )


{-|
Updates the current view on each signal tick.
-}
update : Action -> (Model, Context) -> (Model, Context)
update action (game, context) =
  case action of
    NoOp ->
      (game, context)
    -- TODO Actually, changing the screen must not happen directly as a
    -- consequence of the user's click but only on receiving the first
    -- next-turn event from the game service.
    StartGame ->
      (game, { context | screen = Screen.Board })
    BoardAction boardAction ->
      ({ game | board = Board.update boardAction game.board }, context)
    WebSocketMessageAction message ->
      let
        _ = Debug.log "websocket message: " message
        action : Board.Action
        action = Board.UpdateFromWebSocket message
        newBoard : Board.Model
        newBoard = Board.update action game.board
      in
        ({ game | board = newBoard }, context)


{-|
Renders the game.
-}
view : Signal.Address Action -> (Model, Context) -> Html
view address (game, context) =
  case context.screen of
    Screen.Welcome -> renderWelcome address
    Screen.Board -> renderBoard address game


{-|
Renders the welcome screen.
-}
renderWelcome : Signal.Address Action -> Html
renderWelcome address =
  let
    content =
      button
        [
          onClick address StartGame
        , style
          [ ("font-size", "large")
          , ("width", "200px")
          , ("height", "50px") ]
        ]
        [ text "START GAME" ]
  in
    div [ class "game" ] [ content ]


{-|
Renders the board.
-}
renderBoard : Signal.Address Action -> Model -> Html
renderBoard address game =
  let
    content = Board.view (Signal.forwardTo address BoardAction) game.board
  in
    div [ class "game" ] [ content ]


{-|
The main mailbox that routes the signals from all UI input elements.
-}
uiInputMailbox : Signal.Mailbox Action
uiInputMailbox = Signal.mailbox NoOp


{-|
The signal from UI input elements.
-}
uiInputSignal : Signal Action
uiInputSignal = uiInputMailbox.signal


mergedSignal : Signal Action
mergedSignal =
  Signal.merge uiInputSignal updateBoardSignal


{-|
The HTML output signal.
-}
main : Signal Html
main =
  let
    model =
      Signal.foldp
        update
        init
        mergedSignal
  in
    Signal.map (view uiInputMailbox.address) model


-- TODO Put Socket.IO handling into a separate module.
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Socket.IO handling:
--------------------------------------------------------------------------------

socket : Task x SocketIO.Socket
socket = SocketIO.io "http://localhost:3001" SocketIO.defaultOptions


{-|
Port for the initial handshake.
-}
port initial : Task x ()
port initial = socket `andThen` SocketIO.emit "" "Hello I am the MicroPlode client! :-)"


--------------------------------------------------------------------------------
-- Socket.IO: Server -> Browser:
--------------------------------------------------------------------------------

updateBoardMailbox : Signal.Mailbox String
updateBoardMailbox = Signal.mailbox ""


{-|
Incoming websocket mesages, server to browser.
-}
updateBoardSignal : Signal Action
updateBoardSignal =
  Signal.map
    (\message -> WebSocketMessageAction message)
    updateBoardMailbox.signal


port updateBoardPort : Task x ()
port updateBoardPort =
  socket `andThen` SocketIO.on "update-board" updateBoardMailbox.address


--------------------------------------------------------------------------------
-- Socket.IO: Browser -> Server:
--------------------------------------------------------------------------------

{-|
Filters the general UI input signal for move events (player clicked on a
square).
-}
moveEventSignal : Signal Move
moveEventSignal =
  let
    filter action =
      case action of
        BoardAction boardAction -> Board.actionToMove boardAction
        otherwise -> Nothing
  in
    Signal.filterMap filter { x = -1, y = -1, player = -1 } uiInputSignal


{-|
Filters the general UI input signal for game events (like game started).
-}
gameEventSignal : Signal Action
gameEventSignal =
  let
    filter action =
      case action of
        StartGame -> Just StartGame
        _ -> Nothing
  in
    Signal.filterMap filter NoOp uiInputSignal


{-|
Converts a move event to a task for sending a corresponding message via
Socket.IO.
-}
moveToSocketTask : Move -> Task x ()
moveToSocketTask action =
  socket `andThen` SocketIO.emit "move" (encodeMove action)


{-|
Converts a game event to a task for sending a corresponding message via
Socket.IO.
-}
gameEventToSocketTask : Action -> Task x ()
gameEventToSocketTask action =
  socket `andThen` SocketIO.emit "game-event" (encodeGameEvent action)


{-|
Encodes a game event as JSON.
-}
encodeGameEvent : Action -> String
encodeGameEvent action =
  let
    event = case action of
      StartGame -> "new-game"
      _ -> "noop"
    payload =
      Json.Encode.object [ ("event", Json.Encode.string event) ]
  in
    Json.Encode.encode 0 payload


{-|
Encodes a move as JSON.
-}
encodeMove : Move -> String
encodeMove move =
  let
    payload =
      Json.Encode.object
        [ ("x", Json.Encode.int move.x)
        , ("y", Json.Encode.int move.y)
        , ("player", Json.Encode.int move.player)
        ]
  in
    Json.Encode.encode 0 payload


{-|
Outgoing websocket messages for moves (browser to server).
-}
port moveToServerPort : Signal (Task x ())
port moveToServerPort =
  Signal.map moveToSocketTask moveEventSignal


{-|
Outgoing websocket messages for game events (browser to server).
-}
port gameEventToPort : Signal (Task x ())
port gameEventToPort =
  Signal.map gameEventToSocketTask gameEventSignal

