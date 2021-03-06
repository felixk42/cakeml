(*Generated by Lem from typeSoundInvariants.lem.*)
open HolKernel Parse boolLib bossLib;
open lem_pervasivesTheory libTheory lem_list_extraTheory astTheory semanticPrimitivesTheory smallStepTheory typeSystemTheory;

val _ = numLib.prefer_num();



val _ = new_theory "typeSoundInvariants"

(* Type system for values, evaluation contexts, and the small-step sematnics'
 * states. The invariant that is used for type soundness. *)

(*open import Pervasives*)
(*open import Lib*)
(*open import Ast*)
(*open import SemanticPrimitives*)
(*open import SmallStep*)
(*open import TypeSystem*)
(*import List_extra*)

(*let mof env = env.SemanticPrimitives.m*)
(*let cof env = env.SemanticPrimitives.c*)
(*let vof env = env.SemanticPrimitives.v*)
(*let dmof env = env.SemanticPrimitives.defined_mods*)
(*let dtof env = env.SemanticPrimitives.defined_types*)

val _ = Hol_datatype `
 store_t = Ref_t of t | W8array_t | Varray_t of t`;


(* Store typing *)
val _ = type_abbrev( "tenvS" , ``: (num, store_t) fmap``);

(* Check that the type names map to valid types *)
(*val flat_tenv_tabbrev_ok : Map.map typeN (list tvarN * t) -> bool*)
val _ = Define `
 (flat_tenv_tabbrev_ok tenv_tabbrev =  
(FEVERY (UNCURRY (\ tn (tvs,t) .  check_freevars( 0) tvs t)) tenv_tabbrev))`;


(*val tenv_tabbrev_ok : mod_env typeN (list tvarN * t) -> bool*)
val _ = Define `
 (tenv_tabbrev_ok (mtenvT, tenvT) =  
(FEVERY (UNCURRY (\s tenvT .  
  (case (s ,tenvT ) of ( _ , tenvT ) => flat_tenv_tabbrev_ok tenvT ))) mtenvT /\
  flat_tenv_tabbrev_ok tenvT))`;


(*val flat_tenv_ctor_ok : flat_tenv_ctor -> bool*)
val _ = Define `
 (flat_tenv_ctor_ok tenv_ctor =  
(EVERY (\ (cn,(tvs,ts,tn)) .  EVERY (check_freevars( 0) tvs) ts) tenv_ctor))`;


(*val tenv_ctor_ok : tenv_ctor -> bool*)
val _ = Define `
 (tenv_ctor_ok (mtenvC, tenvC) =  
(EVERY (\p .  (case (p ) of ( (_,tenvC) ) => flat_tenv_ctor_ok tenvC )) mtenvC /\
  flat_tenv_ctor_ok tenvC))`;


 val _ = Define `

(tenv_val_ok Empty = T)
/\
(tenv_val_ok (Bind_tvar n tenv) = (tenv_val_ok tenv))
/\
(tenv_val_ok (Bind_name x tvs t tenv) =  
(check_freevars (tvs + num_tvs tenv) [] t /\ tenv_val_ok tenv))`;


(*val tenv_mod_ok : Map.map modN (alist varN (nat * t)) -> bool*)
val _ = Define `
 (tenv_mod_ok tenvM = (FEVERY (UNCURRY (\ mn tenv .  tenv_val_ok (bind_var_list2 tenv Empty))) tenvM))`;


(*val tenv_ok : type_environment -> bool*)
val _ = Define `
 (tenv_ok tenv =  
(tenv_tabbrev_ok tenv.t /\
  tenv_mod_ok tenv.m /\
  tenv_ctor_ok tenv.c /\
  tenv_val_ok tenv.v))`;


(*val new_dec_tenv_ok : new_dec_tenv -> bool*)
val _ = Define `
 (new_dec_tenv_ok (t,c,v) =  
(flat_tenv_tabbrev_ok t /\
  flat_tenv_ctor_ok c /\
  EVERY (\p .  (case (p ) of ( (_,(n,t)) ) => check_freevars n [] t )) v))`;


(* Global constructor type environments keyed by constructor name and type *)
val _ = type_abbrev( "ctMap" , ``: ((conN # tid_or_exn), ( tvarN list # t list)) fmap``);

(*val ctMap_ok : ctMap -> bool*)
val _ = Define `
 (ctMap_ok ctMap =  
(FEVERY (UNCURRY (\ (cn,tn) (tvs,ts) .  EVERY (check_freevars( 0) tvs) ts)) ctMap))`;


(* Convert from a lexically scoped constructor environment to the global one *)
(*val flat_to_ctMap_list : flat_tenv_ctor -> alist (conN * tid_or_exn) (list tvarN * list t)*)
val _ = Define `
 (flat_to_ctMap_list tenvC =  
(MAP (\ (cn,(tvs,ts,t)) .  ((cn,t),(tvs,ts))) tenvC))`;


(*val flat_to_ctMap : flat_tenv_ctor -> ctMap*)
val _ = Define `
 (flat_to_ctMap tenvC = (FUPDATE_LIST FEMPTY (REVERSE (flat_to_ctMap_list tenvC))))`;


(* Get the modules that are used by the type and exception definitions *)
(*val decls_to_mods : decls -> set (maybe modN)*)
val _ = Define `
 (decls_to_mods d =  
((({ SOME mn |  mn | ? tn. (Long mn tn) IN d.defined_types } UNION
  { SOME mn |  mn | ? cn. (Long mn cn) IN d.defined_exns }) UNION
  { NONE |  tn | Short tn IN d.defined_types }) UNION
  { NONE |  tn | Short tn IN d.defined_exns }))`;


(* Check that a constructor type environment is consistent with a runtime type
 * enviroment, using the full type keyed constructor type environment to ensure
 * that the correct types are used. *)
(*val consistent_con_env : ctMap -> env_ctor -> tenv_ctor -> bool*)
val _ = Define `
 (consistent_con_env ctMap env_c tenvC =  
(tenv_ctor_ok tenvC /\
  ctMap_ok ctMap /\
  (! cn n t.    
(lookup_alist_mod_env cn env_c = SOME (n, t))
    ==>    
(? tvs ts.      
(lookup_alist_mod_env cn tenvC = SOME (tvs, ts, t)) /\      
(FLOOKUP ctMap (id_to_n cn,t) = SOME (tvs, ts)) /\      
(LENGTH ts = n)))
  /\
  (! cn.    
(lookup_alist_mod_env cn env_c = NONE)
    ==>    
(lookup_alist_mod_env cn tenvC = NONE))))`;


(* A value has a type *)
(* The number is how many deBruijn type variables are bound in the context. *)
(*val type_v : nat -> ctMap -> tenvS -> v -> t -> bool*)

(* A value environment has a corresponding type environment.  Since all of the
 * entries in the environment are values, and values have no free variables,
 * each entry in the environment can be typed in the empty environment (if at
 * all) *)
(*val type_env : ctMap -> tenvS -> env_val -> tenv_val -> bool*)

(* The type of the store *)
(*val type_s : ctMap -> tenvS -> store v -> bool*)

(* An evaluation context has the second type when its hole is filled with a
 * value of the first type. *)
(* The number is how many deBruijn type variables are bound in the context.
 * This is only used for constructor contexts, because the value restriction
 * ensures that no other contexts can be created under a let binding. *)
(*val type_ctxt : nat -> ctMap -> tenvS -> type_environment -> ctxt_frame -> t -> t -> bool*)
(*val type_ctxts : nat -> ctMap -> tenvS -> list ctxt -> t -> t -> bool*)
(*val type_state : forall 'ffi. nat -> ctMap -> tenvS -> small_state 'ffi -> t -> bool*)
(*val context_invariant : nat -> list ctxt -> nat -> bool*)

val _ = Hol_reln ` (! tvs cenv senv n.
T
==>
type_v tvs cenv senv (Litv (IntLit n)) Tint)

/\ (! tvs cenv senv c.
T
==>
type_v tvs cenv senv (Litv (Char c)) Tchar)

/\ (! tvs cenv senv s.
T
==>
type_v tvs cenv senv (Litv (StrLit s)) Tstring)

/\ (! tvs cenv senv w.
T
==>
type_v tvs cenv senv (Litv (Word8 w)) Tword8)

/\ (! tvs cenv senv w.
T
==>
type_v tvs cenv senv (Litv (Word64 w)) Tword64)

/\ (! tvs cenv senv cn vs tvs' tn ts' ts.
(EVERY (check_freevars tvs []) ts' /\
(LENGTH tvs' = LENGTH ts') /\
type_vs tvs cenv senv vs (MAP (type_subst (FUPDATE_LIST FEMPTY (REVERSE (ZIP (tvs', ts'))))) ts) /\
(FLOOKUP cenv (cn, tn) = SOME (tvs',ts)))
==>
type_v tvs cenv senv (Conv (SOME (cn,tn)) vs) (Tapp ts' (tid_exn_to_tc tn)))

/\ (! tvs cenv senv vs ts.
(type_vs tvs cenv senv vs ts)
==>
type_v tvs cenv senv (Conv NONE vs) (Tapp ts TC_tup))

/\ (! tvs ctMap senv env tenv n e t1 t2.
(consistent_con_env ctMap (environment_c env) tenv.c /\
tenv_mod_ok tenv.m /\
consistent_mod_env senv ctMap (environment_m env) tenv.m /\
type_env ctMap senv (environment_v env) tenv.v /\
check_freevars tvs [] t1 /\
type_e (tenv with<| v := Bind_name n( 0) t1 (bind_tvar tvs tenv.v)|>) e t2)
==>
type_v tvs ctMap senv (Closure env n e) (Tfn t1 t2))

/\ (! tvs ctMap senv env funs n t tenv tenv'.
(consistent_con_env ctMap (environment_c env) tenv.c /\
tenv_mod_ok tenv.m /\
consistent_mod_env senv ctMap (environment_m env) tenv.m /\
type_env ctMap senv (environment_v env) tenv.v /\
type_funs (tenv with<| v := bind_var_list( 0) tenv' (bind_tvar tvs tenv.v)|>) funs tenv' /\
(ALOOKUP tenv' n = SOME t) /\
ALL_DISTINCT (MAP (\ (f,x,e) .  f) funs) /\
MEM n (MAP (\ (f,x,e) .  f) funs))
==>
type_v tvs ctMap senv (Recclosure env funs n) t)

/\ (! tvs cenv senv n t.
(check_freevars( 0) [] t /\
(FLOOKUP senv n = SOME (Ref_t t)))
==>
type_v tvs cenv senv (Loc n) (Tref t))

/\ (! tvs cenv senv n.
(FLOOKUP senv n = SOME W8array_t)
==>
type_v tvs cenv senv (Loc n) Tword8array)

/\ (! tvs cenv senv n t.
(check_freevars( 0) [] t /\
(FLOOKUP senv n = SOME (Varray_t t)))
==>
type_v tvs cenv senv (Loc n) (Tapp [t] TC_array))

/\ (! tvs cenv senv vs t.
(check_freevars( 0) [] t /\
EVERY (\ v .  type_v tvs cenv senv v t) vs)
==>
type_v tvs cenv senv (Vectorv vs) (Tapp [t] TC_vector))

/\ (! tvs cenv senv.
T
==>
type_vs tvs cenv senv [] [])

/\ (! tvs cenv senv v vs t ts.
(type_v tvs cenv senv v t /\
type_vs tvs cenv senv vs ts)
==>
type_vs tvs cenv senv (v::vs) (t::ts))

/\ (! cenv senv.
T
==>
type_env cenv senv [] Empty)

/\ (! cenv senv n v env t tenv tvs.
(type_v tvs cenv senv v t /\
type_env cenv senv env tenv)
==>
type_env cenv senv ((n,v)::env) (Bind_name n tvs t tenv))

/\ (! tenvS tenvC.
T
==>
consistent_mod_env tenvS tenvC [] FEMPTY)

/\ (! tenvS tenvC mn env menv tenv tenvM.
(type_env tenvC tenvS env (bind_var_list2 tenv Empty) /\
consistent_mod_env tenvS tenvC menv tenvM)
==>
consistent_mod_env tenvS tenvC ((mn,env)::menv) (tenvM |+ (mn, tenv)))`;

val _ = Define `
 (type_s cenv senv s =  
(! l.
    ((? st. FLOOKUP senv l = SOME st) <=> (? v. store_lookup l s = SOME v)) /\
    (! st sv. ((FLOOKUP senv l = SOME st) /\ (store_lookup l s = SOME sv)) ==>
       (case (sv,st) of
           (Refv v, Ref_t t) => type_v( 0) cenv senv v t
         | (W8array es, W8array_t) => T
         | (Varray vs, Varray_t t) => EVERY (\ v .  type_v( 0) cenv senv v t) vs
         | _ => F
       ))))`;


val _ = Hol_reln ` (! n.
T
==>
context_invariant n [] n)

/\ (! dec_tvs c env.
(context_invariant dec_tvs c( 0))
==>
context_invariant dec_tvs ((Craise () ,env) :: c) 0)

/\ (! dec_tvs c pes env.
(context_invariant dec_tvs c( 0))
==>
context_invariant dec_tvs ((Chandle ()  pes,env) :: c) 0)

/\ (! dec_tvs c op vs es env.
(context_invariant dec_tvs c( 0))
==>
context_invariant dec_tvs ((Capp op vs ()  es,env) :: c) 0)

/\ (! dec_tvs c l e env.
(context_invariant dec_tvs c( 0))
==>
context_invariant dec_tvs ((Clog l ()  e,env) :: c) 0)

/\ (! dec_tvs c e1 e2 env.
(context_invariant dec_tvs c( 0))
==>
context_invariant dec_tvs ((Cif ()  e1 e2,env) :: c) 0)

/\ (! dec_tvs c pes env err_v.
(context_invariant dec_tvs c( 0))
==>
context_invariant dec_tvs ((Cmat ()  pes err_v,env) :: c) 0)

/\ (! dec_tvs c tvs x e env.
(context_invariant dec_tvs c( 0))
==>
context_invariant dec_tvs ((Clet x ()  e,env) :: c) tvs)

/\ (! dec_tvs c cn vs es tvs env.
(context_invariant dec_tvs c tvs /\
( ~ (tvs =( 0)) ==> EVERY is_value es))
==>
context_invariant dec_tvs ((Ccon cn vs ()  es,env) :: c) tvs)`;

val _ = Hol_reln ` (! tvs all_cenv senv tenv t.
(check_freevars tvs [] t)
 ==>
type_ctxt tvs all_cenv senv tenv (Craise () ) Texn t)

/\ (! tvs all_cenv senv tenv pes t.
(! ((p,e) :: LIST_TO_SET pes). ? tenv'.
   ALL_DISTINCT (pat_bindings p []) /\
   type_p (num_tvs tenv.v) tenv.c p Texn tenv' /\
   type_e (tenv with<| v := bind_var_list( 0) tenv' tenv.v|>) e t)
==>
type_ctxt tvs all_cenv senv tenv (Chandle ()  pes) t t)

/\ (! tvs all_cenv senv tenv vs es op t1 t2 ts1 ts2.
(check_freevars tvs [] t1 /\
check_freevars tvs [] t2 /\
type_vs( 0) all_cenv senv vs ts1 /\
type_es tenv es ts2 /\
type_op op ((REVERSE ts2 ++ [t1]) ++ ts1) t2)
==>
type_ctxt tvs all_cenv senv tenv (Capp op vs ()  es) t1 t2)

/\ (! tvs all_cenv senv tenv op e.
(type_e tenv e (Tapp [] (TC_name (Short "bool"))))
==>
type_ctxt tvs all_cenv senv tenv (Clog op ()  e) (Tapp [] (TC_name (Short "bool"))) (Tapp [] (TC_name (Short "bool"))))

/\ (! tvs all_cenv senv tenv e1 e2 t.
(type_e tenv e1 t /\
type_e tenv e2 t)
==>
type_ctxt tvs all_cenv senv tenv (Cif ()  e1 e2) (Tapp [] (TC_name (Short "bool"))) t)

/\ (! tvs all_cenv senv tenv t1 t2 pes err_v.
(((pes = []) ==> (check_freevars tvs [] t1 /\ check_freevars( 0) [] t2)) /\
(! ((p,e) :: LIST_TO_SET pes) . ? tenv'.
   ALL_DISTINCT (pat_bindings p []) /\
   type_p tvs tenv.c p t1 tenv' /\
   type_e (tenv with<| v := bind_var_list( 0) tenv' tenv.v|>) e t2) /\
type_v( 0) all_cenv senv err_v Texn)
==>
type_ctxt tvs all_cenv senv tenv (Cmat ()  pes err_v) t1 t2)

/\ (! tvs all_cenv senv tenv e t1 t2 n.
(check_freevars tvs [] t1 /\
type_e (tenv with<| v := opt_bind_name n tvs t1 tenv.v|>) e t2)
==>
type_ctxt tvs all_cenv senv tenv (Clet n ()  e) t1 t2)

/\ (! tvs all_cenv senv tenv cn vs es ts1 ts2 t tn ts' tvs'.
(EVERY (check_freevars tvs []) ts' /\
(LENGTH tvs' = LENGTH ts') /\
type_vs tvs all_cenv senv vs
        (MAP (type_subst (FUPDATE_LIST FEMPTY (REVERSE (ZIP (tvs', ts'))))) ts1) /\
type_es (tenv with<| v := bind_tvar tvs tenv.v|>) es (MAP (type_subst (FUPDATE_LIST FEMPTY (REVERSE (ZIP (tvs', ts'))))) ts2) /\
(lookup_alist_mod_env cn tenv.c = SOME (tvs', ((REVERSE ts2++[t])++ts1), tn)))
==>
type_ctxt tvs all_cenv senv tenv (Ccon (SOME cn) vs ()  es) (type_subst (FUPDATE_LIST FEMPTY (REVERSE (ZIP (tvs', ts')))) t)
          (Tapp ts' (tid_exn_to_tc tn)))

/\ (! tvs all_cenv senv tenv vs es t ts1 ts2.
(check_freevars tvs [] t /\
type_vs tvs all_cenv senv vs ts1 /\
type_es (tenv with<| v := bind_tvar tvs tenv.v|>) es ts2)
==>
type_ctxt tvs all_cenv senv tenv (Ccon NONE vs ()  es) t (Tapp ((REVERSE ts2++[t])++ts1) TC_tup))`;

val _ = Define `
 (poly_context cs =  
((case cs of
      (Ccon cn vs ()  es,env) :: cs => EVERY is_value es
    | (Clet x ()  e,env) :: cs => T
    | [] => T
    | _ => F
  )))`;


val _ = Define `
 (is_ccon c =  
((case c of
      Ccon cn vs ()  es => T
    | _ => F
  )))`;


val _ = Hol_reln ` (! tvs tenvC senv t.
(check_freevars tvs [] t)
==>
type_ctxts tvs tenvC senv [] t t)

/\ (! tvs ctMap senv c env cs tenv t1 t2 t3.
(type_env ctMap senv (environment_v env) tenv.v /\
consistent_con_env ctMap (environment_c env) tenv.c /\
tenv_mod_ok tenv.m /\
consistent_mod_env senv ctMap (environment_m env) tenv.m /\
type_ctxt tvs ctMap senv tenv c t1 t2 /\
type_ctxts (if is_ccon c /\ poly_context cs then tvs else  0) ctMap senv cs t2 t3)
==>
type_ctxts tvs ctMap senv ((c,env)::cs) t1 t3)`;

val _ = Hol_reln ` (! dec_tvs ctMap senv s env e c t1 t2 tenv tvs tr.
(context_invariant dec_tvs c tvs /\
consistent_con_env ctMap (environment_c env) tenv.c /\
tenv_mod_ok tenv.m /\
consistent_mod_env senv ctMap (environment_m env) tenv.m /\
type_ctxts tvs ctMap senv c t1 t2 /\
type_env ctMap senv (environment_v env) tenv.v /\
type_s ctMap senv s /\
type_e (tenv with<| v := bind_tvar tvs tenv.v|>) e t1 /\
(( ~ (tvs =( 0))) ==> is_value e))
==>
type_state dec_tvs ctMap senv (env, (s,tr), Exp e, c) t2)

/\ (! dec_tvs ctMap senv s env v c t1 t2 tvs tr.
(context_invariant dec_tvs c tvs /\
type_ctxts tvs ctMap senv c t1 t2 /\
type_s ctMap senv s /\
type_v tvs ctMap senv v t1)
==>
type_state dec_tvs ctMap senv (env, (s,tr), Val v, c) t2)`;

(* The first argument has strictly more bindings than the second. *)
(*val weakM_def : Map.map modN (alist varN (nat * t)) -> Map.map modN (alist varN (nat * t)) -> bool*)
val _ = Define `
 (weakM tenvM tenvM' =  
(! mn tenv'.
    (FLOOKUP tenvM' mn = SOME tenv')
    ==>
    (? tenv. (FLOOKUP tenvM mn = SOME tenv) /\ weakE tenv tenv')))`;


(*val weakC_def : tenv_ctor -> tenv_ctor -> bool*)
val _ = Define `
 (weakC tenvC tenvC' =  
(flat_weakC (SND tenvC) (SND tenvC') /\  
(! mn flat_tenvC'.    
(ALOOKUP (FST tenvC') mn = SOME flat_tenvC')
    ==>    
(? flat_tenvC. (ALOOKUP (FST tenvC) mn = SOME flat_tenvC) /\ flat_weakC flat_tenvC flat_tenvC'))))`;


(* The global constructor type environment has the primitive exceptions in it *)
(*val ctMap_has_exns : ctMap -> bool*)
val _ = Define `
 (ctMap_has_exns ctMap =  
((FLOOKUP ctMap ("Bind", TypeExn (Short "Bind")) = SOME ([],[])) /\
  (FLOOKUP ctMap ("Chr", TypeExn (Short "Chr")) = SOME ([],[])) /\
  (FLOOKUP ctMap ("Div", TypeExn (Short "Div")) = SOME ([],[])) /\
  (FLOOKUP ctMap ("Subscript", TypeExn (Short "Subscript")) = SOME ([],[]))))`;


(* The global constructor type environment has the list primitives in it *)
(*val ctMap_has_lists : ctMap -> bool*)
val _ = Define `
 (ctMap_has_lists ctMap =  
((FLOOKUP ctMap ("nil", TypeId (Short "list")) = SOME (["'a"],[])) /\
  (FLOOKUP ctMap ("::", TypeId (Short "list")) =
   SOME (["'a"],[Tvar "'a"; Tapp [Tvar "'a"] (TC_name (Short "list"))])) /\
  (! cn. (~ (cn = "::") /\ ~ (cn = "nil")) ==> (FLOOKUP ctMap (cn, TypeId (Short "list")) = NONE))))`;


(* The global constructor type environment has the bool primitives in it *)
(*val ctMap_has_bools : ctMap -> bool*)
val _ = Define `
 (ctMap_has_bools ctMap =  
((FLOOKUP ctMap ("true", TypeId (Short "bool")) = SOME ([],[])) /\
  (FLOOKUP ctMap ("false", TypeId (Short "bool")) = SOME ([],[])) /\
  (! cn. (~ (cn = "true") /\ ~ (cn = "false")) ==> (FLOOKUP ctMap (cn, TypeId (Short "bool")) = NONE))))`;


(* The types and exceptions that are missing are all declared in modules. *)
(*val weak_decls_only_mods : decls -> decls -> bool*)
val _ = Define `
  (weak_decls_only_mods d1 d2 =    
((! tn.
       ((Short tn IN d1.defined_types) ==> (Short tn IN d2.defined_types))) /\
    (! cn.
       ((Short cn IN d1.defined_exns) ==> (Short cn IN d2.defined_exns)))))`;


(* The run-time declared constructors and exceptions are all either declared in
 * the type system, or from modules that have been declared *)

(*val consistent_decls : set tid_or_exn -> decls -> bool*)
val _ = Define `
 (consistent_decls tes d =  
(! (te :: tes).
    (case te of
        TypeExn cid => (cid IN d.defined_exns) \/ (? mn cn. (cid = Long mn cn) /\ (mn IN d.defined_mods))
      | TypeId tid => (tid IN d.defined_types) \/ (? mn tn. (tid = Long mn tn) /\ (mn IN d.defined_mods))
    )))`;


(*val consistent_ctMap : decls -> ctMap -> bool*)
val _ = Define `
 (consistent_ctMap d ctMap =  
(! ((cn,tid) :: FDOM ctMap).
    (case tid of
        TypeId tn => tn IN d.defined_types
      | TypeExn cn => cn IN d.defined_exns
    )))`;


(*val decls_ok : decls -> bool*)
val _ = Define `
 (decls_ok d =  
(decls_to_mods d SUBSET ({NONE} UNION IMAGE SOME d.defined_mods)))`;


(* For using the type soundess theorem, we have to know there are good
 * constructor and module type environments that don't have bits hidden by a
 * signature. *)
val _ = Define `
 (type_sound_invariants r (d,tenv,st,env) =  
(? ctMap tenvS decls_no_sig tenvM_no_sig tenvC_no_sig.
    consistent_decls (state_defined_types st) decls_no_sig /\
    consistent_ctMap decls_no_sig ctMap /\
    ctMap_has_exns ctMap /\
    ctMap_has_lists ctMap /\
    ctMap_has_bools ctMap /\
    tenv_tabbrev_ok tenv.t /\
    tenv_mod_ok tenvM_no_sig /\
    tenv_mod_ok tenv.m /\
    consistent_mod_env tenvS ctMap (environment_m env) tenvM_no_sig /\
    consistent_con_env ctMap (environment_c env) tenvC_no_sig /\
    type_env ctMap tenvS (environment_v env) tenv.v /\
    type_s ctMap tenvS st.refs /\
    weakM tenvM_no_sig tenv.m /\
    weakC tenvC_no_sig tenv.c /\
    decls_ok decls_no_sig /\
    weak_decls decls_no_sig d /\
    weak_decls_only_mods decls_no_sig d /\
    (! err. (r = SOME (Rerr (Rraise err))) ==> type_v( 0) ctMap tenvS err Texn) /\    
(d.defined_mods = (state_defined_mods st))))`;


val _ = Define `
 (update_type_sound_inv ((decls1:decls),(tenv:type_environment),(st: 'ffi state),(env: v environment)) decls1' tenvT' tenvM' tenvC' tenv' st' new_ctors r =  
((case r of
       Rval (new_mods, new_vals) =>
         (union_decls decls1' decls1,
          <| t := (merge_mod_env tenvT' tenv.t);
             m := (FUNION tenvM' tenv.m);
             c := (merge_alist_mod_env tenvC' tenv.c);
             v := (bind_var_list2 tenv' tenv.v) |>,
          st',extend_top_env new_mods new_vals new_ctors env)
     | Rerr _ => (union_decls decls1' decls1,tenv,st',env)
  )))`;

val _ = export_theory()

