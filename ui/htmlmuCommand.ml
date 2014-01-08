(*
 * Copyright (c) 2014 David Sheets <sheets@alum.mit.edu>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 *)

open Cmdliner
open XmlmuCmdliner

(* TODO: version *)
let default_cmd =
  let doc = "perform functions on (X)HTML" in
  (Term.(ret (pure (`Help (`Pager, None)))),
   let man = [
     `S "DESCRIPTION";
     `P "A collection of functions over (X)HTML documents and fragments";
     `S "COMMON OPTIONS";
     `P "$(b,--help) will show more help for each of the sub-commands above.";
     `S "BUGS";
     `P "Report bugs on the Web at <https://github.com/dsheets/htmlmu>."] in
   Term.info "html" ~doc ~man)

(* TODO: version *)
let mu =
  let doc = "convert XHTML into polyglot (X)HTML" in
  mu ~doc (fun file_option ->
    try XmlmuTransform.pump
          (input_of_file_option file_option)
          (XmlmuTransform.Interpreter.eval Htmlmu.PolyglotTransform.transform)
          (Xmlmu.output_of_out_channel ~decl:false stdout)
    with Xmlm.Error ((line,col),err) ->
      Printf.eprintf "xmlm error: line %d col %d\n" line col;
      Printf.eprintf "%s\n%!" (Xmlm.error_message err)
  )

let cmds = [
  mu;
]

;;

match Term.eval_choice default_cmd cmds with
| `Error _ -> exit 1 | _ -> exit 0
