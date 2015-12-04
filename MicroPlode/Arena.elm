module MicroPlode.Arena
  ( Action
  , Model
  , init
  , view
  , update
  , actionsToCoordinates) where


import Array exposing (Array)
import Html exposing (..)
import Html.Attributes exposing (..)

import MicroPlode.Click as Click exposing (Click)
import MicroPlode.Square as Square


type alias Model = Array (Array Square.Model)


type Action
  = Click Square.Action


initRow : Int -> Array Square.Model
initRow y =
  List.map (\x -> Square.init x y) [0..9]
  |> Array.fromList


{-|
Initializes the arena.
-}
init : Model
init =
  List.map initRow [0..9]
  |> Array.fromList


{-|
Updates the arena.
-}
update : Action -> Model -> Model
update action arena =
  case action of
    Click increment ->
      let
        -- deconstruct Square.Increment Action to get x/y coordinates
        (Square.Increment {x, y, player}) = increment
        row = Array.get y arena |> Maybe.withDefault Array.empty
        square = Array.get x row |> Maybe.withDefault (Square.init 0 0)
        -- update (create new) square
        square' = Square.update increment square
        -- create new row with new square
        row' = Array.set x square' row
      in
        -- set new row into arena
        Array.set y row' arena


{-|
Renders the arena.
-}
view : Signal.Address Action -> Model -> Html
view address arena =
  let
    listOfRowArrays = Array.toList arena
    listOfRowLists = List.map Array.toList listOfRowArrays
    renderedRows = listOfRowLists
      |> List.map (renderRow address)
  in
    table [ class "arena" ] renderedRows


renderRow : Signal.Address Action -> List Square.Model -> Html
renderRow address row =
  let
    tds = List.map (Square.view (Signal.forwardTo address Click)) row
  in
    tr [] tds


actionsToCoordinates : Action -> Maybe Click
actionsToCoordinates action =
  case action of
     Click (Square.Increment click) -> Just click
     -- otherwise -> Nothing
