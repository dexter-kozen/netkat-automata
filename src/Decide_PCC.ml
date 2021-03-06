
module D = Decide_Deriv.BDDDeriv
module S = Sexplib.Sexp
module Ast = Decide_Ast
module Term = Ast.Term
                
open Core.Std
open Sexplib.Conv

exception WrongEMatrix of string
exception WrongDMatrix of string
exception InvalidBisimulation

module PCC (D : Decide_Deriv.DerivTerm) = struct
  module UF = Decide_Util.UnionFind(D)

  type certificate = {
    lhs : Term.t;
    rhs : Term.t;
    left_e_matrix : D.EMatrix.t;
    left_d_matrix : D.DMatrix.t;
    right_e_matrix : D.EMatrix.t;
    right_d_matrix : D.DMatrix.t;
    bisim : UF.t
  } with sexp

  let generate_certificate t1 t2 t1' t2' uf =
    let cert = {
      lhs = t1;
      rhs = t2;
      left_e_matrix = D.get_e t1';
      right_e_matrix = D.get_e t2';
      left_d_matrix = D.get_d t1';
      right_d_matrix = D.get_d t2';
      bisim = uf
    } in
    let file = Pervasives.open_out "netkat.cert" in
    Printf.fprintf file ";; %s == %s\n"
      (Term.to_string t1)
      (Term.to_string t2);
    Printf.fprintf file "%s" (S.to_string (sexp_of_certificate cert));
    Pervasives.close_out file


  let equivalent bisim elm1 elm2 =
    D.EMatrix.compare (D.get_e elm1) (D.get_e elm2) = 0 && D.DMatrix.equivalent bisim (D.get_d elm1) (D.get_d elm2)

  let verify_bisimulation uf t1 t2 =
    (* Check t1 UF t2 *)
    List.for_all (UF.equivalence_classes uf)
      ~f:(fun cls ->
          List.for_all (UF.Class.members cls) (fun mem -> equivalent (fun a b -> UF.eq uf (D.make_term a) (D.make_term b)) (UF.Class.canonical_element cls) mem))

  let parse_certificate file =
    let file = S.load_sexp file in
    let cert = certificate_of_sexp file in
    UF.validate cert.bisim;
    Decide_Util.set_univ [Decide_Ast.Term.values cert.lhs;
                          Decide_Ast.Term.values cert.rhs];
    let lhs_deriv = D.make_term (Ast.TermSet.singleton cert.lhs) in
    let rhs_deriv = D.make_term (Ast.TermSet.singleton cert.rhs) in
    if (try D.EMatrix.compare (D.get_e lhs_deriv) cert.left_e_matrix <> 0
       with Not_found -> true) then
      raise (WrongEMatrix(Printf.sprintf "left-hand side E matrix did not match term %s" (Term.to_string cert.lhs)))
    else if (try D.DMatrix.compare (D.get_d lhs_deriv) cert.left_d_matrix <> 0
             with Not_found -> true) then
      raise (WrongDMatrix(Printf.sprintf "left-hand side D matrix did not match term %s" (Term.to_string cert.lhs)))
    else if (try D.EMatrix.compare (D.get_e rhs_deriv) cert.right_e_matrix <> 0
             with Not_found -> true) then
      raise (WrongEMatrix(Printf.sprintf "right-hand side E matrix did not match term %s" (Term.to_string cert.rhs)))
    else if (try D.DMatrix.compare (D.get_d rhs_deriv) cert.right_d_matrix <> 0
             with Not_found -> true) then
      raise (WrongDMatrix(Printf.sprintf "right-hand side D matrix did not match term %s" (Term.to_string cert.lhs)))
    else if (try not (verify_bisimulation cert.bisim lhs_deriv rhs_deriv)
             with Not_found -> true) then
      raise InvalidBisimulation
end
