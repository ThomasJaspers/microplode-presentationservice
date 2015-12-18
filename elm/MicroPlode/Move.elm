module MicroPlode.Move
  ( Move
  , init) where


type alias Move =
  { x : Int
  , y : Int
  , player : Int
  }


init : Int -> Int -> Int -> Move
init x y player =
  { x = x
  , y = y
  , player = player
  }
