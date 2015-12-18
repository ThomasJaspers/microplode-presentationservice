module MicroPlode.Square
  ( Action(Increment)
  , Model
  , init
  , view
  , update
  , decodeSquare
  , squareDecoder) where


import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json exposing ((:=))

import MicroPlode.Move as Move exposing (Move)


type alias Model =
  { x : Int
  , y : Int
  , load : Int
  , playerId : Maybe Int
  }


type Action
  = Increment Move


{-|
Initializes a square.
-}
init : Int -> Int -> Model
init x y =
  { x = x
  , y = y
  , load = 0
  , playerId = Nothing
  }


-- TODO
-- We only accept full updates from the board service, thus a single square
-- does not need an update function
{-|
Updates the square's load.
-}
update : Action -> Model -> Model
update action square =
  case action of
    Increment _ ->
      { square | load = square.load + 1 }


view : Signal.Address Action -> Model -> Html
view address square =
  let
    loadText =
      if square.load == 0
      then text "o"
      else square.load |> toString |> text
    player =
      case square.playerId of
        Just 1 -> " player1"
        Just 2 -> " player2"
        _ -> ""
  in
    td
      [ class ("square " ++ player)
      , onClick address (Increment (Move.init square.x square.y 1)) ]
      [ loadText ]


decodeSquare : String -> Model
decodeSquare json =
  let
    result = Json.decodeString squareDecoder json
  in
    case result of
      Ok model -> model
      Err error ->
        let _ = Debug.log "Square: JSON decode error" error
        in init -1 -1


squareDecoder : Json.Decoder Model
squareDecoder =
  Json.object4 Model
  ("x" := Json.int)
  ("y" := Json.int)
  ("load" := Json.int)
  (Json.maybe ("playerId" := Json.int))
