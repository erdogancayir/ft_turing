(* Shared types of the program *)

module StringMap = Map.Make (String)

type direction = Left | Right

type transition = {
  read : char;
  to_state : string;
  write : char;
  action : direction;
}

type machine = {
  name : string;
  alphabet : char list;
  blank : char;
  states : string list;
  initial : string;
  finals : string list;
  (* state name -> transitions available from this state *)
  transitions : transition list StringMap.t;
}

let string_of_direction = function Left -> "LEFT" | Right -> "RIGHT"
