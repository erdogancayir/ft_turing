(* Loading and validation of a json machine description.
   Every function returns a [result]: [Ok value] or [Error message]. *)

open Types

let ( let* ) = Result.bind

(* ---------- small helpers ---------- *)

(* Apply [f] to every element, stop at the first error.
   Tail recursive, so it also works on very long inputs. *)
let map_result f lst =
  let rec loop acc = function
    | [] -> Ok (List.rev acc)
    | x :: rest -> ( match f x with Ok y -> loop (y :: acc) rest | Error e -> Error e)
  in
  loop [] lst

let check cond msg = if cond then Ok () else Error msg

let rec find_duplicate = function
  | [] -> None
  | x :: rest -> if List.mem x rest then Some x else find_duplicate rest

let no_duplicate what to_str lst =
  match find_duplicate lst with
  | None -> Ok ()
  | Some x -> Error (Printf.sprintf "duplicate %s '%s'" what (to_str x))

let char_to_string c = String.make 1 c

(* ---------- json field accessors ---------- *)

let field name = function
  | `Assoc fields -> (
      match List.assoc_opt name fields with
      | Some v -> Ok v
      | None -> Error (Printf.sprintf "missing field \"%s\"" name))
  | _ -> Error (Printf.sprintf "cannot read field \"%s\": not an object" name)

let to_string name = function
  | `String s -> Ok s
  | _ -> Error (Printf.sprintf "field \"%s\" must be a string" name)

let to_list name = function
  | `List l -> Ok l
  | _ -> Error (Printf.sprintf "field \"%s\" must be a list" name)

let string_field name json =
  let* v = field name json in
  to_string name v

let string_list_field name json =
  let* v = field name json in
  let* l = to_list name v in
  map_result (to_string name) l

(* A symbol is a string of length exactly 1 *)
let to_symbol name s =
  if String.length s = 1 then Ok s.[0]
  else Error (Printf.sprintf "in \"%s\": \"%s\" is not a single character" name s)

let symbol_field name json =
  let* s = string_field name json in
  to_symbol name s

(* ---------- validation of each part ---------- *)

let parse_name json =
  let* name = string_field "name" json in
  let* () = check (name <> "") "field \"name\" must not be empty" in
  Ok name

let parse_alphabet json =
  let* strings = string_list_field "alphabet" json in
  let* symbols = map_result (to_symbol "alphabet") strings in
  let* () = check (symbols <> []) "field \"alphabet\" must not be empty" in
  let* () = no_duplicate "alphabet symbol" char_to_string symbols in
  Ok symbols

let parse_blank alphabet json =
  let* blank = symbol_field "blank" json in
  let* () = check (List.mem blank alphabet) "blank character must be part of the alphabet" in
  Ok blank

let parse_states json =
  let* states = string_list_field "states" json in
  let* () = check (states <> []) "field \"states\" must not be empty" in
  let* () = check (not (List.mem "" states)) "a state name must not be empty" in
  let* () = no_duplicate "state" Fun.id states in
  Ok states

let parse_initial states json =
  let* initial = string_field "initial" json in
  let* () =
    check (List.mem initial states)
      (Printf.sprintf "initial state '%s' is not in the states list" initial)
  in
  Ok initial

let parse_finals states json =
  let* finals = string_list_field "finals" json in
  let* () = no_duplicate "final state" Fun.id finals in
  let* _ =
    map_result
      (fun f ->
        check (List.mem f states)
          (Printf.sprintf "final state '%s' is not in the states list" f))
      finals
  in
  Ok finals

let parse_action = function
  | "LEFT" -> Ok Left
  | "RIGHT" -> Ok Right
  | s -> Error (Printf.sprintf "invalid action '%s' (expected LEFT or RIGHT)" s)

let parse_transition alphabet states from json =
  let in_state msg = Error (Printf.sprintf "transition of state '%s': %s" from msg) in
  let result =
    let* read = symbol_field "read" json in
    let* write = symbol_field "write" json in
    let* to_state = string_field "to_state" json in
    let* action_str = string_field "action" json in
    let* action = parse_action action_str in
    let* () = check (List.mem read alphabet) (Printf.sprintf "read '%c' is not in the alphabet" read) in
    let* () = check (List.mem write alphabet) (Printf.sprintf "write '%c' is not in the alphabet" write) in
    let* () =
      check (List.mem to_state states)
        (Printf.sprintf "to_state '%s' is not in the states list" to_state)
    in
    Ok { read; to_state; write; action }
  in
  match result with Ok t -> Ok t | Error msg -> in_state msg

(* One entry of the "transitions" dictionary: "state": [ ... ] *)
let parse_state_transitions alphabet states (state, json) =
  let* () =
    check (List.mem state states)
      (Printf.sprintf "transitions given for unknown state '%s'" state)
  in
  let* list = to_list "transitions" json in
  let* transitions = map_result (parse_transition alphabet states state) list in
  let* () =
    match find_duplicate (List.map (fun t -> t.read) transitions) with
    | None -> Ok ()
    | Some c ->
        Error (Printf.sprintf "state '%s' has several transitions reading '%c'" state c)
  in
  Ok (state, transitions)

let parse_transitions alphabet states json =
  let* v = field "transitions" json in
  match v with
  | `Assoc entries ->
      let* () = no_duplicate "transitions entry for state" Fun.id (List.map fst entries) in
      let* parsed = map_result (parse_state_transitions alphabet states) entries in
      Ok (List.fold_left (fun map (s, ts) -> StringMap.add s ts map) StringMap.empty parsed)
  | _ -> Error "field \"transitions\" must be an object"

(* ---------- entry points ---------- *)

let machine_of_json json =
  let* () = match json with `Assoc _ -> Ok () | _ -> Error "the description must be a json object" in
  let* name = parse_name json in
  let* alphabet = parse_alphabet json in
  let* blank = parse_blank alphabet json in
  let* states = parse_states json in
  let* initial = parse_initial states json in
  let* finals = parse_finals states json in
  let* transitions = parse_transitions alphabet states json in
  Ok { name; alphabet; blank; states; initial; finals; transitions }

let load_json filename =
  try Ok (Yojson.Basic.from_file filename) with
  | Yojson.Json_error msg -> Error ("invalid json: " ^ msg)
  | Sys_error msg -> Error ("cannot read file: " ^ msg)
  | exn -> Error ("cannot read file: " ^ Printexc.to_string exn)

let load_machine filename =
  let* json = load_json filename in
  machine_of_json json

(* The input must only use alphabet symbols, and never the blank *)
let check_input machine input =
  let chars = List.init (String.length input) (String.get input) in
  let* _ =
    map_result
      (fun c ->
        if c = machine.blank then
          Error (Printf.sprintf "input must not contain the blank character '%c'" c)
        else if not (List.mem c machine.alphabet) then
          Error (Printf.sprintf "input character '%c' is not in the alphabet" c)
        else Ok ())
      chars
  in
  Ok input
