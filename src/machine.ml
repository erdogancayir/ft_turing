(* Display and execution of a Turing machine *)

open Types

(* ---------- display ---------- *)

let stars = String.make 80 '*'

let print_header machine =
  let width = 78 in
  let name = machine.name in
  let left = max 0 ((width - String.length name) / 2) in
  let right = max 0 (width - String.length name - left) in
  let empty_line = "*" ^ String.make width ' ' ^ "*" in
  print_endline stars;
  print_endline empty_line;
  print_endline ("*" ^ String.make left ' ' ^ name ^ String.make right ' ' ^ "*");
  print_endline empty_line;
  print_endline stars

let string_of_transition state t =
  Printf.sprintf "(%s, %c) -> (%s, %c, %s)" state t.read t.to_state t.write
    (string_of_direction t.action)

let transitions_of machine state =
  Option.value ~default:[] (StringMap.find_opt state machine.transitions)

let print_description machine =
  let list l = "[ " ^ String.concat ", " l ^ " ]" in
  print_header machine;
  Printf.printf "Alphabet: %s\n" (list (List.map (String.make 1) machine.alphabet));
  Printf.printf "States : %s\n" (list machine.states);
  Printf.printf "Initial : %s\n" machine.initial;
  Printf.printf "Finals : %s\n" (list machine.finals);
  List.iter
    (fun state ->
      List.iter (fun t -> print_endline (string_of_transition state t)) (transitions_of machine state))
    machine.states;
  print_endline stars

(* ---------- execution ---------- *)

type outcome =
  | Halted of string * int (* final state, number of steps *)
  | Blocked of string * char (* state, symbol under the head *)

let find_transition machine state symbol =
  List.find_opt (fun t -> t.read = symbol) (transitions_of machine state)

(* Run the machine one transition at a time, printing each step.
   Tail recursive: no stack overflow on long executions. *)
let rec run machine state tape steps =
  if List.mem state machine.finals then (
    Printf.printf "%s (%s)\n" (Tape.to_string tape) state;
    Halted (state, steps))
  else
    let symbol = Tape.read tape in
    match find_transition machine state symbol with
    | None ->
        Printf.printf "%s (%s, %c) -> ???\n" (Tape.to_string tape) state symbol;
        Blocked (state, symbol)
    | Some t ->
        Printf.printf "%s %s\n" (Tape.to_string tape) (string_of_transition state t);
        let next_tape = Tape.move (Tape.write tape t.write) t.action in
        run machine t.to_state next_tape (steps + 1)

let execute machine input =
  print_description machine;
  run machine machine.initial (Tape.of_string machine.blank input) 0
