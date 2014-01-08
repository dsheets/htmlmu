module T = XmlmuTransform

let xmlns="http://www.w3.org/1999/xhtml"

module MathML = struct
  let xmlns="http://www.w3.org/1998/Math/MathML"
end

module SVG = struct
  let xmlns="http://www.w3.org/2000/svg"
end

let sub_vocabularies = [
  SVG.xmlns,    "svg";
  MathML.xmlns, "math";
]

let void_elements = [
  "img";
  "input";
  "link";
  "meta";
  "br";
  "hr";
  "source";
  "wbr";
  "param";
  "embed";
  "base";
  "area";
  "col";
  "track";
  "keygen";
]

module Polyglot(Lang : T.INTERP) = struct
  let html_ns = Lang.xmlns xmlns
  open Lang

  let transform () =
    let dtd_queue = queue "dtd_queue" in
    let ns_stack = stack "ns_stack" in
    let recovery_stack = stack "recovery_stack" in
    let empty_ns = xmlns "" in
    let push_html = push_stack ns_stack html_ns in
    let fix_subns from_ns = pipe [
      match_ Element (List.rev_map (fun (ns,name) ->
        element name, pipe [
          push_stack ns_stack (xmlns ns);
          push_stack recovery_stack identity;
        ]
      ) sub_vocabularies
      ) identity;
      let bind_ns to_ns = pipe [
        match_ Xmlns [ to_ns, identity ] (replace_xmlns to_ns);
        match_ Xmlns [ from_ns, identity ] (declare_xmlns "xmlns" to_ns)
      ] in
      peek_stack ns_stack bind_ns (bind_ns html_ns)
    ] in
    pipe [
      run_stack ns_stack;
      run_stack recovery_stack;

      match_ Xmlns [
        empty_ns, peek_stack ns_stack fix_subns (fix_subns empty_ns);
        html_ns, pipe [
          peek_stack ns_stack (fun ns ->
            match_ (This ns) [ html_ns, identity ]
              (push_stack recovery_stack push_html);
          ) identity;
          peek_stack recovery_stack (fun x -> x) push_html;
          peek_stack ns_stack fix_subns (fix_subns html_ns);
        ];
      ] (select_ Xmlns (push_stack ns_stack));

      (* save any dtd until we check the doc root *)
      select_ Dtd (fun dtdt -> pipe [
        if_queue_open dtd_queue (pipe [
          push_queue dtd_queue dtdt;
          close_queue dtd_queue;
          drop;
        ]) identity;
      ]);

      (* add html5 dtd if this stream has an html root and no dtd *)
      drain_queue dtd_queue (fun dtdt -> pipe [
        match_ (This dtdt) [
          dtd None, match_ Xmlns [
            html_ns, emit_before (dtd_signal (dtd (Some "<!DOCTYPE html>")));
          ] (emit_before (dtd_signal dtdt));
        ] (emit_before (dtd_signal dtdt));
        (* This will emit and continue inside this loop due to direct CPS *)
      ]);

      match_ Xmlns [
        html_ns,
        (* if it's not a void element, don't close it *)
        match_ Element (List.map (fun name ->
          element name, identity;
        ) void_elements
        ) (emit_after (data_signal ""));
      ] identity;
    ]
end

(* TODO: semantics of stream modifiers:
   drop
   emit_before
   emit_after

   use blocks? offer way to restart pipeline?
*)

module PolyglotTransform = Polyglot(XmlmuTransform.Interpreter)
