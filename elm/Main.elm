module Main (main) where


import Effects exposing (Effects)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Encode
import Signal
import SocketIO
import Task exposing (Task, andThen)

import MicroPlode.Click as Click exposing (Click)
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
update : Action -> (Model, Context) -> (Model, Context, Effects Action)
update action (game, context) =
  (case action of
    NoOp ->
      (game, context, Effects.none)
    StartGame ->
      (game, { context | screen = Screen.Board }, Effects.none)
    -- TODO Also send POST request to service
    BoardAction boardAction ->

      ({ game | board = Board.update boardAction game.board }, context, Effects.none)
    WebSocketMessageAction message ->
      let
        _ = Debug.log "websocket message: " message
        action : Board.Action
        action = Board.UpdateFromWebSocket message
        newBoard : Board.Model
        newBoard = Board.update action game.board
      in
        ({ game | board = newBoard }, context, Effects.none)
  )


update2 : Action -> (Model, Context) -> (Model, Context)
update2 action (game, context) =
  let
    (game', context', _) = update action (game, context)
  in
    (game', context')


doPostStartGame : Effects Action
doPostStartGame =
  Http.post null "/game" Http.empty
    |> Task.toMaybe
    |> Task.map NewGif
    |> Effects.task


{-|
Renders the game.
-}
view : Signal.Address Action -> (Model, Context) -> Html
view address (game, context) =
  case context.screen of
    Screen.Welcome -> renderWelcome address
    Screen.Board -> renderBoard address game


renderWelcome : Signal.Address Action -> Html
renderWelcome address =
  let
    content =
      button
        [
          -- TODO Send HTTP POST to /game when clicking the button
          onClick address StartGame
        , style
          [ ("font-size", "large")
          , ("width", "200px")
          , ("height", "50px") ]
        ]
        [ text "START GAME" ]
  in
    div [ class "game" ] [ content ]


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


{-|
Filter & transform uiInputSignal so that it only contains mouse clicks on
squares.
-}
boardActionSignal : Signal Click
boardActionSignal =
  let
    filter action =
      case action of
        BoardAction boardAction -> Board.actionsToCoordinates boardAction
        otherwise -> Nothing
  in
    Signal.filterMap filter { x = -1, y = -1, player = -1 } uiInputSignal
-- TODO The default value is actually send to the server. How to get rid of
-- that?


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
        update2
        init
        mergedSignal
  in
    Signal.map (view uiInputMailbox.address) model


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


{-|
Outgoing websocket mesages, browser to server.
-}
port wsToServer : Signal (Task x ())
port wsToServer =
  Signal.map
    (\click ->
      socket `andThen` SocketIO.emit "click" (encodeClick click)
    )
    boardActionSignal


encodeClick : Click -> String
encodeClick click =
  let
    object =
      Json.Encode.object
        [ ("x", Json.Encode.int click.x)
        , ("y", Json.Encode.int click.y)
        , ("player", Json.Encode.int click.player)
        ]
  in
    Json.Encode.encode 0 object


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
