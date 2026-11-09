(* Entry point: argument parsing and error reporting *)

let usage =
  "usage: ft_turing [-h] jsonfile input\n\n\
   positional arguments:\n\
  \  jsonfile            json description of the machine\n\n\
  \  input               input of the machine\n\n\
   optional arguments:\n\
  \  -h, --help          show this help message and exit"

let error msg =
  flush stdout;
  prerr_endline ("Error: " ^ msg);
  exit 1

let start jsonfile input =
  let ( let* ) = Result.bind in
  let loaded =
    let* machine = Parser.load_machine jsonfile in
    let* input = Parser.check_input machine input in
    Ok (machine, input)
  in
  match loaded with
  | Error msg -> error msg
  | Ok (machine, input) -> (
      match Machine.execute machine input with
      | Machine.Halted (state, steps) ->
          Printf.printf "Machine halted in final state '%s' after %d steps.\n" state steps
      | Machine.Blocked (state, symbol) ->
          error
            (Printf.sprintf "machine blocked: no transition from state '%s' reading '%c'."
               state symbol))

let () =
  match List.tl (Array.to_list Sys.argv) with
  | args when List.exists (fun a -> a = "-h" || a = "--help") args -> print_endline usage
  | [ jsonfile; input ] -> (
      try start jsonfile input with
      | Stack_overflow -> error "stack overflow"
      | Out_of_memory -> error "out of memory")
  | _ ->
      prerr_endline usage;
      exit 1
