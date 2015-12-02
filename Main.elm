module Main (main) where


import Html exposing (..)
import Html.Attributes exposing (..)
import Signal

import MicroPlode.Arena as Arena
import MicroPlode.Screen as Screen exposing (Screen)


type alias Model =
  { arena : Arena.Model
  }


type alias Context =
  { view : Screen
  }


type Action
  = ArenaAction Arena.Action
  | NoOp


{-|
Initializes the model and the context.
-}
init : (Model, Context)
init =
  ( { arena = Arena.init }
  , { view = Screen.Game }
  )


{-|
Updates the current view on each signal tick.
-}
update : Action -> (Model, Context) -> (Model, Context)
update action (game, context) =
  case action of
    NoOp ->
      (game, context)
    ArenaAction arenaAction ->
      ({ game | arena = Arena.update arenaAction game.arena }, context)


{-|
Renders the game view.
-}
view : Signal.Address Action -> (Model, Context) -> Html
view address (game, context) =
  let
    content = Arena.view (Signal.forwardTo address ArenaAction) game.arena
  in
    div [ class "game" ] [ content ]


{-|
The main mailbox that routes the signals from all UI input elements.
-}
mainMailbox : Signal.Mailbox Action
mainMailbox = Signal.mailbox NoOp


{-|
Merges the constant timed tick and the signal from UI input elements.
-}
mainSignal : Signal Action
mainSignal = mainMailbox.signal


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
        mainSignal
  in
    Signal.map (view mainMailbox.address) model
