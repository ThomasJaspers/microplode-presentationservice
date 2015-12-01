module Main (main) where

import Html exposing (..)
import Html.Attributes exposing (..)
import Signal

type alias Model = Int

type alias Context =
  { view : String
  }


type Action
  = NoOp


{-|
Initializes the model and the context.
-}
init : (Model, Context)
init =
  (42, { view = "Welcome" })


{-|
Updates the current view on each signal tick.
-}
update : Action -> (Model, Context) -> (Model, Context)
update action (game, context) =
  case action of
    NoOp ->
      (game, context)


{-|
Renders the game view.
-}
view : Signal.Address Action -> (Model, Context) -> Html
view address (game, context) =
  div
    [ class "game" ]
    [ text "MicroPlode" ]


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
