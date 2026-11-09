(* A purely functional infinite tape (zipper):
   - left  : cells on the left of the head, closest first (reversed)
   - head  : cell under the head
   - right : cells on the right of the head
   Cells that were never written are blank. *)

type t = { left : char list; head : char; right : char list; blank : char }

let of_string blank input =
  match List.init (String.length input) (String.get input) with
  | [] -> { left = []; head = blank; right = []; blank }
  | first :: rest -> { left = []; head = first; right = rest; blank }

let read tape = tape.head

let write tape c = { tape with head = c }

let move tape (dir : Types.direction) =
  match dir, tape.left, tape.right with
  | Left, [], _ -> { tape with left = []; head = tape.blank; right = tape.head :: tape.right }
  | Left, l :: ls, _ -> { tape with left = ls; head = l; right = tape.head :: tape.right }
  | Right, _, [] -> { tape with left = tape.head :: tape.left; head = tape.blank; right = [] }
  | Right, _, r :: rs -> { tape with left = tape.head :: tape.left; head = r; right = rs }

(* Minimum number of cells displayed, the rest is padded with blanks *)
let min_width = 20

let to_string tape =
  let cell c = String.make 1 c in
  let left = List.rev_map cell tape.left in
  let right = List.map cell tape.right in
  let used = List.length left + 1 + List.length right in
  let padding = String.make (max 0 (min_width - used)) tape.blank in
  "[" ^ String.concat "" left ^ "<" ^ cell tape.head ^ ">"
  ^ String.concat "" right ^ padding ^ "]"
