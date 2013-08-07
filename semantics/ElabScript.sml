(*Generated by Lem from elab.lem.*)
open bossLib Theory Parse res_quanTheory
open fixedPointTheory finite_mapTheory listTheory pairTheory pred_setTheory
open integerTheory set_relationTheory sortingTheory stringTheory wordsTheory

val _ = numLib.prefer_num();



open AstTheory TokensTheory LibTheory

val _ = new_theory "Elab"

(* An AST that can be the result of parsing, and then elaborated into the main
 * CakeML AST in ast.lem.  We are assuming that constructors start with capital
 * letters, and non-constructors start with lower case (as in OCaml) so that
 * the parser can determine what is a constructor application.  Example syntax
 * in comments before each node.
 * 
 * Also, an elaboration from this syntax to the AST in ast.lem.  The
 * elaboration spots types that are bound to ML primitives.  It also prefixes
 * datatype constructors and types with their paths, so
 *
 * structure S = struct datatype t = C val x = C end
 *
 * becomes
 *
 * structure S = struct datatype t = C val x = S.C end
 * 
 *)

(*open Lib*)
(*open Ast*)

val _ = Hol_datatype `
 ast_pat =
    (* x *)
    Ast_Pvar of varN
    (* 1 *)
    (* true *)
    (* () *)
  | Ast_Plit of lit
    (* C(x,y) *)
    (* D *)
    (* E x *)
  | Ast_Pcon of ( conN id) option => ast_pat list
    (* ref x *)
  | Ast_Pref of ast_pat`;


val _ = Hol_datatype `
 ast_exp =
    (* raise (E 4) *)
    Ast_Raise of ast_exp
    (* e handle E x => x | F => 1 *)
  | Ast_Handle of ast_exp => (ast_pat # ast_exp) list
    (* 1 *)
    (* true *)
    (* () *)
  | Ast_Lit of lit
    (* x *)
  | Ast_Var of varN id
    (* C(x,y) *)
    (* D *)
    (* E x *)
  | Ast_Con of ( conN id) option => ast_exp list
    (* fn x => e *)
  | Ast_Fun of varN => ast_exp
    (* e e *)
  | Ast_App of ast_exp => ast_exp
    (* e andalso e *)
    (* e orelse e *)
  | Ast_Log of lop => ast_exp => ast_exp
    (* if e then e else e *)
  | Ast_If of ast_exp => ast_exp => ast_exp
    (* case e of C(x,y) => x | D y => y *)
  | Ast_Mat of ast_exp => (ast_pat # ast_exp) list
    (* let val x = e in e end *)
  | Ast_Let of varN => ast_exp => ast_exp
    (* let fun f x = e and g y = e in e end *) 
  | Ast_Letrec of (varN # varN # ast_exp) list => ast_exp`;


val _ = Hol_datatype `
 ast_t =
    (* 'a *)
    Ast_Tvar of tvarN
    (* t *)
    (* num t *)
    (* (num,bool) t *)
  | Ast_Tapp of ast_t list => ( typeN id) option
    (* t -> t *)
  | Ast_Tfn of ast_t => ast_t`;


(* type t = C of t1 * t2 | D of t2  * t3
 * and 'a u = E of 'a
 * and ('a,'b) v = F of 'b u | G of 'a u *)
val _ = type_abbrev( "ast_type_def" , ``: ( tvarN list # typeN # (conN # ast_t list) list) list``);

val _ = Hol_datatype `
 ast_dec =
    (* val (C(x,y)) = C(1,2) *) 
    Ast_Dlet of ast_pat => ast_exp
    (* fun f x = e and g y = f *) 
  | Ast_Dletrec of (varN # varN # ast_exp) list
    (* see above *)
  | Ast_Dtype of ast_type_def
  | Ast_Dexn of conN => ast_t list`;


val _ = type_abbrev( "ast_decs" , ``: ast_dec list``);

val _ = Hol_datatype `
 ast_spec =
    Ast_Sval of varN => ast_t
  | Ast_Stype of ast_type_def
  | Ast_Stype_opq of tvarN list => typeN`;


val _ = type_abbrev( "ast_specs" , ``: ast_spec list``);

val _ = Hol_datatype `
 ast_top =
    Ast_Tmod of modN => ast_specs option => ast_decs
  | Ast_Tdec of ast_dec`;


val _ = type_abbrev( "ast_prog" , ``: ast_top list``);

val _ = type_abbrev( "ctor_env" , ``: (conN, ( conN id)) env``);

(*val elab_p : ctor_env -> ast_pat -> pat*)
 val elab_p_defn = Hol_defn "elab_p" `

(elab_p ctors (Ast_Pvar n) = (Pvar n))
/\
(elab_p ctors (Ast_Plit l) = (Plit l))
/\
(elab_p ctors (Ast_Pcon (SOME (Short cn)) ps) =  
((case lookup cn ctors of
      SOME cid =>
        Pcon (SOME cid) (elab_ps ctors ps)
    | NONE =>
        Pcon (SOME (Short cn)) (elab_ps ctors ps)
  )))
/\
(elab_p ctors (Ast_Pcon cn ps) =  
(Pcon cn (elab_ps ctors ps)))
/\
(elab_p ctors (Ast_Pref p) = (Pref (elab_p ctors p)))
/\
(elab_ps ctors [] = ([]))
/\
(elab_ps ctors (p::ps) = (elab_p ctors p :: elab_ps ctors ps))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn elab_p_defn;

val _ = type_abbrev( "tdef_env" , ``: (typeN,tc0) env``);

(*val elab_t : tdef_env -> ast_t -> t*)
(*val elab_e : ctor_env -> ast_exp -> exp*)
(*val elab_funs : ctor_env -> list (varN * varN * ast_exp) -> 
                list (varN * varN * exp)*)
(*val elab_dec : option modN -> tdef_env -> ctor_env -> ast_dec -> tdef_env * ctor_env * dec*)
(*val elab_decs : option modN -> tdef_env -> ctor_env -> list ast_dec -> tdef_env * ctor_env * list dec*)
(*val elab_spec : option modN -> tdef_env -> list ast_spec -> list spec*)
(*val elab_top : tdef_env -> ctor_env -> ast_top -> tdef_env * ctor_env * top*)
(*val elab_prog : tdef_env -> ctor_env -> list ast_top -> tdef_env * ctor_env * prog*)

 val elab_e_defn = Hol_defn "elab_e" `

(elab_e ctors (Ast_Raise e) =  
(Raise (elab_e ctors e)))
/\
(elab_e ctors (Ast_Handle e pes) =  
(Handle (elab_e ctors e) 
         ( MAP (\ (p,e) . (elab_p ctors p, elab_e ctors e)) pes)))
/\
(elab_e ctors (Ast_Lit l) =  
(Lit l))
/\ 
(elab_e ctors (Ast_Var id) =  
(Var id))
/\
(elab_e ctors (Ast_Con (SOME (Short cn)) es) =  
((case lookup cn ctors of
      SOME cid =>
        Con (SOME cid) ( MAP (elab_e ctors) es)
    | NONE =>
        Con (SOME (Short cn)) ( MAP (elab_e ctors) es)
  )))
/\
(elab_e ctors (Ast_Con cn es) =  
(Con cn ( MAP (elab_e ctors) es)))
/\
(elab_e ctors (Ast_Fun n e) =  
(Fun n (elab_e ctors e)))
/\
(elab_e ctors (Ast_App e1 e2) =  
(App Opapp (elab_e ctors e1) (elab_e ctors e2)))
/\
(elab_e ctors (Ast_Log lop e1 e2) =  
(Log lop (elab_e ctors e1) (elab_e ctors e2)))
/\
(elab_e ctors (Ast_If e1 e2 e3) =  
(If (elab_e ctors e1) (elab_e ctors e2) (elab_e ctors e3)))
/\
(elab_e ctors (Ast_Mat e pes) =  
(Mat (elab_e ctors e) 
      ( MAP (\ (p,e) . (elab_p ctors p, elab_e ctors e)) pes)))
/\
(elab_e ctors (Ast_Let x e1 e2) =  
(Let x (elab_e ctors e1) (elab_e ctors e2)))
/\
(elab_e ctors (Ast_Letrec funs e) =  
(Letrec (elab_funs ctors funs) 
         (elab_e ctors e)))
/\
(elab_funs ctors [] =  
([]))
/\
(elab_funs ctors ((n1,n2,e)::funs) =  
((n1,n2,elab_e ctors e) :: elab_funs ctors funs))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn elab_e_defn;

 val elab_t_defn = Hol_defn "elab_t" `

(elab_t type_bound (Ast_Tvar n) = (Tvar n))
/\
(elab_t type_bound (Ast_Tfn t1 t2) =  
(
  Tfn (elab_t type_bound t1) (elab_t type_bound t2)))
    /\
(elab_t type_bound (Ast_Tapp ts NONE) =  
(let ts' = ( MAP (elab_t type_bound) ts) in
    Tapp ts' TC_tup))
/\
(elab_t type_bound (Ast_Tapp ts (SOME (Long m tn))) =  
(let ts' = ( MAP (elab_t type_bound) ts) in
    Tapp ts' (TC_name (Long m tn))))
/\
(elab_t type_bound (Ast_Tapp ts (SOME (Short tn))) =  
(let ts' = ( MAP (elab_t type_bound) ts) in
    (case lookup tn type_bound of
        NONE => Tapp ts' (TC_name (Short tn))
      | SOME tc0 => Tapp ts' tc0
    )))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn elab_t_defn;

val _ = Define `
 (get_ctors_bindings mn t = ( FLAT
    ( MAP (\ (tvs,tn,ctors) . MAP (\ (cn,t) . (cn, mk_id mn cn)) ctors) t)))`;

   
val _ = Define `
 (elab_td type_bound (tvs,tn,ctors) =
  (tvs, tn, MAP (\ (cn,t) . (cn, MAP (elab_t type_bound) t)) ctors))`;


 val elab_dec_def = Define `

(elab_dec mn type_bound ctors (Ast_Dlet p e) =  
(let p' = ( elab_p ctors p) in
    ([], emp, Dlet p' (elab_e ctors e))))
/\
(elab_dec mn type_bound ctors (Ast_Dletrec funs) =
  ([], emp, Dletrec (elab_funs ctors funs)))
/\
(elab_dec mn type_bound ctors (Ast_Dtype t) =  
 (let type_bound' = ( MAP (\ (tvs,tn,ctors) . (tn, TC_name (mk_id mn tn))) t) in
  (type_bound',
   get_ctors_bindings mn t,
   Dtype ( MAP (elab_td (merge type_bound' type_bound)) t))))
/\
(elab_dec mn type_bound ctors (Ast_Dexn cn ts) =
  (emp,
   bind cn (mk_id mn cn) emp,
   Dexn cn ( MAP (elab_t type_bound) ts)))`;


 val elab_decs_defn = Hol_defn "elab_decs" `

(elab_decs mn type_bound ctors [] = ([],emp,[]))
/\
(elab_decs mn type_bound ctors (d::ds) =  
 (let (type_bound', ctors', d') = ( elab_dec mn type_bound ctors d) in
  let (type_bound'',ctors'',ds') =    
 (elab_decs mn (merge type_bound' type_bound) (merge ctors' ctors) ds) 
  in
    (merge type_bound'' type_bound', merge ctors'' ctors', (d' ::ds'))))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn elab_decs_defn;

 val elab_spec_defn = Hol_defn "elab_spec" `
 
(elab_spec mn type_bound [] = ([]))
/\
(elab_spec mn type_bound (Ast_Sval x t::spec) =  
(Sval x (elab_t type_bound t) :: elab_spec mn type_bound spec))
/\
(elab_spec mn type_bound (Ast_Stype td :: spec) =  
(let type_bound' = ( MAP (\ (tvs,tn,ctors) . (tn, TC_name (mk_id mn tn))) td) in
    Stype ( MAP (elab_td (merge type_bound' type_bound)) td) :: elab_spec mn (merge type_bound' type_bound) spec))
/\
(elab_spec mn type_bound (Ast_Stype_opq tvs tn::spec) =  
(Stype_opq tvs tn :: elab_spec mn ((tn, TC_name (mk_id mn tn)) ::type_bound) spec))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn elab_spec_defn;

 val elab_top_def = Define `

(elab_top type_bound ctors (Ast_Tdec d) =  
(let (type_bound', ctors', d') = ( elab_dec NONE type_bound ctors d) in
      (type_bound', ctors', Tdec d')))
/\
(elab_top type_bound ctors (Ast_Tmod mn spec ds) =  
(let (type_bound',ctors',ds') = ( elab_decs (SOME mn) type_bound ctors ds) in
      (type_bound,ctors,Tmod mn (option_map (elab_spec (SOME mn) type_bound) spec) ds')))`;


 val elab_prog_defn = Hol_defn "elab_prog" `

(elab_prog type_bound ctors [] = ([],emp,[]))
/\
(elab_prog type_bound ctors (top::prog) =  
(let (type_bound',ctors',top') = ( elab_top type_bound ctors top) in
  let (type_bound'',ctors'',prog') =    
 (elab_prog (merge type_bound' type_bound) (merge ctors' ctors) prog)
  in
    (merge type_bound'' type_bound', merge ctors'' ctors', (top' ::prog'))))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn elab_prog_defn;
val _ = export_theory()

