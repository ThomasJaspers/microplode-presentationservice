module MicroPlode.Board
  ( Action(UpdateFromWebSocket)
  , Model
  , init
  , view
  , update
  , actionsToCoordinates
  , decodeBoard) where


import Array exposing (Array)
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Json exposing ((:=))

import MicroPlode.Click as Click exposing (Click)
import MicroPlode.Square as Square


type alias Model = Array (Array Square.Model)


type Action =
    Click Square.Action
  | UpdateFromWebSocket String


initRow : Int -> Array Square.Model
initRow y =
  List.map (\x -> Square.init x y) [0..9]
  |> Array.fromList


{-|
Initializes the board.
-}
init : Model
init =
  List.map initRow [0..9]
  |> Array.fromList


{-|
Updates the board.
-}
update : Action -> Model -> Model
update action board =
  case action of
    UpdateFromWebSocket webSocketMessage ->
      decodeBoard webSocketMessage
    -- TODO
    -- We only accept full updates from the board service, so the update
    -- on single click needs to be removed/ignored
    Click increment ->
      board
    {-
    Click increment ->
      let
        -- deconstruct Square.Increment Action to get x/y coordinates
        (Square.Increment {x, y, player}) = increment
        row = Array.get y board |> Maybe.withDefault Array.empty
        square = Array.get x row |> Maybe.withDefault (Square.init 0 0)
        -- update (create new) square
        square' = Square.update increment square
        -- create new row with new square
        row' = Array.set x square' row
      in
        -- set new row into board
        Array.set y row' board
    -}


{-|
Renders the board.
-}
view : Signal.Address Action -> Model -> Html
view address board =
  let
    listOfRowArrays = Array.toList board
    listOfRowLists = List.map Array.toList listOfRowArrays
    renderedRows = listOfRowLists
      |> List.map (renderRow address)
  in
    table [ class "board" ] renderedRows


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
     otherwise -> Nothing


decodeBoard : String -> Model
decodeBoard json =
  let
    result = Json.decodeString webSocketMessageDecoder json
  in
    case result of
      Ok model -> model
      Err error ->
        let _ = Debug.log "Board: JSON decode error" error
        in init


webSocketMessageDecoder : Json.Decoder Model
webSocketMessageDecoder =
  Json.at ["board"] boardDecoder


boardDecoder : Json.Decoder Model
boardDecoder =
  Json.array rowDecoder


rowDecoder : Json.Decoder (Array Square.Model)
rowDecoder =
  Json.array Square.squareDecoder
