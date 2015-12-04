module MicroPlode.Square
  ( Action(Increment)
  , Model
  , init
  , view
  , update) where


import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


import MicroPlode.Click as Click exposing (Click)


type alias Model =
  { x : Int
  , y : Int
  , charge : Int
  }


type Action
  = Increment Click


{-|
Initializes a square.
-}
init : Int -> Int -> Model
init x y =
  { x = x
  , y = y
  , charge = 0
  }


{-|
Updates the square's charge.
-}
update : Action -> Model -> Model
update action square =
  case action of
    Increment _ ->
      { square | charge = square.charge + 1 }


view : Signal.Address Action -> Model -> Html
view address square =
  let chargeText =
    if square.charge == 0
    then text "o"
    else square.charge |> toString |> text
  in
    td
      [ class "square"
      , onClick address (Increment (Click.init square.x square.y 1)) ]
      [ chargeText ]

