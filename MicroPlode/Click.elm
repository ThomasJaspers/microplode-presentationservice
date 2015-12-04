module MicroPlode.Click
  ( Click
  , init) where


type alias Click =
  { x : Int
  , y : Int
  , player : Int
  }


init : Int -> Int -> Int -> Click
init x y player =
  { x = x
  , y = y
  , player = player
  }
