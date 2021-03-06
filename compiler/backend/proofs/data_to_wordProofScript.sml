open preamble bvlSemTheory dataSemTheory dataPropsTheory copying_gcTheory
     int_bitwiseTheory data_to_wordPropsTheory finite_mapTheory
     data_to_wordTheory wordPropsTheory labPropsTheory whileTheory
     set_sepTheory semanticsPropsTheory word_to_wordProofTheory
     helperLib alignmentTheory;

val _ = new_theory "data_to_wordProof";

(* TODO: move *)

val WORD_MUL_BIT0 = store_thm("WORD_MUL_BIT0",
  ``!a b. (a * b) ' 0 <=> a ' 0 /\ b ' 0``,
  fs [word_mul_def,word_index,bitTheory.BIT0_ODD,ODD_MULT]
  \\ Cases \\ Cases \\ fs [word_index,bitTheory.BIT0_ODD]);

val word_lsl_index = Q.store_thm("word_lsl_index",
  `i < dimindex(:'a) ⇒
    (((w:'a word) << n) ' i ⇔ n ≤ i ∧ w ' (i-n))`,
  rw[word_lsl_def,fcpTheory.FCP_BETA]);

val word_lsr_index = Q.store_thm("word_lsr_index",
  `i < dimindex(:'a) ⇒
   (((w:'a word) >>> n) ' i ⇔ i + n < dimindex(:'a) ∧ w ' (i+n))`,
  rw[word_lsr_def,fcpTheory.FCP_BETA]);

val lsr_lsl = Q.store_thm("lsr_lsl",
  `∀w n. aligned n w ⇒ (w >>> n << n = w)`,
  rw[]
  \\ rw[GSYM WORD_EQ]
  \\ fs[word_bit_def]
  \\ rw[word_lsl_index,word_lsr_index]
  \\ Cases_on`n ≤ x` \\ fs[]
  \\ fs[aligned_extract]
  \\ fs[word_extract_def,w2w_def,word_bits_def]
  \\ last_x_assum(mp_tac o Q.AP_TERM`combin$C $' x`)
  \\ simp[fcpTheory.FCP_BETA,word_0]);

val word_index_test = store_thm("word_index_test",
  ``n < dimindex (:'a) ==> (w ' n <=> ((w && n2w (2 ** n)) <> 0w:'a word))``,
  srw_tac [wordsLib.WORD_BIT_EQ_ss] [wordsTheory.word_index])

val word_and_one_eq_0_iff = store_thm("word_and_one_eq_0_iff", (* same in stack_alloc *)
  ``!w. ((w && 1w) = 0w) <=> ~(w ' 0)``,
  srw_tac [wordsLib.WORD_BIT_EQ_ss] [word_index])

val get_var_set_var = store_thm("get_var_set_var[simp]",
  ``get_var n (set_var n w s) = SOME w``,
  full_simp_tac(srw_ss())[wordSemTheory.get_var_def,wordSemTheory.set_var_def]);

val set_var_set_var = store_thm("set_var_set_var[simp]",
  ``set_var n v (set_var n w s) = set_var n v s``,
  fs[wordSemTheory.state_component_equality,wordSemTheory.set_var_def,
      insert_shadow]);

val toAList_LN = Q.store_thm("toAList_LN[simp]",
  `toAList LN = []`,
  EVAL_TAC)

val adjust_set_LN = Q.store_thm("adjust_set_LN[simp]",
  `adjust_set LN = insert 0 () LN`,
  srw_tac[][adjust_set_def,fromAList_def]);

val ALOOKUP_SKIP_LEMMA = prove(
  ``¬MEM n (MAP FST xs) /\ d = e ==>
    ALOOKUP (xs ++ [(n,d)] ++ ys) n = SOME e``,
  full_simp_tac(srw_ss())[ALOOKUP_APPEND] \\ fs[GSYM ALOOKUP_NONE])

val LAST_EQ = prove(
  ``(LAST (x::xs) = if xs = [] then x else LAST xs) /\
    (FRONT (x::xs) = if xs = [] then [] else x::FRONT xs)``,
  Cases_on `xs` \\ full_simp_tac(srw_ss())[]);

val LASTN_LIST_REL_LEMMA = prove(
  ``!xs1 ys1 xs n y ys x P.
      LASTN n xs1 = x::xs /\ LIST_REL P xs1 ys1 ==>
      ?y ys. LASTN n ys1 = y::ys /\ P x y /\ LIST_REL P xs ys``,
  Induct \\ Cases_on `ys1` \\ full_simp_tac(srw_ss())[LASTN_ALT] \\ rpt strip_tac
  \\ imp_res_tac LIST_REL_LENGTH \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ `F` by decide_tac);

val LASTN_CONS_IMP_LENGTH = store_thm("LASTN_CONS_IMP_LENGTH",
  ``!xs n y ys.
      n <= LENGTH xs ==>
      (LASTN n xs = y::ys) ==> LENGTH (y::ys) = n``,
  Induct \\ full_simp_tac(srw_ss())[LASTN_ALT]
  \\ srw_tac[][] THEN1 decide_tac \\ full_simp_tac(srw_ss())[GSYM NOT_LESS]);

val LASTN_IMP_APPEND = store_thm("LASTN_IMP_APPEND",
  ``!xs n ys.
      n <= LENGTH xs /\ (LASTN n xs = ys) ==>
      ?zs. xs = zs ++ ys /\ LENGTH ys = n``,
  Induct \\ full_simp_tac(srw_ss())[LASTN_ALT] \\ srw_tac[][] THEN1 decide_tac
  \\ `n <= LENGTH xs` by decide_tac \\ res_tac \\ full_simp_tac(srw_ss())[]
  \\ qpat_x_assum `xs = zs ++ LASTN n xs` (fn th => simp [Once th]));

val NOT_NIL_IMP_LAST = prove(
  ``!xs x. xs <> [] ==> LAST (x::xs) = LAST xs``,
  Cases \\ full_simp_tac(srw_ss())[]);

val IS_SOME_IF = prove(
  ``IS_SOME (if b then x else y) = if b then IS_SOME x else IS_SOME y``,
  Cases_on `b` \\ full_simp_tac(srw_ss())[]);

val PERM_ALL_DISTINCT_MAP = prove(
  ``!xs ys. PERM xs ys ==>
            ALL_DISTINCT (MAP f xs) ==>
            ALL_DISTINCT (MAP f ys) /\ !x. MEM x ys <=> MEM x xs``,
  full_simp_tac(srw_ss())[MEM_PERM] \\ srw_tac[][]
  \\ `PERM (MAP f xs) (MAP f ys)` by full_simp_tac(srw_ss())[PERM_MAP]
  \\ metis_tac [ALL_DISTINCT_PERM])

val GENLIST_I =
  GENLIST_EL |> Q.SPECL [`xs`,`\i. EL i xs`,`LENGTH xs`]
    |> SIMP_RULE std_ss []

val ALL_DISTINCT_EL = ``ALL_DISTINCT xs``
  |> ONCE_REWRITE_CONV [GSYM GENLIST_I]
  |> SIMP_RULE std_ss [ALL_DISTINCT_GENLIST]

val PERM_list_rearrange = prove(
  ``!f xs. ALL_DISTINCT xs ==> PERM xs (list_rearrange f xs)``,
  srw_tac[][] \\ match_mp_tac PERM_ALL_DISTINCT
  \\ full_simp_tac(srw_ss())[mem_list_rearrange]
  \\ full_simp_tac(srw_ss())[wordSemTheory.list_rearrange_def] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[ALL_DISTINCT_GENLIST] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[BIJ_DEF,INJ_DEF,SURJ_DEF]
  \\ full_simp_tac(srw_ss())[ALL_DISTINCT_EL]);

val ALL_DISTINCT_MEM_IMP_ALOOKUP_SOME = prove(
  ``!xs x y. ALL_DISTINCT (MAP FST xs) /\ MEM (x,y) xs ==> ALOOKUP xs x = SOME y``,
  Induct \\ full_simp_tac(srw_ss())[]
  \\ Cases \\ full_simp_tac(srw_ss())[ALOOKUP_def] \\ srw_tac[][]
  \\ res_tac \\ full_simp_tac(srw_ss())[MEM_MAP,FORALL_PROD]
  \\ rev_full_simp_tac(srw_ss())[]) |> SPEC_ALL;

val IS_SOME_ALOOKUP_EQ = prove(
  ``!l x. IS_SOME (ALOOKUP l x) = MEM x (MAP FST l)``,
  Induct \\ full_simp_tac(srw_ss())[]
  \\ Cases \\ full_simp_tac(srw_ss())[ALOOKUP_def] \\ srw_tac[][]);

val MEM_IMP_IS_SOME_ALOOKUP = prove(
  ``!l x y. MEM (x,y) l ==> IS_SOME (ALOOKUP l x)``,
  full_simp_tac(srw_ss())[IS_SOME_ALOOKUP_EQ,MEM_MAP,EXISTS_PROD] \\ metis_tac []);

val SUBSET_INSERT_EQ_SUBSET = prove(
  ``~(x IN s) ==> (s SUBSET (x INSERT t) <=> s SUBSET t)``,
  full_simp_tac(srw_ss())[EXTENSION]);

val EVERY2_IMP_EL = prove(
  ``!xs ys P n. EVERY2 P xs ys /\ n < LENGTH ys ==> P (EL n xs) (EL n ys)``,
  Induct \\ Cases_on `ys` \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ Cases_on `n` \\ full_simp_tac(srw_ss())[]);

val FST_PAIR_EQ = prove(
  ``!x v. (FST x,v) = x <=> v = SND x``,
  Cases \\ full_simp_tac(srw_ss())[]);

val EVERY2_APPEND_IMP = prove(
  ``!xs1 xs2 zs P.
      EVERY2 P (xs1 ++ xs2) zs ==>
      ?zs1 zs2. zs = zs1 ++ zs2 /\ EVERY2 P xs1 zs1 /\ EVERY2 P xs2 zs2``,
  Induct \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ res_tac \\ full_simp_tac(srw_ss())[]
  \\ Q.LIST_EXISTS_TAC [`y::zs1`,`zs2`] \\ full_simp_tac(srw_ss())[]);

val ZIP_ID = prove(
  ``!xs. ZIP (MAP FST xs, MAP SND xs) = xs``,
  Induct \\ full_simp_tac(srw_ss())[]);

val write_bytearray_isWord = Q.store_thm("write_bytearray_isWord",
  `∀ls a m x.
   isWord (m x) ⇒
   isWord (write_bytearray a ls m dm be x)`,
  Induct \\ rw[wordSemTheory.write_bytearray_def]
  \\ rw[wordSemTheory.mem_store_byte_aux_def]
  \\ every_case_tac \\ fs[]
  \\ simp[APPLY_UPDATE_THM]
  \\ rw[isWord_def]);

val FOLDL_LENGTH_LEMMA = prove(
  ``!xs k l d q r.
      FOLDL (λ(i,t) a. (i + d,insert i a t)) (k,l) xs = (q,r) ==>
      q = LENGTH xs * d + k``,
  Induct \\ fs [FOLDL] \\ rw [] \\ res_tac \\ fs [MULT_CLAUSES]);

val fromList_SNOC = store_thm("fromList_SNOC",
 ``!xs y. fromList (SNOC y xs) = insert (LENGTH xs) y (fromList xs)``,
  fs [fromList_def,FOLDL_APPEND,SNOC_APPEND] \\ rw []
  \\ Cases_on `FOLDL (λ(i,t) a. (i + 1,insert i a t)) (0,LN) xs`
  \\ fs [] \\ imp_res_tac FOLDL_LENGTH_LEMMA \\ fs []);

val fromList2_SNOC = store_thm("fromList2_SNOC",
 ``!xs y. fromList2 (SNOC y xs) = insert (2 * LENGTH xs) y (fromList2 xs)``,
  fs [fromList2_def,FOLDL_APPEND,SNOC_APPEND] \\ rw []
  \\ Cases_on `FOLDL (λ(i,t) a. (i + 2,insert i a t)) (0,LN) xs`
  \\ fs [] \\ imp_res_tac FOLDL_LENGTH_LEMMA \\ fs []);

(* -- *)

(* -------------------------------------------------------
    word_ml_inv: definition and lemmas
   ------------------------------------------------------- *)

val join_env_def = Define `
  join_env env vs =
    MAP (\(n,v). (THE (lookup ((n-2) DIV 2) env), v))
      (FILTER (\(n,v). n <> 0 /\ EVEN n) vs)`

val flat_def = Define `
  (flat (Env env::xs) (StackFrame vs _::ys) =
     join_env env vs ++ flat xs ys) /\
  (flat (Exc env _::xs) (StackFrame vs _::ys) =
     join_env env vs ++ flat xs ys) /\
  (flat _ _ = [])`

val flat_APPEND = prove(
  ``!xs ys xs1 ys1.
      LENGTH xs = LENGTH ys ==>
      flat (xs ++ xs1) (ys ++ ys1) = flat xs ys ++ flat xs1 ys1``,
  Induct \\ Cases_on `ys` \\ full_simp_tac(srw_ss())[flat_def] \\ srw_tac[][]
  \\ Cases_on `h'` \\ Cases_on `h`
  \\ TRY (Cases_on `o'`) \\ full_simp_tac(srw_ss())[flat_def]);

val adjust_var_DIV_2 = prove(
  ``(adjust_var n - 2) DIV 2 = n``,
  full_simp_tac(srw_ss())[ONCE_REWRITE_RULE[MULT_COMM]adjust_var_def,MULT_DIV]);

val adjust_var_DIV_2_ANY = prove(
  ``(adjust_var n) DIV 2 = n + 1``,
  fs [adjust_var_def,ONCE_REWRITE_RULE[MULT_COMM]ADD_DIV_ADD_DIV]);

val EVEN_adjust_var = prove(
  ``EVEN (adjust_var n)``,
  full_simp_tac(srw_ss())[adjust_var_def,EVEN_MOD2,
    ONCE_REWRITE_RULE[MULT_COMM]MOD_TIMES]);

val adjust_var_NEQ_0 = prove(
  ``adjust_var n <> 0``,
  rpt strip_tac \\ full_simp_tac(srw_ss())[adjust_var_def]);

val adjust_var_NEQ_1 = prove(
  ``adjust_var n <> 1``,
  rpt strip_tac
  \\ `EVEN (adjust_var n) = EVEN 1` by full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[EVEN_adjust_var]);

val adjust_var_NEQ = store_thm("adjust_var_NEQ[simp]",
  ``adjust_var n <> 0 /\
    adjust_var n <> 1 /\
    adjust_var n <> 3 /\
    adjust_var n <> 5 /\
    adjust_var n <> 7 /\
    adjust_var n <> 9 /\
    adjust_var n <> 11 /\
    adjust_var n <> 13``,
  rpt strip_tac \\ fs [adjust_var_NEQ_0]
  \\ `EVEN (adjust_var n) = EVEN 1` by full_simp_tac(srw_ss())[]
  \\ `EVEN (adjust_var n) = EVEN 3` by full_simp_tac(srw_ss())[]
  \\ `EVEN (adjust_var n) = EVEN 5` by full_simp_tac(srw_ss())[]
  \\ `EVEN (adjust_var n) = EVEN 7` by full_simp_tac(srw_ss())[]
  \\ `EVEN (adjust_var n) = EVEN 9` by full_simp_tac(srw_ss())[]
  \\ `EVEN (adjust_var n) = EVEN 11` by full_simp_tac(srw_ss())[]
  \\ `EVEN (adjust_var n) = EVEN 13` by full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[EVEN_adjust_var]);

val unit_opt_eq = prove(
  ``(x = y:unit option) <=> (IS_SOME x <=> IS_SOME y)``,
  Cases_on `x` \\ Cases_on `y` \\ full_simp_tac(srw_ss())[]);

val adjust_var_11 = prove(
  ``(adjust_var n = adjust_var m) <=> n = m``,
  full_simp_tac(srw_ss())[adjust_var_def,EQ_MULT_LCANCEL]);

val lookup_adjust_var_adjust_set = prove(
  ``lookup (adjust_var n) (adjust_set s) = lookup n s``,
  full_simp_tac(srw_ss())[lookup_def,adjust_set_def,lookup_fromAList,unit_opt_eq,adjust_var_NEQ_0]
  \\ full_simp_tac(srw_ss())[IS_SOME_ALOOKUP_EQ,MEM_MAP,PULL_EXISTS,EXISTS_PROD,adjust_var_11]
  \\ full_simp_tac(srw_ss())[MEM_toAList] \\ Cases_on `lookup n s` \\ full_simp_tac(srw_ss())[]);

val none_opt_eq = prove(
  ``((x = NONE) = (y = NONE)) <=> (IS_SOME x <=> IS_SOME y)``,
  Cases_on `x` \\ Cases_on `y` \\ full_simp_tac(srw_ss())[]);

val lookup_adjust_var_adjust_set_NONE = prove(
  ``lookup (adjust_var n) (adjust_set s) = NONE <=> lookup n s = NONE``,
  full_simp_tac(srw_ss())[lookup_def,adjust_set_def,lookup_fromAList,adjust_var_NEQ_0,none_opt_eq]
  \\ full_simp_tac(srw_ss())[IS_SOME_ALOOKUP_EQ,MEM_MAP,PULL_EXISTS,EXISTS_PROD,adjust_var_11]
  \\ full_simp_tac(srw_ss())[MEM_toAList] \\ Cases_on `lookup n s` \\ full_simp_tac(srw_ss())[]);

val lookup_adjust_var_adjust_set_SOME_UNIT = prove(
  ``lookup (adjust_var n) (adjust_set s) = SOME () <=> IS_SOME (lookup n s)``,
  Cases_on `lookup (adjust_var n) (adjust_set s) = NONE`
  \\ pop_assum (fn th => assume_tac th THEN
       assume_tac (SIMP_RULE std_ss [lookup_adjust_var_adjust_set_NONE] th))
  \\ full_simp_tac(srw_ss())[] \\ Cases_on `lookup n s`
  \\ Cases_on `lookup (adjust_var n) (adjust_set s)` \\ full_simp_tac(srw_ss())[]);

val word_ml_inv_lookup = prove(
  ``word_ml_inv (heap,be,a,sp) limit c refs
      (ys ++ join_env l1 (toAList (inter l2 (adjust_set l1))) ++ xs) /\
    lookup n l1 = SOME x /\
    lookup (adjust_var n) l2 = SOME w ==>
    word_ml_inv (heap,be,a,sp) limit c refs
      (ys ++ [(x,w)] ++ join_env l1 (toAList (inter l2 (adjust_set l1))) ++ xs)``,
  full_simp_tac(srw_ss())[toAList_def,foldi_def,LET_DEF]
  \\ full_simp_tac(srw_ss())[GSYM toAList_def] \\ srw_tac[][]
  \\ `MEM (x,w) (join_env l1 (toAList (inter l2 (adjust_set l1))))` by
   (full_simp_tac(srw_ss())[join_env_def,MEM_MAP,MEM_FILTER,EXISTS_PROD,MEM_toAList,lookup_inter]
    \\ qexists_tac `adjust_var n` \\ full_simp_tac(srw_ss())[adjust_var_DIV_2,EVEN_adjust_var]
    \\ full_simp_tac(srw_ss())[adjust_var_NEQ_0] \\ every_case_tac
    \\ full_simp_tac(srw_ss())[lookup_adjust_var_adjust_set_NONE])
  \\ full_simp_tac(srw_ss())[MEM_SPLIT] \\ full_simp_tac(srw_ss())[] \\ full_simp_tac(srw_ss())[adjust_var_def]
  \\ qpat_x_assum `word_ml_inv yyy limit c refs xxx` mp_tac
  \\ match_mp_tac word_ml_inv_rearrange \\ full_simp_tac(srw_ss())[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]);

val word_ml_inv_get_var_IMP = store_thm("word_ml_inv_get_var_IMP",
  ``word_ml_inv (heap,be,a,sp) limit c refs
      (join_env s.locals (toAList (inter t.locals (adjust_set s.locals)))++envs) /\
    get_var n s.locals = SOME x /\
    get_var (adjust_var n) t = SOME w ==>
    word_ml_inv (heap,be,a,sp) limit c refs
      ([(x,w)]++join_env s.locals
          (toAList (inter t.locals (adjust_set s.locals)))++envs)``,
  srw_tac[][] \\ match_mp_tac (word_ml_inv_lookup
             |> Q.INST [`ys`|->`[]`] |> SIMP_RULE std_ss [APPEND])
  \\ full_simp_tac(srw_ss())[get_var_def,wordSemTheory.get_var_def]);

val word_ml_inv_get_vars_IMP = store_thm("word_ml_inv_get_vars_IMP",
  ``!n x w envs.
      word_ml_inv (heap,be,a,sp) limit c refs
        (join_env s.locals
           (toAList (inter t.locals (adjust_set s.locals)))++envs) /\
      get_vars n s.locals = SOME x /\
      get_vars (MAP adjust_var n) t = SOME w ==>
      word_ml_inv (heap,be,a,sp) limit c refs
        (ZIP(x,w)++join_env s.locals
           (toAList (inter t.locals (adjust_set s.locals)))++envs)``,
  Induct \\ full_simp_tac(srw_ss())[get_vars_def,wordSemTheory.get_vars_def] \\ rpt strip_tac
  \\ every_case_tac \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ imp_res_tac word_ml_inv_get_var_IMP
  \\ Q.MATCH_ASSUM_RENAME_TAC `dataSem$get_var h s.locals = SOME x7`
  \\ Q.MATCH_ASSUM_RENAME_TAC `_ (adjust_var h) _ = SOME x8`
  \\ `word_ml_inv (heap,be,a,sp) limit c refs
        (join_env s.locals (toAList (inter t.locals (adjust_set s.locals))) ++
        (x7,x8)::envs)` by
   (pop_assum mp_tac \\ match_mp_tac word_ml_inv_rearrange
    \\ full_simp_tac(srw_ss())[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[])
  \\ res_tac \\ pop_assum (K all_tac) \\ pop_assum mp_tac
  \\ match_mp_tac word_ml_inv_rearrange
  \\ full_simp_tac(srw_ss())[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]) |> SPEC_ALL;

val IMP_adjust_var = prove(
  ``n <> 0 /\ EVEN n ==> adjust_var ((n - 2) DIV 2) = n``,
  full_simp_tac(srw_ss())[EVEN_EXISTS] \\ srw_tac[][] \\ Cases_on `m` \\ full_simp_tac(srw_ss())[MULT_CLAUSES]
  \\ once_rewrite_tac [MULT_COMM] \\ full_simp_tac(srw_ss())[MULT_DIV]
  \\ full_simp_tac(srw_ss())[adjust_var_def] \\ decide_tac);

val unit_some_eq_IS_SOME = prove(
  ``!x. (x = SOME ()) <=> IS_SOME x``,
  Cases \\ full_simp_tac(srw_ss())[]);

val word_ml_inv_insert = store_thm("word_ml_inv_insert",
  ``word_ml_inv (heap,be,a,sp) limit c refs
      ([(x,w)]++join_env d (toAList (inter l (adjust_set d)))++xs) ==>
    word_ml_inv (heap,be,a,sp) limit c refs
      (join_env (insert dest x d)
        (toAList (inter (insert (adjust_var dest) w l)
                           (adjust_set (insert dest x d))))++xs)``,
  match_mp_tac word_ml_inv_rearrange \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[join_env_def,MEM_MAP,MEM_FILTER,EXISTS_PROD]
  \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[MEM_toAList]
  \\ full_simp_tac(srw_ss())[lookup_insert,lookup_inter_alt]
  \\ Cases_on `dest = (p_1 - 2) DIV 2` \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[adjust_var_DIV_2]
  \\ imp_res_tac IMP_adjust_var \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[domain_lookup] \\ every_case_tac \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[adjust_var_11] \\ full_simp_tac(srw_ss())[]
  \\ disj1_tac \\ disj2_tac \\ qexists_tac `p_1` \\ full_simp_tac(srw_ss())[unit_some_eq_IS_SOME]
  \\ full_simp_tac(srw_ss())[adjust_set_def,lookup_fromAList] \\ rev_full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[IS_SOME_ALOOKUP_EQ,MEM_MAP,PULL_EXISTS,EXISTS_PROD,adjust_var_11]
  \\ full_simp_tac(srw_ss())[MEM_toAList,lookup_insert] \\ every_case_tac \\ full_simp_tac(srw_ss())[]);

(* -------------------------------------------------------
    definition and verification of GC function
   ------------------------------------------------------- *)

val ptr_to_addr_def = Define `
  ptr_to_addr conf base (w:'a word) =
    base + ((w >>> (shift_length conf)) * bytes_in_word)`

val is_fwd_ptr_def = Define `
  (is_fwd_ptr (Word w) = ((w && 3w) = 0w)) /\
  (is_fwd_ptr _ = F)`;

val update_addr_def = Define `
  update_addr conf fwd_ptr (old_addr:'a word) =
    ((fwd_ptr << (shift_length conf)) ||
     ((shift_length conf - 1) -- 0) old_addr)`

val memcpy_def = Define `
  memcpy w a b m dm =
    if w = 0w then (b,m,T) else
      let (b1,m1,c1) = memcpy (w-1w) (a + bytes_in_word) (b + bytes_in_word)
                      ((b =+ m a) m) dm in
        (b1,m1,c1 /\ a IN dm /\ b IN dm)`

val word_gc_move_def = Define `
  (word_gc_move conf (Loc l1 l2,i,pa,old,m,dm) = (Loc l1 l2,i,pa,m,T)) /\
  (word_gc_move conf (Word w,i,pa,old,m,dm) =
     if (w && 1w) = 0w then (Word w,i,pa,m,T) else
       let c = (ptr_to_addr conf old w IN dm) in
       let v = m (ptr_to_addr conf old w) in
         if is_fwd_ptr v then
           (Word (update_addr conf (theWord v >>> 2) w),i,pa,m,c)
         else
           let header_addr = ptr_to_addr conf old w in
           let c = (c /\ header_addr IN dm /\ isWord (m header_addr)) in
           let len = decode_length conf (theWord (m header_addr)) in
           let v = i + len + 1w in
           let (pa1,m1,c1) = memcpy (len+1w) header_addr pa m dm in
           let c = (c /\ header_addr IN dm /\ c1) in
           let m1 = (header_addr =+ Word (i << 2)) m1 in
             (Word (update_addr conf i w),v,pa1,m1,c))`

val word_gc_move_roots_def = Define `
  (word_gc_move_roots conf ([],i,pa,old,m,dm) = ([],i,pa,m,T)) /\
  (word_gc_move_roots conf (w::ws,i,pa,old,m,dm) =
     let (w1,i1,pa1,m1,c1) = word_gc_move conf (w,i,pa,old,m,dm) in
     let (ws2,i2,pa2,m2,c2) = word_gc_move_roots conf (ws,i1,pa1,old,m1,dm) in
       (w1::ws2,i2,pa2,m2,c1 /\ c2))`

val word_gc_move_list_def = Define `
  word_gc_move_list conf (a:'a word,l:'a word,i,pa:'a word,old,m,dm) =
   if l = 0w then (a,i,pa,m,T) else
     let w = (m a):'a word_loc in
     let (w1,i1,pa1,m1,c1) = word_gc_move conf (w,i,pa,old,m,dm) in
     let m1 = (a =+ w1) m1 in
     let (a2,i2,pa2,m2,c2) = word_gc_move_list conf (a+bytes_in_word,l-1w,i1,pa1,old,m1,dm) in
       (a2,i2,pa2,m2,a IN dm /\ c1 /\ c2)`

val word_gc_move_loop_def = Define `
  word_gc_move_loop k conf (pb,i,pa,old,m,dm,c) =
    if pb = pa then (i,pa,m,c) else
    if k = 0 then (i,pa,m,F) else
      let w = m pb in
      let c = (c /\ pb IN dm /\ isWord w) in
      let len = decode_length conf (theWord w) in
        if word_bit 2 (theWord w) then
          let pb = pb + (len + 1w) * bytes_in_word in
            word_gc_move_loop (k-1n) conf (pb,i,pa,old,m,dm,c)
        else
          let pb = pb + bytes_in_word in
          let (pb,i1,pa1,m1,c1) = word_gc_move_list conf (pb,len,i,pa,old,m,dm) in
            word_gc_move_loop (k-1n) conf (pb,i1,pa1,old,m1,dm,c /\ c1)`

val word_full_gc_def = Define `
  word_full_gc conf (all_roots,new,old:'a word,m,dm) =
    let (rs,i1,pa1,m1,c1) = word_gc_move_roots conf (all_roots,0w,new,old,m,dm) in
    let (i1,pa1,m1,c2) =
          word_gc_move_loop (dimword(:'a)) conf (new,i1,pa1,old,m1,dm,c1)
    in (rs,i1,pa1,m1,c2)`

val word_gc_fun_assum_def = Define `
  word_gc_fun_assum (conf:data_to_word$config) (s:store_name |-> 'a word_loc) <=>
    {Globals; CurrHeap; OtherHeap; HeapLength} SUBSET FDOM s /\
    isWord (s ' OtherHeap) /\
    isWord (s ' CurrHeap) /\
    isWord (s ' HeapLength) /\
    good_dimindex (:'a) /\
    conf.len_size <> 0 /\
    conf.len_size + 2 < dimindex (:'a) /\
    shift_length conf < dimindex (:'a)`

val word_gc_fun_def = Define `
  (word_gc_fun (conf:data_to_word$config)):'a gc_fun_type = \(roots,m,dm,s).
     let c = word_gc_fun_assum conf s in
     let new = theWord (s ' OtherHeap) in
     let old = theWord (s ' CurrHeap) in
     let len = theWord (s ' HeapLength) in
     let all_roots = s ' Globals::roots in
     let (roots1,i1,pa1,m1,c2) = word_full_gc conf (all_roots,new,old,m,dm) in
     let s1 = s |++ [(CurrHeap, Word new);
                     (OtherHeap, Word old);
                     (NextFree, Word pa1);
                     (EndOfHeap, Word (new + len));
                     (Globals, HD roots1)] in
       if c /\ c2 then SOME (TL roots1,m1,s1) else NONE`

val one_and_or_1 = prove(
  ``(1w && (w || 1w)) = 1w``,
  srw_tac [wordsLib.WORD_BIT_EQ_ss, boolSimps.CONJ_ss] [word_index])

val one_and_or_3 = prove(
  ``(3w && (w || 3w)) = 3w``,
  srw_tac [wordsLib.WORD_BIT_EQ_ss, boolSimps.CONJ_ss] [word_index])

val ODD_not_zero = prove(
  ``ODD n ==> n2w n <> 0w``,
  CCONTR_TAC \\ full_simp_tac std_ss []
  \\ `((n2w n):'a word) ' 0 = (0w:'a word) ' 0` by metis_tac []
  \\ full_simp_tac(srw_ss())[wordsTheory.word_index,bitTheory.BIT_def,bitTheory.BITS_THM]
  \\ full_simp_tac(srw_ss())[dimword_def,bitTheory.ODD_MOD2_LEM])

val three_not_0 = store_thm("three_not_0[simp]",
  ``3w <> 0w``,
  match_mp_tac ODD_not_zero \\ full_simp_tac(srw_ss())[]);

val DISJ_EQ_IMP = METIS_PROVE [] ``(~b \/ c) <=> (b ==> c)``

val three_and_shift_2 = prove(
  ``(3w && (w << 2)) = 0w``,
  srw_tac [wordsLib.WORD_BIT_EQ_ss, boolSimps.CONJ_ss] [word_index])

val shift_to_zero = prove(
  ``3w >>> 2 = 0w``,
  srw_tac [wordsLib.WORD_BIT_EQ_ss, boolSimps.CONJ_ss] [word_index])

val shift_around_under_big_shift = prove(
  ``!w n k. n <= k ==> (w << n >>> n << k = w << k)``,
  srw_tac [wordsLib.WORD_BIT_EQ_ss, boolSimps.CONJ_ss] [word_index])

val select_shift_out = prove(
  ``n <> 0 ==> ((n - 1 -- 0) (w || v << n) = (n - 1 -- 0) w)``,
  srw_tac [wordsLib.WORD_BIT_EQ_ss, boolSimps.CONJ_ss] [word_index])

val shift_length_NOT_ZERO = store_thm("shift_length_NOT_ZERO[simp]",
  ``shift_length conf <> 0``,
  full_simp_tac(srw_ss())[shift_length_def] \\ decide_tac);

val get_addr_and_1_not_0 = prove(
  ``(1w && get_addr conf k a) <> 0w``,
  Cases_on `a` \\ full_simp_tac(srw_ss())[get_addr_def,get_lowerbits_def]
  \\ rewrite_tac [one_and_or_1,GSYM WORD_OR_ASSOC] \\ full_simp_tac(srw_ss())[]);

val one_lsr_shift_length = prove(
  ``1w >>> shift_length conf = 0w``,
  srw_tac [wordsLib.WORD_BIT_EQ_ss, boolSimps.CONJ_ss]
    [word_index, shift_length_def])

val ptr_to_addr_get_addr = prove(
  ``k * 2 ** shift_length conf < dimword (:'a) ==>
    ptr_to_addr conf curr (get_addr conf k a) =
    curr + n2w k * bytes_in_word:'a word``,
  strip_tac
  \\ full_simp_tac(srw_ss())[ptr_to_addr_def,bytes_in_word_def,WORD_MUL_LSL,get_addr_def]
  \\ simp_tac std_ss [Once WORD_MULT_COMM] \\ AP_THM_TAC \\ AP_TERM_TAC
  \\ full_simp_tac(srw_ss())[get_lowerbits_LSL_shift_length,word_mul_n2w]
  \\ once_rewrite_tac [GSYM w2n_11]
  \\ rewrite_tac [w2n_lsr] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[MULT_DIV]
  \\ Cases_on `2 ** shift_length conf` \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `n` \\ full_simp_tac(srw_ss())[MULT_CLAUSES]
  \\ decide_tac);

val is_fws_ptr_OR_3 = prove(
  ``is_fwd_ptr (Word (w << 2)) /\ ~is_fwd_ptr (Word (w || 3w))``,
  full_simp_tac(srw_ss())[is_fwd_ptr_def] \\ rewrite_tac [one_and_or_3,three_and_shift_2]
  \\ full_simp_tac(srw_ss())[]);

val is_fws_ptr_OR_15 = prove(
  ``~is_fwd_ptr (Word (w || 15w))``,
  full_simp_tac(srw_ss())[is_fwd_ptr_def]
  \\ srw_tac [wordsLib.WORD_BIT_EQ_ss] [word_index, get_lowerbits_def]
  \\ qexists_tac `0` \\ fs []);

val is_fws_ptr_OR_31 = prove(
  ``~is_fwd_ptr (Word (w || 31w))``,
  full_simp_tac(srw_ss())[is_fwd_ptr_def]
  \\ srw_tac [wordsLib.WORD_BIT_EQ_ss] [word_index, get_lowerbits_def]
  \\ qexists_tac `0` \\ fs []);

val select_get_lowerbits = prove(
  ``(shift_length conf − 1 -- 0) (get_lowerbits conf a) =
    get_lowerbits conf a``,
  Cases_on `a`
  \\ srw_tac [wordsLib.WORD_BIT_EQ_ss] [word_index, get_lowerbits_def]
  \\ eq_tac
  \\ rw []
  \\ fs []
  )

val LE_DIV_LT_IMP = prove(
  ``n <= l DIV 2 ** m /\ k < n ==> k * 2 ** m < l``,
  srw_tac[][] \\ `k < l DIV 2 ** m` by decide_tac
  \\ full_simp_tac(srw_ss())[X_LT_DIV,MULT_CLAUSES,GSYM ADD1]
  \\ Cases_on `2 ** m` \\ full_simp_tac(srw_ss())[]
  \\ decide_tac);

val word_bits_eq_slice_shift = store_thm("word_bits_eq_slice_shift",
  ``((k -- n) w) = (((k '' n) w) >>> n)``,
  srw_tac [wordsLib.WORD_BIT_EQ_ss, boolSimps.CONJ_ss] [word_index]
  \\ Cases_on `i + n < dimindex (:'a)`
  \\ fs []
  )

val word_slice_or = prove(
  ``(k '' n) (w || v) = ((k '' n) w || (k '' n) v)``,
  srw_tac [wordsLib.WORD_BIT_EQ_ss, boolSimps.CONJ_ss] [word_index]
  \\ eq_tac
  \\ rw []
  \\ fs []
  )

val word_slice_lsl_eq_0 = prove(
  ``(k '' n) (w << (k + 1)) = 0w``,
  srw_tac [wordsLib.WORD_BIT_EQ_ss, boolSimps.CONJ_ss] [word_index])

val word_slice_2_3_eq_0 = prove(
  ``(n '' 2) 3w = 0w``,
  srw_tac [wordsLib.WORD_BIT_EQ_ss, boolSimps.CONJ_ss] [word_index])

val can_select_def = Define `
  can_select k n w <=> ((k - 1 -- n) (w << n) = w)`

val read_length_lemma = prove(
  ``can_select (n+2) 2 (n2w k :'a word) ==>
    (((n + 1 -- 2) (h ≪ (2 + n) ‖ n2w k ≪ 2 ‖ 3w)) = n2w k :'a word)``,
  full_simp_tac(srw_ss())[word_bits_eq_slice_shift,word_slice_or,can_select_def,DECIDE ``n+2-1=n+1n``]
  \\ full_simp_tac(srw_ss())[DECIDE ``2+n=n+1+1n``,word_slice_lsl_eq_0,word_slice_2_3_eq_0]);

val memcpy_thm = prove(
  ``!xs a:'a word c b m m1 dm b1 ys frame.
      memcpy (n2w (LENGTH xs):'a word) a b m dm = (b1,m1,c) /\
      (LENGTH ys = LENGTH xs) /\ LENGTH xs < dimword(:'a) /\
      (frame * word_list a xs * word_list b ys) (fun2set (m,dm)) ==>
      (frame * word_list a xs * word_list b xs) (fun2set (m1,dm)) /\
      b1 = b + n2w (LENGTH xs) * bytes_in_word /\ c``,
  Induct_on `xs` \\ Cases_on `ys`
  THEN1 (simp [LENGTH,Once memcpy_def,LENGTH])
  THEN1 (simp [LENGTH,Once memcpy_def,LENGTH])
  THEN1 (rpt strip_tac \\ full_simp_tac(srw_ss())[LENGTH])
  \\ rpt gen_tac \\ strip_tac
  \\ qpat_x_assum `_ = (b1,m1,c)`  mp_tac
  \\ once_rewrite_tac [memcpy_def]
  \\ asm_rewrite_tac [n2w_11]
  \\ drule LESS_MOD
  \\ simp_tac (srw_ss()) [ADD1,GSYM word_add_n2w]
  \\ pop_assum mp_tac
  \\ simp_tac (srw_ss()) [word_list_def,LET_THM]
  \\ pairarg_tac
  \\ first_x_assum drule
  \\ full_simp_tac(srw_ss())[] \\ NTAC 2 strip_tac
  \\ qpat_x_assum `_ = (b1',m1',c1)` mp_tac
  \\ SEP_W_TAC \\ SEP_F_TAC
  \\ full_simp_tac(srw_ss())[AC STAR_ASSOC STAR_COMM]
  \\ rpt (disch_then assume_tac)
  \\ full_simp_tac(srw_ss())[] \\ imp_res_tac (DECIDE ``n+1n<k ==> n<k``) \\ full_simp_tac(srw_ss())[]
  \\ rpt var_eq_tac \\ SEP_R_TAC \\ full_simp_tac(srw_ss())[WORD_LEFT_ADD_DISTRIB]);

val LESS_EQ_IMP_APPEND = prove(
  ``!n xs. n <= LENGTH xs ==> ?ys zs. xs = ys ++ zs /\ LENGTH ys = n``,
  Induct_on `xs` \\ full_simp_tac(srw_ss())[] \\ Cases_on `n` \\ full_simp_tac(srw_ss())[LENGTH_NIL]
  \\ srw_tac[][] \\ res_tac \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ qexists_tac `h::ys` \\ full_simp_tac(srw_ss())[]);

val NOT_is_fwd_ptr = prove(
  ``word_payload addrs ll tag tt1 conf = (h,ts,c5) ==> ~is_fwd_ptr (Word h)``,
  Cases_on `tag` \\ fs [word_payload_def] \\ rw []
  \\ full_simp_tac std_ss [GSYM WORD_OR_ASSOC,is_fws_ptr_OR_3,is_fws_ptr_OR_15,
      is_fws_ptr_OR_31,isWord_def,theWord_def,make_header_def,LET_DEF,make_byte_header_def]);

val word_gc_move_thm = prove(
  ``(gc_move (x,[],a,n,heap,T,limit) = (x1,h1,a1,n1,heap1,T)) /\
    heap_length heap <= dimword (:'a) DIV 2 ** shift_length conf /\
    (word_heap curr heap conf * word_list pa xs * frame) (fun2set (m,dm)) /\
    (word_gc_move conf (word_addr conf x,n2w a,pa,curr,m,dm) =
      (w:'a word_loc,i1,pa1,m1,c1)) /\
    LENGTH xs = n ==>
    ?xs1.
      (word_heap curr heap1 conf *
       word_heap pa h1 conf *
       word_list pa1 xs1 * frame) (fun2set (m1,dm)) /\
      (w = word_addr conf x1) /\
      heap_length heap1 = heap_length heap /\
      c1 /\ (i1 = n2w a1) /\ n1 = LENGTH xs1 /\
      pa1 = pa + bytes_in_word * n2w (heap_length h1)``,
  reverse (Cases_on `x`) \\ full_simp_tac(srw_ss())[gc_move_def] THEN1
   (srw_tac[][] \\ full_simp_tac(srw_ss())[word_heap_def,SEP_CLAUSES]
    \\ Cases_on `a'` \\ full_simp_tac(srw_ss())[word_addr_def,word_gc_move_def]
    \\ qexists_tac `xs` \\ full_simp_tac(srw_ss())[heap_length_def])
  \\ CASE_TAC \\ full_simp_tac(srw_ss())[]
  \\ rename1 `heap_lookup k heap = SOME x`
  \\ Cases_on `x` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[word_addr_def]
  \\ pop_assum mp_tac \\ full_simp_tac(srw_ss())[word_gc_move_def,get_addr_and_1_not_0]
  \\ imp_res_tac copying_gcTheory.heap_lookup_LESS
  \\ drule LE_DIV_LT_IMP \\ full_simp_tac(srw_ss())[] \\ strip_tac
  \\ full_simp_tac(srw_ss())[ptr_to_addr_get_addr,word_heap_def,SEP_CLAUSES]
  \\ imp_res_tac heap_lookup_SPLIT \\ full_simp_tac(srw_ss())[] \\ rpt var_eq_tac
  \\ full_simp_tac(srw_ss())[word_heap_APPEND,word_heap_def,word_el_def]
  THEN1
   (helperLib.SEP_R_TAC \\ full_simp_tac(srw_ss())[LET_THM,theWord_def,is_fws_ptr_OR_3]
    \\ srw_tac[][] \\ qexists_tac `xs` \\ full_simp_tac(srw_ss())[]
    \\ full_simp_tac(srw_ss())[update_addr_def,shift_to_zero]
    \\ `2 <= shift_length conf` by (full_simp_tac(srw_ss())[shift_length_def] \\ decide_tac)
    \\ full_simp_tac(srw_ss())[shift_around_under_big_shift]
    \\ full_simp_tac(srw_ss())[get_addr_def,select_shift_out]
    \\ full_simp_tac(srw_ss())[select_get_lowerbits,heap_length_def])
  \\ rename1 `_ = SOME (DataElement addrs ll tt)`
  \\ PairCases_on `tt`
  \\ full_simp_tac(srw_ss())[word_el_def]
  \\ `?h ts c5. word_payload addrs ll tt0 tt1 conf =
         (h:'a word,ts,c5)` by METIS_TAC [PAIR]
  \\ full_simp_tac(srw_ss())[LET_THM] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac bool_ss [word_list_def]
  \\ SEP_R_TAC
  \\ full_simp_tac bool_ss [GSYM word_list_def]
  \\ full_simp_tac std_ss [GSYM WORD_OR_ASSOC,is_fws_ptr_OR_3,isWord_def,theWord_def]
  \\ full_simp_tac (std_ss++sep_cond_ss) [cond_STAR,SEP_CLAUSES]
  \\ `~is_fwd_ptr (Word h)` by (imp_res_tac NOT_is_fwd_ptr \\ fs [])
  \\ fs []
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ `n2w (LENGTH ts) + 1w = n2w (LENGTH (Word h::ts)):'a word` by
        full_simp_tac(srw_ss())[LENGTH,ADD1,word_add_n2w]
  \\ full_simp_tac bool_ss []
  \\ drule memcpy_thm
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,APPEND]
  \\ full_simp_tac(srw_ss())[gc_forward_ptr_thm] \\ rev_full_simp_tac(srw_ss())[]
  \\ rpt var_eq_tac
  \\ full_simp_tac(srw_ss())[heap_length_def,el_length_def]
  \\ full_simp_tac(srw_ss())[GSYM heap_length_def]
  \\ imp_res_tac word_payload_IMP
  \\ rpt var_eq_tac
  \\ drule LESS_EQ_IMP_APPEND \\ strip_tac
  \\ full_simp_tac(srw_ss())[] \\ rpt var_eq_tac
  \\ full_simp_tac(srw_ss())[word_list_APPEND]
  \\ disch_then (qspec_then `ys` assume_tac)
  \\ SEP_F_TAC
  \\ impl_tac THEN1
   (full_simp_tac(srw_ss())[ADD1,SUM_APPEND,X_LE_DIV,RIGHT_ADD_DISTRIB]
    \\ Cases_on `2 ** shift_length conf` \\ full_simp_tac(srw_ss())[]
    \\ Cases_on `n` \\ full_simp_tac(srw_ss())[MULT_CLAUSES]
    \\ Cases_on `n'` \\ full_simp_tac(srw_ss())[MULT_CLAUSES] \\ decide_tac)
  \\ rpt strip_tac
  \\ full_simp_tac(srw_ss())[word_addr_def,word_add_n2w,ADD_ASSOC] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[word_heap_APPEND,word_heap_def,
       SEP_CLAUSES,word_el_def,LET_THM]
  \\ full_simp_tac(srw_ss())[word_list_def]
  \\ SEP_W_TAC \\ qexists_tac `zs` \\ full_simp_tac(srw_ss())[]
  \\ reverse conj_tac THEN1
   (full_simp_tac(srw_ss())[update_addr_def,get_addr_def,
       select_shift_out,select_get_lowerbits,ADD1])
  \\ pop_assum mp_tac
  \\ full_simp_tac(srw_ss())[AC STAR_ASSOC STAR_COMM]
  \\ full_simp_tac(srw_ss())[heap_length_def,SUM_APPEND,el_length_def,ADD1]
  \\ full_simp_tac(srw_ss())[word_list_exists_def,SEP_CLAUSES,SEP_EXISTS_THM]
  \\ srw_tac[][] \\ qexists_tac `ts`
  \\ full_simp_tac(srw_ss())[AC STAR_ASSOC STAR_COMM,SEP_CLAUSES]);

val word_gc_move_roots_thm = prove(
  ``!x a n heap limit pa x1 h1 a1 n1 heap1 pa1 m m1 xs i1 c1 w frame.
      (gc_move_list (x,[],a,n,heap,T,limit) = (x1,h1,a1,n1,heap1,T)) /\
      heap_length heap <= dimword (:'a) DIV 2 ** shift_length conf /\
      (word_heap curr heap conf * word_list pa xs * frame) (fun2set (m,dm)) /\
      (word_gc_move_roots conf (MAP (word_addr conf) x,n2w a,pa,curr,m,dm) =
        (w:'a word_loc list,i1,pa1,m1,c1)) /\
      LENGTH xs = n ==>
      ?xs1.
        (word_heap curr heap1 conf *
         word_heap pa h1 conf *
         word_list pa1 xs1 * frame) (fun2set (m1,dm)) /\
        (w = MAP (word_addr conf) x1) /\
        heap_length heap1 = heap_length heap /\
        c1 /\ (i1 = n2w a1) /\ n1 = LENGTH xs1 /\
        pa1 = pa + n2w (heap_length h1) * bytes_in_word``,
  Induct THEN1
   (full_simp_tac(srw_ss())[gc_move_list_def,word_gc_move_roots_def,word_heap_def,SEP_CLAUSES]
    \\ srw_tac[][] \\ qexists_tac `xs` \\ full_simp_tac(srw_ss())[heap_length_def])
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[gc_move_list_def,LET_THM]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ pop_assum mp_tac
  \\ once_rewrite_tac [gc_move_list_ALT]
  \\ full_simp_tac(srw_ss())[LET_THM]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[word_gc_move_roots_def,LET_THM]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ `c'` by imp_res_tac gc_move_list_ok \\ full_simp_tac(srw_ss())[]
  \\ drule (word_gc_move_thm |> GEN_ALL |> SIMP_RULE std_ss [])
  \\ once_rewrite_tac [CONJ_ASSOC]
  \\ once_rewrite_tac [CONJ_COMM]
  \\ disch_then drule \\ full_simp_tac(srw_ss())[]
  \\ strip_tac \\ SEP_F_TAC \\ full_simp_tac(srw_ss())[]
  \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ first_x_assum drule
  \\ once_rewrite_tac [CONJ_ASSOC]
  \\ once_rewrite_tac [CONJ_COMM]
  \\ disch_then drule \\ full_simp_tac(srw_ss())[]
  \\ strip_tac \\ SEP_F_TAC \\ full_simp_tac(srw_ss())[]
  \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ rename1 `_ = (xs7,xs8,a7,LENGTH xs9,heap7,T)`
  \\ qexists_tac `xs9` \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[word_heap_APPEND]
  \\ full_simp_tac(srw_ss())[AC STAR_COMM STAR_ASSOC]
  \\ full_simp_tac(srw_ss())[WORD_LEFT_ADD_DISTRIB,heap_length_def,SUM_APPEND,GSYM word_add_n2w]);

val word_gc_move_list_thm = prove(
  ``!x a n heap limit pa x1 h1 a1 n1 heap1 pa1 m m1 xs i1 c1 frame k k1.
      (gc_move_list (x,[],a,n,heap,T,limit) = (x1,h1,a1,n1,heap1,T)) /\
      heap_length heap <= dimword (:'a) DIV 2 ** shift_length conf /\
      (word_gc_move_list conf (k,n2w (LENGTH x),n2w a,pa,curr,m,dm) =
        (k1,i1,pa1,m1,c1)) /\
      (word_heap curr heap conf * word_list pa xs *
       word_list k (MAP (word_addr conf) x) * frame) (fun2set (m,dm)) /\
      LENGTH xs = n /\ LENGTH x < dimword (:'a) ==>
      ?xs1.
        (word_heap curr heap1 conf *
         word_heap (pa:'a word) h1 conf *
         word_list pa1 xs1 *
         word_list k (MAP (word_addr conf) x1) * frame) (fun2set (m1,dm)) /\
        heap_length heap1 = heap_length heap /\
        c1 /\ (i1 = n2w a1) /\ n1 = LENGTH xs1 /\
        k1 = k + n2w (LENGTH x) * bytes_in_word /\
        pa1 = pa + n2w (heap_length h1) * bytes_in_word``,
  Induct THEN1
   (full_simp_tac(srw_ss())[gc_move_list_def,Once word_gc_move_list_def,word_heap_def,SEP_CLAUSES]
    \\ srw_tac[][] \\ qexists_tac `xs` \\ full_simp_tac(srw_ss())[heap_length_def])
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[gc_move_list_def,LET_THM]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ pop_assum mp_tac
  \\ once_rewrite_tac [gc_move_list_ALT]
  \\ full_simp_tac(srw_ss())[LET_THM] \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ qpat_x_assum `word_gc_move_list conf _ = _` mp_tac
  \\ simp [Once word_gc_move_list_def,LET_THM] \\ full_simp_tac(srw_ss())[]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[GSYM word_add_n2w,ADD1]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ `c'` by imp_res_tac gc_move_list_ok \\ full_simp_tac(srw_ss())[] \\ pop_assum kall_tac
  \\ NTAC 2 (pop_assum mp_tac)
  \\ full_simp_tac(srw_ss())[word_list_def] \\ SEP_R_TAC \\ rpt strip_tac
  \\ drule (word_gc_move_thm |> GEN_ALL |> SIMP_RULE std_ss [])
  \\ once_rewrite_tac [CONJ_ASSOC]
  \\ once_rewrite_tac [CONJ_COMM]
  \\ disch_then drule \\ full_simp_tac(srw_ss())[]
  \\ strip_tac \\ SEP_F_TAC \\ full_simp_tac(srw_ss())[]
  \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ first_x_assum drule
  \\ qpat_x_assum `word_gc_move_list conf _ = _` mp_tac
  \\ SEP_W_TAC \\ strip_tac
  \\ once_rewrite_tac [CONJ_ASSOC]
  \\ once_rewrite_tac [CONJ_COMM] \\ full_simp_tac(srw_ss())[]
  \\ disch_then imp_res_tac
  \\ `LENGTH x < dimword (:'a)` by decide_tac \\ full_simp_tac(srw_ss())[]
  \\ pop_assum kall_tac
  \\ SEP_F_TAC \\ full_simp_tac(srw_ss())[]
  \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ rename1 `_ = (xs7,xs8,a7,LENGTH xs9,heap7,T)`
  \\ qexists_tac `xs9` \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[word_heap_APPEND]
  \\ full_simp_tac(srw_ss())[AC STAR_COMM STAR_ASSOC]
  \\ full_simp_tac(srw_ss())[WORD_LEFT_ADD_DISTRIB,heap_length_def,
        SUM_APPEND,GSYM word_add_n2w]);

val word_payload_swap = prove(
  ``word_payload l5 (LENGTH l5) tag r conf = (h,MAP (word_addr conf) l5,T) /\
    LENGTH xs' = LENGTH l5 ==>
    word_payload xs' (LENGTH l5) tag r conf = (h,MAP (word_addr conf) xs',T)``,
  Cases_on `tag` \\ full_simp_tac(srw_ss())[word_payload_def]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[LENGTH_NIL]);

val word_gc_move_loop_thm = prove(
  ``!h1 h2 a n heap c0 limit h11 a1 n1 heap1 i1 pa1 m1 c1 xs frame m k.
      (gc_move_loop (h1,h2,a,n,heap,c0,limit) = (h11,a1,n1,heap1,T)) /\ c0 /\
      heap_length heap <= dimword (:'a) DIV 2 ** shift_length conf /\
      heap_length heap * (dimindex (:'a) DIV 8) < dimword (:'a) /\
      conf.len_size + 2 < dimindex (:'a) /\
      (word_heap curr heap conf *
       word_heap new (h1 ++ h2) conf *
       word_list (new + n2w (heap_length (h1++h2)) * bytes_in_word) xs * frame)
         (fun2set (m,dm)) /\
      limit - heap_length h1 <= k /\
      limit = heap_length heap /\ good_dimindex (:'a) /\
      (word_gc_move_loop k conf (new + n2w (heap_length h1) * bytes_in_word,n2w a,
           new + n2w (heap_length (h1++h2)) * bytes_in_word,curr,m,dm,T) =
         (i1,pa1,m1,c1)) /\ LENGTH xs = n ==>
      ?xs1.
        (word_heap curr heap1 conf *
         word_heap (new:'a word) h11 conf *
         word_list pa1 xs1 * frame) (fun2set (m1,dm)) /\
        heap_length heap1 = heap_length heap /\
        c1 /\ (i1 = n2w a1) /\ n1 = LENGTH xs1 /\
        pa1 = new + bytes_in_word * n2w (heap_length h11)``,
  recInduct gc_move_loop_ind \\ rpt strip_tac
  THEN1
   (full_simp_tac(srw_ss())[gc_move_loop_def] \\ rpt var_eq_tac
    \\ full_simp_tac(srw_ss())[]
    \\ pop_assum mp_tac \\ once_rewrite_tac [word_gc_move_loop_def]
    \\ full_simp_tac(srw_ss())[]
    \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
    \\ qexists_tac `xs` \\ full_simp_tac(srw_ss())[AC STAR_COMM STAR_ASSOC])
  \\ qpat_x_assum `gc_move_loop _ = _` mp_tac
  \\ once_rewrite_tac [gc_move_loop_def]
  \\ IF_CASES_TAC \\ full_simp_tac(srw_ss())[]
  \\ CASE_TAC \\ full_simp_tac(srw_ss())[LET_THM]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ strip_tac \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac gc_move_loop_ok \\ full_simp_tac(srw_ss())[]
  \\ rename1 `HD h5 = DataElement l5 n5 b5`
  \\ Cases_on `h5` \\ full_simp_tac(srw_ss())[]
  \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ qpat_x_assum `word_gc_move_loop _ _ _ = _` mp_tac
  \\ once_rewrite_tac [word_gc_move_loop_def]
  \\ IF_CASES_TAC THEN1
   (`F` by all_tac
    \\ full_simp_tac(srw_ss())[heap_length_def,SUM_APPEND,el_length_def,
           WORD_LEFT_ADD_DISTRIB,GSYM word_add_n2w]
    \\ pop_assum mp_tac
    \\ Q.PAT_ABBREV_TAC `x = bytes_in_word * n2w (SUM (MAP el_length h1))`
    \\ full_simp_tac(srw_ss())[]
    \\ full_simp_tac std_ss [GSYM WORD_ADD_ASSOC,addressTheory.WORD_EQ_ADD_CANCEL]
    \\ full_simp_tac(srw_ss())[bytes_in_word_def,word_add_n2w,word_mul_n2w]
    \\ full_simp_tac(srw_ss())[NOT_LESS]
    \\ full_simp_tac(srw_ss())[GSYM heap_length_def]
    \\ qpat_x_assum `_ <= heap_length heap` mp_tac
    \\ qpat_x_assum `heap_length heap * _ < _ ` mp_tac
    \\ qpat_x_assum `good_dimindex (:'a)` mp_tac
    \\ rpt (pop_assum kall_tac) \\ srw_tac[][]
    \\ `dimindex (:α) DIV 8 + dimindex (:α) DIV 8 * n5 +
        dimindex (:α) DIV 8 * heap_length h2 < dimword (:α)` by all_tac
    \\ full_simp_tac(srw_ss())[]
    \\ rev_full_simp_tac(srw_ss())[good_dimindex_def,dimword_def]
    \\ rev_full_simp_tac(srw_ss())[good_dimindex_def,dimword_def] \\ decide_tac)
  \\ Cases_on `b5`
  \\ full_simp_tac(srw_ss())[word_heap_APPEND,word_heap_def,
       SEP_CLAUSES,STAR_ASSOC,word_el_def]
  \\ qpat_x_assum `_ (fun2set (m,dm))` assume_tac
  \\ full_simp_tac(srw_ss())[LET_THM]
  \\ pop_assum mp_tac
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ strip_tac
  \\ full_simp_tac (std_ss++sep_cond_ss) [cond_STAR] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac std_ss [word_list_def] \\ SEP_R_TAC
  \\ full_simp_tac(srw_ss())[isWord_def,theWord_def]
  \\ rev_full_simp_tac(srw_ss())[]
  \\ rename1 `word_payload _ _ tag _ conf = _`
  \\ drule word_payload_T_IMP
  \\ impl_tac THEN1 (fs []) \\ strip_tac
  \\ `k <> 0` by
   (fs [heap_length_APPEND,el_length_def,heap_length_def] \\ decide_tac)
  \\ full_simp_tac std_ss []
  \\ Cases_on `word_bit 2 h` \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[]
  THEN1
   (full_simp_tac(srw_ss())[gc_move_list_def] \\ rpt var_eq_tac
    \\ full_simp_tac(srw_ss())[]
    \\ full_simp_tac(srw_ss())[heap_length_def,el_length_def,SUM_APPEND]
    \\ qpat_x_assum `!xx. nn` mp_tac
    \\ full_simp_tac(srw_ss())[GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
    \\ ntac 2 strip_tac \\ full_simp_tac(srw_ss())[SEP_CLAUSES]
    \\ first_x_assum match_mp_tac
    \\ qexists_tac `xs` \\ qexists_tac `m` \\ full_simp_tac(srw_ss())[]
    \\ qexists_tac `k - 1` \\ fs [])
  \\ qpat_x_assum `gc_move_list _ = _` mp_tac
  \\ once_rewrite_tac [gc_move_list_ALT] \\ strip_tac
  \\ full_simp_tac(srw_ss())[LET_THM]
  \\ pop_assum mp_tac
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ strip_tac
  \\ ntac 5 var_eq_tac
  \\ drule word_gc_move_list_thm \\ full_simp_tac(srw_ss())[]
  \\ ntac 2 strip_tac \\ full_simp_tac(srw_ss())[]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ first_x_assum drule
  \\ disch_then (qspec_then `xs` mp_tac)
  \\ fs [] \\ strip_tac \\ SEP_F_TAC
  \\ impl_tac THEN1
   (full_simp_tac(srw_ss())[NOT_LESS] \\ qpat_x_assum `_ <= heap_length heap` mp_tac
    \\ qpat_x_assum `heap_length heap <= _ ` mp_tac
    \\ qpat_x_assum `heap_length heap <= _ ` mp_tac
    \\ rpt (pop_assum kall_tac) \\ full_simp_tac(srw_ss())[X_LE_DIV]
    \\ full_simp_tac(srw_ss())[heap_length_APPEND,heap_length_def,el_length_def]
    \\ Cases_on `2 ** shift_length conf` \\ full_simp_tac(srw_ss())[]
    \\ Cases_on `n` \\ full_simp_tac(srw_ss())[MULT_CLAUSES] \\ decide_tac)
  \\ strip_tac \\ fs []
  \\ ntac 5 var_eq_tac
  \\ `LENGTH xs' = LENGTH l5` by imp_res_tac gc_move_list_IMP_LENGTH
  \\ `word_payload xs' (LENGTH l5) tag r conf =
       (h,MAP (word_addr conf) xs',T)` by
         (match_mp_tac word_payload_swap \\ full_simp_tac(srw_ss())[])
  \\ full_simp_tac(srw_ss())[] \\ rev_full_simp_tac(srw_ss())[]
  \\ first_x_assum match_mp_tac \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[heap_length_def,el_length_def,SUM_APPEND]
  \\ full_simp_tac(srw_ss())[GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB,SEP_CLAUSES]
  \\ qpat_x_assum `_ = (i1,pa1,m1,c1)` (fn th => full_simp_tac(srw_ss())[GSYM th])
  \\ qexists_tac `xs1'` \\ full_simp_tac(srw_ss())[]
  \\ qexists_tac `m1'` \\ full_simp_tac(srw_ss())[]
  \\ qexists_tac `k-1` \\ fs []
  \\ qpat_x_assum `_ (fun2set (m1',dm))` mp_tac
  \\ full_simp_tac(srw_ss())[word_heap_APPEND,heap_length_def,el_length_def,SUM_APPEND]
  \\ full_simp_tac(srw_ss())[GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB,SEP_CLAUSES]
  \\ full_simp_tac(srw_ss())[AC STAR_ASSOC STAR_COMM,word_heap_APPEND]);

val word_full_gc_thm = prove(
  ``(full_gc (roots,heap,limit) = (roots1,heap1,a1,T)) /\
    heap_length heap <= dimword (:'a) DIV 2 ** shift_length conf /\
    heap_length heap * (dimindex (:'a) DIV 8) < dimword (:'a) /\
    conf.len_size + 2 < dimindex (:'a) /\
    (word_heap (curr:'a word) heap conf *
     word_heap new (heap_expand limit) conf * frame) (fun2set (m,dm)) /\
    limit = heap_length heap /\ good_dimindex (:'a) /\
    (word_full_gc conf (MAP (word_addr conf) roots,new,curr,m,dm) =
       (rs1,i1,pa1,m1,c1)) ==>
    (word_heap new (heap1 ++ heap_expand (limit - a1)) conf *
     word_heap curr (heap_expand limit) conf * frame) (fun2set (m1,dm)) /\
    c1 /\ i1 = n2w a1 /\
    rs1 = MAP (word_addr conf) roots1 /\
    pa1 = new + bytes_in_word * n2w a1``,
  strip_tac \\ full_simp_tac(srw_ss())[full_gc_def,LET_THM]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[word_heap_def,word_el_def]
  \\ full_simp_tac(srw_ss())[SEP_CLAUSES]
  \\ imp_res_tac gc_move_loop_ok \\ full_simp_tac(srw_ss())[]
  \\ drule word_gc_move_roots_thm
  \\ full_simp_tac(srw_ss())[word_list_exists_def,SEP_CLAUSES,
       SEP_EXISTS_THM,word_heap_heap_expand]
  \\ full_simp_tac (std_ss++sep_cond_ss) [cond_STAR]
  \\ full_simp_tac(srw_ss())[word_full_gc_def,LET_THM]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ disch_then drule \\ full_simp_tac(srw_ss())[] \\ strip_tac
  \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ drule word_gc_move_loop_thm
  \\ full_simp_tac(srw_ss())[heap_length_def]
  \\ once_rewrite_tac [CONJ_COMM] \\ full_simp_tac(srw_ss())[GSYM CONJ_ASSOC]
  \\ `SUM (MAP el_length heap) <= dimword (:'a)` by
   (fs [X_LE_DIV] \\ Cases_on `2n ** shift_length conf` \\ fs [MULT_CLAUSES])
  \\ disch_then drule
  \\ disch_then drule
  \\ strip_tac \\ SEP_F_TAC
  \\ full_simp_tac(srw_ss())[AC STAR_ASSOC STAR_COMM]
  \\ strip_tac \\ rpt var_eq_tac
  \\ full_simp_tac(srw_ss())[word_heap_APPEND,word_heap_heap_expand]
  \\ pop_assum mp_tac
  \\ full_simp_tac(srw_ss())[STAR_ASSOC]
  \\ CONV_TAC ((RATOR_CONV o RAND_CONV) (RATOR_CONV
       (MOVE_OUT_CONV ``word_heap (curr:'a word) (temp:'a ml_heap)``)))
  \\ strip_tac \\ drule word_heap_IMP_word_list_exists
  \\ full_simp_tac(srw_ss())[word_heap_heap_expand]
  \\ full_simp_tac(srw_ss())[word_list_exists_def,SEP_CLAUSES,SEP_EXISTS_THM]
  \\ full_simp_tac (std_ss++sep_cond_ss) [cond_STAR] \\ strip_tac
  \\ rename1 `LENGTH ys = heap_length temp`
  \\ qexists_tac `ys` \\ full_simp_tac(srw_ss())[heap_length_def]
  \\ qexists_tac `xs1'` \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[AC STAR_ASSOC STAR_COMM]);

val LIST_REL_EQ_MAP = store_thm("LIST_REL_EQ_MAP",
  ``!vs ws f. LIST_REL (λv w. f v = w) vs ws <=> ws = MAP f vs``,
  Induct \\ full_simp_tac(srw_ss())[]);

val full_gc_IMP = prove(
  ``full_gc (xs,heap,limit) = (t,heap2,n,T) ==>
    n <= limit /\ limit = heap_length heap``,
  full_simp_tac(srw_ss())[full_gc_def,LET_THM]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]);

val word_gc_fun_lemma = prove(
  ``good_dimindex (:'a) /\
    heap_in_memory_store heap a sp c s m dm limit /\
    abs_ml_inv c (v::MAP FST stack) refs (hs,heap,be,a,sp) limit /\
    LIST_REL (\v w. word_addr c v = w) hs (s ' Globals::MAP SND stack) /\
    full_gc (hs,heap,limit) = (roots2,heap2,heap_length heap2,T) ==>
    let heap1 = heap2 ++ heap_expand (limit - heap_length heap2) in
      ?stack1 m1 s1 a1 sp1.
        word_gc_fun c (MAP SND stack,m,dm,s) = SOME (stack1,m1,s1) /\
        heap_in_memory_store heap1 (heap_length heap2)
          (limit - heap_length heap2) c s1 m1 dm limit /\
        LIST_REL (λv w. word_addr c v = (w:'a word_loc)) roots2
          (s1 ' Globals::MAP SND (ZIP (MAP FST stack,stack1))) /\
        LENGTH stack1 = LENGTH stack``,
  strip_tac
  \\ rewrite_tac [word_gc_fun_def] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[heap_in_memory_store_def,FLOOKUP_DEF,theWord_def,LET_THM]
  \\ pairarg_tac
  \\ full_simp_tac(srw_ss())[finite_mapTheory.FDOM_FUPDATE_LIST,FUPDATE_LIST,FAPPLY_FUPDATE_THM]
  \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ `s ' Globals::MAP SND stack = MAP (word_addr c) (v'::xs)` by
    (full_simp_tac(srw_ss())[LIST_REL_EQ_MAP] \\ CONV_TAC (DEPTH_CONV ETA_CONV) \\ full_simp_tac(srw_ss())[])
  \\ full_simp_tac std_ss [] \\ drule (GEN_ALL word_full_gc_thm)
  \\ rewrite_tac [CONJ_ASSOC]
  \\ once_rewrite_tac [CONJ_COMM]
  \\ disch_then drule
  \\ disch_then (qspec_then `emp` mp_tac)
  \\ full_simp_tac(srw_ss())[SEP_CLAUSES]
  \\ impl_tac
  THEN1 (imp_res_tac full_gc_IMP \\ fs [])
  \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac full_gc_IMP_LENGTH
  \\ Cases_on `roots2` \\ full_simp_tac(srw_ss())[]
  \\ `LENGTH xs = LENGTH stack` by metis_tac [LENGTH_MAP]
  \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[listTheory.MAP_ZIP]
  \\ full_simp_tac(srw_ss())[LIST_REL_EQ_MAP]
  \\ CONV_TAC (DEPTH_CONV ETA_CONV) \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac full_gc_IMP \\ full_simp_tac(srw_ss())[]
  \\ rev_full_simp_tac(srw_ss())[heap_length_APPEND,heap_length_heap_expand]
  \\ `heap_length heap2 + (heap_length heap - heap_length heap2) =
      heap_length heap` by decide_tac \\ full_simp_tac(srw_ss())[]
  \\ fs [word_gc_fun_assum_def,isWord_def]) |> GEN_ALL
  |> SIMP_RULE (srw_ss()) [LET_DEF,PULL_EXISTS,GSYM CONJ_ASSOC] |> SPEC_ALL;

val word_gc_fun_correct = prove(
  ``good_dimindex (:'a) /\
    heap_in_memory_store heap a sp c s m dm limit /\
    word_ml_inv (heap:'a ml_heap,be,a,sp) limit c refs ((v,s ' Globals)::stack) ==>
    ?stack1 m1 s1 heap1 a1 sp1.
      word_gc_fun c (MAP SND stack,m,dm,s) = SOME (stack1,m1,s1) /\
      heap_in_memory_store heap1 a1 sp1 c s1 m1 dm limit /\
      word_ml_inv (heap1,be,a1,sp1) limit c refs
        ((v,s1 ' Globals)::ZIP (MAP FST stack,stack1))``,
  full_simp_tac(srw_ss())[word_ml_inv_def] \\ srw_tac[][] \\ imp_res_tac full_gc_thm
  \\ full_simp_tac(srw_ss())[PULL_EXISTS] \\ srw_tac[][]
  \\ mp_tac word_gc_fun_lemma \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ Q.LIST_EXISTS_TAC [`heap2 ++ heap_expand (limit - heap_length heap2)`,
       `heap_length heap2`,`limit - heap_length heap2`,`v''`,`xs'`]
  \\ full_simp_tac(srw_ss())[MAP_ZIP]);


(* -------------------------------------------------------
    definition of state relation
   ------------------------------------------------------- *)

val code_rel_def = Define `
  code_rel c s_code (t_code: (num # 'a wordLang$prog) num_map) <=>
    EVERY (\(n,x). lookup n t_code = SOME x) (stubs (:'a) c) /\
    !n arg_count prog.
      (lookup n s_code = SOME (arg_count:num,prog)) ==>
      (lookup n t_code = SOME (arg_count+1,FST (comp c n 1 prog)))`

val stack_rel_def = Define `
  (stack_rel (Env env) (StackFrame vs NONE) <=>
     EVERY (\(x1,x2). isWord x2 ==> x1 <> 0 /\ EVEN x1) vs /\
     !n. IS_SOME (lookup n env) <=>
         IS_SOME (lookup (adjust_var n) (fromAList vs))) /\
  (stack_rel (Exc env n) (StackFrame vs (SOME (x1,x2,x3))) <=>
     stack_rel (Env env) (StackFrame vs NONE) /\ (x1 = n)) /\
  (stack_rel _ _ <=> F)`

val the_global_def = Define `
  the_global g = the (Number 0) (OPTION_MAP RefPtr g)`;

val contains_loc_def = Define `
  contains_loc (StackFrame vs _) (l1,l2) = (ALOOKUP vs 0 = SOME (Loc l1 l2))`

val state_rel_thm = Define `
  state_rel c l1 l2 (s:'ffi dataSem$state) (t:('a,'ffi) wordSem$state) v1 locs <=>
    (* I/O, clock and handler are the same, GC is fixed, code is compiled *)
    (t.ffi = s.ffi) /\
    (t.clock = s.clock) /\
    (t.handler = s.handler) /\
    (t.gc_fun = word_gc_fun c) /\
    code_rel c s.code t.code /\
    good_dimindex (:'a) /\
    shift_length c < dimindex (:'a) /\
    (* the store *)
    EVERY (\n. n IN FDOM t.store) [Globals] /\
    (* every local is represented in word lang *)
    (v1 = [] ==> lookup 0 t.locals = SOME (Loc l1 l2)) /\
    (!n. IS_SOME (lookup n s.locals) ==>
         IS_SOME (lookup (adjust_var n) t.locals)) /\
    (* the stacks contain the same names, have same shape *)
    EVERY2 stack_rel s.stack t.stack /\
    EVERY2 contains_loc t.stack locs /\
    (* there exists some GC-compatible abstraction *)
    memory_rel c t.be s.refs s.space t.store t.memory t.mdomain
      (v1 ++
       join_env s.locals (toAList (inter t.locals (adjust_set s.locals))) ++
       [(the_global s.global,t.store ' Globals)] ++
       flat s.stack t.stack)`

val state_rel_def = state_rel_thm |> REWRITE_RULE [memory_rel_def]

val state_rel_with_clock = Q.store_thm("state_rel_with_clock",
  `state_rel a b c s1 s2 d e ⇒
   state_rel a b c (s1 with clock := k) (s2 with clock := k) d e`,
  srw_tac[][state_rel_def]);

(* -------------------------------------------------------
    init
   ------------------------------------------------------- *)

val flat_NIL = prove(
  ``flat [] xs = []``,
  Cases_on `xs` \\ fs [flat_def]);

val conf_ok_def = Define `
  conf_ok (:'a) c <=>
    shift_length c < dimindex (:α) ∧
    shift (:α) ≤ shift_length c ∧ c.len_size ≠ 0 ∧
    c.len_size + 7 < dimindex (:α)`

val init_store_ok_def = Define `
  init_store_ok c store m (dm:'a word set) <=>
    ?limit curr.
      limit <= max_heap_limit (:'a) c /\
      FLOOKUP store Globals = SOME (Word 0w) /\
      FLOOKUP store CurrHeap = SOME (Word curr) ∧
      FLOOKUP store OtherHeap = FLOOKUP store EndOfHeap ∧
      FLOOKUP store NextFree = SOME (Word curr) ∧
      FLOOKUP store EndOfHeap =
        SOME (Word (curr + bytes_in_word * n2w limit)) ∧
      FLOOKUP store HeapLength =
        SOME (Word (bytes_in_word * n2w limit)) ∧
      (word_list_exists curr (limit + limit)) (fun2set (m,dm)) ∧
      byte_aligned curr`

val state_rel_init = store_thm("state_rel_init",
  ``t.ffi = ffi ∧ t.handler = 0 ∧ t.gc_fun = word_gc_fun c ∧
    code_rel c code t.code ∧
    good_dimindex (:α) ∧
    lookup 0 t.locals = SOME (Loc l1 l2) ∧
    t.stack = [] /\
    conf_ok (:'a) c /\
    init_store_ok c t.store t.memory t.mdomain ==>
    state_rel c l1 l2 (initial_state ffi code t.clock) (t:('a,'ffi) state) [] []``,
  simp_tac std_ss [word_list_exists_ADD,conf_ok_def,init_store_ok_def]
  \\ fs [state_rel_thm,dataSemTheory.initial_state_def,
    join_env_def,lookup_def,the_global_def,
    libTheory.the_def,flat_NIL,FLOOKUP_DEF] \\ strip_tac \\ fs []
  \\ `FILTER (λ(n,v). n ≠ 0 ∧ EVEN n)
        (toAList (inter t.locals (insert 0 () LN))) = []` by
   (fs [FILTER_EQ_NIL] \\ fs [EVERY_MEM,MEM_toAList,FORALL_PROD]
    \\ fs [lookup_inter_alt]) \\ fs [max_heap_limit_def]
  \\ fs [GSYM (EVAL ``(Smallnum 0)``)]
  \\ match_mp_tac IMP_memory_rel_Number
  \\ fs [] \\ conj_tac
  THEN1 (EVAL_TAC \\ fs [labPropsTheory.good_dimindex_def,dimword_def])
  \\ fs [memory_rel_def]
  \\ rewrite_tac [CONJ_ASSOC]
  \\ once_rewrite_tac [CONJ_COMM]
  \\ `limit * (dimindex (:α) DIV 8) + 1 < dimword (:α)` by
   (fs [labPropsTheory.good_dimindex_def,dimword_def]
    \\ rfs [shift_def] \\ decide_tac)
  \\ asm_exists_tac \\ fs []
  \\ fs [word_ml_inv_def]
  \\ qexists_tac `heap_expand limit`
  \\ qexists_tac `0`
  \\ qexists_tac `limit`
  \\ reverse conj_tac THEN1
   (fs[abs_ml_inv_def,roots_ok_def,heap_ok_def,heap_length_heap_expand,
       unused_space_inv_def,bc_stack_ref_inv_def,FDOM_EQ_EMPTY]
    \\ fs [heap_expand_def,heap_lookup_def]
    \\ rw [] \\ fs [isForwardPointer_def,bc_ref_inv_def,reachable_refs_def])
  \\ fs [heap_in_memory_store_def,heap_length_heap_expand,word_heap_heap_expand]
  \\ fs [FLOOKUP_DEF]
  \\ fs [byte_aligned_def,bytes_in_word_def,labPropsTheory.good_dimindex_def,
         word_mul_n2w]
  \\ simp_tac bool_ss [GSYM (EVAL ``2n**2``),GSYM (EVAL ``2n**3``)]
  \\ once_rewrite_tac [MULT_COMM]
  \\ simp_tac bool_ss [aligned_add_pow] \\ rfs []);

(* -------------------------------------------------------
    compiler proof
   ------------------------------------------------------- *)

val adjust_var_NOT_0 = store_thm("adjust_var_NOT_0[simp]",
  ``adjust_var n <> 0``,
  full_simp_tac(srw_ss())[adjust_var_def]);

val state_rel_get_var_IMP = prove(
  ``state_rel c l1 l2 s t v1 locs ==>
    (get_var n s.locals = SOME x) ==>
    ?w. get_var (adjust_var n) t = SOME w``,
  full_simp_tac(srw_ss())[dataSemTheory.get_var_def,wordSemTheory.get_var_def]
  \\ full_simp_tac(srw_ss())[state_rel_def] \\ rpt strip_tac
  \\ `IS_SOME (lookup n s.locals)` by full_simp_tac(srw_ss())[] \\ res_tac
  \\ Cases_on `lookup (adjust_var n) t.locals` \\ full_simp_tac(srw_ss())[]);

val state_rel_get_vars_IMP = prove(
  ``!n xs.
      state_rel c l1 l2 s t [] locs ==>
      (get_vars n s.locals = SOME xs) ==>
      ?ws. get_vars (MAP adjust_var n) t = SOME ws /\ (LENGTH xs = LENGTH ws)``,
  Induct \\ full_simp_tac(srw_ss())[dataSemTheory.get_vars_def,wordSemTheory.get_vars_def]
  \\ rpt strip_tac
  \\ Cases_on `get_var h s.locals` \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `get_vars n s.locals` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ imp_res_tac state_rel_get_var_IMP \\ full_simp_tac(srw_ss())[]);

val state_rel_0_get_vars_IMP = prove(
  ``state_rel c l1 l2 s t [] locs ==>
    (get_vars n s.locals = SOME xs) ==>
    ?ws. get_vars (0::MAP adjust_var n) t = SOME ((Loc l1 l2)::ws) /\
         (LENGTH xs = LENGTH ws)``,
  rpt strip_tac
  \\ imp_res_tac state_rel_get_vars_IMP
  \\ full_simp_tac(srw_ss())[wordSemTheory.get_vars_def]
  \\ full_simp_tac(srw_ss())[state_rel_def,wordSemTheory.get_var_def]);

val get_var_T_OR_F = prove(
  ``state_rel c l1 l2 s (t:('a,'ffi) state) [] locs /\
    get_var n s.locals = SOME x /\
    get_var (adjust_var n) t = SOME w ==>
    18 MOD dimword (:'a) <> 2 MOD dimword (:'a) /\
    ((x = Boolv T) ==> (w = Word 2w)) /\
    ((x = Boolv F) ==> (w = Word 18w))``,
  full_simp_tac(srw_ss())[state_rel_def,get_var_def,wordSemTheory.get_var_def]
  \\ strip_tac \\ strip_tac THEN1 (full_simp_tac(srw_ss())[good_dimindex_def] \\ full_simp_tac(srw_ss())[dimword_def])
  \\ full_simp_tac bool_ss [GSYM APPEND_ASSOC]
  \\ imp_res_tac (word_ml_inv_lookup |> Q.INST [`ys`|->`[]`]
                    |> SIMP_RULE std_ss [APPEND])
  \\ pop_assum mp_tac
  \\ simp [word_ml_inv_def,toAList_def,foldi_def,word_ml_inv_def,PULL_EXISTS]
  \\ strip_tac \\ strip_tac
  \\ full_simp_tac(srw_ss())[abs_ml_inv_def,bc_stack_ref_inv_def]
  \\ pop_assum (fn th => full_simp_tac(srw_ss())[GSYM th])
  \\ full_simp_tac(srw_ss())[Boolv_def] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[v_inv_def] \\ full_simp_tac(srw_ss())[word_addr_def]
  \\ EVAL_TAC \\ full_simp_tac(srw_ss())[good_dimindex_def,dimword_def]);

val mk_loc_def = Define `
  mk_loc (SOME (t1,d1,d2)) = Loc d1 d2`;

val cut_env_IMP_cut_env = prove(
  ``state_rel c l1 l2 s t [] locs /\
    dataSem$cut_env r s.locals = SOME x ==>
    ?y. wordSem$cut_env (adjust_set r) t.locals = SOME y``,
  full_simp_tac(srw_ss())[dataSemTheory.cut_env_def,wordSemTheory.cut_env_def]
  \\ full_simp_tac(srw_ss())[adjust_set_def,domain_fromAList,SUBSET_DEF,MEM_MAP,
         PULL_EXISTS,sptreeTheory.domain_lookup,lookup_fromAList] \\ srw_tac[][]
  \\ Cases_on `x' = 0` \\ full_simp_tac(srw_ss())[] THEN1 full_simp_tac(srw_ss())[state_rel_def]
  \\ imp_res_tac alistTheory.ALOOKUP_MEM
  \\ full_simp_tac(srw_ss())[unit_some_eq_IS_SOME,IS_SOME_ALOOKUP_EQ,MEM_MAP]
  \\ Cases_on `y'` \\ Cases_on `y''`
  \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[adjust_var_11] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[state_rel_def] \\ res_tac
  \\ `IS_SOME (lookup q s.locals)` by full_simp_tac(srw_ss())[] \\ res_tac
  \\ Cases_on `lookup (adjust_var q) t.locals` \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[MEM_toAList,unit_some_eq_IS_SOME] \\ res_tac \\ full_simp_tac(srw_ss())[]);

val jump_exc_call_env = prove(
  ``wordSem$jump_exc (call_env x s) = jump_exc s``,
  full_simp_tac(srw_ss())[wordSemTheory.jump_exc_def,wordSemTheory.call_env_def]);

val jump_exc_dec_clock = prove(
  ``mk_loc (wordSem$jump_exc (dec_clock s)) = mk_loc (jump_exc s)``,
  full_simp_tac(srw_ss())[wordSemTheory.jump_exc_def,wordSemTheory.dec_clock_def]
  \\ srw_tac[][] \\ BasicProvers.EVERY_CASE_TAC \\ full_simp_tac(srw_ss())[mk_loc_def]);

val LASTN_ADD1 = LASTN_LENGTH_ID
  |> Q.SPEC `x::xs` |> SIMP_RULE (srw_ss()) [ADD1]

val jump_exc_push_env_NONE = prove(
  ``mk_loc (jump_exc (push_env y NONE s)) =
    mk_loc (jump_exc (s:('a,'b) wordSem$state))``,
  full_simp_tac(srw_ss())[wordSemTheory.push_env_def,wordSemTheory.jump_exc_def]
  \\ Cases_on `env_to_list y s.permute` \\ full_simp_tac(srw_ss())[LET_DEF]
  \\ Cases_on `s.handler = LENGTH s.stack` \\ full_simp_tac(srw_ss())[LASTN_ADD1]
  \\ Cases_on `~(s.handler < LENGTH s.stack)` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  THEN1 (`F` by DECIDE_TAC)
  \\ `LASTN (s.handler + 1) (StackFrame q NONE::s.stack) =
      LASTN (s.handler + 1) s.stack` by
    (match_mp_tac LASTN_TL \\ decide_tac)
  \\ every_case_tac \\ srw_tac[][mk_loc_def]
  \\ `F` by decide_tac);

val state_rel_pop_env_IMP = prove(
  ``state_rel c q l s1 t1 xs locs /\
    pop_env s1 = SOME s2 ==>
    ?t2 l8 l9 ll.
      pop_env t1 = SOME t2 /\ locs = (l8,l9)::ll /\
      state_rel c l8 l9 s2 t2 xs ll``,
  full_simp_tac(srw_ss())[pop_env_def]
  \\ Cases_on `s1.stack` \\ full_simp_tac(srw_ss())[] \\ Cases_on `h` \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ full_simp_tac(srw_ss())[state_rel_def]
  \\ TRY (Cases_on `y`) \\ full_simp_tac(srw_ss())[stack_rel_def]
  \\ full_simp_tac(srw_ss())[stack_rel_def,wordSemTheory.pop_env_def]
  \\ rev_full_simp_tac(srw_ss())[] \\ Cases_on `y` \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `o'` \\ full_simp_tac(srw_ss())[stack_rel_def,wordSemTheory.pop_env_def]
  \\ rev_full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ Cases_on `y` \\ full_simp_tac(srw_ss())[]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[]
  \\ TRY (Cases_on `r'`) \\ full_simp_tac(srw_ss())[stack_rel_def]
  \\ full_simp_tac(srw_ss())[lookup_fromAList,contains_loc_def]
  \\ asm_exists_tac \\ full_simp_tac(srw_ss())[]
  \\ first_x_assum (fn th => mp_tac th THEN match_mp_tac word_ml_inv_rearrange)
  \\ full_simp_tac(srw_ss())[flat_def] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `x` \\ full_simp_tac(srw_ss())[join_env_def,MEM_MAP,MEM_FILTER,EXISTS_PROD]
  \\ full_simp_tac(srw_ss())[MEM_toAList,lookup_fromAList,lookup_inter_alt]
  \\ imp_res_tac alistTheory.ALOOKUP_MEM \\ metis_tac []);

val state_rel_pop_env_set_var_IMP = prove(
  ``state_rel c q l s1 t1 [(a,w)] locs /\
    pop_env s1 = SOME s2 ==>
    ?t2 l8 l9 ll.
      pop_env t1 = SOME t2 /\ locs = (l8,l9)::ll /\
      state_rel c l8 l9 (set_var q1 a s2) (set_var (adjust_var q1) w t2) [] ll``,
  full_simp_tac(srw_ss())[pop_env_def]
  \\ Cases_on `s1.stack` \\ full_simp_tac(srw_ss())[] \\ Cases_on `h` \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[state_rel_def,set_var_def,wordSemTheory.set_var_def]
  \\ rev_full_simp_tac(srw_ss())[] \\ Cases_on `y` \\ full_simp_tac(srw_ss())[stack_rel_def]
  \\ Cases_on `o'` \\ full_simp_tac(srw_ss())[stack_rel_def,wordSemTheory.pop_env_def]
  \\ full_simp_tac(srw_ss())[stack_rel_def,wordSemTheory.pop_env_def]
  \\ TRY (Cases_on `x` \\ full_simp_tac(srw_ss())[])
  \\ full_simp_tac(srw_ss())[lookup_insert,adjust_var_11]
  \\ rev_full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ Cases_on `y`
  \\ full_simp_tac(srw_ss())[contains_loc_def,lookup_fromAList] \\ srw_tac[][]
  \\ TRY (Cases_on `r` \\ full_simp_tac(srw_ss())[])
  \\ full_simp_tac(srw_ss())[stack_rel_def,wordSemTheory.pop_env_def] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[lookup_fromAList] \\ rev_full_simp_tac(srw_ss())[]
  \\ first_assum (match_exists_tac o concl) \\ full_simp_tac(srw_ss())[] (* asm_exists_tac *)
  \\ full_simp_tac(srw_ss())[flat_def]
  \\ `word_ml_inv (heap,t1.be,a',sp) limit c s1.refs
       ((a,w)::(join_env s l ++
         [(the_global s1.global,t1.store ' Globals)] ++ flat t ys))` by
   (first_x_assum (fn th => mp_tac th THEN match_mp_tac word_ml_inv_rearrange)
    \\ full_simp_tac(srw_ss())[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[])
  \\ full_simp_tac bool_ss [GSYM APPEND_ASSOC,APPEND]
  \\ match_mp_tac (word_ml_inv_insert
       |> SIMP_RULE std_ss [APPEND,GSYM APPEND_ASSOC])
  \\ first_x_assum (fn th => mp_tac th THEN match_mp_tac word_ml_inv_rearrange)
  \\ full_simp_tac(srw_ss())[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `x` \\ full_simp_tac(srw_ss())[join_env_def,MEM_MAP,MEM_FILTER,EXISTS_PROD]
  \\ full_simp_tac(srw_ss())[MEM_toAList,lookup_fromAList,lookup_inter_alt]
  \\ imp_res_tac alistTheory.ALOOKUP_MEM \\ metis_tac []);

val state_rel_jump_exc = prove(
  ``state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs /\
    get_var n s.locals = SOME x /\
    get_var (adjust_var n) t = SOME w /\
    jump_exc s = SOME s1 ==>
    ?t1 d1 d2 l5 l6 ll.
      jump_exc t = SOME (t1,d1,d2) /\
      LASTN (LENGTH s1.stack + 1) locs = (l5,l6)::ll /\
      !i. state_rel c l5 l6 (set_var i x s1) (set_var (adjust_var i) w t1) [] ll``,
  full_simp_tac(srw_ss())[jump_exc_def] \\ rpt CASE_TAC \\ srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ full_simp_tac(srw_ss())[state_rel_def]
  \\ full_simp_tac(srw_ss())[wordSemTheory.set_var_def,set_var_def]
  \\ full_simp_tac bool_ss [GSYM APPEND_ASSOC]
  \\ imp_res_tac word_ml_inv_get_var_IMP
  \\ imp_res_tac LASTN_LIST_REL_LEMMA
  \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[wordSemTheory.jump_exc_def]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[stack_rel_def]
  \\ Cases_on `y'` \\ full_simp_tac(srw_ss())[contains_loc_def]
  \\ `s.handler + 1 <= LENGTH s.stack` by decide_tac
  \\ imp_res_tac LASTN_CONS_IMP_LENGTH \\ full_simp_tac(srw_ss())[ADD1]
  \\ imp_res_tac EVERY2_LENGTH \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[lookup_insert,adjust_var_11]
  \\ full_simp_tac(srw_ss())[contains_loc_def,lookup_fromAList] \\ srw_tac[][]
  \\ first_assum (match_exists_tac o concl) \\ full_simp_tac(srw_ss())[] (* asm_exists_tac *)
  \\ `s.handler + 1 <= LENGTH s.stack /\
      s.handler + 1 <= LENGTH t.stack` by decide_tac
  \\ imp_res_tac LASTN_IMP_APPEND \\ full_simp_tac(srw_ss())[ADD1]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[flat_APPEND,flat_def]
  \\ `word_ml_inv (heap,t.be,a,sp) limit c s.refs
       ((x,w)::(join_env s' l ++
         [(the_global s.global,t.store ' Globals)] ++ flat t' ys))` by
   (first_x_assum (fn th => mp_tac th THEN match_mp_tac word_ml_inv_rearrange)
    \\ full_simp_tac(srw_ss())[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[])
  \\ full_simp_tac bool_ss [GSYM APPEND_ASSOC,APPEND]
  \\ match_mp_tac (word_ml_inv_insert
       |> SIMP_RULE std_ss [APPEND,GSYM APPEND_ASSOC])
  \\ first_x_assum (fn th => mp_tac th THEN match_mp_tac word_ml_inv_rearrange)
  \\ full_simp_tac(srw_ss())[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `x'` \\ full_simp_tac(srw_ss())[join_env_def,MEM_MAP,MEM_FILTER,EXISTS_PROD]
  \\ full_simp_tac(srw_ss())[MEM_toAList,lookup_fromAList,lookup_inter_alt]
  \\ imp_res_tac alistTheory.ALOOKUP_MEM \\ metis_tac []);

val get_vars_IMP_LENGTH = prove(
  ``!x t s. dataSem$get_vars x s = SOME t ==> LENGTH x = LENGTH t``,
  Induct \\ full_simp_tac(srw_ss())[dataSemTheory.get_vars_def] \\ srw_tac[][]
  \\ every_case_tac \\ res_tac \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]);

val lookup_adjust_var_fromList2 = prove(
  ``lookup (adjust_var n) (fromList2 (w::ws)) = lookup n (fromList ws)``,
  full_simp_tac(srw_ss())[lookup_fromList2,EVEN_adjust_var,lookup_fromList]
  \\ full_simp_tac(srw_ss())[adjust_var_def]
  \\ once_rewrite_tac [MULT_COMM]
  \\ full_simp_tac(srw_ss())[GSYM MULT_CLAUSES,MULT_DIV]);

val state_rel_call_env = prove(
  ``get_vars args s.locals = SOME q /\
    get_vars (MAP adjust_var args) (t:('a,'ffi) wordSem$state) = SOME ws /\
    state_rel c l5 l6 s t [] locs ==>
    state_rel c l1 l2 (call_env q (dec_clock s))
      (call_env (Loc l1 l2::ws) (dec_clock t)) [] locs``,
  full_simp_tac(srw_ss())[state_rel_def,call_env_def,wordSemTheory.call_env_def,
      dec_clock_def,wordSemTheory.dec_clock_def,lookup_adjust_var_fromList2]
  \\ srw_tac[][lookup_fromList2,lookup_fromList] \\ srw_tac[][]
  \\ imp_res_tac get_vars_IMP_LENGTH
  \\ imp_res_tac wordPropsTheory.get_vars_length_lemma \\ full_simp_tac(srw_ss())[]
  \\ first_assum (match_exists_tac o concl) \\ full_simp_tac(srw_ss())[] (* asm_exists_tac *)
  \\ full_simp_tac bool_ss [GSYM APPEND_ASSOC]
  \\ imp_res_tac word_ml_inv_get_vars_IMP
  \\ first_assum (fn th => mp_tac th THEN match_mp_tac word_ml_inv_rearrange)
  \\ full_simp_tac(srw_ss())[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `x` \\ full_simp_tac(srw_ss())[join_env_def,MEM_MAP,MEM_FILTER]
  \\ Cases_on `y` \\ full_simp_tac(srw_ss())[MEM_toAList,lookup_inter_alt] \\ srw_tac[][MEM_ZIP]
  \\ full_simp_tac(srw_ss())[lookup_fromList2,lookup_fromList]
  \\ rpt disj1_tac
  \\ Q.MATCH_ASSUM_RENAME_TAC `EVEN k`
  \\ full_simp_tac(srw_ss())[DIV_LT_X]
  \\ `k < 2 + LENGTH q * 2 /\ 0 < LENGTH q * 2` by
   (rev_full_simp_tac(srw_ss())[] \\ Cases_on `q` \\ full_simp_tac(srw_ss())[]
    THEN1 (Cases_on `k` \\ full_simp_tac(srw_ss())[] \\ Cases_on `n` \\ full_simp_tac(srw_ss())[] \\ decide_tac)
    \\ full_simp_tac(srw_ss())[MULT_CLAUSES] \\ decide_tac)
  \\ full_simp_tac(srw_ss())[] \\ qexists_tac `(k - 2) DIV 2` \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[DIV_LT_X] \\ srw_tac[][]
  \\ Cases_on `k` \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `n` \\ full_simp_tac(srw_ss())[DECIDE ``SUC (SUC n) = n + 2``]
  \\ simp [MATCH_MP ADD_DIV_RWT (DECIDE ``0<2:num``)]
  \\ full_simp_tac(srw_ss())[GSYM ADD1,EL]);

val data_get_vars_SNOC_IMP = prove(
  ``!x2 x. dataSem$get_vars (SNOC x1 x2) s = SOME x ==>
           ?y1 y2. x = SNOC y1 y2 /\
                   dataSem$get_var x1 s = SOME y1 /\
                   dataSem$get_vars x2 s = SOME y2``,
  Induct \\ full_simp_tac(srw_ss())[dataSemTheory.get_vars_def]
  \\ srw_tac[][] \\ every_case_tac \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]) |> SPEC_ALL;

val word_get_vars_SNOC_IMP = prove(
  ``!x2 x. wordSem$get_vars (SNOC x1 x2) s = SOME x ==>
           ?y1 y2. x = SNOC y1 y2 /\
              wordSem$get_var x1 s = SOME y1 /\
              wordSem$get_vars x2 s = SOME y2``,
  Induct \\ full_simp_tac(srw_ss())[wordSemTheory.get_vars_def]
  \\ srw_tac[][] \\ every_case_tac \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]) |> SPEC_ALL;

val word_ml_inv_CodePtr = prove(
  ``word_ml_inv (heap,be,a,sp) limit c s.refs ((CodePtr n,v)::xs) ==>
    (v = Loc n 0)``,
  full_simp_tac(srw_ss())[word_ml_inv_def,PULL_EXISTS] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[abs_ml_inv_def,bc_stack_ref_inv_def,v_inv_def]
  \\ srw_tac[][word_addr_def]);

val state_rel_CodePtr = prove(
  ``state_rel c l1 l2 s t [] locs /\
    get_vars args s.locals = SOME x /\
    get_vars (MAP adjust_var args) t = SOME y /\
    LAST x = CodePtr n /\ x <> [] ==>
    y <> [] /\ LAST y = Loc n 0``,
  rpt strip_tac
  \\ imp_res_tac wordPropsTheory.get_vars_length_lemma
  \\ imp_res_tac get_vars_IMP_LENGTH \\ full_simp_tac(srw_ss())[]
  THEN1 (srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ Cases_on `x` \\ full_simp_tac(srw_ss())[])
  \\ `args <> []` by (Cases_on `args` \\ full_simp_tac(srw_ss())[] \\ Cases_on `x` \\ full_simp_tac(srw_ss())[])
  \\ `?x1 x2. args = SNOC x1 x2` by metis_tac [SNOC_CASES]
  \\ full_simp_tac bool_ss [MAP_SNOC]
  \\ imp_res_tac data_get_vars_SNOC_IMP
  \\ imp_res_tac word_get_vars_SNOC_IMP \\ srw_tac[][]
  \\ full_simp_tac bool_ss [LAST_SNOC] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[state_rel_def]
  \\ full_simp_tac bool_ss [GSYM APPEND_ASSOC]
  \\ imp_res_tac word_ml_inv_get_var_IMP \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac word_ml_inv_CodePtr);

val find_code_thm = prove(
  ``!(s:'ffi dataSem$state) (t:('a,'ffi)wordSem$state).
      state_rel c l1 l2 s t [] locs /\
      get_vars args s.locals = SOME x /\
      get_vars (0::MAP adjust_var args) t = SOME (Loc l1 l2::ws) /\
      find_code dest x s.code = SOME (q,r) ==>
      ?args1 n1 n2.
        find_code dest (Loc l1 l2::ws) t.code = SOME (args1,FST (comp c n1 n2 r)) /\
        state_rel c l1 l2 (call_env q (dec_clock s))
          (call_env args1 (dec_clock t)) [] locs``,
  Cases_on `dest` \\ srw_tac[][] \\ full_simp_tac(srw_ss())[find_code_def]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[wordSemTheory.find_code_def] \\ srw_tac[][]
  \\ `code_rel c s.code t.code` by full_simp_tac(srw_ss())[state_rel_def]
  \\ full_simp_tac(srw_ss())[code_rel_def] \\ res_tac \\ full_simp_tac(srw_ss())[ADD1]
  \\ imp_res_tac wordPropsTheory.get_vars_length_lemma
  \\ full_simp_tac(srw_ss())[wordSemTheory.get_vars_def]
  \\ Cases_on `get_var 0 t` \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `get_vars (MAP adjust_var args) t` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ TRY (imp_res_tac state_rel_CodePtr \\ full_simp_tac(srw_ss())[]
          \\ qpat_x_assum `ws <> []` (assume_tac)
          \\ imp_res_tac NOT_NIL_IMP_LAST \\ full_simp_tac(srw_ss())[])
  \\ imp_res_tac get_vars_IMP_LENGTH \\ full_simp_tac(srw_ss())[]
  THENL [Q.LIST_EXISTS_TAC [`n`,`1`],Q.LIST_EXISTS_TAC [`x'`,`1`]] \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac state_rel_call_env \\ full_simp_tac(srw_ss())[]
  \\ `args <> []` by (Cases_on `args` \\ full_simp_tac(srw_ss())[] \\ Cases_on `x` \\ full_simp_tac(srw_ss())[])
  \\ `?x1 x2. args = SNOC x1 x2` by metis_tac [SNOC_CASES] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[MAP_SNOC]
  \\ imp_res_tac data_get_vars_SNOC_IMP \\ srw_tac[][]
  \\ imp_res_tac word_get_vars_SNOC_IMP \\ srw_tac[][]
  \\ full_simp_tac bool_ss [GSYM SNOC |> CONJUNCT2]
  \\ full_simp_tac bool_ss [FRONT_SNOC]
  \\ `get_vars (0::MAP adjust_var x2) t = SOME (Loc l1 l2::y2')` by
        full_simp_tac(srw_ss())[wordSemTheory.get_vars_def]
  \\ imp_res_tac state_rel_call_env \\ full_simp_tac(srw_ss())[]) |> SPEC_ALL;

val env_to_list_lookup_equiv = prove(
  ``env_to_list y f = (q,r) ==>
    (!n. ALOOKUP q n = lookup n y) /\
    (!x1 x2. MEM (x1,x2) q ==> lookup x1 y = SOME x2)``,
  full_simp_tac(srw_ss())[wordSemTheory.env_to_list_def,LET_DEF] \\ srw_tac[][]
  \\ `ALL_DISTINCT (MAP FST (toAList y))` by full_simp_tac(srw_ss())[ALL_DISTINCT_MAP_FST_toAList]
  \\ imp_res_tac (MATCH_MP PERM_ALL_DISTINCT_MAP
        (QSORT_PERM |> Q.ISPEC `key_val_compare` |> SPEC_ALL))
  \\ `ALL_DISTINCT (QSORT key_val_compare (toAList y))`
        by imp_res_tac ALL_DISTINCT_MAP
  \\ pop_assum (assume_tac o Q.SPEC `f (0:num)` o MATCH_MP PERM_list_rearrange)
  \\ imp_res_tac PERM_ALL_DISTINCT_MAP
  \\ rpt (qpat_x_assum `!x. pp ==> qq` (K all_tac))
  \\ rpt (qpat_x_assum `!x y. pp ==> qq` (K all_tac)) \\ rev_full_simp_tac(srw_ss())[]
  \\ rpt (pop_assum (mp_tac o Q.GEN `x` o SPEC_ALL))
  \\ rpt (pop_assum (mp_tac o SPEC ``f:num->num->num``))
  \\ Q.ABBREV_TAC `xs =
       (list_rearrange (f 0) (QSORT key_val_compare (toAList y)))`
  \\ rpt strip_tac \\ rev_full_simp_tac(srw_ss())[MEM_toAList]
  \\ Cases_on `?i. MEM (n,i) xs` \\ full_simp_tac(srw_ss())[] THEN1
     (imp_res_tac ALL_DISTINCT_MEM_IMP_ALOOKUP_SOME \\ full_simp_tac(srw_ss())[]
      \\ UNABBREV_ALL_TAC \\ full_simp_tac(srw_ss())[] \\ rev_full_simp_tac(srw_ss())[MEM_toAList])
  \\ `~MEM n (MAP FST xs)` by rev_full_simp_tac(srw_ss())[MEM_MAP,FORALL_PROD]
  \\ full_simp_tac(srw_ss())[GSYM ALOOKUP_NONE]
  \\ UNABBREV_ALL_TAC \\ full_simp_tac(srw_ss())[] \\ rev_full_simp_tac(srw_ss())[MEM_toAList]
  \\ Cases_on `lookup n y` \\ full_simp_tac(srw_ss())[]);

val cut_env_adjust_set_lookup_0 = prove(
  ``wordSem$cut_env (adjust_set r) x = SOME y ==> lookup 0 y = lookup 0 x``,
  full_simp_tac(srw_ss())[wordSemTheory.cut_env_def,SUBSET_DEF,domain_lookup,adjust_set_def,
      lookup_fromAList] \\ srw_tac[][lookup_inter]
  \\ pop_assum (qspec_then `0` mp_tac) \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[lookup_fromAList,lookup_inter]);

val cut_env_IMP_MEM = prove(
  ``dataSem$cut_env s r = SOME x ==>
    (IS_SOME (lookup n x) <=> IS_SOME (lookup n s))``,
  full_simp_tac(srw_ss())[cut_env_def,SUBSET_DEF,domain_lookup]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[lookup_inter] \\ every_case_tac \\ full_simp_tac(srw_ss())[]
  \\ res_tac \\ full_simp_tac(srw_ss())[]);

val cut_env_IMP_lookup = prove(
  ``wordSem$cut_env s r = SOME x /\ lookup n x = SOME q ==>
    lookup n r = SOME q``,
  full_simp_tac(srw_ss())[wordSemTheory.cut_env_def,SUBSET_DEF,domain_lookup]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[lookup_inter] \\ every_case_tac \\ full_simp_tac(srw_ss())[]);

val cut_env_IMP_lookup_EQ = prove(
  ``dataSem$cut_env r y = SOME x /\ n IN domain r ==>
    lookup n x = lookup n y``,
  full_simp_tac(srw_ss())[dataSemTheory.cut_env_def,SUBSET_DEF,domain_lookup]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[lookup_inter] \\ every_case_tac \\ full_simp_tac(srw_ss())[]);

val cut_env_res_IS_SOME_IMP = prove(
  ``wordSem$cut_env r x = SOME y /\ IS_SOME (lookup k y) ==>
    IS_SOME (lookup k x) /\ IS_SOME (lookup k r)``,
  full_simp_tac(srw_ss())[wordSemTheory.cut_env_def,SUBSET_DEF,domain_lookup]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[lookup_inter] \\ every_case_tac \\ full_simp_tac(srw_ss())[]);

val adjust_var_cut_env_IMP_MEM = prove(
  ``wordSem$cut_env (adjust_set s) r = SOME x ==>
    domain x SUBSET EVEN /\
    (IS_SOME (lookup (adjust_var n) x) <=> IS_SOME (lookup n s))``,
  full_simp_tac(srw_ss())[wordSemTheory.cut_env_def,SUBSET_DEF,domain_lookup]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[lookup_inter_alt] THEN1
   (full_simp_tac(srw_ss())[domain_lookup,unit_some_eq_IS_SOME,adjust_set_def]
    \\ full_simp_tac(srw_ss())[IS_SOME_ALOOKUP_EQ,MEM_MAP,lookup_fromAList]
    \\ every_case_tac \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[IN_DEF]
    \\ full_simp_tac(srw_ss())[IS_SOME_ALOOKUP_EQ,MEM_MAP,lookup_fromAList]
    \\ pairarg_tac \\ srw_tac[][] \\ full_simp_tac(srw_ss())[EVEN_adjust_var])
  \\ full_simp_tac(srw_ss())[domain_lookup,lookup_adjust_var_adjust_set_SOME_UNIT] \\ srw_tac[][]
  \\ metis_tac [lookup_adjust_var_adjust_set_SOME_UNIT,IS_SOME_DEF]);

val state_rel_call_env_push_env = prove(
  ``!opt:(num # 'a wordLang$prog # num # num) option.
      state_rel c l1 l2 s (t:('a,'ffi)wordSem$state) [] locs /\
      get_vars args s.locals = SOME xs /\
      get_vars (MAP adjust_var args) t = SOME ws /\
      dataSem$cut_env r s.locals = SOME x /\
      wordSem$cut_env (adjust_set r) t.locals = SOME y ==>
      state_rel c q l (call_env xs (push_env x (IS_SOME opt) (dec_clock s)))
       (call_env (Loc q l::ws) (push_env y opt (dec_clock t))) []
       ((l1,l2)::locs)``,
  Cases \\ TRY (PairCases_on `x'`) \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[state_rel_def,call_env_def,push_env_def,dec_clock_def,
         wordSemTheory.call_env_def,wordSemTheory.push_env_def,
         wordSemTheory.dec_clock_def]
  \\ Cases_on `env_to_list y t.permute` \\ full_simp_tac(srw_ss())[LET_DEF,stack_rel_def]
  \\ full_simp_tac(srw_ss())[lookup_adjust_var_fromList2,contains_loc_def] \\ strip_tac
  \\ full_simp_tac(srw_ss())[lookup_fromList,lookup_fromAList]
  \\ imp_res_tac get_vars_IMP_LENGTH \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac wordPropsTheory.get_vars_length_lemma \\ full_simp_tac(srw_ss())[IS_SOME_IF]
  \\ full_simp_tac(srw_ss())[lookup_fromList2,lookup_fromList]
  \\ imp_res_tac env_to_list_lookup_equiv \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac cut_env_adjust_set_lookup_0 \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac cut_env_IMP_MEM
  \\ imp_res_tac adjust_var_cut_env_IMP_MEM \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac EVERY2_LENGTH \\ full_simp_tac(srw_ss())[]
  \\ rpt strip_tac \\ TRY
   (imp_res_tac adjust_var_cut_env_IMP_MEM
    \\ full_simp_tac(srw_ss())[domain_lookup,SUBSET_DEF,PULL_EXISTS]
    \\ full_simp_tac(srw_ss())[EVERY_MEM,FORALL_PROD] \\ ntac 3 strip_tac
    \\ res_tac \\ res_tac \\ full_simp_tac(srw_ss())[IN_DEF] \\ srw_tac[][] \\ strip_tac
    \\ srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ rev_full_simp_tac(srw_ss())[isWord_def] \\ NO_TAC)
  \\ first_assum (match_exists_tac o concl) \\ full_simp_tac(srw_ss())[] (* asm_exists_tac *)
  \\ full_simp_tac(srw_ss())[flat_def]
  \\ full_simp_tac bool_ss [GSYM APPEND_ASSOC]
  \\ imp_res_tac word_ml_inv_get_vars_IMP
  \\ first_assum (fn th => mp_tac th THEN match_mp_tac word_ml_inv_rearrange)
  \\ full_simp_tac(srw_ss())[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ TRY (rpt disj1_tac
    \\ Cases_on `x'` \\ full_simp_tac(srw_ss())[join_env_def,MEM_MAP,MEM_FILTER,EXISTS_PROD]
    \\ full_simp_tac(srw_ss())[MEM_toAList] \\ srw_tac[][MEM_ZIP]
    \\ full_simp_tac(srw_ss())[lookup_fromList2,lookup_fromList,lookup_inter_alt]
    \\ Q.MATCH_ASSUM_RENAME_TAC `EVEN k`
    \\ full_simp_tac(srw_ss())[DIV_LT_X]
    \\ `k < 2 + LENGTH xs * 2 /\ 0 < LENGTH xs * 2` by
     (rev_full_simp_tac(srw_ss())[] \\ Cases_on `xs` \\ full_simp_tac(srw_ss())[]
      THEN1 (Cases_on `k` \\ full_simp_tac(srw_ss())[] \\ Cases_on `n` \\ full_simp_tac(srw_ss())[] \\ decide_tac)
      \\ full_simp_tac(srw_ss())[MULT_CLAUSES] \\ decide_tac)
    \\ full_simp_tac(srw_ss())[] \\ qexists_tac `(k - 2) DIV 2` \\ full_simp_tac(srw_ss())[]
    \\ full_simp_tac(srw_ss())[DIV_LT_X]
    \\ Cases_on `k` \\ full_simp_tac(srw_ss())[]
    \\ Cases_on `n` \\ full_simp_tac(srw_ss())[DECIDE ``SUC (SUC n) = n + 2``]
    \\ full_simp_tac(srw_ss())[MATCH_MP ADD_DIV_RWT (DECIDE ``0<2:num``)]
    \\ full_simp_tac(srw_ss())[GSYM ADD1,EL] \\ NO_TAC)
  \\ full_simp_tac(srw_ss())[] \\ disj1_tac \\ disj2_tac
  \\ Cases_on `x'` \\ full_simp_tac(srw_ss())[join_env_def,MEM_MAP,MEM_FILTER,EXISTS_PROD]
  \\ full_simp_tac(srw_ss())[MEM_toAList] \\ srw_tac[][MEM_ZIP]
  \\ full_simp_tac(srw_ss())[lookup_fromList2,lookup_fromList,lookup_inter_alt]
  \\ Q.MATCH_ASSUM_RENAME_TAC `EVEN k`
  \\ qexists_tac `k` \\ full_simp_tac(srw_ss())[] \\ res_tac \\ srw_tac[][]
  \\ imp_res_tac cut_env_IMP_lookup \\ full_simp_tac(srw_ss())[]
  \\ TRY (AP_TERM_TAC \\ match_mp_tac cut_env_IMP_lookup_EQ) \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[domain_lookup] \\ imp_res_tac MEM_IMP_IS_SOME_ALOOKUP \\ rev_full_simp_tac(srw_ss())[]
  \\ imp_res_tac cut_env_res_IS_SOME_IMP
  \\ full_simp_tac(srw_ss())[IS_SOME_EXISTS]
  \\ full_simp_tac(srw_ss())[adjust_set_def,lookup_fromAList] \\ rev_full_simp_tac(srw_ss())[]
  \\ imp_res_tac alistTheory.ALOOKUP_MEM
  \\ full_simp_tac(srw_ss())[unit_some_eq_IS_SOME,IS_SOME_ALOOKUP_EQ,MEM_MAP,EXISTS_PROD]
  \\ srw_tac[][adjust_var_11,adjust_var_DIV_2]
  \\ imp_res_tac MEM_toAList \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[dataSemTheory.cut_env_def,SUBSET_DEF,domain_lookup]
  \\ res_tac \\ full_simp_tac(srw_ss())[MEM_toAList]);

val find_code_thm_ret = prove(
  ``!(s:'ffi dataSem$state) (t:('a,'ffi)wordSem$state).
      state_rel c l1 l2 s t [] locs /\
      get_vars args s.locals = SOME xs /\
      get_vars (MAP adjust_var args) t = SOME ws /\
      find_code dest xs s.code = SOME (ys,prog) /\
      dataSem$cut_env r s.locals = SOME x /\
      wordSem$cut_env (adjust_set r) t.locals = SOME y ==>
      ?args1 n1 n2.
        find_code dest (Loc q l::ws) t.code = SOME (args1,FST (comp c n1 n2 prog)) /\
        state_rel c q l (call_env ys (push_env x F (dec_clock s)))
          (call_env args1 (push_env y
             (NONE:(num # ('a wordLang$prog) # num # num) option)
          (dec_clock t))) [] ((l1,l2)::locs)``,
  reverse (Cases_on `dest`) \\ srw_tac[][] \\ full_simp_tac(srw_ss())[find_code_def]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[wordSemTheory.find_code_def] \\ srw_tac[][]
  \\ `code_rel c s.code t.code` by full_simp_tac(srw_ss())[state_rel_def]
  \\ full_simp_tac(srw_ss())[code_rel_def] \\ res_tac \\ full_simp_tac(srw_ss())[ADD1]
  \\ imp_res_tac wordPropsTheory.get_vars_length_lemma \\ full_simp_tac(srw_ss())[]
  \\ TRY (imp_res_tac state_rel_CodePtr \\ full_simp_tac(srw_ss())[]
          \\ qpat_x_assum `ws <> []` (assume_tac)
          \\ imp_res_tac NOT_NIL_IMP_LAST \\ full_simp_tac(srw_ss())[])
  \\ imp_res_tac get_vars_IMP_LENGTH \\ full_simp_tac(srw_ss())[]
  THEN1 (Q.LIST_EXISTS_TAC [`x'`,`1`] \\ full_simp_tac(srw_ss())[]
         \\ qspec_then `NONE` mp_tac state_rel_call_env_push_env \\ full_simp_tac(srw_ss())[])
  \\ Q.LIST_EXISTS_TAC [`n`,`1`] \\ full_simp_tac(srw_ss())[]
  \\ `args <> []` by (Cases_on `args` \\ full_simp_tac(srw_ss())[] \\ Cases_on `xs` \\ full_simp_tac(srw_ss())[])
  \\ `?x1 x2. args = SNOC x1 x2` by metis_tac [SNOC_CASES] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[MAP_SNOC]
  \\ imp_res_tac data_get_vars_SNOC_IMP \\ srw_tac[][]
  \\ imp_res_tac word_get_vars_SNOC_IMP \\ srw_tac[][]
  \\ full_simp_tac bool_ss [GSYM SNOC |> CONJUNCT2]
  \\ full_simp_tac bool_ss [FRONT_SNOC]
  \\ match_mp_tac (state_rel_call_env_push_env |> Q.SPEC `NONE`
                   |> SIMP_RULE std_ss [] |> GEN_ALL)
  \\ full_simp_tac(srw_ss())[] \\ metis_tac []) |> SPEC_ALL;

val find_code_thm_handler = prove(
  ``!(s:'ffi dataSem$state) (t:('a,'ffi)wordSem$state).
      state_rel c l1 l2 s t [] locs /\
      get_vars args s.locals = SOME xs /\
      get_vars (MAP adjust_var args) t = SOME ws /\
      find_code dest xs s.code = SOME (ys,prog) /\
      dataSem$cut_env r s.locals = SOME x /\
      wordSem$cut_env (adjust_set r) t.locals = SOME y ==>
      ?args1 n1 n2.
        find_code dest (Loc q l::ws) t.code = SOME (args1,FST (comp c n1 n2 prog)) /\
        state_rel c q l (call_env ys (push_env x T (dec_clock s)))
          (call_env args1 (push_env y
             (SOME (adjust_var x0,(prog1:'a wordLang$prog),nn,l + 1))
          (dec_clock t))) [] ((l1,l2)::locs)``,
  reverse (Cases_on `dest`) \\ srw_tac[][] \\ full_simp_tac(srw_ss())[find_code_def]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[wordSemTheory.find_code_def] \\ srw_tac[][]
  \\ `code_rel c s.code t.code` by full_simp_tac(srw_ss())[state_rel_def]
  \\ full_simp_tac(srw_ss())[code_rel_def] \\ res_tac \\ full_simp_tac(srw_ss())[ADD1]
  \\ imp_res_tac wordPropsTheory.get_vars_length_lemma \\ full_simp_tac(srw_ss())[]
  \\ TRY (imp_res_tac state_rel_CodePtr \\ full_simp_tac(srw_ss())[]
          \\ qpat_x_assum `ws <> []` (assume_tac)
          \\ imp_res_tac NOT_NIL_IMP_LAST \\ full_simp_tac(srw_ss())[])
  \\ imp_res_tac get_vars_IMP_LENGTH \\ full_simp_tac(srw_ss())[]
  THEN1 (Q.LIST_EXISTS_TAC [`x'`,`1`] \\ full_simp_tac(srw_ss())[]
         \\ match_mp_tac (state_rel_call_env_push_env |> Q.SPEC `SOME xx`
                   |> SIMP_RULE std_ss [] |> GEN_ALL) \\ full_simp_tac(srw_ss())[] \\ metis_tac [])
  \\ Q.LIST_EXISTS_TAC [`n`,`1`] \\ full_simp_tac(srw_ss())[]
  \\ `args <> []` by (Cases_on `args` \\ full_simp_tac(srw_ss())[] \\ Cases_on `xs` \\ full_simp_tac(srw_ss())[])
  \\ `?x1 x2. args = SNOC x1 x2` by metis_tac [SNOC_CASES] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[MAP_SNOC]
  \\ imp_res_tac data_get_vars_SNOC_IMP \\ srw_tac[][]
  \\ imp_res_tac word_get_vars_SNOC_IMP \\ srw_tac[][]
  \\ full_simp_tac bool_ss [GSYM SNOC |> CONJUNCT2]
  \\ full_simp_tac bool_ss [FRONT_SNOC]
  \\ match_mp_tac (state_rel_call_env_push_env |> Q.SPEC `SOME xx`
                   |> SIMP_RULE std_ss [] |> GEN_ALL)
  \\ full_simp_tac(srw_ss())[] \\ metis_tac []) |> SPEC_ALL;

val bvl_find_code = store_thm("bvl_find_code",
  ``bvlSem$find_code dest xs code = SOME(ys,prog) ⇒
  ¬bad_dest_args dest xs``,
  Cases_on`dest`>>
  full_simp_tac(srw_ss())[bvlSemTheory.find_code_def,wordSemTheory.bad_dest_args_def])

val s_key_eq_LENGTH = prove(
  ``!xs ys. s_key_eq xs ys ==> (LENGTH xs = LENGTH ys)``,
  Induct \\ Cases_on `ys` \\ full_simp_tac(srw_ss())[s_key_eq_def]);

val s_key_eq_LASTN = prove(
  ``!xs ys n. s_key_eq xs ys ==> s_key_eq (LASTN n xs) (LASTN n ys)``,
  Induct \\ Cases_on `ys` \\ full_simp_tac(srw_ss())[s_key_eq_def,LASTN_ALT]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[s_key_eq_def,LASTN_ALT] \\ res_tac
  \\ imp_res_tac s_key_eq_LENGTH \\ full_simp_tac(srw_ss())[] \\ `F` by decide_tac);

val evaluate_mk_loc_EQ = prove(
  ``evaluate (q,t) = (NONE,t1:('a,'b) state) ==>
    mk_loc (jump_exc t1) = ((mk_loc (jump_exc t)):'a word_loc)``,
  qspecl_then [`q`,`t`] mp_tac wordPropsTheory.evaluate_stack_swap \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[wordSemTheory.jump_exc_def]
  \\ imp_res_tac s_key_eq_LENGTH \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ imp_res_tac s_key_eq_LASTN
  \\ pop_assum (qspec_then `t.handler + 1` mp_tac)
  \\ every_case_tac \\ full_simp_tac(srw_ss())[s_key_eq_def,s_frame_key_eq_def,mk_loc_def])

val mk_loc_eq_push_env_exc_Exception = prove(
  ``evaluate
      (c:'a wordLang$prog, call_env args1
            (push_env y (SOME (x0,prog1:'a wordLang$prog,x1,l))
               (dec_clock t))) = (SOME (Exception xx w),(t1:('a,'b) state)) ==>
    mk_loc (jump_exc t1) = mk_loc (jump_exc t) :'a word_loc``,
  qspecl_then [`c`,`call_env args1
    (push_env y (SOME (x0,prog1:'a wordLang$prog,x1,l)) (dec_clock t))`]
       mp_tac wordPropsTheory.evaluate_stack_swap \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[wordSemTheory.call_env_def,wordSemTheory.push_env_def,
         wordSemTheory.dec_clock_def]
  \\ Cases_on `env_to_list y t.permute` \\ full_simp_tac(srw_ss())[LET_DEF,LASTN_ADD1]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[wordSemTheory.jump_exc_def]
  \\ first_assum (qspec_then `t1.stack` mp_tac)
  \\ imp_res_tac s_key_eq_LENGTH \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ imp_res_tac s_key_eq_LASTN
  \\ pop_assum (qspec_then `t.handler+1` mp_tac) \\ srw_tac[][]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[s_key_eq_def,s_frame_key_eq_def,mk_loc_def]);

val evaluate_IMP_domain_EQ = prove(
  ``evaluate (c,call_env (args1:'a word_loc list) (push_env y (opt:(num # ('a wordLang$prog) # num # num) option) (dec_clock t))) =
      (SOME (Result ll w),t1) /\ pop_env t1 = SOME t2 ==>
    domain t2.locals = domain y``,
  qspecl_then [`c`,`call_env args1 (push_env y opt (dec_clock t))`] mp_tac
      wordPropsTheory.evaluate_stack_swap \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[wordSemTheory.call_env_def]
  \\ Cases_on `opt` \\ full_simp_tac(srw_ss())[] \\ TRY (PairCases_on `x`)
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[wordSemTheory.pop_env_def,wordSemTheory.push_env_def]
  \\ Cases_on `env_to_list y (dec_clock t).permute` \\ full_simp_tac(srw_ss())[LET_DEF]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[s_key_eq_def] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[wordSemTheory.env_to_list_def,LET_DEF] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[s_frame_key_eq_def,domain_fromAList] \\ srw_tac[][]
  \\ qpat_x_assum `xxx = MAP FST l` (fn th => full_simp_tac(srw_ss())[GSYM th])
  \\ full_simp_tac(srw_ss())[EXTENSION,MEM_MAP,EXISTS_PROD,mem_list_rearrange,QSORT_MEM,
         domain_lookup,MEM_toAList]);

val evaluate_IMP_domain_EQ_Exc = prove(
  ``evaluate (c,call_env args1 (push_env y
      (SOME (x0,prog1:'a wordLang$prog,x1,l))
      (dec_clock (t:('a,'b) state)))) = (SOME (Exception ll w),t1) ==>
    domain t1.locals = domain y``,
  qspecl_then [`c`,`call_env args1
     (push_env y (SOME (x0,prog1:'a wordLang$prog,x1,l)) (dec_clock t))`]
     mp_tac wordPropsTheory.evaluate_stack_swap \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[wordSemTheory.call_env_def,wordSemTheory.push_env_def,
         wordSemTheory.dec_clock_def]
  \\ Cases_on `env_to_list y t.permute` \\ full_simp_tac(srw_ss())[LET_DEF,LASTN_ADD1] \\ srw_tac[][]
  \\ first_x_assum (qspec_then `t1.stack` mp_tac) \\ srw_tac[][]
  \\ imp_res_tac s_key_eq_LASTN \\ full_simp_tac(srw_ss())[]
  \\ first_x_assum (qspec_then `t.handler+1` mp_tac) \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[wordSemTheory.env_to_list_def,LET_DEF] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[s_frame_key_eq_def,domain_fromAList] \\ srw_tac[][]
  \\ qpat_x_assum `xxx = MAP FST lss` (fn th => full_simp_tac(srw_ss())[GSYM th])
  \\ full_simp_tac(srw_ss())[EXTENSION,MEM_MAP,EXISTS_PROD,mem_list_rearrange,QSORT_MEM,
         domain_lookup,MEM_toAList]);

val mk_loc_jump_exc = prove(
  ``mk_loc
       (jump_exc
          (call_env args1
             (push_env y (SOME (adjust_var n,prog1,x0,l))
                (dec_clock t)))) = Loc x0 l``,
  full_simp_tac(srw_ss())[wordSemTheory.push_env_def,wordSemTheory.call_env_def,
      wordSemTheory.jump_exc_def]
  \\ Cases_on `env_to_list y (dec_clock t).permute`
  \\ full_simp_tac(srw_ss())[LET_DEF,LASTN_ADD1,mk_loc_def]);

val inc_clock_def = Define `
  inc_clock n (t:('a,'ffi) wordSem$state) = t with clock := t.clock + n`;

val inc_clock_0 = store_thm("inc_clock_0[simp]",
  ``!t. inc_clock 0 t = t``,
  full_simp_tac(srw_ss())[inc_clock_def,wordSemTheory.state_component_equality]);

val inc_clock_inc_clock = store_thm("inc_clock_inc_clock[simp]",
  ``!t. inc_clock n (inc_clock m t) = inc_clock (n+m) t``,
  full_simp_tac(srw_ss())[inc_clock_def,wordSemTheory.state_component_equality,AC ADD_ASSOC ADD_COMM]);

val mk_loc_jmup_exc_inc_clock = store_thm("mk_loc_jmup_exc_inc_clock[simp]",
  ``mk_loc (jump_exc (inc_clock ck t)) = mk_loc (jump_exc t)``,
  full_simp_tac(srw_ss())[mk_loc_def,wordSemTheory.jump_exc_def,inc_clock_def]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[mk_loc_def]);

val jump_exc_inc_clock_EQ_NONE = prove(
  ``jump_exc (inc_clock n s) = NONE <=> jump_exc s = NONE``,
  full_simp_tac(srw_ss())[mk_loc_def,wordSemTheory.jump_exc_def,inc_clock_def]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[mk_loc_def]);

val state_rel_lookup_globals = Q.store_thm("state_rel_lookup_globals",
  `state_rel c l1 l2 s t v1 locs ∧ s.global = SOME g (* ∧
   FLOOKUP s.refs g = SOME (ValueArray gs) *)
   ⇒
   ∃x u.
   FLOOKUP t.store Globals = SOME (Word (get_addr c x u))`,
  rw[state_rel_def]
  \\ fs[the_global_def,libTheory.the_def]
  \\ qmatch_assum_abbrev_tac`word_ml_inv heapp limit c refs _`
  \\ qmatch_asmsub_abbrev_tac`[gg]`
  \\ `∃rest. word_ml_inv heapp limit c refs (gg::rest)`
  by (
    qmatch_asmsub_abbrev_tac`a1 ++ [gg] ++ a2`
    \\ qexists_tac`a1++a2`
    \\ simp[Abbr`heapp`]
    \\ match_mp_tac (GEN_ALL (MP_CANON word_ml_inv_rearrange))
    \\ ONCE_REWRITE_TAC[CONJ_COMM]
    \\ asm_exists_tac
    \\ simp[] \\ metis_tac[] )
  \\ fs[word_ml_inv_def,Abbr`heapp`]
  \\ fs[abs_ml_inv_def]
  \\ fs[bc_stack_ref_inv_def]
  \\ fs[Abbr`gg`,v_inv_def]
  \\ simp[FLOOKUP_DEF]
  \\ first_assum(CHANGED_TAC o SUBST1_TAC o SYM)
  \\ rveq
  \\ simp_tac(srw_ss())[word_addr_def]
  \\ metis_tac[]);

val state_rel_cut_env = store_thm("state_rel_cut_env",
  ``state_rel c l1 l2 s t [] locs /\
    dataSem$cut_env names s.locals = SOME x ==>
    state_rel c l1 l2 (s with locals := x) t [] locs``,
  full_simp_tac(srw_ss())[state_rel_def,dataSemTheory.cut_env_def] \\ srw_tac[][]
  THEN1 (full_simp_tac(srw_ss())[lookup_inter] \\ every_case_tac \\ full_simp_tac(srw_ss())[])
  \\ asm_exists_tac \\ full_simp_tac(srw_ss())[]
  \\ first_x_assum (fn th => mp_tac th THEN match_mp_tac word_ml_inv_rearrange)
  \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ rpt disj1_tac
  \\ PairCases_on `x` \\ full_simp_tac(srw_ss())[join_env_def,MEM_MAP]
  \\ Cases_on `y` \\ full_simp_tac(srw_ss())[EXISTS_PROD,MEM_FILTER]
  \\ qexists_tac `q` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  THEN1
   (AP_TERM_TAC
    \\ full_simp_tac(srw_ss())[FUN_EQ_THM,lookup_inter_alt,MEM_toAList,domain_lookup]
    \\ full_simp_tac(srw_ss())[SUBSET_DEF,IN_DEF,domain_lookup] \\ srw_tac[][]
    \\ imp_res_tac IMP_adjust_var
    \\ `lookup (adjust_var ((q - 2) DIV 2))
           (adjust_set (inter s.locals names)) = NONE` by
     (simp [lookup_adjust_var_adjust_set_NONE,lookup_inter_alt]
      \\ full_simp_tac(srw_ss())[domain_lookup]) \\ rev_full_simp_tac(srw_ss())[])
  \\ full_simp_tac(srw_ss())[MEM_toAList,lookup_inter_alt]
  \\ full_simp_tac(srw_ss())[domain_lookup,unit_some_eq_IS_SOME,adjust_set_def,lookup_fromAList]
  \\ rev_full_simp_tac(srw_ss())[IS_SOME_ALOOKUP_EQ,MEM_MAP] \\ srw_tac[][]
  \\ Cases_on `y'` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][EXISTS_PROD,adjust_var_11]
  \\ full_simp_tac(srw_ss())[MEM_toAList,lookup_inter_alt]);

val state_rel_get_var_RefPtr = Q.store_thm("state_rel_get_var_RefPtr",
  `state_rel c l1 l2 s t v1 locs ∧
   get_var n s.locals = SOME (RefPtr p) ⇒
   ∃f u. get_var (adjust_var n) t = SOME (Word (get_addr c (FAPPLY f p) u))`,
  rw[]
  \\ imp_res_tac state_rel_get_var_IMP
  \\ fs[state_rel_def,wordSemTheory.get_var_def,dataSemTheory.get_var_def]
  \\ full_simp_tac std_ss [Once (GSYM APPEND_ASSOC)]
  \\ drule (GEN_ALL word_ml_inv_lookup)
  \\ disch_then drule
  \\ disch_then drule
  \\ REWRITE_TAC[GSYM APPEND_ASSOC]
  \\ qmatch_goalsub_abbrev_tac`v1 ++ (rr ++ ls)`
  \\ qmatch_abbrev_tac`P (v1 ++ (rr ++ ls)) ⇒ _`
  \\ strip_tac
  \\ `P (rr ++ v1 ++ ls)`
  by (
    unabbrev_all_tac
    \\ match_mp_tac (GEN_ALL (MP_CANON word_ml_inv_rearrange))
    \\ ONCE_REWRITE_TAC[CONJ_COMM]
    \\ asm_exists_tac
    \\ simp[] \\ metis_tac[] )
  \\ pop_assum mp_tac
  \\ pop_assum kall_tac
  \\ simp[Abbr`P`,Abbr`rr`,word_ml_inv_def]
  \\ strip_tac \\ rveq
  \\ fs[abs_ml_inv_def]
  \\ fs[bc_stack_ref_inv_def]
  \\ fs[v_inv_def]
  \\ simp[word_addr_def]
  \\ metis_tac[]);

val state_rel_get_var_Block = Q.store_thm("state_rel_get_var_Block",
  `state_rel c l1 l2 s t v1 locs ∧
   get_var n s.locals = SOME (Block tag vs) ⇒
   ∃w. get_var (adjust_var n) t = SOME (Word w)`,
  rw[]
  \\ imp_res_tac state_rel_get_var_IMP
  \\ fs[state_rel_def,wordSemTheory.get_var_def,dataSemTheory.get_var_def]
  \\ full_simp_tac std_ss [Once (GSYM APPEND_ASSOC)]
  \\ drule (GEN_ALL word_ml_inv_lookup)
  \\ disch_then drule
  \\ disch_then drule
  \\ REWRITE_TAC[GSYM APPEND_ASSOC]
  \\ qmatch_goalsub_abbrev_tac`v1 ++ (rr ++ ls)`
  \\ qmatch_abbrev_tac`P (v1 ++ (rr ++ ls)) ⇒ _`
  \\ strip_tac
  \\ `P (rr ++ v1 ++ ls)`
  by (
    unabbrev_all_tac
    \\ match_mp_tac (GEN_ALL (MP_CANON word_ml_inv_rearrange))
    \\ ONCE_REWRITE_TAC[CONJ_COMM]
    \\ asm_exists_tac
    \\ simp[] \\ metis_tac[] )
  \\ pop_assum mp_tac
  \\ pop_assum kall_tac
  \\ simp[Abbr`P`,Abbr`rr`,word_ml_inv_def]
  \\ strip_tac \\ rveq
  \\ fs[abs_ml_inv_def]
  \\ fs[bc_stack_ref_inv_def]
  \\ fs[v_inv_def]
  \\ rator_x_assum`COND`mp_tac
  \\ IF_CASES_TAC \\ simp[word_addr_def]
  \\ strip_tac \\ rveq
  \\ simp[word_addr_def]);

val state_rel_cut_state_opt_get_var = Q.store_thm("state_rel_cut_state_opt_get_var",
  `state_rel c l1 l2 s t [] locs ∧
   cut_state_opt names_opt s = SOME x ∧
   get_var v x.locals = SOME w ⇒
   ∃s'. state_rel c l1 l2 s' t [] locs ∧
        get_var v s'.locals = SOME w`,
  rw[cut_state_opt_def]
  \\ every_case_tac \\ fs[] >- metis_tac[]
  \\ fs[cut_state_def]
  \\ every_case_tac \\ fs[]
  \\ imp_res_tac state_rel_cut_env
  \\ metis_tac[] );

val jump_exc_push_env_NONE_simp = prove(
  ``(jump_exc (dec_clock t) = NONE <=> jump_exc t = NONE) /\
    (jump_exc (push_env y NONE t) = NONE <=> jump_exc t = NONE) /\
    (jump_exc (call_env args s) = NONE <=> jump_exc s = NONE)``,
  full_simp_tac(srw_ss())[wordSemTheory.jump_exc_def,wordSemTheory.call_env_def,
      wordSemTheory.dec_clock_def] \\ srw_tac[][] THEN1 every_case_tac
  \\ full_simp_tac(srw_ss())[wordSemTheory.push_env_def]
  \\ Cases_on `env_to_list y t.permute` \\ full_simp_tac(srw_ss())[LET_DEF]
  \\ Cases_on `t.handler = LENGTH t.stack` \\ full_simp_tac(srw_ss())[LASTN_ADD1]
  \\ Cases_on `~(t.handler < LENGTH t.stack)` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  THEN1 (`F` by DECIDE_TAC)
  \\ `LASTN (t.handler + 1) (StackFrame q NONE::t.stack) =
      LASTN (t.handler + 1) t.stack` by
    (match_mp_tac LASTN_TL \\ decide_tac) \\ full_simp_tac(srw_ss())[]
  \\ every_case_tac \\ CCONTR_TAC
  \\ full_simp_tac(srw_ss())[NOT_LESS]
  \\ `SUC (LENGTH t.stack) <= t.handler + 1` by decide_tac
  \\ imp_res_tac (LASTN_LENGTH_LESS_EQ |> Q.SPEC `x::xs`
       |> SIMP_RULE std_ss [LENGTH]) \\ full_simp_tac(srw_ss())[]);

val s_key_eq_handler_eq_IMP = prove(
  ``s_key_eq t.stack t1.stack /\ t.handler = t1.handler ==>
    (jump_exc t1 <> NONE <=> jump_exc t <> NONE)``,
  full_simp_tac(srw_ss())[wordSemTheory.jump_exc_def] \\ srw_tac[][]
  \\ imp_res_tac s_key_eq_LENGTH \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `t1.handler < LENGTH t1.stack` \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac s_key_eq_LASTN
  \\ pop_assum (qspec_then `t1.handler + 1` mp_tac)
  \\ every_case_tac \\ full_simp_tac(srw_ss())[s_key_eq_def,s_frame_key_eq_def]);

val eval_NONE_IMP_jump_exc_NONE_EQ = prove(
  ``evaluate (q,t) = (NONE,t1) ==> (jump_exc t1 = NONE <=> jump_exc t = NONE)``,
  srw_tac[][] \\ mp_tac (wordPropsTheory.evaluate_stack_swap |> Q.SPECL [`q`,`t`])
  \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ imp_res_tac s_key_eq_handler_eq_IMP \\ metis_tac []);

val jump_exc_push_env_SOME = prove(
  ``jump_exc (push_env y (SOME (x,prog1,l1,l2)) t) <> NONE``,
  full_simp_tac(srw_ss())[wordSemTheory.jump_exc_def,wordSemTheory.push_env_def]
  \\ Cases_on `env_to_list y t.permute` \\ full_simp_tac(srw_ss())[LET_DEF]
  \\ full_simp_tac(srw_ss())[LASTN_ADD1]);

val eval_push_env_T_Raise_IMP_stack_length = prove(
  ``evaluate (p,call_env ys (push_env x T (dec_clock s))) =
       (SOME (Rerr (Rraise a)),r') ==>
    LENGTH r'.stack = LENGTH s.stack``,
  qspecl_then [`p`,`call_env ys (push_env x T (dec_clock s))`]
    mp_tac dataPropsTheory.evaluate_stack_swap
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[call_env_def,jump_exc_def,push_env_def,dec_clock_def,LASTN_ADD1]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]);

val eval_push_env_SOME_exc_IMP_s_key_eq = prove(
  ``evaluate (p, call_env args1 (push_env y (SOME (x1,x2,x3,x4)) (dec_clock t))) =
      (SOME (Exception l w),t1) ==>
    s_key_eq t1.stack t.stack /\ t.handler = t1.handler``,
  qspecl_then [`p`,`call_env args1 (push_env y (SOME (x1,x2,x3,x4)) (dec_clock t))`]
    mp_tac wordPropsTheory.evaluate_stack_swap
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[wordSemTheory.call_env_def,wordSemTheory.jump_exc_def,
         wordSemTheory.push_env_def,wordSemTheory.dec_clock_def,LASTN_ADD1]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `env_to_list y t.permute` \\ full_simp_tac(srw_ss())[LET_DEF,LASTN_ADD1]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]);

val eval_exc_stack_shorter = prove(
  ``evaluate (c,call_env ys (push_env x F (dec_clock s))) =
      (SOME (Rerr (Rraise a)),r') ==>
    LENGTH r'.stack < LENGTH s.stack``,
  srw_tac[][] \\ qspecl_then [`c`,`call_env ys (push_env x F (dec_clock s))`]
             mp_tac dataPropsTheory.evaluate_stack_swap
  \\ full_simp_tac(srw_ss())[] \\ once_rewrite_tac [EQ_SYM_EQ] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[dataSemTheory.jump_exc_def,call_env_def,push_env_def,dec_clock_def]
  \\ qpat_x_assum `xx = SOME s2` mp_tac
  \\ rpt (pop_assum (K all_tac))
  \\ full_simp_tac(srw_ss())[LASTN_ALT] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[ADD1]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ match_mp_tac LESS_LESS_EQ_TRANS
  \\ qexists_tac `LENGTH (LASTN (s.handler + 1) s.stack)`
  \\ full_simp_tac(srw_ss())[LENGTH_LASTN_LESS]);

val alloc_size_def = Define `
  alloc_size k = (if k * (dimindex (:'a) DIV 8) < dimword (:α) then
                    n2w (k * (dimindex (:'a) DIV 8))
                  else (-1w)):'a word`

val NOT_1_domain = prove(
  ``~(1 IN domain (adjust_set names))``,
  full_simp_tac(srw_ss())[domain_fromAList,adjust_set_def,MEM_MAP,MEM_toAList,
      FORALL_PROD,adjust_var_def] \\ CCONTR_TAC \\ full_simp_tac(srw_ss())[] \\ decide_tac)

val cut_env_adjust_set_insert_1 = prove(
  ``cut_env (adjust_set names) (insert 1 w l) = cut_env (adjust_set names) l``,
  full_simp_tac(srw_ss())[wordSemTheory.cut_env_def,MATCH_MP SUBSET_INSERT_EQ_SUBSET NOT_1_domain]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[lookup_inter,lookup_insert]
  \\ Cases_on `x = 1` \\ full_simp_tac(srw_ss())[] \\ every_case_tac \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[SIMP_RULE std_ss [domain_lookup] NOT_1_domain]);

val case_EQ_SOME_IFF = prove(
  ``(case p of NONE => NONE | SOME x => g x) = SOME y <=>
    ?x. p = SOME x /\ g x = SOME y``,
  Cases_on `p` \\ full_simp_tac(srw_ss())[]);

val state_rel_set_store_AllocSize = prove(
  ``state_rel c l1 l2 s (set_store AllocSize (Word w) t) v locs =
    state_rel c l1 l2 s t v locs``,
  full_simp_tac(srw_ss())[state_rel_def,wordSemTheory.set_store_def]
  \\ eq_tac \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[heap_in_memory_store_def,FLOOKUP_DEF,FAPPLY_FUPDATE_THM]
  \\ metis_tac []);

val inter_insert = store_thm("inter_insert",
  ``inter (insert n x t1) t2 =
    if n IN domain t2 then insert n x (inter t1 t2) else inter t1 t2``,
  srw_tac[][] \\ full_simp_tac(srw_ss())[spt_eq_thm,wf_inter,wf_insert,lookup_inter_alt,lookup_insert]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]);

val lookup_1_adjust_set = prove(
  ``lookup 1 (adjust_set l) = NONE``,
  full_simp_tac(srw_ss())[adjust_set_def,lookup_fromAList,ALOOKUP_NONE,MEM_MAP,FORALL_PROD]
  \\ full_simp_tac(srw_ss())[adjust_var_def] \\ CCONTR_TAC \\ full_simp_tac(srw_ss())[] \\ decide_tac);

val lookup_3_adjust_set = prove(
  ``lookup 3 (adjust_set l) = NONE``,
  full_simp_tac(srw_ss())[adjust_set_def,lookup_fromAList,ALOOKUP_NONE,MEM_MAP,FORALL_PROD]
  \\ full_simp_tac(srw_ss())[adjust_var_def] \\ CCONTR_TAC \\ full_simp_tac(srw_ss())[] \\ decide_tac);

val state_rel_insert_1 = prove(
  ``state_rel c l1 l2 s (t with locals := insert 1 x t.locals) v locs =
    state_rel c l1 l2 s t v locs``,
  full_simp_tac(srw_ss())[state_rel_def] \\ eq_tac \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[lookup_insert,adjust_var_NEQ_1]
  \\ full_simp_tac(srw_ss())[inter_insert,domain_lookup,lookup_1_adjust_set]
  \\ metis_tac []);

val state_rel_insert_3 = prove(
  ``state_rel c l1 l2 s (t with locals := insert 3 x t.locals) v locs =
    state_rel c l1 l2 s t v locs``,
  full_simp_tac(srw_ss())[state_rel_def] \\ eq_tac \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[lookup_insert,adjust_var_NEQ_1]
  \\ asm_exists_tac \\ fs []
  \\ full_simp_tac(srw_ss())[inter_insert,domain_lookup,lookup_3_adjust_set]);

val state_rel_insert_3_1 = prove(
  ``state_rel c l1 l2 s (t with locals := insert 3 x (insert 1 y t.locals)) v locs =
    state_rel c l1 l2 s t v locs``,
  full_simp_tac(srw_ss())[state_rel_def] \\ eq_tac \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[lookup_insert,adjust_var_NEQ_1]
  \\ asm_exists_tac \\ fs []
  \\ full_simp_tac(srw_ss())[inter_insert,domain_lookup,
        lookup_3_adjust_set,lookup_1_adjust_set]);

val state_rel_inc_clock = prove(
  ``state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs ==>
    state_rel c l1 l2 (s with clock := s.clock + 1)
                      (t with clock := t.clock + 1) [] locs``,
  full_simp_tac(srw_ss())[state_rel_def]);

val dec_clock_inc_clock = prove(
  ``(dataSem$dec_clock (s with clock := s.clock + 1) = s) /\
    (wordSem$dec_clock (t with clock := t.clock + 1) = t)``,
  full_simp_tac(srw_ss())[dataSemTheory.dec_clock_def,wordSemTheory.dec_clock_def]
  \\ full_simp_tac(srw_ss())[dataSemTheory.state_component_equality]
  \\ full_simp_tac(srw_ss())[wordSemTheory.state_component_equality])

val word_gc_move_IMP_isWord = prove(
  ``word_gc_move c' (Word c,i,pa,old,m,dm) = (w1,i1,pa1,m1,c1) ==> isWord w1``,
  full_simp_tac(srw_ss())[word_gc_move_def,LET_DEF]
  \\ CONV_TAC (DEPTH_CONV PairRules.PBETA_CONV)
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[isWord_def]);

val word_gc_move_roots_IMP_FILTER = prove(
  ``!ws i pa old m dm ws2 i2 pa2 m2 c2 c.
      word_gc_move_roots c (ws,i,pa,old,m,dm) = (ws2,i2,pa2,m2,c2) ==>
      word_gc_move_roots c (FILTER isWord ws,i,pa,old,m,dm) =
                           (FILTER isWord ws2,i2,pa2,m2,c2)``,
  Induct \\ full_simp_tac(srw_ss())[word_gc_move_roots_def] \\ Cases \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[word_gc_move_roots_def]
  THEN1
   (srw_tac[][] \\ full_simp_tac(srw_ss())[LET_DEF] \\ imp_res_tac word_gc_move_IMP_isWord
    \\ Cases_on `word_gc_move_roots c' (ws,i1,pa1,old,m1,dm)` \\ full_simp_tac(srw_ss())[]
    \\ PairCases_on `r` \\ full_simp_tac(srw_ss())[] \\ res_tac \\ srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ srw_tac[][])
  \\ full_simp_tac(srw_ss())[isWord_def,word_gc_move_def,LET_DEF]
  \\ Cases_on `word_gc_move_roots c (ws,i,pa,old,m,dm)`
  \\ PairCases_on `r` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[isWord_def]);

val IMP_EQ_DISJ = METIS_PROVE [] ``(b1 ==> b2) <=> ~b1 \/ b2``

val word_gc_fun_IMP_FILTER = prove(
  ``word_gc_fun c (xs,m,dm,s) = SOME (stack1,m1,s1) ==>
    word_gc_fun c (FILTER isWord xs,m,dm,s) = SOME (FILTER isWord stack1,m1,s1)``,
  full_simp_tac(srw_ss())[word_gc_fun_def,LET_THM,word_gc_fun_def,word_full_gc_def]
  \\ rpt (pairarg_tac \\ full_simp_tac(srw_ss())[])
  \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[word_gc_move_roots_def,LET_THM]
  \\ rpt (pairarg_tac \\ full_simp_tac(srw_ss())[])
  \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac word_gc_move_roots_IMP_FILTER
  \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ rev_full_simp_tac(srw_ss())[] \\ full_simp_tac(srw_ss())[])

val loc_merge_def = Define `
  (loc_merge [] ys = []) /\
  (loc_merge (Loc l1 l2::xs) ys = Loc l1 l2::loc_merge xs ys) /\
  (loc_merge (Word w::xs) (y::ys) = y::loc_merge xs ys) /\
  (loc_merge (Word w::xs) [] = Word w::xs)`

val LENGTH_loc_merge = prove(
  ``!xs ys. LENGTH (loc_merge xs ys) = LENGTH xs``,
  Induct \\ Cases_on `ys` \\ full_simp_tac(srw_ss())[loc_merge_def]
  \\ Cases_on `h` \\ full_simp_tac(srw_ss())[loc_merge_def]
  \\ Cases_on `h'` \\ full_simp_tac(srw_ss())[loc_merge_def]);

val word_gc_move_roots_IMP_FILTER = prove(
  ``!ws i pa old m dm ws2 i2 pa2 m2 c2 c.
      word_gc_move_roots c (FILTER isWord ws,i,pa,old,m,dm) = (ws2,i2,pa2,m2,c2) ==>
      word_gc_move_roots c (ws,i,pa,old,m,dm) =
                           (loc_merge ws ws2,i2,pa2,m2,c2)``,
  Induct \\ full_simp_tac(srw_ss())[word_gc_move_roots_def,loc_merge_def]
  \\ reverse Cases \\ full_simp_tac(srw_ss())[isWord_def,loc_merge_def,LET_DEF]
  THEN1
   (full_simp_tac(srw_ss())[word_gc_move_def] \\ srw_tac[][]
    \\ Cases_on `word_gc_move_roots c (ws,i,pa,old,m,dm)` \\ full_simp_tac(srw_ss())[]
    \\ PairCases_on `r` \\ full_simp_tac(srw_ss())[] \\ res_tac \\ full_simp_tac(srw_ss())[])
  \\ full_simp_tac(srw_ss())[word_gc_move_roots_def,loc_merge_def] \\ srw_tac[][]
  \\ Cases_on `word_gc_move c' (Word c,i,pa,old,m,dm)`
  \\ PairCases_on `r` \\ full_simp_tac(srw_ss())[] \\ res_tac \\ full_simp_tac(srw_ss())[LET_DEF]
  \\ Cases_on `word_gc_move_roots c' (FILTER isWord ws,r0,r1,old,r2,dm)`
  \\ PairCases_on `r` \\ full_simp_tac(srw_ss())[] \\ res_tac \\ full_simp_tac(srw_ss())[LET_DEF] \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[loc_merge_def]);

val word_gc_fun_loc_merge = prove(
  ``word_gc_fun c (FILTER isWord xs,m,dm,s) = SOME (ys,m1,s1) ==>
    word_gc_fun c (xs,m,dm,s) = SOME (loc_merge xs ys,m1,s1)``,
  full_simp_tac(srw_ss())[word_gc_fun_def,LET_THM,word_gc_fun_def,word_full_gc_def]
  \\ rpt (pairarg_tac \\ full_simp_tac(srw_ss())[])
  \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[word_gc_move_roots_def,LET_THM]
  \\ rpt (pairarg_tac \\ full_simp_tac(srw_ss())[])
  \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac word_gc_move_roots_IMP_FILTER
  \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ rev_full_simp_tac(srw_ss())[] \\ full_simp_tac(srw_ss())[]);

val word_gc_fun_IMP = prove(
  ``word_gc_fun c (xs,m,dm,s) = SOME (ys,m1,s1) ==>
    FLOOKUP s1 AllocSize = FLOOKUP s AllocSize /\
    FLOOKUP s1 Handler = FLOOKUP s Handler /\
    Globals IN FDOM s1``,
  full_simp_tac(srw_ss())[IMP_EQ_DISJ,word_gc_fun_def] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[GSYM IMP_EQ_DISJ,word_gc_fun_def] \\ srw_tac[][]
  \\ UNABBREV_ALL_TAC \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ EVAL_TAC)

val word_gc_move_roots_IMP_EVERY2 = prove(
  ``!xs ys pa m i c1 m1 pa1 i1 old dm c.
      word_gc_move_roots c (xs,i,pa,old,m,dm) = (ys,i1,pa1,m1,c1) ==>
      EVERY2 (\x y. (isWord x <=> isWord y) /\ (~isWord x ==> x = y)) xs ys``,
  Induct \\ full_simp_tac(srw_ss())[word_gc_move_roots_def]
  \\ full_simp_tac(srw_ss())[IMP_EQ_DISJ,word_gc_fun_def] \\ srw_tac[][]
  \\ CCONTR_TAC \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[GSYM IMP_EQ_DISJ,word_gc_fun_def] \\ srw_tac[][] \\ res_tac
  \\ qpat_x_assum `word_gc_move c (h,i,pa,old,m,dm) = (w1,i1',pa1',m1',c1')` mp_tac
  \\ full_simp_tac(srw_ss())[] \\ Cases_on `h` \\ full_simp_tac(srw_ss())[word_gc_move_def] \\ srw_tac[][]
  \\ CCONTR_TAC \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[isWord_def]
  \\ UNABBREV_ALL_TAC \\ srw_tac[][] \\ pop_assum mp_tac \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ CCONTR_TAC \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[isWord_def]);

val word_gc_IMP_EVERY2 = prove(
  ``word_gc_fun c (xs,m,dm,st) = SOME (ys,m1,s1) ==>
    EVERY2 (\x y. (isWord x <=> isWord y) /\ (~isWord x ==> x = y)) xs ys``,
  full_simp_tac(srw_ss())[word_gc_fun_def,LET_THM,word_gc_fun_def,word_full_gc_def]
  \\ rpt (pairarg_tac \\ full_simp_tac(srw_ss())[])
  \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[word_gc_move_roots_def,LET_THM]
  \\ rpt (pairarg_tac \\ full_simp_tac(srw_ss())[])
  \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac word_gc_move_roots_IMP_EVERY2);

val word_gc_fun_LENGTH = store_thm("word_gc_fun_LENGTH",
  ``word_gc_fun c (xs,m,dm,s) = SOME (zs,m1,s1) ==> LENGTH xs = LENGTH zs``,
  srw_tac[][] \\ drule word_gc_IMP_EVERY2 \\ srw_tac[][] \\ imp_res_tac EVERY2_LENGTH);

val gc_fun_ok_word_gc_fun = store_thm("gc_fun_ok_word_gc_fun",
  ``gc_fun_ok (word_gc_fun c1)``,
  fs [gc_fun_ok_def] \\ rpt gen_tac \\ strip_tac
  \\ imp_res_tac word_gc_fun_LENGTH \\ fs []
  \\ imp_res_tac word_gc_fun_IMP
  \\ fs [FLOOKUP_DEF]
  \\ fs [word_gc_fun_def]
  \\ pairarg_tac \\ fs []
  \\ fs [DOMSUB_FAPPLY_THM]
  \\ rpt var_eq_tac \\ fs []
  \\ fs [word_gc_fun_assum_def,DOMSUB_FAPPLY_THM]
  \\ fs [fmap_EXT,FUPDATE_LIST,EXTENSION]
  \\ conj_tac THEN1 metis_tac []
  \\ fs [FAPPLY_FUPDATE_THM,DOMSUB_FAPPLY_THM]
  \\ rw [] \\ fs []);

val word_gc_fun_APPEND_IMP = prove(
  ``word_gc_fun c (xs ++ ys,m,dm,s) = SOME (zs,m1,s1) ==>
    ?zs1 zs2. zs = zs1 ++ zs2 /\ LENGTH xs = LENGTH zs1 /\ LENGTH ys = LENGTH zs2``,
  srw_tac[][] \\ imp_res_tac word_gc_fun_LENGTH \\ full_simp_tac(srw_ss())[LENGTH_APPEND]
  \\ pop_assum mp_tac \\ pop_assum (K all_tac)
  \\ qspec_tac (`zs`,`zs`) \\ qspec_tac (`ys`,`ys`) \\ qspec_tac (`xs`,`xs`)
  \\ Induct \\ full_simp_tac(srw_ss())[] \\ Cases_on `zs` \\ full_simp_tac(srw_ss())[LENGTH_NIL] \\ srw_tac[][]
  \\ once_rewrite_tac [EQ_SYM_EQ] \\ full_simp_tac(srw_ss())[LENGTH_NIL]
  \\ full_simp_tac(srw_ss())[ADD_CLAUSES] \\ res_tac
  \\ full_simp_tac(srw_ss())[] \\ Q.LIST_EXISTS_TAC [`h::zs1`,`zs2`] \\ full_simp_tac(srw_ss())[]);

val IMP_loc_merge_APPEND = prove(
  ``!ts qs xs ys.
      LENGTH (FILTER isWord ts) = LENGTH qs ==>
      loc_merge (ts ++ xs) (qs ++ ys) = loc_merge ts qs ++ loc_merge xs ys``,
  Induct \\ full_simp_tac(srw_ss())[] THEN1 (Cases_on `qs` \\ full_simp_tac(srw_ss())[LENGTH,loc_merge_def])
  \\ Cases \\ full_simp_tac(srw_ss())[isWord_def,loc_merge_def]
  \\ Cases \\ full_simp_tac(srw_ss())[loc_merge_def]) |> SPEC_ALL;

val TAKE_DROP_loc_merge_APPEND = prove(
  ``TAKE (LENGTH q) (loc_merge (MAP SND q) xs ++ ys) = loc_merge (MAP SND q) xs /\
    DROP (LENGTH q) (loc_merge (MAP SND q) xs ++ ys) = ys``,
  `LENGTH q = LENGTH (loc_merge (MAP SND q) xs)` by full_simp_tac(srw_ss())[LENGTH_loc_merge]
  \\ full_simp_tac(srw_ss())[TAKE_LENGTH_APPEND,DROP_LENGTH_APPEND]);

val loc_merge_NIL = prove(
  ``!xs. loc_merge xs [] = xs``,
  Induct \\ full_simp_tac(srw_ss())[loc_merge_def] \\ Cases \\ full_simp_tac(srw_ss())[loc_merge_def]);

val loc_merge_APPEND = prove(
  ``!xs1 xs2 ys.
      ?zs1 zs2. loc_merge (xs1 ++ xs2) ys = zs1 ++ zs2 /\
                LENGTH zs1 = LENGTH xs1 /\ LENGTH xs2 = LENGTH xs2 /\
                ?ts. loc_merge xs2 ts = zs2``,
  Induct \\ full_simp_tac(srw_ss())[loc_merge_def,LENGTH_NIL,LENGTH_loc_merge] THEN1 (metis_tac [])
  \\ Cases THEN1
   (Cases_on `ys` \\ full_simp_tac(srw_ss())[loc_merge_def] \\ srw_tac[][]
    THEN1 (Q.LIST_EXISTS_TAC [`Word c::xs1`,`xs2`] \\ full_simp_tac(srw_ss())[]
           \\ qexists_tac `[]` \\ full_simp_tac(srw_ss())[loc_merge_NIL])
    \\ pop_assum (qspecl_then [`xs2`,`t`] strip_assume_tac)
    \\ full_simp_tac(srw_ss())[] \\ Q.LIST_EXISTS_TAC [`h::zs1`,`zs2`] \\ full_simp_tac(srw_ss())[] \\ metis_tac [])
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[loc_merge_def]
  \\ pop_assum (qspecl_then [`xs2`,`ys`] strip_assume_tac)
  \\ full_simp_tac(srw_ss())[] \\ Q.LIST_EXISTS_TAC [`Loc n n0::zs1`,`zs2`] \\ full_simp_tac(srw_ss())[] \\ metis_tac [])

val EVERY2_loc_merge = prove(
  ``!xs ys. EVERY2 (\x y. (isWord y ==> isWord x) /\
                          (~isWord x ==> x = y)) xs (loc_merge xs ys)``,
  Induct \\ full_simp_tac(srw_ss())[loc_merge_def,LENGTH_NIL,LENGTH_loc_merge] \\ Cases
  \\ full_simp_tac(srw_ss())[loc_merge_def] \\ Cases_on `ys`
  \\ full_simp_tac(srw_ss())[loc_merge_def,GSYM EVERY2_refl,isWord_def])

val dec_stack_loc_merge_enc_stack = prove(
  ``!xs ys. ?ss. dec_stack (loc_merge (enc_stack xs) ys) xs = SOME ss``,
  Induct \\ full_simp_tac(srw_ss())[wordSemTheory.enc_stack_def,
    loc_merge_def,wordSemTheory.dec_stack_def]
  \\ Cases \\ Cases_on `o'` \\ full_simp_tac(srw_ss())[] \\ TRY (PairCases_on `x`)
  \\ full_simp_tac(srw_ss())[wordSemTheory.enc_stack_def] \\ srw_tac[][]
  \\ qspecl_then [`MAP SND l`,`enc_stack xs`,`ys`] mp_tac loc_merge_APPEND
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ full_simp_tac(srw_ss())[wordSemTheory.dec_stack_def]
  \\ pop_assum (fn th => full_simp_tac(srw_ss())[GSYM th])
  \\ full_simp_tac(srw_ss())[DROP_LENGTH_APPEND]
  \\ first_assum (qspec_then `ts` strip_assume_tac) \\ full_simp_tac(srw_ss())[]
  \\ decide_tac);

val ALOOKUP_ZIP = prove(
  ``!l zs1.
      ALOOKUP l (0:num) = SOME (Loc q r) /\
      LIST_REL (λx y. (isWord y ⇒ isWord x) ∧
        (¬isWord x ⇒ x = y)) (MAP SND l) zs1 ==>
      ALOOKUP (ZIP (MAP FST l,zs1)) 0 = SOME (Loc q r)``,
  Induct \\ full_simp_tac(srw_ss())[] \\ Cases \\ full_simp_tac(srw_ss())[ALOOKUP_def,PULL_EXISTS]
  \\ Cases_on `q' = 0` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[isWord_def] \\ srw_tac[][]);

val stack_rel_dec_stack_IMP_stack_rel = prove(
  ``!xs ys ts stack locs.
      LIST_REL stack_rel ts xs /\ LIST_REL contains_loc xs locs /\
      dec_stack (loc_merge (enc_stack xs) ys) xs = SOME stack ==>
      LIST_REL stack_rel ts stack /\ LIST_REL contains_loc stack locs``,
  Induct_on `ts` \\ Cases_on `xs` \\ full_simp_tac(srw_ss())[]
  THEN1 (full_simp_tac(srw_ss())[wordSemTheory.enc_stack_def,loc_merge_def,wordSemTheory.dec_stack_def])
  \\ full_simp_tac(srw_ss())[PULL_EXISTS] \\ srw_tac[][]
  \\ Cases_on `h` \\ Cases_on `o'` \\ TRY (PairCases_on `x`) \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[wordSemTheory.enc_stack_def,wordSemTheory.dec_stack_def]
  \\ qspecl_then [`MAP SND l`,`enc_stack t`,`ys`] mp_tac loc_merge_APPEND
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ pop_assum (fn th => full_simp_tac(srw_ss())[GSYM th] THEN assume_tac th)
  \\ full_simp_tac(srw_ss())[DROP_LENGTH_APPEND,TAKE_LENGTH_APPEND]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[]
  \\ pop_assum (fn th => full_simp_tac(srw_ss())[GSYM th])
  \\ res_tac \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `h'` \\ full_simp_tac(srw_ss())[stack_rel_def]
  \\ full_simp_tac(srw_ss())[lookup_fromAList,IS_SOME_ALOOKUP_EQ]
  \\ full_simp_tac(srw_ss())[EVERY_MEM,FORALL_PROD] \\ Cases_on `y`
  \\ full_simp_tac(srw_ss())[contains_loc_def]
  \\ qspecl_then [`MAP SND l ++ enc_stack t`,`ys`] mp_tac EVERY2_loc_merge
  \\ full_simp_tac(srw_ss())[] \\ strip_tac
  \\ `LENGTH (MAP SND l) = LENGTH zs1` by full_simp_tac(srw_ss())[]
  \\ imp_res_tac LIST_REL_APPEND_IMP \\ full_simp_tac(srw_ss())[MAP_ZIP]
  \\ full_simp_tac(srw_ss())[AND_IMP_INTRO]
  \\ `ALOOKUP (ZIP (MAP FST l,zs1)) 0 = SOME (Loc q r)` by
   (`LENGTH (MAP SND l) = LENGTH zs1` by full_simp_tac(srw_ss())[]
    \\ imp_res_tac LIST_REL_APPEND_IMP \\ full_simp_tac(srw_ss())[MAP_ZIP]
    \\ imp_res_tac ALOOKUP_ZIP \\ full_simp_tac(srw_ss())[] \\ NO_TAC)
  \\ full_simp_tac(srw_ss())[] \\ NTAC 3 strip_tac \\ first_x_assum match_mp_tac
  \\ rev_full_simp_tac(srw_ss())[MEM_ZIP] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[EL_MAP]
  \\ Q.MATCH_ASSUM_RENAME_TAC `isWord (EL k zs1)`
  \\ full_simp_tac(srw_ss())[MEM_EL,PULL_EXISTS] \\ asm_exists_tac \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[FST_PAIR_EQ]
  \\ imp_res_tac EVERY2_IMP_EL \\ rev_full_simp_tac(srw_ss())[EL_MAP]);

val join_env_NIL = prove(
  ``join_env s [] = []``,
  full_simp_tac(srw_ss())[join_env_def]);

val join_env_CONS = prove(
  ``join_env s ((n,v)::xs) =
    if n <> 0 /\ EVEN n then
      (THE (lookup ((n - 2) DIV 2) s),v)::join_env s xs
    else join_env s xs``,
  full_simp_tac(srw_ss())[join_env_def] \\ srw_tac[][]);

val FILTER_enc_stack_lemma = prove(
  ``!xs ys.
      LIST_REL stack_rel xs ys ==>
      FILTER isWord (MAP SND (flat xs ys)) =
      FILTER isWord (enc_stack ys)``,
  Induct \\ Cases_on `ys`
  \\ full_simp_tac(srw_ss())[stack_rel_def,wordSemTheory.enc_stack_def,flat_def]
  \\ Cases \\ Cases_on `h` \\ full_simp_tac(srw_ss())[] \\ Cases_on `o'`
  \\ TRY (PairCases_on `x`) \\ full_simp_tac(srw_ss())[stack_rel_def] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[wordSemTheory.enc_stack_def,flat_def,FILTER_APPEND]
  \\ qpat_x_assum `EVERY (\(x1,x2). isWord x2 ==> x1 <> 0 /\ EVEN x1) l` mp_tac
  \\ rpt (pop_assum (K all_tac))
  \\ Induct_on `l` \\ full_simp_tac(srw_ss())[] \\ full_simp_tac(srw_ss())[join_env_NIL]
  \\ Cases \\ full_simp_tac(srw_ss())[join_env_CONS] \\ srw_tac[][]);

val stack_rel_simp = prove(
  ``(stack_rel (Env s) y <=>
     ?vs. stack_rel (Env s) y /\ (y = StackFrame vs NONE)) /\
    (stack_rel (Exc s n) y <=>
     ?vs x1 x2 x3. stack_rel (Exc s n) y /\ (y = StackFrame vs (SOME (x1,x2,x3))))``,
  Cases_on `y` \\ full_simp_tac(srw_ss())[stack_rel_def] \\ Cases_on `o'`
  \\ full_simp_tac(srw_ss())[stack_rel_def] \\ PairCases_on `x`
  \\ full_simp_tac(srw_ss())[stack_rel_def,CONJ_ASSOC]);

val join_env_EQ_ZIP = prove(
  ``!vs s zs1.
      EVERY (\(x1,x2). isWord x2 ==> x1 <> 0 /\ EVEN x1) vs /\
      LENGTH (join_env s vs) = LENGTH zs1 /\
      LIST_REL (\x y. isWord x = isWord y /\ (~isWord x ==> x = y))
         (MAP SND (join_env s vs)) zs1 ==>
      join_env s
        (ZIP (MAP FST vs,loc_merge (MAP SND vs) (FILTER isWord zs1))) =
      ZIP (MAP FST (join_env s vs),zs1)``,
  Induct \\ simp [join_env_NIL,loc_merge_def] \\ rpt strip_tac
  \\ Cases_on `h` \\ simp [] \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `r` \\ full_simp_tac(srw_ss())[isWord_def]
  \\ full_simp_tac(srw_ss())[loc_merge_def] \\ full_simp_tac(srw_ss())[join_env_CONS] \\ rev_full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ rev_full_simp_tac(srw_ss())[isWord_def] \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `y` \\ full_simp_tac(srw_ss())[loc_merge_def,join_env_CONS,isWord_def]);

val LENGTH_MAP_SND_join_env_IMP = prove(
  ``!vs zs1 s.
      LIST_REL (\x y. (isWord x = isWord y) /\ (~isWord x ==> x = y))
        (MAP SND (join_env s vs)) zs1 /\
      EVERY (\(x1,x2). isWord x2 ==> x1 <> 0 /\ EVEN x1) vs /\
      LENGTH (join_env s vs) = LENGTH zs1 ==>
      LENGTH (FILTER isWord (MAP SND vs)) = LENGTH (FILTER isWord zs1)``,
  Induct \\ rpt strip_tac THEN1
   (pop_assum mp_tac \\ simp [join_env_NIL]
    \\ Cases_on `zs1` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][])
  \\ Cases_on `h` \\ full_simp_tac(srw_ss())[join_env_CONS] \\ srw_tac[][]
  THEN1 (full_simp_tac(srw_ss())[] \\ rev_full_simp_tac(srw_ss())[] \\ first_assum match_mp_tac \\ metis_tac[])
  \\ full_simp_tac(srw_ss())[] \\ Cases_on `q <> 0 /\ EVEN q`
  \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ metis_tac [])

val lemma1 = prove(``(y1 = y2) /\ (x1 = x2) ==> (f x1 y1 = f x2 y2)``,full_simp_tac(srw_ss())[]);

val word_gc_fun_EL_lemma = prove(
  ``!xs ys stack1 m dm st m1 s1 stack.
      LIST_REL stack_rel xs stack /\
      EVERY2 (\x y. isWord x = isWord y /\ (~isWord x ==> x = y))
         (MAP SND (flat xs ys)) stack1 /\
      dec_stack (loc_merge (enc_stack ys) (FILTER isWord stack1)) ys =
        SOME stack /\ LIST_REL stack_rel xs ys ==>
      (flat xs stack =
       ZIP (MAP FST (flat xs ys),stack1))``,
  Induct THEN1 (EVAL_TAC \\ full_simp_tac(srw_ss())[] \\ EVAL_TAC \\ srw_tac[][] \\ srw_tac[][flat_def])
  \\ Cases_on `h` \\ full_simp_tac(srw_ss())[] \\ once_rewrite_tac [stack_rel_simp]
  \\ full_simp_tac(srw_ss())[PULL_EXISTS,stack_rel_def,flat_def,wordSemTheory.enc_stack_def]
  \\ srw_tac[][] \\ imp_res_tac EVERY2_APPEND_IMP \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[FILTER_APPEND]
  \\ `LENGTH (FILTER isWord (MAP SND vs')) = LENGTH (FILTER isWord zs1)` by
   (imp_res_tac EVERY2_LENGTH \\ full_simp_tac(srw_ss())[]
    \\ imp_res_tac LENGTH_MAP_SND_join_env_IMP)
  \\ imp_res_tac IMP_loc_merge_APPEND \\ full_simp_tac(srw_ss())[]
  \\ qpat_x_assum `dec_stack xx dd = SOME yy` mp_tac
  \\ full_simp_tac(srw_ss())[wordSemTheory.dec_stack_def]
  \\ full_simp_tac(srw_ss())[TAKE_DROP_loc_merge_APPEND,LENGTH_loc_merge,DECIDE ``~(n+m<n:num)``]
  \\ CASE_TAC \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[flat_def] \\ imp_res_tac EVERY2_LENGTH \\ full_simp_tac(srw_ss())[GSYM ZIP_APPEND]
  \\ match_mp_tac lemma1
  \\ rpt strip_tac \\ TRY (first_x_assum match_mp_tac \\ full_simp_tac(srw_ss())[])
  \\ TRY (match_mp_tac join_env_EQ_ZIP) \\ full_simp_tac(srw_ss())[]) |> SPEC_ALL;

val state_rel_gc = prove(
  ``state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs ==>
    FLOOKUP t.store AllocSize = SOME (Word (alloc_size k)) /\
    s.locals = LN /\
    t.locals = LS (Loc l1 l2) ==>
    ?t2 wl m st w1 w2 stack.
      t.gc_fun (enc_stack t.stack,t.memory,t.mdomain,t.store) =
        SOME (wl,m,st) /\
      dec_stack wl t.stack = SOME stack /\
      FLOOKUP st AllocSize = SOME (Word (alloc_size k)) /\
      state_rel c l1 l2 (s with space := 0)
        (t with <|stack := stack; store := st; memory := m|>) [] locs``,
  full_simp_tac(srw_ss())[state_rel_def] \\ srw_tac[][] \\ rev_full_simp_tac(srw_ss())[] \\ full_simp_tac(srw_ss())[] \\ rev_full_simp_tac(srw_ss())[lookup_def] \\ srw_tac[][]
  \\ qhdtm_x_assum `word_ml_inv` mp_tac
  \\ Q.PAT_ABBREV_TAC `pat = join_env LN _` \\ srw_tac[][]
  \\ `pat = []` by (UNABBREV_ALL_TAC \\ EVAL_TAC) \\ full_simp_tac(srw_ss())[]
  \\ rev_full_simp_tac(srw_ss())[] \\ full_simp_tac(srw_ss())[] \\ pop_assum (K all_tac)
  \\ first_x_assum (fn th1 => first_x_assum (fn th2 => first_x_assum (fn th3 =>
       mp_tac (MATCH_MP word_gc_fun_correct (CONJ th1 (CONJ th2 th3))))))
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac word_gc_fun_IMP_FILTER
  \\ imp_res_tac FILTER_enc_stack_lemma \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac word_gc_fun_loc_merge \\ full_simp_tac(srw_ss())[FILTER_APPEND]
  \\ imp_res_tac word_gc_fun_IMP \\ full_simp_tac(srw_ss())[]
  \\ `?stack. dec_stack (loc_merge (enc_stack t.stack) (FILTER isWord stack1))
        t.stack = SOME stack` by metis_tac [dec_stack_loc_merge_enc_stack]
  \\ asm_exists_tac \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac stack_rel_dec_stack_IMP_stack_rel \\ full_simp_tac(srw_ss())[]
  \\ asm_exists_tac \\ full_simp_tac(srw_ss())[]
  \\ first_x_assum (fn th => mp_tac th THEN match_mp_tac word_ml_inv_rearrange)
  \\ full_simp_tac(srw_ss())[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ disj2_tac
  \\ pop_assum mp_tac
  \\ match_mp_tac (METIS_PROVE [] ``x=y==>(x==>y)``)
  \\ AP_TERM_TAC
  \\ AP_TERM_TAC
  \\ match_mp_tac (GEN_ALL word_gc_fun_EL_lemma)
  \\ imp_res_tac word_gc_IMP_EVERY2 \\ full_simp_tac(srw_ss())[]);

val gc_lemma = prove(
  ``let t0 = call_env [Loc l1 l2] (push_env y
        (NONE:(num # 'a wordLang$prog # num # num) option) t) in
      dataSem$cut_env names (s:'ffi dataSem$state).locals = SOME x /\
      state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs /\
      FLOOKUP t.store AllocSize = SOME (Word (alloc_size k)) /\
      wordSem$cut_env (adjust_set names) t.locals = SOME y ==>
      ?t2 wl m st w1 w2 stack.
        t0.gc_fun (enc_stack t0.stack,t0.memory,t0.mdomain,t0.store) =
          SOME (wl,m,st) /\
        dec_stack wl t0.stack = SOME stack /\
        pop_env (t0 with <|stack := stack; store := st; memory := m|>) = SOME t2 /\
        FLOOKUP t2.store AllocSize = SOME (Word (alloc_size k)) /\
        state_rel c l1 l2 (s with <| locals := x; space := 0 |>) t2 [] locs``,
  srw_tac[][] \\ full_simp_tac(srw_ss())[LET_DEF]
  \\ Q.UNABBREV_TAC `t0` \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac (state_rel_call_env_push_env
      |> Q.SPEC `NONE` |> Q.INST [`args`|->`[]`] |> GEN_ALL
      |> SIMP_RULE std_ss [MAP,get_vars_def,wordSemTheory.get_vars_def]
      |> SPEC_ALL |> REWRITE_RULE [GSYM AND_IMP_INTRO]
      |> (fn th => MATCH_MP th (UNDISCH state_rel_inc_clock))
      |> SIMP_RULE (srw_ss()) [dec_clock_inc_clock] |> DISCH_ALL)
  \\ full_simp_tac(srw_ss())[]
  \\ pop_assum (qspecl_then [`l1`,`l2`] mp_tac) \\ srw_tac[][]
  \\ pop_assum (mp_tac o MATCH_MP state_rel_gc)
  \\ impl_tac THEN1
   (full_simp_tac(srw_ss())[wordSemTheory.call_env_def,call_env_def,
        wordSemTheory.push_env_def,fromList_def]
    \\ Cases_on `env_to_list y t.permute` \\ full_simp_tac(srw_ss())[LET_DEF]
    \\ full_simp_tac(srw_ss())[fromList2_def,Once insert_def])
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[wordSemTheory.call_env_def]
  \\ pop_assum (mp_tac o MATCH_MP
      (state_rel_pop_env_IMP |> REWRITE_RULE [GSYM AND_IMP_INTRO]
         |> Q.GEN `s2`)) \\ srw_tac[][]
  \\ pop_assum (qspec_then `s with <| locals := x ; space := 0 |>` mp_tac)
  \\ impl_tac THEN1
   (full_simp_tac(srw_ss())[pop_env_def,push_env_def,call_env_def,
      dataSemTheory.state_component_equality])
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[wordSemTheory.pop_env_def,wordSemTheory.push_env_def]
  \\ Cases_on `env_to_list y t.permute` \\ full_simp_tac(srw_ss())[LET_DEF]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]);

val gc_add_call_env = prove(
  ``(case gc (push_env y NONE t5) of
     | NONE => (SOME Error,x)
     | SOME s' => case pop_env s' of
                  | NONE => (SOME Error, call_env [] s')
                  | SOME s' => f s') = (res,t) ==>
    (case gc (call_env [Loc l1 l2] (push_env y NONE t5)) of
     | NONE => (SOME Error,x)
     | SOME s' => case pop_env s' of
                  | NONE => (SOME Error, call_env [] s')
                  | SOME s' => f s') = (res,t)``,
  full_simp_tac(srw_ss())[wordSemTheory.gc_def,wordSemTheory.call_env_def,LET_DEF,
      wordSemTheory.push_env_def]
  \\ Cases_on `env_to_list y t5.permute` \\ full_simp_tac(srw_ss())[LET_DEF]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[wordSemTheory.pop_env_def]);

val has_space_state_rel = prove(
  ``has_space (Word ((alloc_size k):'a word)) (r:('a,'ffi) state) = SOME T /\
    state_rel c l1 l2 s r [] locs ==>
    state_rel c l1 l2 (s with space := k) r [] locs``,
  full_simp_tac(srw_ss())[state_rel_def] \\ srw_tac[][]
  \\ asm_exists_tac \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[heap_in_memory_store_def,wordSemTheory.has_space_def]
  \\ full_simp_tac(srw_ss())[GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
  \\ full_simp_tac(srw_ss())[alloc_size_def,bytes_in_word_def]
  \\ `(sp * (dimindex (:'a) DIV 8)) + 1 < dimword (:'a)` by
   (imp_res_tac word_ml_inv_SP_LIMIT
    \\ match_mp_tac LESS_EQ_LESS_TRANS
    \\ once_rewrite_tac [CONJ_COMM]
    \\ asm_exists_tac \\ full_simp_tac(srw_ss())[])
  \\ `(sp * (dimindex (:'a) DIV 8)) < dimword (:'a)` by decide_tac
  \\ every_case_tac \\ full_simp_tac(srw_ss())[word_mul_n2w]
  \\ full_simp_tac(srw_ss())[good_dimindex_def]
  \\ full_simp_tac(srw_ss())[w2n_minus1] \\ rev_full_simp_tac(srw_ss())[]
  \\ `F` by decide_tac);

val evaluate_IMP_inc_clock = prove(
  ``evaluate (q,t) = (NONE,t1) ==>
    evaluate (q,inc_clock ck t) = (NONE,inc_clock ck t1)``,
  srw_tac[][inc_clock_def] \\ match_mp_tac evaluate_add_clock
  \\ full_simp_tac(srw_ss())[]);

val evaluate_IMP_inc_clock_Ex = prove(
  ``evaluate (q,t) = (SOME (Exception x y),t1) ==>
    evaluate (q,inc_clock ck t) = (SOME (Exception x y),inc_clock ck t1)``,
  srw_tac[][inc_clock_def] \\ match_mp_tac evaluate_add_clock
  \\ full_simp_tac(srw_ss())[]);

val get_var_inc_clock = prove(
  ``get_var n (inc_clock k s) = get_var n s``,
  full_simp_tac(srw_ss())[wordSemTheory.get_var_def,inc_clock_def]);

val get_vars_inc_clock = prove(
  ``get_vars n (inc_clock k s) = get_vars n s``,
  Induct_on `n` \\ full_simp_tac(srw_ss())[wordSemTheory.get_vars_def]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[get_var_inc_clock]);

val set_var_inc_clock = store_thm("set_var_inc_clock",
  ``set_var n x (inc_clock ck t) = inc_clock ck (set_var n x t)``,
  full_simp_tac(srw_ss())[wordSemTheory.set_var_def,inc_clock_def]);

val do_app = LIST_CONJ [dataSemTheory.do_app_def,do_space_def,
  data_spaceTheory.op_space_req_def,
  bvi_to_dataTheory.op_space_reset_def, bviSemTheory.do_app_def,
  bviSemTheory.do_app_aux_def, bvlSemTheory.do_app_def]

val w2n_minus_1_LESS_EQ = store_thm("w2n_minus_1_LESS_EQ",
  ``(w2n (-1w:'a word) <= w2n (w:'a word)) <=> w + 1w = 0w``,
  fs [word_2comp_n2w]
  \\ Cases_on `w` \\ fs [word_add_n2w]
  \\ `n + 1 <= dimword (:'a)` by decide_tac
  \\ Cases_on `dimword (:'a) = n + 1` \\ fs []);

val bytes_in_word_ADD_1_NOT_ZERO = prove(
  ``good_dimindex (:'a) ==>
    bytes_in_word * w + 1w <> 0w:'a word``,
  rpt strip_tac
  \\ `(bytes_in_word * w + 1w) ' 0 = (0w:'a word) ' 0` by metis_tac []
  \\ fs [WORD_ADD_BIT0,word_index,WORD_MUL_BIT0]
  \\ rfs [bytes_in_word_def,EVAL ``good_dimindex (:α)``,word_index]
  \\ rfs [bytes_in_word_def,EVAL ``good_dimindex (:α)``,word_index]);

val alloc_lemma = store_thm("alloc_lemma",
  ``state_rel c l1 l2 s (t:('a,'ffi)wordSem$state) [] locs /\
    dataSem$cut_env names s.locals = SOME x /\
    alloc (alloc_size k) (adjust_set names)
        (t with locals := insert 1 (Word (alloc_size k)) t.locals) =
      ((q:'a result option),r) ==>
    (q = SOME NotEnoughSpace ⇒ r.ffi = s.ffi) ∧
    (q ≠ SOME NotEnoughSpace ⇒
     state_rel c l1 l2 (s with <|locals := x; space := k|>) r [] locs ∧
     alloc_size k <> -1w:'a word /\
     q = NONE)``,
  strip_tac
  \\ full_simp_tac(srw_ss())[wordSemTheory.alloc_def,
       LET_DEF,addressTheory.CONTAINER_def]
  \\ Q.ABBREV_TAC `t5 = (set_store AllocSize (Word (alloc_size k))
               (t with locals := insert 1 (Word (alloc_size k)) t.locals))`
  \\ imp_res_tac cut_env_IMP_cut_env
  \\ full_simp_tac(srw_ss())[cut_env_adjust_set_insert_1]
  \\ first_x_assum (assume_tac o HO_MATCH_MP gc_add_call_env)
  \\ `FLOOKUP t5.store AllocSize = SOME (Word (alloc_size k)) /\
      cut_env (adjust_set names) t5.locals = SOME y /\
      state_rel c l1 l2 s t5 [] locs` by
   (UNABBREV_ALL_TAC \\ full_simp_tac(srw_ss())[state_rel_set_store_AllocSize]
    \\ full_simp_tac(srw_ss())[cut_env_adjust_set_insert_1,
         wordSemTheory.set_store_def] \\ srw_tac[][]
    \\ full_simp_tac(srw_ss())[SUBSET_DEF,state_rel_insert_1,FLOOKUP_DEF])
  \\ strip_tac
  \\ mp_tac (gc_lemma |> Q.INST [`t`|->`t5`] |> SIMP_RULE std_ss [LET_DEF])
  \\ full_simp_tac(srw_ss())[] \\ strip_tac \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[wordSemTheory.gc_def,wordSemTheory.call_env_def,
         wordSemTheory.push_env_def]
  \\ Cases_on `env_to_list y t5.permute` \\ full_simp_tac(srw_ss())[LET_DEF]
  \\ `IS_SOME (has_space (Word (alloc_size k):'a word_loc) t2)` by
       full_simp_tac(srw_ss())[wordSemTheory.has_space_def,
          state_rel_def,heap_in_memory_store_def]
  \\ Cases_on `has_space (Word (alloc_size k):'a word_loc) t2`
  \\ full_simp_tac(srw_ss())[]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[]
  \\ rev_full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ imp_res_tac has_space_state_rel \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac dataPropsTheory.pop_env_const \\ full_simp_tac(srw_ss())[]
  \\ imp_res_tac wordPropsTheory.pop_env_const \\ full_simp_tac(srw_ss())[]
  \\ UNABBREV_ALL_TAC
  \\ full_simp_tac(srw_ss())[wordSemTheory.set_store_def,state_rel_def]
  \\ qpat_assum `has_space (Word (alloc_size k)) r = SOME T` assume_tac
  \\ CCONTR_TAC \\ fs [wordSemTheory.has_space_def]
  \\ rfs [heap_in_memory_store_def,FLOOKUP_DEF,FAPPLY_FUPDATE_THM]
  \\ rfs [WORD_LEFT_ADD_DISTRIB,GSYM word_add_n2w,w2n_minus_1_LESS_EQ]
  \\ rfs [bytes_in_word_ADD_1_NOT_ZERO])

val evaluate_GiveUp = store_thm("evaluate_GiveUp",
  ``state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs ==>
    ?r. evaluate (GiveUp,t) = (SOME NotEnoughSpace,r) /\
        r.ffi = s.ffi /\ t.ffi = s.ffi``,
  fs [GiveUp_def,wordSemTheory.evaluate_def,wordSemTheory.word_exp_def]
  \\ strip_tac
  \\ Cases_on `alloc (-1w) (insert 0 () LN) (set_var 1 (Word (-1w)) t)
                  :'a result option # ('a,'ffi) wordSem$state`
  \\ fs [wordSemTheory.set_var_def]
  \\ `-1w = alloc_size (dimword (:'a)):'a word` by
   (fs [alloc_size_def,state_rel_def]
    \\ fs [labPropsTheory.good_dimindex_def,dimword_def] \\ rw [])
  \\ pop_assum (fn th => fs [th])
  \\ drule (alloc_lemma |> Q.INST [`names`|->`LN`,`k`|->`dimword(:'a)`] |> GEN_ALL)
  \\ fs [dataSemTheory.cut_env_def,set_var_def]
  \\ Cases_on `q = SOME NotEnoughSpace` \\ fs []
  \\ CCONTR_TAC \\ fs []
  \\ rpt var_eq_tac
  \\ fs [state_rel_def]
  \\ fs [word_ml_inv_def,abs_ml_inv_def,unused_space_inv_def,heap_ok_def]
  \\ imp_res_tac heap_lookup_SPLIT \\ fs [heap_length_APPEND]
  \\ fs [heap_length_def,el_length_def]
  \\ fs [labPropsTheory.good_dimindex_def,dimword_def] \\ rw []
  \\ rfs [] \\ fs []);

val state_rel_cut_IMP = store_thm("state_rel_cut_IMP",
  ``state_rel c l1 l2 s t [] locs /\ cut_state_opt names_opt s = SOME x ==>
    state_rel c l1 l2 x t [] locs``,
  Cases_on `names_opt` \\ fs [dataSemTheory.cut_state_opt_def]
  THEN1 (rw [] \\ fs [])
  \\ fs [dataSemTheory.cut_state_def]
  \\ every_case_tac \\ fs [] \\ rw [] \\ fs []
  \\ imp_res_tac state_rel_cut_env);

val get_vars_SING = store_thm("get_vars_SING",
  ``dataSem$get_vars args s = SOME [w] ==> ?y. args = [y]``,
  Cases_on `args` \\ fs [get_vars_def]
  \\ every_case_tac \\ fs [] \\ rw [] \\ fs []
  \\ Cases_on `t` \\ fs [get_vars_def]
  \\ every_case_tac \\ fs [] \\ rw [] \\ fs []);

val clean_tac = rpt var_eq_tac \\ rpt (qpat_x_assum `T` kall_tac)
fun rpt_drule th = drule (th |> GEN_ALL) \\ rpt (disch_then drule \\ fs [])

val eval_tac = fs [wordSemTheory.evaluate_def,
  wordSemTheory.word_exp_def, wordSemTheory.set_var_def, set_var_def,
  bvi_to_data_def, wordSemTheory.the_words_def,
  bviSemTheory.bvl_to_bvi_def, data_to_bvi_def,
  bviSemTheory.bvi_to_bvl_def,wordSemTheory.mem_load_def,
  wordLangTheory.word_op_def, wordSemTheory.word_sh_def,
  wordLangTheory.num_exp_def]

val INT_EQ_NUM_LEMMA = store_thm("INT_EQ_NUM_LEMMA",
  ``0 <= (i:int) <=> ?index. i = & index``,
  Cases_on `i` \\ fs []);

val get_vars_2_IMP = store_thm("get_vars_2_IMP",
  ``(wordSem$get_vars [x1;x2] s = SOME [v1;v2]) ==>
    get_var x1 s = SOME v1 /\
    get_var x2 s = SOME v2``,
  fs [wordSemTheory.get_vars_def] \\ every_case_tac \\ fs []);

val get_vars_3_IMP = store_thm("get_vars_3_IMP",
  ``(wordSem$get_vars [x1;x2;x3] s = SOME [v1;v2;v3]) ==>
    get_var x1 s = SOME v1 /\
    get_var x2 s = SOME v2 /\
    get_var x3 s = SOME v3``,
  fs [wordSemTheory.get_vars_def] \\ every_case_tac \\ fs []);

val memory_rel_get_vars_IMP = prove(
  ``memory_rel c be s.refs sp st m dm
     (join_env s.locals
        (toAList (inter t.locals (adjust_set s.locals))) ++ envs) ∧
    get_vars n (s:'ffi dataSem$state).locals = SOME x ∧
    get_vars (MAP adjust_var n) (t:('a,'ffi) wordSem$state) = SOME w ⇒
    memory_rel c be s.refs sp st m dm
      (ZIP (x,w) ++
       join_env s.locals
         (toAList (inter t.locals (adjust_set s.locals))) ++ envs)``,
  fs [memory_rel_def] \\ rw [] \\ asm_exists_tac \\ fs []
  \\ drule word_ml_inv_get_vars_IMP \\ fs []);

val memory_rel_insert = prove(
  ``memory_rel c be refs sp st m dm
     ([(x,w)] ++ join_env d (toAList (inter l (adjust_set d))) ++ xs) ⇒
    memory_rel c be refs sp st m dm
     (join_env (insert dest x d)
        (toAList
           (inter (insert (adjust_var dest) w l)
              (adjust_set (insert dest x d)))) ++ xs)``,
  fs [memory_rel_def] \\ rw [] \\ asm_exists_tac \\ fs []
  \\ match_mp_tac word_ml_inv_insert \\ fs []);

val get_real_addr_lemma = store_thm("get_real_addr_lemma",
  ``shift_length c < dimindex (:'a) /\
    good_dimindex (:'a) /\
    get_var v t = SOME (Word ptr_w) /\
    get_real_addr c t.store ptr_w = SOME x ==>
    word_exp t (real_addr c v) = SOME (Word (x:'a word))``,
  fs [get_real_addr_def] \\ every_case_tac \\ fs []
  \\ fs [wordSemTheory.get_var_def,real_addr_def] \\ eval_tac \\ fs []
  \\ rpt strip_tac \\ fs []
  \\ fs [labPropsTheory.good_dimindex_def,dimword_def] \\ rw []
  \\ rfs [shift_def]);

val get_real_offset_lemma = store_thm("get_real_offset_lemma",
  ``get_var v t = SOME (Word i_w) /\
    good_dimindex (:'a) /\
    get_real_offset i_w = SOME y ==>
    word_exp t (real_offset c v) = SOME (Word (y:'a word))``,
  fs [get_real_offset_def] \\ every_case_tac \\ fs []
  \\ fs [wordSemTheory.get_var_def,real_offset_def] \\ eval_tac \\ fs []
  \\ fs [labPropsTheory.good_dimindex_def,dimword_def] \\ rw []);

val get_real_byte_offset_lemma = Q.store_thm("get_real_byte_offset_lemma",
  `get_var v t = SOME (Word (w:α word)) ∧ good_dimindex (:α) ⇒
   word_exp t (real_byte_offset v) = SOME (Word (bytes_in_word + (w >>> 2)))`,
  rw[real_byte_offset_def,wordSemTheory.get_var_def]
  \\ eval_tac \\ fs[good_dimindex_def]);

val reorder_lemma = prove(
  ``memory_rel c be x.refs x.space t.store t.memory t.mdomain (x1::x2::x3::xs) ==>
    memory_rel c be x.refs x.space t.store t.memory t.mdomain (x3::x1::x2::xs)``,
  match_mp_tac memory_rel_rearrange \\ fs [] \\ rw [] \\ fs []);

val evaluate_StoreEach = store_thm("evaluate_StoreEach",
  ``!xs ys t offset m1.
      store_list (a + offset) ys t.memory t.mdomain = SOME m1 /\
      get_vars xs t = SOME ys /\
      get_var i t = SOME (Word a) ==>
      evaluate (StoreEach i xs offset, t) = (NONE,t with memory := m1)``,
  Induct
  \\ fs [store_list_def,StoreEach_def] \\ eval_tac
  \\ fs [wordSemTheory.state_component_equality,
           wordSemTheory.get_vars_def,store_list_def,
           wordSemTheory.get_var_def]
  \\ rw [] \\ fs [] \\ CASE_TAC \\ fs []
  \\ Cases_on `get_vars xs t` \\ fs [] \\ clean_tac
  \\ fs [store_list_def,wordSemTheory.mem_store_def]
  \\ `(t with memory := m1) =
      (t with memory := (a + offset =+ x) t.memory) with memory := m1` by
       (fs [wordSemTheory.state_component_equality] \\ NO_TAC)
  \\ pop_assum (fn th => rewrite_tac [th])
  \\ first_x_assum match_mp_tac \\ fs []
  \\ asm_exists_tac \\ fs []
  \\ rename1 `get_vars qs t = SOME ts`
  \\ pop_assum mp_tac
  \\ qspec_tac (`ts`,`ts`)
  \\ qspec_tac (`qs`,`qs`)
  \\ Induct \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_def]
  \\ rw [] \\ every_case_tac \\ fs [])
  |> Q.SPECL [`xs`,`ys`,`t`,`0w`] |> SIMP_RULE (srw_ss()) [] |> GEN_ALL;

val domain_adjust_set_EVEN = store_thm("domain_adjust_set_EVEN",
  ``k IN domain (adjust_set s) ==> EVEN k``,
  fs [adjust_set_def,domain_lookup,lookup_fromAList] \\ rw [] \\ fs []
  \\ imp_res_tac ALOOKUP_MEM \\ fs [MEM_MAP]
  \\ pairarg_tac \\ fs [EVEN_adjust_var]);

val inter_insert_ODD_adjust_set = store_thm("inter_insert_ODD_adjust_set",
  ``!k. ODD k ==>
      inter (insert (adjust_var dest) w (insert k v s)) (adjust_set t) =
      inter (insert (adjust_var dest) w s) (adjust_set t)``,
  fs [spt_eq_thm,wf_inter,lookup_inter_alt,lookup_insert]
  \\ rw [] \\ rw [] \\ fs []
  \\ imp_res_tac domain_adjust_set_EVEN \\ fs [EVEN_ODD]);

val inter_insert_ODD_adjust_set_alt = store_thm("inter_insert_ODD_adjust_set_alt",
  ``!k. ODD k ==>
      inter (insert k v s) (adjust_set t) =
      inter s (adjust_set t)``,
  fs [spt_eq_thm,wf_inter,lookup_inter_alt,lookup_insert]
  \\ rw [] \\ rw [] \\ fs []
  \\ imp_res_tac domain_adjust_set_EVEN \\ fs [EVEN_ODD]);

val get_vars_adjust_var = prove(
  ``ODD k ==>
    get_vars (MAP adjust_var args) (t with locals := insert k w s) =
    get_vars (MAP adjust_var args) (t with locals := s)``,
  Induct_on `args`
  \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_def,lookup_insert]
  \\ rw [] \\ fs [ODD_EVEN,EVEN_adjust_var]);

val get_vars_with_store = store_thm("get_vars_with_store",
  ``!args. get_vars args (t with <| locals := t.locals ; store := s |>) =
           get_vars args t``,
  Induct \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_def]);

val word_less_lemma1 = prove(
  ``v2 < (v1:'a word) <=> ~(v1 <= v2)``,
  metis_tac [WORD_NOT_LESS]);

val heap_in_memory_store_IMP_UPDATE = prove(
  ``heap_in_memory_store heap a sp c st m dm l ==>
    heap_in_memory_store heap a sp c (st |+ (Globals,h)) m dm l``,
  fs [heap_in_memory_store_def,FLOOKUP_UPDATE]);

val get_vars_2_imp = prove(
  ``wordSem$get_vars [x1;x2] s = SOME [y1;y2] ==>
    wordSem$get_var x1 s = SOME y1 /\
    wordSem$get_var x2 s = SOME y2``,
  fs [wordSemTheory.get_vars_def] \\ every_case_tac \\ fs []);

val get_vars_1_imp = prove(
  ``wordSem$get_vars [x1] s = SOME [y1] ==>
    wordSem$get_var x1 s = SOME y1``,
  fs [wordSemTheory.get_vars_def] \\ every_case_tac \\ fs []);

val LESS_DIV_16_IMP = prove(
  ``n < k DIV 16 ==> 16 * n + 2 < k:num``,
  fs [X_LT_DIV]);

val word_exp_real_addr = prove(
  ``get_real_addr c t.store ptr_w = SOME a /\
    shift_length c < dimindex (:α) ∧ good_dimindex (:α) /\
    lookup (adjust_var a1) (t:('a,'ffi) wordSem$state).locals = SOME (Word ptr_w) ==>
    !w. word_exp (t with locals := insert 1 (Word (w:'a word)) t.locals)
          (real_addr c (adjust_var a1)) = SOME (Word a)``,
  rpt strip_tac \\ match_mp_tac (GEN_ALL get_real_addr_lemma)
  \\ fs [wordSemTheory.get_var_def,lookup_insert])

val word_exp_real_addr_2 = prove(
  ``get_real_addr c (t:('a,'ffi) wordSem$state).store ptr_w = SOME a /\
    shift_length c < dimindex (:α) ∧ good_dimindex (:α) /\
    lookup (adjust_var a1) t.locals = SOME (Word ptr_w) ==>
    !w1 w2.
      word_exp
        (t with locals := insert 3 (Word (w1:'a word)) (insert 1 (Word w2) t.locals))
        (real_addr c (adjust_var a1)) = SOME (Word a)``,
  rpt strip_tac \\ match_mp_tac (GEN_ALL get_real_addr_lemma)
  \\ fs [wordSemTheory.get_var_def,lookup_insert])

val encode_header_IMP_BIT0 = prove(
  ``encode_header c tag l = SOME w ==> w ' 0``,
  fs [encode_header_def,make_header_def] \\ rw []
  \\ fs [word_or_def,fcpTheory.FCP_BETA,word_index]);

val get_addr_inj = Q.store_thm("get_addr_inj",
  `p1 * 2 ** shift_length c < dimword (:'a) ∧
   p2 * 2 ** shift_length c < dimword (:'a) ∧
   get_addr c p1 (Word (0w:'a word)) = get_addr c p2 (Word 0w)
   ⇒ p1 = p2`,
  rw[get_addr_def,get_lowerbits_def]
  \\ `1 < 2 ** shift_length c` by (
    fs[ONE_LT_EXP,shift_length_NOT_ZERO,GSYM NOT_ZERO_LT_ZERO] )
  \\ `dimword (:'a) < dimword(:'a) * 2 ** shift_length c` by fs[]
  \\ `p1 < dimword (:'a) ∧ p2 < dimword (:'a)`
  by (
    imp_res_tac LESS_TRANS
    \\ fs[LT_MULT_LCANCEL])
  \\ `n2w p1 << shift_length c >>> shift_length c = n2w p1`
  by ( match_mp_tac lsl_lsr \\ fs[] )
  \\ `n2w p2 << shift_length c >>> shift_length c = n2w p2`
  by ( match_mp_tac lsl_lsr \\ fs[] )
  \\ qmatch_assum_abbrev_tac`(x || 1w) = (y || 1w)`
  \\ `x = y`
  by (
    unabbrev_all_tac
    \\ fsrw_tac[wordsLib.WORD_BIT_EQ_ss][]
    \\ rw[]
    \\ rfs[word_index]
    \\ Cases_on`i` \\ fs[]
    \\ last_x_assum(qspec_then`SUC n`mp_tac)
    \\ simp[] )
  \\ `n2w p1 = n2w p2` by metis_tac[]
  \\ imp_res_tac n2w_11
  \\ rfs[]);

val Word64Rep_inj = Q.store_thm("Word64Rep_inj",
  `good_dimindex(:'a) ⇒
   (Word64Rep (:'a) w1 = Word64Rep (:'a) w2 ⇔ w1 = w2)`,
  rw[good_dimindex_def,Word64Rep_def]
  \\ srw_tac[wordsLib.WORD_BIT_EQ_ss][Word64Rep_def,EQ_IMP_THM]);

val IMP_read_bytearray_GENLIST = Q.store_thm("IMP_read_bytearray_GENLIST",
  `∀ls len a. len = LENGTH ls ∧
   (∀i. i < len ⇒ g (a + n2w i) = SOME (EL i ls))
  ⇒ read_bytearray a len g = SOME ls`,
  Induct \\ rw[read_bytearray_def] \\ fs[]
  \\ last_x_assum(qspec_then`a + 1w`mp_tac)
  \\ impl_tac
  >- (
    rw[]
    \\ first_x_assum(qspec_then`SUC i`mp_tac)
    \\ simp[]
    \\ simp[ADD1,GSYM word_add_n2w] )
  \\ rw[]
  \\ first_x_assum(qspec_then`0`mp_tac)
  \\ simp[]);

val domain_adjust_set_NOT_EMPTY = store_thm("domain_adjust_set_NOT_EMPTY[simp]",
  ``domain (adjust_set s) <> EMPTY``,
  fs [EXTENSION,domain_lookup,adjust_set_def] \\ EVAL_TAC
  \\ fs [lookup_insert] \\ metis_tac []);

val get_vars_termdep = store_thm("get_vars_termdep[simp]",
  ``!xs. get_vars xs (t with termdep := t.termdep - 1) = get_vars xs t``,
  Induct \\ EVAL_TAC \\ rw [] \\ every_case_tac \\ fs []);

val lookup_RefByte_location = prove(
  ``state_rel c l1 l2 x t [] locs ==>
    lookup RefByte_location t.code = SOME (3,RefByte_code c) /\
    lookup RefArray_location t.code = SOME (3,RefArray_code c) /\
    lookup FromList_location t.code = SOME (4,FromList_code c) /\
    lookup Replicate_location t.code = SOME (5,Replicate_code)``,
  fs [state_rel_def,code_rel_def,stubs_def]);

val word_exp_rw = LIST_CONJ
  [wordSemTheory.word_exp_def,
   wordLangTheory.word_op_def,
   wordSemTheory.word_sh_def,
   wordSemTheory.get_var_imm_def,
   wordLangTheory.num_exp_def,
   wordSemTheory.the_words_def,
   lookup_insert]

val get_vars_SOME_IFF_data = prove(
  ``(get_vars [] t = SOME [] <=> T) /\
    (get_vars (x::xs) t = SOME (y::ys) <=>
     dataSem$get_var x t = SOME y /\
     get_vars xs t = SOME ys)``,
  fs [dataSemTheory.get_vars_def] \\ every_case_tac \\ fs []);

val get_vars_SOME_IFF = prove(
  ``(get_vars [] t = SOME [] <=> T) /\
    (get_vars (x::xs) t = SOME (y::ys) <=>
     get_var x t = SOME y /\
     wordSem$get_vars xs t = SOME ys)``,
  fs [wordSemTheory.get_vars_def] \\ every_case_tac \\ fs []);

val get_vars_sing = store_thm("get_vars_sing",
  ``get_vars [n] t = SOME x <=> ?x1. get_vars [n] t = SOME [x1] /\ x = [x1]``,
  fs [wordSemTheory.get_vars_def] \\ every_case_tac \\ fs [] \\ EQ_TAC \\ fs []);

val word_ml_inv_get_var_IMP = save_thm("word_ml_inv_get_var_IMP",
  word_ml_inv_get_vars_IMP
  |> Q.INST [`n`|->`[n1]`,`x`|->`[x1]`] |> GEN_ALL
  |> REWRITE_RULE [get_vars_SOME_IFF,get_vars_SOME_IFF_data,MAP]
  |> SIMP_RULE std_ss [Once get_vars_sing,PULL_EXISTS,get_vars_SOME_IFF,ZIP,APPEND]);

val get_var_set_var_thm = store_thm("get_var_set_var_thm",
  ``wordSem$get_var n (set_var m x y) = if n = m then SOME x else get_var n y``,
  fs[wordSemTheory.get_var_def,wordSemTheory.set_var_def,lookup_insert]);

val lookup_IMP_insert_EQ = store_thm("lookup_IMP_insert_EQ",
  ``!t x y. lookup x t = SOME y ==> insert x y t = t``,
  Induct \\ fs [lookup_def,Once insert_def] \\ rw []);

val alloc_alt =
  SPEC_ALL alloc_lemma
  |> ConseqConv.WEAKEN_CONSEQ_CONV_RULE
     (ConseqConv.CONSEQ_REWRITE_CONV
        ([],[],[prove(``alloc_size k ≠ -1w ==> T``,fs [])]))
  |> GEN_ALL

val insert_insert_3_1 = prove(
  ``insert 3 x (insert 1 y t) = insert 1 y (insert 3 x t)``,
  Cases_on `t` \\ EVAL_TAC \\ Cases_on `s0` \\ EVAL_TAC);

val alloc_size_dimword = store_thm("alloc_size_dimword",
  ``good_dimindex (:'a) ==>
    alloc_size (dimword (:'a)) = -1w:'a word``,
  fs [alloc_size_def,EVAL ``good_dimindex (:'a)``] \\ rw [] \\ fs []);

val alloc_fail = alloc_lemma
  |> Q.INST [`k`|->`dimword (:'a)`]
  |> SIMP_RULE std_ss [UNDISCH alloc_size_dimword]
  |> DISCH_ALL |> MP_CANON

val shift_lsl = store_thm("shift_lsl",
  ``good_dimindex (:'a) ==> w << shift (:'a) = w * bytes_in_word:'a word``,
  rw [labPropsTheory.good_dimindex_def,shift_def,bytes_in_word_def]
  \\ fs [WORD_MUL_LSL]);

val AllocVar_thm = store_thm("AllocVar_thm",
  ``state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs ∧
    dataSem$cut_env names s.locals = SOME x ∧
    get_var 1 t = SOME (Word w) /\
    evaluate (AllocVar limit names,t) = (q,r) /\
    limit < dimword (:'a) DIV 8 ==>
    (q = SOME NotEnoughSpace ⇒ r.ffi = s.ffi) ∧
    (q ≠ SOME NotEnoughSpace ⇒
      w2n w DIV 4 < limit /\
      state_rel c l1 l2 (s with <|locals := x; space := w2n w DIV 4 + 1|>) r [] locs ∧
      q = NONE)``,
  fs [wordSemTheory.evaluate_def,AllocVar_def,list_Seq_def] \\ strip_tac
  \\ `limit < dimword (:'a)` by
        (rfs [EVAL ``good_dimindex (:'a)``,state_rel_def,dimword_def])
  \\ `?end next.
        FLOOKUP t.store EndOfHeap = SOME (Word end) /\
        FLOOKUP t.store NextFree = SOME (Word next)` by
          full_simp_tac(srw_ss())[state_rel_def,heap_in_memory_store_def]
  \\ fs [word_exp_rw,get_var_set_var_thm] \\ rfs []
  \\ rfs [wordSemTheory.get_var_def]
  \\ `~(2 ≥ dimindex (:α))` by
         fs [state_rel_def,EVAL ``good_dimindex (:α)``,shift_def] \\ fs []
  \\ rfs [word_exp_rw,wordSemTheory.set_var_def,lookup_insert]
  \\ fs [asmSemTheory.word_cmp_def]
  \\ fs [WORD_LO,w2n_lsr] \\ rfs []
  \\ reverse (Cases_on `w2n w DIV 4 < limit`) \\ fs [] THEN1
   (rfs [word_exp_rw,wordSemTheory.set_var_def,lookup_insert]
    \\ reverse FULL_CASE_TAC
    \\ qpat_assum `state_rel c l1 l2 s t [] locs` mp_tac
    \\ rewrite_tac [state_rel_def] \\ strip_tac
    \\ fs [heap_in_memory_store_def] \\ fs []
    \\ fs [WORD_LEFT_ADD_DISTRIB,GSYM word_add_n2w]
    THEN1
     (rw [] \\ fs [] \\ rfs [] \\ fs [state_rel_def]
      \\ fs [WORD_LEFT_ADD_DISTRIB,GSYM word_add_n2w]
      \\ fs [NOT_LESS,w2n_minus_1_LESS_EQ,bytes_in_word_ADD_1_NOT_ZERO])
    \\ match_mp_tac (GEN_ALL alloc_fail) \\ fs []
    \\ `state_rel c l1 l2 s (t with locals :=
           insert 3 (Word (end + -1w * next)) t.locals) [] locs` by
          fs [state_rel_insert_3]
    \\ asm_exists_tac \\ fs []
    \\ asm_exists_tac \\ fs [insert_insert_3_1])
  \\ qpat_assum `_ = (q,r)` mp_tac
  \\ IF_CASES_TAC THEN1
    (fs [state_rel_def,EVAL ``good_dimindex (:α)``,shift_def])
  \\ pop_assum kall_tac \\ fs [lookup_insert]
  \\ `1w ≪ shift (:α) + w ⋙ 2 ≪ shift (:α) =
      alloc_size (w2n w DIV 4 + 1)` by
   (fs [alloc_size_def] \\ IF_CASES_TAC THEN1
     (`w >>> 2 = n2w (w2n w DIV 4)` by all_tac
      \\ fs [shift_lsl,state_rel_def,bytes_in_word_def,word_add_n2w,word_mul_n2w]
      \\ rewrite_tac [GSYM w2n_11,w2n_lsr] \\ fs [])
    \\ qsuff_tac `(w2n w DIV 4 + 1) * (dimindex (:α) DIV 8) < dimword (:'a)`
    THEN1 fs [] \\ pop_assum kall_tac
    \\ fs [EVAL ``good_dimindex (:'a)``,state_rel_def,dimword_def]
    \\ rfs [] \\ NO_TAC)
  \\ fs []
  \\ reverse IF_CASES_TAC
  THEN1
   (fs [] \\ strip_tac \\ rveq \\ fs []
    \\ match_mp_tac state_rel_cut_env \\ reverse (srw_tac[][]) \\ fs []
    \\ fs[state_rel_insert_3_1]
    \\ match_mp_tac has_space_state_rel \\ fs []
    \\ fs [wordSemTheory.has_space_def])
  \\ fs [] \\ strip_tac
  \\ match_mp_tac (GEN_ALL alloc_alt)
  \\ qexists_tac `t with locals := insert 3 (Word (end + -1w * next)) t.locals`
  \\ fs [state_rel_insert_3]
  \\ asm_exists_tac \\ fs []
  \\ qpat_assum `_ = (q,r)` (fn th => fs [GSYM th])
  \\ simp [insert_insert_3_1]);

val set_vars_sing = store_thm("set_vars_sing",
  ``set_vars [n] [w] t = set_var n w t``,
  EVAL_TAC);

val memory_rel_lookup = store_thm("memory_rel_lookup",
  ``memory_rel c be refs s st m dm
      (join_env l1 (toAList (inter l2 (adjust_set l1))) ++ xs) ∧
    lookup n l1 = SOME x ∧ lookup (adjust_var n) l2 = SOME w ⇒
    memory_rel c be refs s st m dm
     ((x,w)::(join_env l1 (toAList (inter l2 (adjust_set l1))) ++ xs))``,
  fs [memory_rel_def] \\ rw [] \\ asm_exists_tac \\ fs []
  \\ rpt_drule (Q.INST [`ys`|->`[]`] word_ml_inv_lookup
        |> SIMP_RULE std_ss [APPEND]));

val Replicate_code_thm = store_thm("Replicate_code_thm",
  ``!n a r m1 a1 a2 a3 a4 a5.
      lookup Replicate_location r.code = SOME (5,Replicate_code) /\
      store_list (a + bytes_in_word) (REPLICATE n v)
        (r:('a,'ffi) wordSem$state).memory r.mdomain = SOME m1 /\
      get_var a1 r = SOME (Loc l1 l2) /\
      get_var a2 r = SOME (Word a) /\
      get_var a3 r = SOME v /\
      get_var a4 r = SOME (Word (n2w (4 * n))) /\
      get_var a5 (r:('a,'ffi) wordSem$state) = SOME ret_val /\
      4 * n < dimword (:'a) /\
      n < r.clock ==>
      evaluate (Call NONE (SOME Replicate_location) [a1;a2;a3;a4;a5] NONE,r) =
        (SOME (Result (Loc l1 l2) ret_val),
         r with <| memory := m1 ; clock := r.clock - n - 1; locals := LN |>)``,
  Induct \\ rw [] \\ simp [wordSemTheory.evaluate_def]
  \\ simp [wordSemTheory.get_vars_def,wordSemTheory.bad_dest_args_def,
        wordSemTheory.find_code_def,wordSemTheory.add_ret_loc_def]
  \\ rw [] \\ simp [Replicate_code_def]
  \\ simp [wordSemTheory.evaluate_def,wordSemTheory.call_env_def,
         wordSemTheory.get_var_def,word_exp_rw,fromList2_def,
         asmSemTheory.word_cmp_def,wordSemTheory.dec_clock_def]
  \\ fs [store_list_def,REPLICATE]
  THEN1 (rw [wordSemTheory.state_component_equality])
  \\ NTAC 3 (once_rewrite_tac [list_Seq_def])
  \\ simp [wordSemTheory.evaluate_def,wordSemTheory.call_env_def,
           wordSemTheory.get_var_def,word_exp_rw,fromList2_def,
           wordSemTheory.set_var_def,wordSemTheory.mem_store_def,
           asmSemTheory.word_cmp_def,wordSemTheory.dec_clock_def]
  \\ fs [list_Seq_def]
  \\ SEP_I_TAC "evaluate"
  \\ fs [wordSemTheory.call_env_def,
           wordSemTheory.get_var_def,word_exp_rw,fromList2_def,
           wordSemTheory.set_var_def,wordSemTheory.mem_store_def,
           asmSemTheory.word_cmp_def,wordSemTheory.dec_clock_def]
  \\ rfs [] \\ fs [MULT_CLAUSES,GSYM word_add_n2w] \\ fs [ADD1]);

val NONNEG_INT = store_thm("NONNEG_INT",
  ``0 <= (i:int) ==> ?j. i = & j``,
  Cases_on `i` \\ fs []);

val BIT_X_1 = store_thm("BIT_X_1",
  ``BIT i 1 = (i = 0)``,
  EQ_TAC \\ rw []);

val minus_2_word_and_id = store_thm("minus_2_word_and_id",
  ``~(w ' 0) ==> (-2w && w) = w``,
  fs [fcpTheory.CART_EQ,word_and_def,fcpTheory.FCP_BETA]
  \\ rewrite_tac [GSYM (SIMP_CONV (srw_ss()) [] ``~1w``)]
  \\ Cases_on `w`
  \\ simp_tac std_ss [word_1comp_def,fcpTheory.FCP_BETA,word_index,
        DIMINDEX_GT_0,BIT_X_1] \\ metis_tac []);

val FOUR_MUL_LSL = store_thm("FOUR_MUL_LSL",
  ``n2w (4 * i) << k = n2w i << (k + 2)``,
  fs [WORD_MUL_LSL,EXP_ADD,word_mul_n2w]);

val RefArray_thm = store_thm("RefArray_thm",
  ``state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs /\
    get_vars [0;1] s.locals = SOME vals /\
    t.clock = dimword (:'a) - 1 /\
    do_app RefArray vals s = Rval (v,s2) ==>
    ?q r new_c.
      evaluate (RefArray_code c,t) = (q,r) /\
      if q = SOME NotEnoughSpace then
        r.ffi = t.ffi
      else
        ?rv. q = SOME (Result (Loc l1 l2) rv) /\
             state_rel c r1 r2 (s2 with <| locals := LN; clock := new_c |>)
                r [(v,rv)] locs``,
  fs [RefArray_code_def]
  \\ fs [do_app_def,do_space_def,EVAL ``op_space_reset RefArray``,
         bviSemTheory.do_app_def,bvlSemTheory.do_app_def,
         bviSemTheory.do_app_aux_def]
  \\ Cases_on `vals` \\ fs []
  \\ Cases_on `t'` \\ fs []
  \\ Cases_on `h` \\ fs []
  \\ Cases_on `t''` \\ fs []
  \\ IF_CASES_TAC \\ fs [] \\ rw []
  \\ drule NONNEG_INT \\ strip_tac \\ rveq \\ fs []
  \\ rename1 `get_vars [0; 1] s.locals = SOME [Number (&i); el]`
  \\ qpat_abbrev_tac `s3 = bvi_to_data _ _`
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [wordSemTheory.evaluate_def,word_exp_rw]
  \\ rpt_drule state_rel_get_vars_IMP \\ strip_tac \\ fs [LENGTH_EQ_2]
  \\ rveq \\ fs [adjust_var_def,get_vars_SOME_IFF]
  \\ fs [wordSemTheory.get_var_def]
  \\ `a1 = Word (n2w (4 * i)) /\ 4 * i < dimword (:'a)` by
   (fs [state_rel_def,get_vars_SOME_IFF_data]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,get_var_def]
    \\ rpt_drule word_ml_inv_get_var_IMP
    \\ fs [get_var_def,wordSemTheory.get_var_def,adjust_var_def]
    \\ qpat_assum `lookup 0 s.locals = SOME (Number (&i))` assume_tac
    \\ rpt (disch_then drule) \\ fs []
    \\ fs [word_ml_inv_def] \\ rw []
    \\ fs [abs_ml_inv_def,bc_stack_ref_inv_def,v_inv_def]
    \\ rw [] \\ fs [word_addr_def,Smallnum_def]
    \\ fs [small_int_def,X_LT_DIV]
    \\ match_mp_tac minus_2_word_and_id
    \\ fs [word_index,word_mul_n2w,bitTheory.BIT0_ODD,ODD_MULT] \\ NO_TAC)
  \\ rveq \\ fs []
  \\ `2 < dimindex (:α)` by
       (fs [state_rel_def,EVAL ``good_dimindex (:α)``] \\ NO_TAC) \\ fs []
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [wordSemTheory.evaluate_def,word_exp_rw]
  \\ `state_rel c l1 l2 s (set_var 1 (Word (n2w (4 * i))) t) [] locs` by
        fs [wordSemTheory.set_var_def,state_rel_insert_1]
  \\ rpt_drule AllocVar_thm
  \\ `?x. dataSem$cut_env (fromList [();()]) s.locals = SOME x` by
    (fs [EVAL ``fromList [(); ()]``,cut_env_def,domain_lookup,
         get_var_def,get_vars_SOME_IFF_data] \\ NO_TAC)
  \\ disch_then drule
  \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_def]
  \\ qabbrev_tac `limit = MIN (2 ** c.len_size) (dimword (:α) DIV 16)`
  \\ fs [get_var_set_var_thm]
  \\ Cases_on `evaluate
       (AllocVar limit (fromList [(); ()]),set_var 1 (Word (n2w (4 * i))) t)` \\ fs []
  \\ disch_then drule
  \\ impl_tac THEN1 (unabbrev_all_tac \\ fs []
                     \\ fs [state_rel_def,EVAL ``good_dimindex (:'a)``,dimword_def])
  \\ strip_tac \\ fs [set_vars_sing]
  \\ reverse IF_CASES_TAC \\ fs [] THEN1 fs [state_rel_def]
  \\ rveq \\ fs []
  \\ fs [bviSemTheory.bvl_to_bvi_def,
         bviSemTheory.bvi_to_bvl_def,
         dataSemTheory.bvi_to_data_def,
         dataSemTheory.call_env_def,
         dataSemTheory.data_to_bvi_def,push_env_def,
         dataSemTheory.set_var_def,wordSemTheory.set_var_def]
  \\ qabbrev_tac `new = LEAST ptr. ptr ∉ FDOM s.refs`
  \\ `new ∉ FDOM s.refs` by metis_tac [LEAST_NOTIN_FDOM]
  \\ fs [] \\ fs [list_Seq_def]
  \\ once_rewrite_tac [wordSemTheory.evaluate_def]
  \\ simp [Once wordSemTheory.evaluate_def]
  \\ fs [word_exp_rw]
  \\ `(?eoh1. FLOOKUP r.store EndOfHeap = SOME (Word eoh1)) /\
      (?cur1. FLOOKUP r.store CurrHeap = SOME (Word cur1))` by
        (fs [state_rel_thm,memory_rel_def,heap_in_memory_store_def] \\ NO_TAC)
  \\ `lookup 2 r.locals = SOME (Word (n2w (4 * i)))` by
   (qabbrev_tac `s9 = s with <|locals := x; space := 4 * i DIV 4 + 1|>`
    \\ fs [state_rel_def,get_vars_SOME_IFF_data]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,get_var_def]
    \\ rpt_drule word_ml_inv_get_var_IMP
    \\ fs [get_var_def,wordSemTheory.get_var_def,adjust_var_def]
    \\ `lookup 0 s9.locals = SOME (Number (&i))` by
     (unabbrev_all_tac \\ fs [cut_env_def] \\ rveq
      \\ fs [lookup_inter_alt] \\ EVAL_TAC)
    \\ rpt (disch_then drule) \\ fs []
    \\ `IS_SOME (lookup 0 s9.locals)` by fs []
    \\ res_tac \\ Cases_on `lookup 2 r.locals` \\ fs []
    \\ fs [word_ml_inv_def] \\ rw []
    \\ fs [abs_ml_inv_def,bc_stack_ref_inv_def,v_inv_def]
    \\ rw [] \\ fs [word_addr_def,Smallnum_def]
    \\ fs [small_int_def,X_LT_DIV]
    \\ match_mp_tac minus_2_word_and_id
    \\ fs [word_index,word_mul_n2w,bitTheory.BIT0_ODD,ODD_MULT] \\ NO_TAC)
  \\ fs [] \\ IF_CASES_TAC
  THEN1 (fs [shift_def,state_rel_def,EVAL ``good_dimindex (:'a)``])
  \\ asm_rewrite_tac [] \\ pop_assum kall_tac \\ fs []
  \\ `n2w (4 * i) ⋙ 2 = n2w i` by
   (once_rewrite_tac [GSYM w2n_11] \\ rewrite_tac [w2n_lsr]
    \\ fs [ONCE_REWRITE_RULE[MULT_COMM]MULT_DIV])
  \\ fs [WORD_LEFT_ADD_DISTRIB]
  \\ `good_dimindex(:'a)` by fs [state_rel_def]
  \\ fs [shift_lsl]
  \\ qabbrev_tac `ww = eoh1 + -1w * bytes_in_word + -1w * (bytes_in_word * n2w i)`
  \\ once_rewrite_tac [wordSemTheory.evaluate_def]
  \\ simp [Once wordSemTheory.evaluate_def]
  \\ fs [word_exp_rw,wordSemTheory.set_var_def]
  \\ once_rewrite_tac [wordSemTheory.evaluate_def]
  \\ simp [Once wordSemTheory.evaluate_def]
  \\ fs [word_exp_rw,wordSemTheory.set_store_def]
  \\ fs [FLOOKUP_DEF,FAPPLY_FUPDATE_THM]
  \\ IF_CASES_TAC
  THEN1 (fs [shift_def,state_rel_def,EVAL ``good_dimindex (:'a)``])
  \\ asm_rewrite_tac [] \\ pop_assum kall_tac \\ fs []
  \\ fs [wordSemTheory.set_var_def]
  \\ once_rewrite_tac [wordSemTheory.evaluate_def]
  \\ simp [Once wordSemTheory.evaluate_def]
  \\ fs [word_exp_rw,wordSemTheory.set_var_def,lookup_insert]
  \\ once_rewrite_tac [wordSemTheory.evaluate_def]
  \\ simp [Once wordSemTheory.evaluate_def]
  \\ fs [word_exp_rw,wordSemTheory.set_store_def,lookup_insert,
         wordSemTheory.get_var_def,wordSemTheory.mem_store_def]
  \\ qpat_assum `state_rel c l1 l2 _ _ _ _` mp_tac
  \\ simp_tac std_ss [Once state_rel_thm] \\ strip_tac \\ fs []
  \\ full_simp_tac bool_ss [GSYM APPEND_ASSOC]
  \\ rpt_drule memory_rel_lookup
  \\ `lookup 1 x = SOME el` by
   (fs [cut_env_def] \\ rveq \\ fs []
    \\ fs [lookup_inter_alt,get_vars_SOME_IFF_data,get_var_def]
    \\ EVAL_TAC \\ NO_TAC)
  \\ `?w6. lookup (adjust_var 1) r.locals = SOME w6` by
   (`IS_SOME (lookup 1 x)` by fs [] \\ res_tac \\ fs []
    \\ Cases_on `lookup (adjust_var 1) r.locals` \\ fs [])
  \\ rpt (disch_then drule) \\ strip_tac
  \\ rpt_drule memory_rel_RefArray
  \\ `encode_header c 2 i = SOME (make_header c 2w i)` by
   (fs[encode_header_def,memory_rel_def,heap_in_memory_store_def]
    \\ reverse conj_tac THEN1
     (fs[encode_header_def,memory_rel_def,heap_in_memory_store_def,EXP_SUB]
      \\ unabbrev_all_tac \\ fs [ONCE_REWRITE_RULE [MULT_COMM] MULT_DIV]
      \\ rfs [labPropsTheory.good_dimindex_def,dimword_def])
    \\ `1 < dimindex (:α) − (c.len_size + 2)` by
     (qpat_assum `c.len_size + _ < dimindex (:α)` mp_tac
      \\ rpt (pop_assum kall_tac) \\ decide_tac)
    \\ Cases_on `dimindex (:α) − (c.len_size + 2)` \\ fs[]
    \\ Cases_on `n` \\ fs [EXP] \\ Cases_on `2 ** n'` \\ fs [])
  \\ rpt (disch_then drule)
  \\ impl_tac THEN1 (fs [ONCE_REWRITE_RULE[MULT_COMM]MULT_DIV])
  \\ strip_tac
  \\ fs [LET_THM]
  \\ `eoh1 = eoh /\ cur1 = curr` by (fs [FLOOKUP_DEF] \\ NO_TAC) \\ rveq \\ fs []
  \\ `eoh + -1w * (bytes_in_word * n2w (i + 1)) = ww` by
      (unabbrev_all_tac \\ fs [WORD_LEFT_ADD_DISTRIB,GSYM word_add_n2w] \\ NO_TAC)
  \\ fs [] \\ pop_assum kall_tac
  \\ fs [store_list_def,FOUR_MUL_LSL]
  \\ `(n2w i ≪ (dimindex (:α) − (c.len_size + 2) + 2) ‖ make_header c 2w 0) =
      make_header c 2w i:'a word` by
   (fs [make_header_def,WORD_MUL_LSL,word_mul_n2w,LEFT_ADD_DISTRIB]
    \\ rpt (AP_TERM_TAC ORELSE AP_THM_TAC)
    \\ fs [memory_rel_def,heap_in_memory_store_def] \\ NO_TAC) \\ fs []
  \\ `lookup Replicate_location r.code = SOME (5,Replicate_code)` by
         (imp_res_tac lookup_RefByte_location \\ NO_TAC)
  \\ assume_tac (GEN_ALL Replicate_code_thm)
  \\ SEP_I_TAC "evaluate"
  \\ fs [wordSemTheory.get_var_def,lookup_insert] \\ rfs []
  \\ pop_assum drule
  \\ impl_tac THEN1 (fs [adjust_var_def] \\ fs [state_rel_def])
  \\ strip_tac \\ fs []
  \\ pop_assum mp_tac \\ fs []
  \\ strip_tac \\ fs []
  \\ simp [state_rel_thm]
  \\ qunabbrev_tac `s3` \\ fs []
  \\ fs [lookup_def]
  \\ qpat_assum `memory_rel _ _ _ _ _ _ _ _` mp_tac
  \\ fs [EVAL ``join_env LN []``]
  \\ drule memory_rel_zero_space
  \\ match_mp_tac memory_rel_rearrange
  \\ fs [] \\ rw [] \\ rw []
  \\ fs [FAPPLY_FUPDATE_THM]
  \\ disj1_tac
  \\ fs [make_ptr_def]
  \\ qunabbrev_tac `ww`
  \\ AP_THM_TAC \\ AP_TERM_TAC \\ fs []
  \\ fs [GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]);

val word_exp_SmallLsr = store_thm("word_exp_SmallLsr",
  ``word_exp s (SmallLsr e n) =
      if dimindex (:'a) <= n then NONE else
        case word_exp s e of
        | SOME (Word w) => SOME (Word ((w:'a word) >>> n))
        | res => (if n = 0 then res else NONE)``,
  rw [SmallLsr_def] \\ assume_tac DIMINDEX_GT_0
  \\ TRY (`F` by decide_tac \\ NO_TAC)
  THEN1
   (full_simp_tac std_ss [GSYM NOT_LESS]
    \\ Cases_on `word_exp s e` \\ fs []
    \\ Cases_on `x` \\ fs [])
  \\ fs [word_exp_rw] \\ every_case_tac \\ fs []  );

val evaluate_MakeBytes = store_thm("evaluate_MakeBytes",
  ``good_dimindex (:'a) ==>
    evaluate (MakeBytes n,s) =
      case get_var n s of
      | SOME (Word w) => (NONE,set_var n (Word (word_of_byte ((w:'a word) >>> 2))) s)
      | _ => (SOME Error,s)``,
  fs [MakeBytes_def,list_Seq_def,wordSemTheory.evaluate_def,word_exp_rw,
      wordSemTheory.get_var_def] \\ strip_tac
  \\ Cases_on `lookup n s.locals` \\ fs []
  \\ Cases_on `x` \\ fs [] \\ IF_CASES_TAC
  \\ fs [EVAL ``good_dimindex (:'a)``]
  \\ fs [wordSemTheory.set_var_def,lookup_insert,word_of_byte_def,
         insert_shadow,wordSemTheory.evaluate_def,word_exp_rw]);

val w2w_shift_shift = store_thm("w2w_shift_shift",
  ``good_dimindex (:'a) ==> ((w2w (w:word8) ≪ 2 ⋙ 2) : 'a word) = w2w w``,
  fs [labPropsTheory.good_dimindex_def,fcpTheory.CART_EQ,
      word_lsl_def,word_lsr_def,fcpTheory.FCP_BETA,w2w]
  \\ rw [] \\ fs [] \\ EQ_TAC \\ rw [] \\ rfs [fcpTheory.FCP_BETA,w2w]);

val RefByte_thm = store_thm("RefByte_thm",
  ``state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs /\
    get_vars [0;1] s.locals = SOME vals /\
    t.clock = dimword (:'a) - 1 /\
    do_app RefByte vals s = Rval (v,s2) ==>
    ?q r new_c.
      evaluate (RefByte_code c,t) = (q,r) /\
      if q = SOME NotEnoughSpace then
        r.ffi = t.ffi
      else
        ?rv. q = SOME (Result (Loc l1 l2) rv) /\
             state_rel c r1 r2 (s2 with <| locals := LN; clock := new_c |>)
                r [(v,rv)] locs``,
  fs [RefByte_code_def]
  \\ fs [do_app_def,do_space_def,EVAL ``op_space_reset RefByte``,
         bviSemTheory.do_app_def,bvlSemTheory.do_app_def,
         bviSemTheory.do_app_aux_def]
  \\ Cases_on `vals` \\ fs []
  \\ Cases_on `t'` \\ fs []
  \\ Cases_on `h` \\ fs []
  \\ Cases_on `t''` \\ fs []
  \\ Cases_on `h'` \\ fs []
  \\ IF_CASES_TAC \\ fs [] \\ rw []
  \\ `good_dimindex (:'a)` by fs [state_rel_def]
  \\ drule NONNEG_INT \\ strip_tac \\ rveq \\ fs []
  \\ rename1 `get_vars [0; 1] s.locals = SOME [Number (&i); Number (&w2n w)]`
  \\ qpat_abbrev_tac `s3 = bvi_to_data _ _`
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [wordSemTheory.evaluate_def,word_exp_rw]
  \\ rpt_drule state_rel_get_vars_IMP \\ strip_tac \\ fs [LENGTH_EQ_2]
  \\ rveq \\ fs [adjust_var_def,get_vars_SOME_IFF]
  \\ fs [wordSemTheory.get_var_def]
  \\ `a1 = Word (n2w (4 * i)) /\ 4 * i < dimword (:'a)` by
   (fs [state_rel_def,get_vars_SOME_IFF_data]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,get_var_def]
    \\ rpt_drule word_ml_inv_get_var_IMP
    \\ fs [get_var_def,wordSemTheory.get_var_def,adjust_var_def]
    \\ qpat_assum `lookup 0 s.locals = SOME (Number (&i))` assume_tac
    \\ rpt (disch_then drule) \\ fs []
    \\ fs [word_ml_inv_def] \\ rw []
    \\ fs [abs_ml_inv_def,bc_stack_ref_inv_def,v_inv_def]
    \\ rw [] \\ fs [word_addr_def,Smallnum_def]
    \\ fs [small_int_def,X_LT_DIV]
    \\ match_mp_tac minus_2_word_and_id
    \\ fs [word_index,word_mul_n2w,bitTheory.BIT0_ODD,ODD_MULT] \\ NO_TAC)
  \\ rveq \\ fs [word_exp_SmallLsr]
  \\ IF_CASES_TAC
  THEN1 (fs [shift_def,state_rel_def,
             EVAL ``good_dimindex (:'a)``] \\ rfs []) \\ fs []
  \\ pop_assum kall_tac
  \\ fs [word_exp_rw]
  \\ IF_CASES_TAC
  THEN1 (fs [shift_def,state_rel_def,
             EVAL ``good_dimindex (:'a)``] \\ rfs []) \\ fs []
  \\ pop_assum kall_tac
  \\ `n2w (4 * i) ⋙ 2 = (n2w i):'a word` by
   (rewrite_tac [GSYM w2n_11,w2n_lsr]
    \\ fs [ONCE_REWRITE_RULE [MULT_COMM] MULT_DIV] \\ NO_TAC) \\ fs []
  \\ qabbrev_tac `wA = ((bytes_in_word + n2w i + -1w)
        ⋙ (dimindex (:α) − 63)):'a word`
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [wordSemTheory.evaluate_def,word_exp_rw]
  \\ `state_rel c l1 l2 s (set_var 1 (Word wA) t) [] locs` by
        fs [wordSemTheory.set_var_def,state_rel_insert_1]
  \\ rpt_drule AllocVar_thm
  \\ `?x. dataSem$cut_env (fromList [();()]) s.locals = SOME x` by
    (fs [EVAL ``fromList [(); ()]``,cut_env_def,domain_lookup,
         get_var_def,get_vars_SOME_IFF_data] \\ NO_TAC)
  \\ disch_then drule
  \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_def]
  \\ qabbrev_tac `limit = MIN (2 ** c.len_size) (dimword (:α) DIV 16)`
  \\ fs [get_var_set_var_thm]
  \\ Cases_on `evaluate
       (AllocVar limit (fromList [(); ()]),set_var 1 (Word wA) t)` \\ fs []
  \\ disch_then drule
  \\ impl_tac THEN1 (unabbrev_all_tac \\ fs []
                     \\ fs [state_rel_def,EVAL ``good_dimindex (:'a)``,dimword_def])
  \\ strip_tac \\ fs [set_vars_sing]
  \\ reverse IF_CASES_TAC \\ fs [] THEN1 fs [state_rel_def]
  \\ rveq \\ fs []
  \\ fs [bviSemTheory.bvl_to_bvi_def,
         bviSemTheory.bvi_to_bvl_def,
         dataSemTheory.bvi_to_data_def,
         dataSemTheory.call_env_def,
         dataSemTheory.data_to_bvi_def,push_env_def,
         dataSemTheory.set_var_def,wordSemTheory.set_var_def]
  \\ qabbrev_tac `new = LEAST ptr. ptr ∉ FDOM s.refs`
  \\ `new ∉ FDOM s.refs` by metis_tac [LEAST_NOTIN_FDOM]
  \\ fs [] \\ once_rewrite_tac [list_Seq_def]
  \\ once_rewrite_tac [wordSemTheory.evaluate_def]
  \\ simp [Once wordSemTheory.evaluate_def]
  \\ fs [word_exp_rw]
  \\ `(?eoh1. FLOOKUP r.store EndOfHeap = SOME (Word eoh1)) /\
      (?cur1. FLOOKUP r.store CurrHeap = SOME (Word cur1))` by
        (fs [state_rel_thm,memory_rel_def,heap_in_memory_store_def] \\ NO_TAC)
  \\ fs []
  \\ `lookup 2 r.locals = SOME (Word (n2w (4 * i)))` by
   (qabbrev_tac `s9 = s with <|locals := x; space := w2n wA DIV 4 + 1|>`
    \\ fs [state_rel_def,get_vars_SOME_IFF_data]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,get_var_def]
    \\ rpt_drule word_ml_inv_get_var_IMP
    \\ fs [get_var_def,wordSemTheory.get_var_def,adjust_var_def]
    \\ `lookup 0 s9.locals = SOME (Number (&i))` by
     (unabbrev_all_tac \\ fs [cut_env_def] \\ rveq
      \\ fs [lookup_inter_alt] \\ EVAL_TAC)
    \\ rpt (disch_then drule) \\ fs []
    \\ `IS_SOME (lookup 0 s9.locals)` by fs []
    \\ res_tac \\ Cases_on `lookup 2 r.locals` \\ fs []
    \\ fs [word_ml_inv_def] \\ rw []
    \\ fs [abs_ml_inv_def,bc_stack_ref_inv_def,v_inv_def]
    \\ rw [] \\ fs [word_addr_def,Smallnum_def]
    \\ fs [small_int_def,X_LT_DIV]
    \\ match_mp_tac minus_2_word_and_id
    \\ fs [word_index,word_mul_n2w,bitTheory.BIT0_ODD,ODD_MULT] \\ NO_TAC)
  \\ `lookup 4 r.locals = SOME (Word (w2w w << 2))` by
   (qabbrev_tac `s9 = s with <|locals := x; space := w2n wA DIV 4 + 1|>`
    \\ fs [state_rel_def,get_vars_SOME_IFF_data]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,get_var_def]
    \\ rpt_drule word_ml_inv_get_var_IMP
    \\ fs [get_var_def,wordSemTheory.get_var_def,adjust_var_def]
    \\ `lookup 1 s9.locals = SOME (Number (&w2n w))` by
     (unabbrev_all_tac \\ fs [cut_env_def] \\ rveq
      \\ fs [lookup_inter_alt] \\ EVAL_TAC)
    \\ rpt (disch_then drule) \\ fs []
    \\ `IS_SOME (lookup 1 s9.locals)` by fs []
    \\ res_tac \\ Cases_on `lookup 4 r.locals` \\ fs []
    \\ fs [word_ml_inv_def] \\ rw []
    \\ fs [abs_ml_inv_def,bc_stack_ref_inv_def,v_inv_def]
    \\ rw [] \\ fs [word_addr_def,Smallnum_def]
    \\ fs [word_mul_n2w,w2w_def,WORD_MUL_LSL]
    \\ fs [small_int_def,X_LT_DIV]
    \\ match_mp_tac minus_2_word_and_id
    \\ fs [word_index,word_mul_n2w,bitTheory.BIT0_ODD,ODD_MULT] \\ NO_TAC)
  \\ fs [] \\ once_rewrite_tac [list_Seq_def]
  \\ once_rewrite_tac [wordSemTheory.evaluate_def]
  \\ IF_CASES_TAC
  THEN1 (fs [shift_def,EVAL ``good_dimindex (:'a)``])
  \\ pop_assum kall_tac \\ fs []
  \\ qabbrev_tac `var5 = (bytes_in_word + n2w i + -1w:'a word) ⋙ shift (:α)`
  \\ IF_CASES_TAC
  THEN1 (fs [shift_def,EVAL ``good_dimindex (:'a)``])
  \\ pop_assum kall_tac \\ fs []
  \\ simp [Once wordSemTheory.evaluate_def]
  \\ fs [word_exp_rw,wordSemTheory.set_var_def]
  \\ IF_CASES_TAC
  THEN1 (fs [shift_def,EVAL ``good_dimindex (:'a)``])
  \\ pop_assum kall_tac \\ fs []
  \\ NTAC 5
   (once_rewrite_tac [list_Seq_def]
    \\ fs [wordSemTheory.evaluate_def,word_exp_rw]
    \\ rpt (IF_CASES_TAC
      THEN1 (fs [shift_def,shift_length_def,state_rel_def,
                 EVAL ``good_dimindex (:'a)``] \\ fs [])
      \\ pop_assum kall_tac \\ fs [wordSemTheory.set_var_def,
           wordSemTheory.set_store_def,WORD_LEFT_ADD_DISTRIB,
           FLOOKUP_DEF,FAPPLY_FUPDATE_THM,lookup_insert])
    \\ fs [wordSemTheory.set_store_def,FLOOKUP_DEF,FAPPLY_FUPDATE_THM,
           lookup_insert])
  \\ fs [evaluate_MakeBytes,word_exp_rw,wordSemTheory.set_var_def,
         lookup_insert,wordSemTheory.get_var_def,w2w_shift_shift]
  \\ qpat_assum `state_rel c l1 l2 _ _ _ _` mp_tac
  \\ simp_tac std_ss [Once state_rel_thm] \\ strip_tac \\ fs []
  \\ `w2n wA DIV 4 = byte_len (:'a) i` by
   (unabbrev_all_tac \\ fs [byte_len_def,bytes_in_word_def,w2n_lsr,
      labPropsTheory.good_dimindex_def,word_add_n2w,dimword_def] \\ rfs []
    \\ fs [GSYM word_add_n2w] \\ fs [word_add_n2w,dimword_def]
    \\ fs [DIV_DIV_DIV_MULT] \\ NO_TAC)
  \\ rpt_drule memory_rel_RefByte
  \\ disch_then (qspecl_then [`w`,`i`] mp_tac) \\ fs []
  \\ impl_tac THEN1
   (unabbrev_all_tac \\ fs []
    \\ fs [labPropsTheory.good_dimindex_def,dimword_def] \\ rfs [])
  \\ strip_tac \\ fs [FLOOKUP_DEF] \\ rveq \\ clean_tac
  \\ `var5 = n2w (byte_len (:α) i)` by
   (unabbrev_all_tac
    \\ rewrite_tac [GSYM w2n_11,w2n_lsr,byte_len_def]
    \\ fs [bytes_in_word_def,shift_def,labPropsTheory.good_dimindex_def]
    \\ fs [word_add_n2w]
    THEN1
     (`i + 3 < dimword (:'a)` by all_tac
      \\ `i + 3 DIV 4 < dimword (:'a)` by all_tac \\ fs []
      \\ rfs [dimword_def] \\ fs [DIV_LT_X])
    THEN1
     (`i + 7 < dimword (:'a)` by all_tac
      \\ `i + 7 DIV 8 < dimword (:'a)` by all_tac \\ fs []
      \\ rfs [dimword_def] \\ fs [DIV_LT_X]) \\ NO_TAC)
  \\ fs [] \\ rveq
  \\ rfs [shift_lsl,GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
  \\ once_rewrite_tac [list_Seq_def]
  \\ fs [wordSemTheory.evaluate_def,word_exp_rw,
         wordSemTheory.get_var_def,lookup_insert,
         wordSemTheory.mem_store_def,store_list_def]
  \\ rewrite_tac [list_Seq_def]
  \\ `lookup Replicate_location r.code = SOME (5,Replicate_code)` by
         (imp_res_tac lookup_RefByte_location \\ NO_TAC)
  \\ assume_tac (GEN_ALL Replicate_code_thm)
  \\ SEP_I_TAC "evaluate"
  \\ fs [wordSemTheory.get_var_def,lookup_insert] \\ rfs []
  \\ pop_assum mp_tac
  \\ qpat_abbrev_tac `ppp = Word (_ || _:'a word)`
  \\ `ppp = Word (make_byte_header c i)` by
   (unabbrev_all_tac \\ fs [make_byte_header_def,bytes_in_word_def]
    \\ fs [labPropsTheory.good_dimindex_def,GSYM word_add_n2w,WORD_MUL_LSL]
    \\ fs [word_mul_n2w,word_add_n2w,shift_def,RIGHT_ADD_DISTRIB] \\ NO_TAC)
  \\ rveq \\ pop_assum kall_tac \\ pop_assum kall_tac
  \\ disch_then drule
  \\ impl_tac THEN1
   (fs [WORD_MUL_LSL,word_mul_n2w,state_rel_def]
    \\ fs [labPropsTheory.good_dimindex_def,dimword_def] \\ rfs []
    \\ unabbrev_all_tac \\ fs [])
  \\ fs [] \\ strip_tac \\ fs [WORD_MUL_LSL,word_mul_n2w]
  \\ pop_assum kall_tac
  \\ simp [state_rel_thm]
  \\ qunabbrev_tac `s3` \\ fs []
  \\ fs [lookup_def]
  \\ qpat_assum `memory_rel _ _ _ _ _ _ _ _` mp_tac
  \\ fs [EVAL ``join_env LN []``]
  \\ drule memory_rel_zero_space
  \\ match_mp_tac memory_rel_rearrange
  \\ fs [] \\ rw [] \\ rw []
  \\ fs [FAPPLY_FUPDATE_THM]
  \\ disj1_tac
  \\ fs [make_ptr_def]
  \\ unabbrev_all_tac
  \\ AP_THM_TAC \\ AP_TERM_TAC \\ fs []
  \\ fs [GSYM word_add_n2w,WORD_LEFT_ADD_DISTRIB]
  \\ fs [WORD_MUL_LSL,word_mul_n2w]);

val FromList1_code_thm = store_thm("Replicate_code_thm",
  ``!k a b r x m1 a1 a2 a3 a4 a5 a6.
      lookup FromList1_location r.code = SOME (6,FromList1_code c) /\
      copy_list c r.store k (a,x,b,(r:('a,'ffi) wordSem$state).memory,
        r.mdomain) = SOME (b1,m1) /\
      shift_length c < dimindex (:'a) /\ good_dimindex (:'a) /\
      get_var a1 r = SOME (Loc l1 l2) /\
      get_var a2 r = SOME (Word (b:'a word)) /\
      get_var a3 r = SOME a /\
      get_var a4 r = SOME (Word (n2w (4 * k))) /\
      get_var a5 r = SOME ret_val /\
      get_var a6 r = SOME x /\
      4 * k < dimword (:'a) /\
      k < r.clock ==>
      evaluate (Call NONE (SOME FromList1_location) [a1;a2;a3;a4;a5;a6] NONE,r) =
        (SOME (Result (Loc l1 l2) ret_val),
         r with <| memory := m1 ; clock := r.clock - k - 1; locals := LN ;
                   store := r.store |+ (NextFree, Word b1) |>)``,
  Induct \\ rw [] \\ simp [wordSemTheory.evaluate_def]
  \\ simp [wordSemTheory.get_vars_def,wordSemTheory.bad_dest_args_def,
        wordSemTheory.find_code_def,wordSemTheory.add_ret_loc_def]
  \\ rw [] \\ simp [FromList1_code_def]
  \\ simp [Once list_Seq_def]
  \\ qpat_assum `_ = SOME (b1,m1)` mp_tac
  \\ once_rewrite_tac [copy_list_def] \\ fs []
  \\ strip_tac THEN1
   (rveq
    \\ simp [wordSemTheory.evaluate_def,wordSemTheory.call_env_def,
             wordSemTheory.get_var_def,word_exp_rw,fromList2_def,
             asmSemTheory.word_cmp_def,wordSemTheory.dec_clock_def,lookup_insert,
             wordSemTheory.mem_store_def,list_Seq_def,wordSemTheory.set_var_def,
             wordSemTheory.set_store_def])
  \\ Cases_on `a` \\ fs []
  \\ Cases_on `get_real_addr c r.store c'` \\ fs []
  \\ qabbrev_tac `m9 = (b =+ x) r.memory`
  \\ ntac 2 (simp [Once list_Seq_def])
  \\ simp [wordSemTheory.evaluate_def,word_exp_rw,wordSemTheory.call_env_def,
           wordSemTheory.get_var_def,word_exp_rw,fromList2_def,
           wordSemTheory.mem_store_def,wordSemTheory.dec_clock_def,lookup_insert,
           wordSemTheory.set_var_def,asmSemTheory.word_cmp_def]
  \\ ntac 4 (simp [Once list_Seq_def])
  \\ simp [wordSemTheory.evaluate_def,word_exp_rw,wordSemTheory.call_env_def,
           wordSemTheory.get_var_def,word_exp_rw,fromList2_def,
           wordSemTheory.mem_store_def,wordSemTheory.dec_clock_def,lookup_insert,
           wordSemTheory.set_var_def,asmSemTheory.word_cmp_def]
  \\ qpat_abbrev_tac `r3 =
          (r with
           <|locals :=
               insert 2 (Word (b + bytes_in_word)) _;
             memory := m9; clock := r.clock − 1|>)`
  \\ rename1 `get_real_addr c r.store c1 = SOME x1`
  \\ `get_real_addr c r3.store c1 = SOME x1` by (fs [Abbr `r3`])
  \\ rpt_drule (get_real_addr_lemma
        |> REWRITE_RULE [CONJ_ASSOC]
        |> ONCE_REWRITE_RULE [CONJ_COMM]) \\ fs []
  \\ disch_then (qspec_then `4` mp_tac)
  \\ impl_tac
  THEN1 (unabbrev_all_tac \\ fs [wordSemTheory.get_var_def,lookup_insert])
  \\ fs [wordSemTheory.mem_load_def,lookup_insert]
  \\ fs [list_Seq_def]
  \\ qpat_abbrev_tac `r7 =
       r with <|locals := insert 6 _ _ ; memory := m9 ; clock := _ |> `
  \\ first_x_assum (qspecl_then [`(m9 (x1 + 2w * bytes_in_word))`,
         `b + bytes_in_word`,`r7`,`m9 (x1 + bytes_in_word)`,`m1`,
         `0`,`2`,`4`,`6`,`8`,`10`] mp_tac)
  \\ reverse impl_tac THEN1
    (strip_tac \\ fs [] \\ rw [wordSemTheory.state_component_equality,Abbr `r7`])
  \\ unabbrev_all_tac \\ fs []
  \\ fs [wordSemTheory.get_var_def,lookup_insert]
  \\ fs [MULT_CLAUSES,GSYM word_add_n2w]);

val state_rel_IMP_test_zero = store_thm("state_rel_IMP_test_zero",
  ``state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) vs locs /\
    get_var i s.locals = SOME (Number n) ==>
    ?w. get_var (adjust_var i) t = SOME (Word w) /\ (w = 0w <=> (n = 0))``,
  strip_tac
  \\ rpt_drule state_rel_get_var_IMP
  \\ strip_tac \\ fs []
  \\ fs [state_rel_thm,get_vars_SOME_IFF_data] \\ rw []
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,get_var_def]
  \\ drule memory_rel_drop \\ strip_tac
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,get_var_def]
  \\ rpt_drule memory_rel_lookup
  \\ fs [wordSemTheory.get_var_def] \\ strip_tac
  \\ `small_int (:'a) 0` by
     (fs [labPropsTheory.good_dimindex_def,dimword_def,small_int_def] \\ NO_TAC)
  \\ rpt_drule (IMP_memory_rel_Number
        |> REWRITE_RULE [CONJ_ASSOC]
        |> ONCE_REWRITE_RULE [CONJ_COMM])
  \\ fs [] \\ strip_tac
  \\ drule memory_rel_Number_EQ \\ fs []
  \\ strip_tac \\ fs [Smallnum_def]
  \\ eq_tac \\ rw [] \\ fs []);

val state_rel_get_var_Number_IMP = store_thm("state_rel_get_var_Number_IMP",
  ``state_rel c l1 l2 s t vs locs /\
    get_var i s.locals = SOME (Number (&n)) /\ small_int (:'a) (&n) ==>
    ?w. get_var (adjust_var i) t = SOME (Word (Smallnum (&n):'a word))``,
  strip_tac
  \\ rpt_drule state_rel_get_var_IMP
  \\ strip_tac \\ fs []
  \\ fs [state_rel_thm,get_vars_SOME_IFF_data] \\ rw []
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,get_var_def]
  \\ drule memory_rel_drop \\ strip_tac
  \\ fs [memory_rel_def]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,get_var_def]
  \\ rpt_drule word_ml_inv_get_var_IMP
  \\ fs [get_var_def,wordSemTheory.get_var_def,adjust_var_def]
  \\ qpat_assum `lookup i s.locals = SOME (Number (&n))` assume_tac
  \\ rpt (disch_then drule) \\ fs []
  \\ fs [word_ml_inv_def] \\ rw []
  \\ fs [abs_ml_inv_def,bc_stack_ref_inv_def,v_inv_def]
  \\ rw [] \\ fs [word_addr_def,Smallnum_def]
  \\ match_mp_tac minus_2_word_and_id
  \\ fs [word_index,word_mul_n2w,bitTheory.BIT0_ODD,ODD_MULT]);

val EXP_LEMMA1 = prove(
  ``4n * n * (2 ** k) = n * 2 ** (k + 2)``,
  fs [EXP_ADD]);

val evaluate_Maxout_bits_code = prove(
  ``n_reg <> dest /\ n < dimword (:'a) /\ rep_len < dimindex (:α) /\
    k < dimindex (:'a) /\
    lookup n_reg (t:('a,'ffi) wordSem$state).locals = SOME (Word (n2w n:'a word)) ==>
    evaluate (Maxout_bits_code rep_len k dest n_reg,set_var dest (Word w) t) =
      (NONE,set_var dest (Word (w || maxout_bits n rep_len k)) t)``,
  fs [Maxout_bits_code_def,wordSemTheory.evaluate_def,wordSemTheory.get_var_def,
      wordSemTheory.set_var_def,wordSemTheory.get_var_imm_def,
      asmSemTheory.word_cmp_def,lookup_insert,WORD_LO,word_exp_rw,
      maxout_bits_def] \\ rw [] \\ fs [insert_shadow]
  \\ `2 ** rep_len < dimword (:α)` by all_tac \\ fs [] \\ fs [dimword_def]);

val Make_ptr_bits_thm = store_thm("Make_ptr_bits_thm",
  ``tag_reg ≠ dest ∧ tag1 < dimword (:α) ∧ c.tag_bits < dimindex (:α) ∧
    len_reg ≠ dest ∧ len1 < dimword (:α) ∧ c.len_bits < dimindex (:α) ∧
    c.len_bits + 1 < dimindex (:α) /\
    FLOOKUP (t:('a,'ffi) wordSem$state).store NextFree = SOME (Word f) /\
    FLOOKUP t.store CurrHeap = SOME (Word d) /\
    lookup tag_reg t.locals = SOME (Word (n2w tag1)) /\
    lookup len_reg t.locals = SOME (Word (n2w len1)) /\
    shift_length c < dimindex (:α) + shift (:α) ==>
    ?t1.
      evaluate (Make_ptr_bits_code c tag_reg len_reg dest,t) =
        (NONE,set_var dest (make_cons_ptr c (f-d) tag1 len1:'a word_loc) t)``,
  fs [Make_ptr_bits_code_def,list_Seq_def,wordSemTheory.evaluate_def,word_exp_rw]
  \\ fs [make_cons_ptr_thm] \\ strip_tac
  \\ pairarg_tac \\ fs []
  \\ pop_assum mp_tac
  \\ assume_tac (GEN_ALL evaluate_Maxout_bits_code)
  \\ SEP_I_TAC "evaluate"
  \\ pop_assum (qspec_then `tag1` mp_tac) \\ fs [] \\ rw []
  \\ assume_tac (GEN_ALL evaluate_Maxout_bits_code)
  \\ SEP_I_TAC "evaluate"
  \\ pop_assum (qspec_then `len1` mp_tac) \\ fs [] \\ rw []
  \\ fs [ptr_bits_def]);

val FromList_thm = store_thm("FromList_thm",
  ``state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs /\
    encode_header c (4 * tag) 0 <> (NONE:'a word option) /\
    get_vars [0; 1; 2] s.locals = SOME [v1; v2; Number (&(4 * tag))] /\
    t.clock = dimword (:'a) - 1 /\
    do_app (FromList tag) [v1; v2] s = Rval (v,s2) ==>
    ?q r new_c.
      evaluate (FromList_code c,t) = (q,r) /\
      if q = SOME NotEnoughSpace then
        r.ffi = t.ffi
      else
        ?rv. q = SOME (Result (Loc l1 l2) rv) /\
             state_rel c r1 r2 (s2 with <| locals := LN; clock := new_c |>)
                r [(v,rv)] locs``,
  fs [dataSemTheory.do_app_def,bviSemTheory.do_app_def,
      bviSemTheory.do_app_aux_def,dataSemTheory.do_space_def,
      bvi_to_dataTheory.op_space_reset_def]
  \\ CASE_TAC \\ fs []
  \\ Cases_on `v1 = Number (&LENGTH x)` \\ fs []
  \\ fs [LENGTH_NIL] \\ strip_tac \\ rveq \\ fs [FromList_code_def]
  \\ once_rewrite_tac [wordSemTheory.evaluate_def]
  \\ rpt_drule state_rel_get_vars_IMP
  \\ fs[wordSemTheory.get_var_imm_def,asmSemTheory.word_cmp_def]
  \\ rpt_drule state_rel_get_vars_IMP \\ strip_tac \\ fs [LENGTH_EQ_3]
  \\ rveq \\ fs [adjust_var_def,get_vars_SOME_IFF,get_vars_SOME_IFF_data]
  \\ qpat_assum `get_var 0 s.locals = SOME (Number (&LENGTH x))` assume_tac
  \\ rpt_drule state_rel_IMP_test_zero
  \\ fs [adjust_var_def] \\ strip_tac \\ fs [] \\ rveq
  \\ `small_int (:α) (&(4 * tag))` by
     (fs [encode_header_def,small_int_def,state_rel_thm,
          labPropsTheory.good_dimindex_def,dimword_def] \\ rfs [] \\ NO_TAC)
  \\ IF_CASES_TAC THEN1
   (qpat_assum `get_var 2 s.locals = SOME (Number (&(4*tag)))` assume_tac
    \\ rpt_drule state_rel_get_var_Number_IMP \\ fs []
    \\ fs [LENGTH_NIL] \\ rveq \\ rw []
    \\ fs [list_Seq_def,wordSemTheory.evaluate_def,word_exp_rw,
           wordSemTheory.get_var_def,adjust_var_def,wordSemTheory.set_var_def]
    \\ rveq \\ fs [lookup_insert]
    \\ `lookup 0 t.locals = SOME (Loc l1 l2)` by fs [state_rel_def] \\ fs []
    \\ fs [state_rel_thm,wordSemTheory.call_env_def,lookup_def]
    \\ fs [EVAL ``(toAList (inter (fromList2 []) (insert 0 () LN)))`` ]
    \\ fs [EVAL ``join_env LN []``,lookup_insert]
    \\ fs [BlockNil_def,Smallnum_def,WORD_MUL_LSL,word_mul_n2w]
    \\ `n2w (16 * tag) + 2w = BlockNil tag : 'a word` by
          fs [BlockNil_def,WORD_MUL_LSL,word_mul_n2w] \\ fs []
    \\ match_mp_tac memory_rel_Cons_empty
    \\ fs [encode_header_def]
    \\ drule memory_rel_zero_space
    \\ match_mp_tac memory_rel_rearrange
    \\ fs [] \\ rw [] \\ fs [])
  \\ fs []
  \\ ntac 2 (once_rewrite_tac [list_Seq_def])
  \\ fs [wordSemTheory.evaluate_def,word_exp_rw,wordSemTheory.get_var_def]
  \\ pairarg_tac \\ fs []
  \\ `state_rel c l1 l2 s (set_var 1 (Word w) t) [] locs` by
        fs [wordSemTheory.set_var_def,state_rel_insert_1]
  \\ rpt_drule AllocVar_thm
  \\ `?x. dataSem$cut_env (fromList [();();()]) s.locals = SOME x` by
    (fs [EVAL ``fromList [();();()]``,cut_env_def,domain_lookup,
         get_var_def,get_vars_SOME_IFF_data] \\ NO_TAC)
  \\ disch_then drule
  \\ fs [get_var_set_var]
  \\ disch_then drule
  \\ impl_tac THEN1 (unabbrev_all_tac \\ fs []
                     \\ fs [state_rel_def,EVAL ``good_dimindex (:'a)``,dimword_def])
  \\ strip_tac \\ fs []
  \\ reverse (Cases_on `res`) \\ fs [] THEN1 (fs [state_rel_def])
  \\ `?f cur. FLOOKUP s1.store NextFree = SOME (Word f) /\
              FLOOKUP s1.store CurrHeap = SOME (Word cur)` by
        (fs [state_rel_def,heap_in_memory_store_def] \\ NO_TAC)
  \\ ntac 5 (once_rewrite_tac [list_Seq_def])
  \\ fs [wordSemTheory.evaluate_def,word_exp_rw,lookup_insert,
         wordSemTheory.set_var_def]
  \\ qabbrev_tac `s0 = s with <|locals := x'; space := w2n w DIV 4 + 1|>`
  \\ `get_var 0 s0.locals = SOME (Number (&LENGTH x)) /\
      get_var 1 s0.locals = SOME v2 /\
      get_var 2 s0.locals = SOME (Number (&(4 * tag)))` by
   (unabbrev_all_tac \\ fs [get_var_def,cut_env_def]
    \\ rveq \\ fs [lookup_inter_alt] \\ EVAL_TAC \\ NO_TAC)
  \\ qpat_assum `get_var 1 s0.locals = SOME v2` assume_tac
  \\ rpt_drule state_rel_get_var_IMP \\ strip_tac
  \\ qpat_assum `get_var 2 s0.locals = SOME (Number (&(4 * tag)))` assume_tac
  \\ rpt_drule state_rel_get_var_Number_IMP \\ strip_tac \\ fs []
  \\ `small_int (:'a) (&LENGTH x)` by
   (fs [state_rel_thm]
    \\ qpat_assum `memory_rel c t.be s.refs s.space t.store _ _ _` assume_tac
    \\ qpat_assum `get_var 0 s.locals = SOME (Number (&LENGTH x))` assume_tac
    \\ qpat_assum `lookup 2 t.locals = SOME (Word w)` assume_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,APPEND,get_var_def]
    \\ fs [inter_insert,NOT_1_domain]
    \\ rpt_drule memory_rel_lookup
    \\ fs [adjust_var_def,lookup_insert] \\ strip_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,APPEND,get_var_def]
    \\ metis_tac [memory_rel_Number_IMP])
  \\ qpat_assum `get_var 0 s0.locals = SOME (Number (&LENGTH x))` assume_tac
  \\ rpt_drule state_rel_get_var_Number_IMP \\ strip_tac \\ fs []
  \\ fs [adjust_var_def] \\ fs [wordSemTheory.get_var_def]
  \\ qpat_assum `get_var 1 s0.locals = SOME v2` assume_tac
  \\ fs [lookup_insert]
  \\ `~(2 ≥ dimindex (:α)) /\ ~(4 ≥ dimindex (:α))` by
       (fs [state_rel_def,labPropsTheory.good_dimindex_def] \\ NO_TAC)
  \\ fs [lookup_insert]
  \\ assume_tac (GEN_ALL Make_ptr_bits_thm)
  \\ SEP_I_TAC "evaluate"
  \\ fs [wordSemTheory.set_var_def,lookup_insert] \\ rfs []
  \\ pop_assum (qspecl_then [`tag`,`LENGTH x`] mp_tac)
  \\ match_mp_tac (METIS_PROVE [] ``a /\ (a /\ b ==> c) ==> ((a ==> b) ==> c)``)
  \\ `16 * tag < dimword (:'a) /\ 4 * LENGTH x < dimword (:'a)` by
   (fs [encode_header_def,X_LT_DIV,small_int_def] \\ NO_TAC)
  \\ conj_tac THEN1
   (fs [Smallnum_def,shift_length_def]
    \\ rewrite_tac [GSYM w2n_11,w2n_lsr]
    \\ fs [ONCE_REWRITE_RULE [MULT_COMM] MULT_DIV]
    \\ fs [state_rel_def,heap_in_memory_store_def,shift_length_def])
  \\ strip_tac \\ fs []
  \\ `w2n w = 4 * LENGTH x` by
   (qpat_assum `state_rel c l1 l2 s t [] locs` assume_tac
    \\ rpt_drule state_rel_get_var_Number_IMP
    \\ fs [adjust_var_def,wordSemTheory.get_var_def,Smallnum_def] \\ NO_TAC)
  \\ fs [state_rel_thm,get_var_def]
  \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,APPEND]
  \\ rpt_drule memory_rel_lookup \\ fs [adjust_var_def]
  \\ qabbrev_tac `hd = (Smallnum (&(4 * tag)) || (3w:'a word) ||
                       (Smallnum (&LENGTH x) << (dimindex (:α) − c.len_size - 2)))`
  \\ fs [list_Seq_def]
  \\ strip_tac \\ fs [LENGTH_NIL]
  \\ assume_tac (GEN_ALL FromList1_code_thm)
  \\ SEP_I_TAC "evaluate"
  \\ pop_assum mp_tac
  \\ fs [wordSemTheory.set_var_def,wordSemTheory.get_var_def,lookup_insert]
  \\ `lookup FromList1_location s1.code = SOME (6,FromList1_code c)` by
       (fs [code_rel_def,stubs_def] \\ NO_TAC)
  \\ disch_then drule
  \\ `encode_header c (4 * tag) (LENGTH x) = SOME hd` by
   (fs [encode_header_def] \\ conj_tac THEN1
     (fs [encode_header_def,dimword_def,labPropsTheory.good_dimindex_def]
      \\ rfs [] \\ conj_tac \\ fs [] \\ rfs [DIV_LT_X]
      \\ fs [ONCE_REWRITE_RULE [MULT_COMM] MULT_DIV])
    \\ fs [make_header_def,Abbr`hd`]
    \\ fs [WORD_MUL_LSL,word_mul_n2w,Smallnum_def,EXP_LEMMA1]
    \\ rpt (AP_TERM_TAC ORELSE AP_THM_TAC)
    \\ fs [memory_rel_def,heap_in_memory_store_def]
    \\ fs [labPropsTheory.good_dimindex_def] \\ rfs [])
  \\ rpt_drule memory_rel_FromList
  \\ impl_tac THEN1
    (fs [Abbr `s0`,ONCE_REWRITE_RULE [MULT_COMM] MULT_DIV])
  \\ strip_tac
  \\ disch_then drule
  \\ impl_tac THEN1
   (fs [Abbr `s0`,ONCE_REWRITE_RULE [MULT_COMM] MULT_DIV]
    \\ fs [Smallnum_def,dimword_def,labPropsTheory.good_dimindex_def] \\ rfs [])
  \\ strip_tac \\ fs [lookup_def,EVAL ``join_env LN []``]
  \\ fs [Abbr`s0`]
  \\ fs [FAPPLY_FUPDATE_THM]
  \\ drule memory_rel_zero_space
  \\ match_mp_tac memory_rel_rearrange
  \\ fs [] \\ rw [] \\ fs []);

val MAP_FST_EQ_IMP_IS_SOME_ALOOKUP = store_thm("MAP_FST_EQ_IMP_IS_SOME_ALOOKUP",
  ``!xs ys.
      MAP FST xs = MAP FST ys ==>
      IS_SOME (ALOOKUP xs n) = IS_SOME (ALOOKUP ys n)``,
  Induct \\ fs [] \\ Cases \\ Cases_on `ys` \\ fs []
  \\ Cases_on `h` \\ fs [] \\ rw []);

val cut_env_adjust_set_insert_1 = store_thm("cut_env_adjust_set_insert_1",
  ``cut_env (adjust_set x) (insert 1 w l) =
    cut_env (adjust_set x) l``,
  fs [wordSemTheory.cut_env_def] \\ rw []
  \\ fs [lookup_inter_alt,lookup_insert]
  \\ rw [] \\ fs [SUBSET_DEF]
  \\ res_tac \\ fs [NOT_1_domain]);

val state_rel_IMP_Number_arg = store_thm("state_rel_IMP_Number_arg",
  ``state_rel c l1 l2 (call_env xs s) (call_env ys t) [] locs /\
    n < dimword (:'a) DIV 16 /\ LENGTH ys = LENGTH xs + 1 ==>
    state_rel c l1 l2
      (call_env (xs ++ [Number (& n)]) s)
      (call_env (ys ++ [Word (n2w (4 * n):'a word)]) t) [] locs``,
  fs [state_rel_thm,call_env_def,wordSemTheory.call_env_def] \\ rw []
  THEN1 (Cases_on `ys` \\ fs [lookup_fromList,lookup_fromList2])
  THEN1
   (fs [lookup_fromList,lookup_fromList2,EVEN_adjust_var]
    \\ POP_ASSUM MP_TAC \\ IF_CASES_TAC \\ fs []
    \\ rw [] \\ fs []
    \\ fs [adjust_var_def,adjust_var_DIV_2_ANY])
  \\ fs [fromList2_SNOC,fromList_SNOC,GSYM SNOC_APPEND]
  \\ fs [LEFT_ADD_DISTRIB,GSYM adjust_var_def]
  \\ full_simp_tac std_ss [SNOC_APPEND,GSYM APPEND_ASSOC]
  \\ match_mp_tac memory_rel_insert
  \\ simp_tac std_ss [APPEND]
  \\ `n2w (4 * n) = Smallnum (&n)` by
     (fs [labPropsTheory.good_dimindex_def,dimword_def,Smallnum_def] \\ NO_TAC)
  \\ fs [] \\ match_mp_tac IMP_memory_rel_Number
  \\ full_simp_tac std_ss [SNOC_APPEND,GSYM APPEND_ASSOC,APPEND]
  \\ fs [small_int_def,labPropsTheory.good_dimindex_def]
  \\ rfs [dimword_def]);

val assign_thm = Q.store_thm("assign_thm",
  `state_rel c l1 l2 s (t:('a,'ffi) wordSem$state) [] locs /\
   (op_requires_names op ==> names_opt <> NONE) /\
   cut_state_opt names_opt s = SOME x /\
   get_vars args x.locals = SOME vals /\
   t.termdep > 0 /\
   do_app op vals x = Rval (v,s2) ==>
   ?q r.
     evaluate (FST (assign c n l dest op args names_opt),t) = (q,r) /\
     (q = SOME NotEnoughSpace ==> r.ffi = t.ffi) /\
     (q <> SOME NotEnoughSpace ==>
     state_rel c l1 l2 (set_var dest v s2) r [] locs /\ q = NONE)`,
  strip_tac \\ drule (evaluate_GiveUp |> GEN_ALL) \\ rw [] \\ fs []
  \\ `t.termdep <> 0` by fs[]
  \\ Cases_on `?tag. op = FromList tag` \\ fs [] THEN1
   (imp_res_tac state_rel_cut_IMP
    \\ fs [assign_def] \\ rveq
    \\ fs [bvi_to_dataTheory.op_requires_names_def,
           bvi_to_dataTheory.op_space_reset_def,cut_state_opt_def]
    \\ Cases_on `names_opt` \\ fs []
    \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
    \\ fs [do_app]
    \\ `?v vs. vals = [Number (&LENGTH vs); v] /\ v_to_list v = SOME vs` by
           (every_case_tac \\ fs [] \\ rw [] \\ NO_TAC)
    \\ clean_tac
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs [LENGTH_EQ_2] \\ clean_tac
    \\ clean_tac
    \\ drule lookup_RefByte_location \\ fs [get_names_def]
    \\ fs [wordSemTheory.evaluate_def,list_Seq_def,word_exp_rw,
           wordSemTheory.find_code_def,wordSemTheory.set_var_def]
    \\ fs [wordSemTheory.add_ret_loc_def,wordSemTheory.find_code_def]
    \\ fs [wordSemTheory.bad_dest_args_def,wordSemTheory.get_vars_def,
           wordSemTheory.get_var_def,lookup_insert]
    \\ disch_then kall_tac
    \\ fs [cut_state_opt_def,cut_state_def]
    \\ rename1 `state_rel c l1 l2 s1 t [] locs`
    \\ Cases_on `dataSem$cut_env x' s.locals` \\ fs []
    \\ clean_tac \\ fs []
    \\ qabbrev_tac `s1 = s with locals := x`
    \\ `?y. cut_env (adjust_set x') t.locals = SOME y` by
         (match_mp_tac (GEN_ALL cut_env_IMP_cut_env) \\ fs []
          \\ metis_tac []) \\ fs []
    \\ Cases_on `lookup (adjust_var a1) t.locals` \\ fs []
    \\ Cases_on `lookup (adjust_var a2) t.locals` \\ fs []
    \\ fs[cut_env_adjust_set_insert_1]
    \\ `dimword (:α) <> 0` by (assume_tac ZERO_LT_dimword \\ decide_tac)
    \\ fs [wordSemTheory.dec_clock_def,EVAL ``(data_to_bvi s).refs``]
    \\ Q.MATCH_GOALSUB_ABBREV_TAC `evaluate (FromList_code _,t4)`
    \\ rveq
    \\ `state_rel c l1 l2 (s1 with clock := dimword(:'a))
          (t with <| clock := dimword(:'a); termdep := t.termdep - 1 |>)
            [] locs` by (fs [state_rel_def] \\ asm_exists_tac \\ fs [] \\ NO_TAC)
    \\ rpt_drule state_rel_call_env_push_env \\ fs []
    \\ `dataSem$get_vars [a1; a2] s.locals = SOME [Number (&LENGTH vs); v']` by
      (fs [dataSemTheory.get_vars_def] \\ every_case_tac \\ fs [cut_env_def]
       \\ clean_tac \\ fs [lookup_inter_alt,get_var_def] \\ NO_TAC)
    \\ `s1.locals = x` by (unabbrev_all_tac \\ fs []) \\ fs []
    \\ disch_then drule \\ fs []
    \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_def]
    \\ `dataSem$cut_env x' s1.locals = SOME s1.locals` by
     (unabbrev_all_tac \\ fs []
      \\ fs [cut_env_def] \\ clean_tac
      \\ fs [domain_inter] \\ fs [lookup_inter_alt] \\ NO_TAC)
    \\ fs [] \\ rfs []
    \\ disch_then drule \\ fs []
    \\ disch_then (qspecl_then [`n`,`l`,`NONE`] mp_tac) \\ fs []
    \\ strip_tac
    \\ `4 * tag < dimword (:'a) DIV 16` by (fs [encode_header_def] \\ NO_TAC)
    \\ rpt_drule state_rel_IMP_Number_arg
    \\ strip_tac
    \\ rpt_drule FromList_thm
    \\ simp [Once call_env_def,wordSemTheory.dec_clock_def,do_app_def,
             get_vars_def,get_var_def,lookup_insert,fromList_def,
             do_space_def,bvi_to_dataTheory.op_space_reset_def,
             bviSemTheory.do_app_def,do_app,call_env_def]
    \\ disch_then (qspecl_then [`l2`,`l1`] strip_assume_tac)
    \\ qmatch_assum_abbrev_tac
         `evaluate (FromList_code c,t5) = _`
    \\ `t5 = t4` by
     (unabbrev_all_tac \\ fs [wordSemTheory.call_env_def,
         wordSemTheory.push_env_def] \\ pairarg_tac \\ fs [] \\ NO_TAC)
    \\ fs [] \\ Cases_on `q = SOME NotEnoughSpace` THEN1 fs [] \\ fs []
    \\ rpt_drule state_rel_pop_env_IMP
    \\ simp [push_env_def,call_env_def,pop_env_def,dec_clock_def,
         Once dataSemTheory.bvi_to_data_def]
    \\ strip_tac \\ fs [] \\ clean_tac
    \\ `domain t2.locals = domain y` by
     (qspecl_then [`FromList_code c`,`t4`] mp_tac
           (wordPropsTheory.evaluate_stack_swap
              |> INST_TYPE [``:'b``|->``:'ffi``])
      \\ fs [] \\ fs [wordSemTheory.pop_env_def]
      \\ Cases_on `r'.stack` \\ fs [] \\ Cases_on `h` \\ fs []
      \\ rename1 `r2.stack = StackFrame ns opt::t'`
      \\ unabbrev_all_tac
      \\ fs [wordSemTheory.call_env_def,wordSemTheory.push_env_def]
      \\ pairarg_tac \\ Cases_on `opt`
      \\ fs [wordPropsTheory.s_key_eq_def,
            wordPropsTheory.s_frame_key_eq_def]
      \\ rw [] \\ drule env_to_list_lookup_equiv
      \\ fs [EXTENSION,domain_lookup,lookup_fromAList]
      \\ fs[GSYM IS_SOME_EXISTS]
      \\ imp_res_tac MAP_FST_EQ_IMP_IS_SOME_ALOOKUP \\ metis_tac []) \\ fs []
    \\ pop_assum mp_tac
    \\ pop_assum mp_tac
    \\ simp [state_rel_def]
    \\ fs [bviSemTheory.bvl_to_bvi_def,
           bviSemTheory.bvi_to_bvl_def,
           dataSemTheory.bvi_to_data_def,
           dataSemTheory.call_env_def,
           dataSemTheory.data_to_bvi_def,push_env_def,
           dataSemTheory.set_var_def,wordSemTheory.set_var_def]
    \\ fs [wordSemTheory.pop_env_def]
    \\ `t.clock = s.clock` by fs [state_rel_def] \\ fs []
    \\ unabbrev_all_tac \\ fs []
    \\ rpt (disch_then strip_assume_tac) \\ clean_tac \\ fs []
    \\ strip_tac THEN1
     (fs [lookup_insert,stack_rel_def,state_rel_def,contains_loc_def,
          wordSemTheory.pop_env_def] \\ rfs[] \\ clean_tac
      \\ every_case_tac \\ fs [] \\ clean_tac \\ fs [lookup_fromAList]
      \\ fs [wordSemTheory.push_env_def]
      \\ pairarg_tac \\ fs []
      \\ drule env_to_list_lookup_equiv
      \\ fs[contains_loc_def])
    \\ conj_tac THEN1 (fs [lookup_insert,adjust_var_11] \\ rw [])
    \\ asm_exists_tac \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac word_ml_inv_insert \\ fs [flat_def]
    \\ first_x_assum (fn th => mp_tac th \\ match_mp_tac word_ml_inv_rearrange)
    \\ fs[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[])
  \\ Cases_on `op = RefByte` \\ fs [] THEN1
   (imp_res_tac state_rel_cut_IMP
    \\ fs [assign_def] \\ rveq
    \\ fs [bvi_to_dataTheory.op_requires_names_def,
           bvi_to_dataTheory.op_space_reset_def,cut_state_opt_def]
    \\ Cases_on `names_opt` \\ fs []
    \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
    \\ fs [do_app]
    \\ `?i b. vals = [Number i; Number b]` by (every_case_tac \\ fs [] \\ NO_TAC)
    \\ clean_tac
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs [LENGTH_EQ_2] \\ clean_tac
    \\ Cases_on `0 <= i` \\ fs []
    \\ qpat_assum `_ = Rval (v,s2)` mp_tac
    \\ reverse IF_CASES_TAC \\ fs []
    \\ clean_tac \\ fs [wordSemTheory.evaluate_def]
    \\ fs [wordSemTheory.bad_dest_args_def]
    \\ fs [wordSemTheory.add_ret_loc_def,wordSemTheory.find_code_def]
    \\ drule lookup_RefByte_location \\ fs [get_names_def]
    \\ disch_then kall_tac
    \\ fs [cut_state_opt_def,cut_state_def]
    \\ rename1 `state_rel c l1 l2 s1 t [] locs`
    \\ Cases_on `dataSem$cut_env x' s.locals` \\ fs []
    \\ clean_tac \\ fs []
    \\ qabbrev_tac `s1 = s with locals := x`
    \\ `?y. cut_env (adjust_set x') t.locals = SOME y` by
         (match_mp_tac (GEN_ALL cut_env_IMP_cut_env) \\ fs []
          \\ metis_tac []) \\ fs []
    \\ `dimword (:α) <> 0` by (assume_tac ZERO_LT_dimword \\ decide_tac)
    \\ fs [wordSemTheory.dec_clock_def,EVAL ``(data_to_bvi s).refs``]
    \\ qpat_abbrev_tac `t4 = wordSem$call_env [Loc n l; _; _] _ with clock := _`
    \\ rename1 `get_vars [adjust_var a1; adjust_var a2] t = SOME [w1;w2]`
    \\ rename1 `get_vars [a1; a2] x = SOME [Number i; Number (&w2n w)]`
    \\ `state_rel c l1 l2 (s1 with clock := dimword(:'a))
          (t with <| clock := dimword(:'a); termdep := t.termdep - 1 |>)
            [] locs` by (fs [state_rel_def] \\ asm_exists_tac \\ fs [] \\ NO_TAC)
    \\ rpt_drule state_rel_call_env_push_env \\ fs []
    \\ `get_vars [a1; a2] s.locals = SOME [Number i; Number (&w2n w)]` by
      (fs [dataSemTheory.get_vars_def] \\ every_case_tac \\ fs [cut_env_def]
       \\ clean_tac \\ fs [lookup_inter_alt,get_var_def] \\ NO_TAC)
    \\ `s1.locals = x` by (unabbrev_all_tac \\ fs []) \\ fs []
    \\ disch_then drule \\ fs []
    \\ `dataSem$cut_env x' x = SOME x` by
     (unabbrev_all_tac \\ fs []
      \\ fs [cut_env_def] \\ clean_tac
      \\ fs [domain_inter] \\ fs [lookup_inter_alt])
    \\ disch_then drule \\ fs []
    \\ disch_then (qspecl_then [`n`,`l`,`NONE`] mp_tac) \\ fs []
    \\ strip_tac
    \\ rpt_drule RefByte_thm
    \\ simp [get_vars_def,call_env_def,get_var_def,lookup_fromList]
    \\ fs [do_app,EVAL ``(data_to_bvi s).refs``]
    \\ fs [EVAL ``get_var 0 (call_env [x1;x2;x3] y)``]
    \\ disch_then (qspecl_then [`l1`,`l2`] mp_tac)
    \\ impl_tac THEN1 EVAL_TAC
    \\ qpat_abbrev_tac `t5 = call_env [Loc n l; w1; w2] _`
    \\ `t5 = t4` by
     (unabbrev_all_tac \\ fs [wordSemTheory.call_env_def,
         wordSemTheory.push_env_def] \\ pairarg_tac \\ fs []
      \\ fs [wordSemTheory.env_to_list_def,wordSemTheory.dec_clock_def] \\ NO_TAC)
    \\ pop_assum (fn th => fs [th]) \\ strip_tac \\ fs []
    \\ Cases_on `q = SOME NotEnoughSpace` THEN1 fs [] \\ fs []
    \\ rpt_drule state_rel_pop_env_IMP
    \\ simp [push_env_def,call_env_def,pop_env_def,dec_clock_def,
         Once dataSemTheory.bvi_to_data_def]
    \\ strip_tac \\ fs [] \\ clean_tac
    \\ `domain t2.locals = domain y` by
     (qspecl_then [`RefByte_code c`,`t4`] mp_tac
           (wordPropsTheory.evaluate_stack_swap
              |> INST_TYPE [``:'b``|->``:'ffi``])
      \\ fs [] \\ fs [wordSemTheory.pop_env_def]
      \\ Cases_on `r'.stack` \\ fs [] \\ Cases_on `h` \\ fs []
      \\ rename1 `r2.stack = StackFrame ns opt::t'`
      \\ unabbrev_all_tac
      \\ fs [wordSemTheory.call_env_def,wordSemTheory.push_env_def]
      \\ pairarg_tac \\ Cases_on `opt`
      \\ fs [wordPropsTheory.s_key_eq_def,
            wordPropsTheory.s_frame_key_eq_def]
      \\ rw [] \\ drule env_to_list_lookup_equiv
      \\ fs [EXTENSION,domain_lookup,lookup_fromAList]
      \\ fs[GSYM IS_SOME_EXISTS]
      \\ imp_res_tac MAP_FST_EQ_IMP_IS_SOME_ALOOKUP \\ metis_tac []) \\ fs []
    \\ pop_assum mp_tac
    \\ pop_assum mp_tac
    \\ simp [state_rel_def]
    \\ fs [bviSemTheory.bvl_to_bvi_def,
           bviSemTheory.bvi_to_bvl_def,
           dataSemTheory.bvi_to_data_def,
           dataSemTheory.call_env_def,
           dataSemTheory.data_to_bvi_def,push_env_def,
           dataSemTheory.set_var_def,wordSemTheory.set_var_def]
    \\ fs [wordSemTheory.pop_env_def]
    \\ `t.clock = s.clock` by fs [state_rel_def] \\ fs []
    \\ unabbrev_all_tac \\ fs []
    \\ rpt (disch_then strip_assume_tac) \\ clean_tac \\ fs []
    \\ strip_tac THEN1
     (fs [lookup_insert,stack_rel_def,state_rel_def,contains_loc_def,
          wordSemTheory.pop_env_def] \\ rfs[] \\ clean_tac
      \\ every_case_tac \\ fs [] \\ clean_tac \\ fs [lookup_fromAList]
      \\ fs [wordSemTheory.push_env_def]
      \\ pairarg_tac \\ fs []
      \\ drule env_to_list_lookup_equiv
      \\ fs[contains_loc_def])
    \\ conj_tac THEN1 (fs [lookup_insert,adjust_var_11] \\ rw [])
    \\ asm_exists_tac \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac word_ml_inv_insert \\ fs [flat_def]
    \\ first_x_assum (fn th => mp_tac th \\ match_mp_tac word_ml_inv_rearrange)
    \\ fs[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[])
  \\ Cases_on `op = RefArray` \\ fs [] THEN1
   (imp_res_tac state_rel_cut_IMP
    \\ fs [assign_def] \\ rveq
    \\ fs [bvi_to_dataTheory.op_requires_names_def,
           bvi_to_dataTheory.op_space_reset_def,cut_state_opt_def]
    \\ Cases_on `names_opt` \\ fs []
    \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
    \\ fs [do_app]
    \\ `?i w. vals = [Number i; w]` by (every_case_tac \\ fs [] \\ NO_TAC)
    \\ clean_tac
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs [LENGTH_EQ_2] \\ clean_tac
    \\ Cases_on `0 <= i` \\ fs []
    \\ clean_tac \\ fs [wordSemTheory.evaluate_def]
    \\ fs [wordSemTheory.bad_dest_args_def]
    \\ fs [wordSemTheory.add_ret_loc_def,wordSemTheory.find_code_def]
    \\ drule lookup_RefByte_location \\ fs [get_names_def]
    \\ disch_then kall_tac
    \\ fs [cut_state_opt_def,cut_state_def]
    \\ rename1 `state_rel c l1 l2 s1 t [] locs`
    \\ Cases_on `dataSem$cut_env x' s.locals` \\ fs []
    \\ clean_tac \\ fs []
    \\ qabbrev_tac `s1 = s with locals := x`
    \\ `?y. cut_env (adjust_set x') t.locals = SOME y` by
         (match_mp_tac (GEN_ALL cut_env_IMP_cut_env) \\ fs []
          \\ metis_tac []) \\ fs []
    \\ `dimword (:α) <> 0` by (assume_tac ZERO_LT_dimword \\ decide_tac)
    \\ fs [wordSemTheory.dec_clock_def,EVAL ``(data_to_bvi s).refs``]
    \\ qpat_abbrev_tac `t4 = wordSem$call_env [Loc n l; _; _] _ with clock := _`
    \\ rename1 `get_vars [adjust_var a1; adjust_var a2] t = SOME [w1;w2]`
    \\ rename1 `get_vars [a1; a2] x = SOME [Number i;v2]`
    \\ `state_rel c l1 l2 (s1 with clock := dimword(:'a))
          (t with <| clock := dimword(:'a); termdep := t.termdep - 1 |>)
            [] locs` by (fs [state_rel_def] \\ asm_exists_tac \\ fs [] \\ NO_TAC)
    \\ rpt_drule state_rel_call_env_push_env \\ fs []
    \\ `get_vars [a1; a2] s.locals = SOME [Number i; v2]` by
      (fs [dataSemTheory.get_vars_def] \\ every_case_tac \\ fs [cut_env_def]
       \\ clean_tac \\ fs [lookup_inter_alt,get_var_def] \\ NO_TAC)
    \\ `s1.locals = x` by (unabbrev_all_tac \\ fs []) \\ fs []
    \\ disch_then drule \\ fs []
    \\ `dataSem$cut_env x' x = SOME x` by
     (unabbrev_all_tac \\ fs []
      \\ fs [cut_env_def] \\ clean_tac
      \\ fs [domain_inter] \\ fs [lookup_inter_alt])
    \\ disch_then drule \\ fs []
    \\ disch_then (qspecl_then [`n`,`l`,`NONE`] mp_tac) \\ fs []
    \\ strip_tac
    \\ rpt_drule RefArray_thm
    \\ simp [get_vars_def,call_env_def,get_var_def,lookup_fromList]
    \\ fs [do_app,EVAL ``(data_to_bvi s).refs``]
    \\ fs [EVAL ``get_var 0 (call_env [x1;x2;x3] y)``]
    \\ disch_then (qspecl_then [`l1`,`l2`] mp_tac)
    \\ impl_tac THEN1 EVAL_TAC
    \\ qpat_abbrev_tac `t5 = call_env [Loc n l; w1; w2] _`
    \\ `t5 = t4` by
     (unabbrev_all_tac \\ fs [wordSemTheory.call_env_def,
         wordSemTheory.push_env_def] \\ pairarg_tac \\ fs []
      \\ fs [wordSemTheory.env_to_list_def,wordSemTheory.dec_clock_def] \\ NO_TAC)
    \\ pop_assum (fn th => fs [th]) \\ strip_tac \\ fs []
    \\ Cases_on `q = SOME NotEnoughSpace` THEN1 fs [] \\ fs []
    \\ rpt_drule state_rel_pop_env_IMP
    \\ simp [push_env_def,call_env_def,pop_env_def,dec_clock_def,
         Once dataSemTheory.bvi_to_data_def]
    \\ strip_tac \\ fs [] \\ clean_tac
    \\ `domain t2.locals = domain y` by
     (qspecl_then [`RefArray_code c`,`t4`] mp_tac
           (wordPropsTheory.evaluate_stack_swap
              |> INST_TYPE [``:'b``|->``:'ffi``])
      \\ fs [] \\ fs [wordSemTheory.pop_env_def]
      \\ Cases_on `r'.stack` \\ fs [] \\ Cases_on `h` \\ fs []
      \\ rename1 `r2.stack = StackFrame ns opt::t'`
      \\ unabbrev_all_tac
      \\ fs [wordSemTheory.call_env_def,wordSemTheory.push_env_def]
      \\ pairarg_tac \\ Cases_on `opt`
      \\ fs [wordPropsTheory.s_key_eq_def,
            wordPropsTheory.s_frame_key_eq_def]
      \\ rw [] \\ drule env_to_list_lookup_equiv
      \\ fs [EXTENSION,domain_lookup,lookup_fromAList]
      \\ fs[GSYM IS_SOME_EXISTS]
      \\ imp_res_tac MAP_FST_EQ_IMP_IS_SOME_ALOOKUP \\ metis_tac []) \\ fs []
    \\ pop_assum mp_tac
    \\ pop_assum mp_tac
    \\ simp [state_rel_def]
    \\ fs [bviSemTheory.bvl_to_bvi_def,
           bviSemTheory.bvi_to_bvl_def,
           dataSemTheory.bvi_to_data_def,
           dataSemTheory.call_env_def,
           dataSemTheory.data_to_bvi_def,push_env_def,
           dataSemTheory.set_var_def,wordSemTheory.set_var_def]
    \\ fs [wordSemTheory.pop_env_def]
    \\ `t.clock = s.clock` by fs [state_rel_def] \\ fs []
    \\ unabbrev_all_tac \\ fs []
    \\ rpt (disch_then strip_assume_tac) \\ clean_tac \\ fs []
    \\ strip_tac THEN1
     (fs [lookup_insert,stack_rel_def,state_rel_def,contains_loc_def,
          wordSemTheory.pop_env_def] \\ rfs[] \\ clean_tac
      \\ every_case_tac \\ fs [] \\ clean_tac \\ fs [lookup_fromAList]
      \\ fs [wordSemTheory.push_env_def]
      \\ pairarg_tac \\ fs []
      \\ drule env_to_list_lookup_equiv
      \\ fs[contains_loc_def])
    \\ conj_tac THEN1 (fs [lookup_insert,adjust_var_11] \\ rw [])
    \\ asm_exists_tac \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac word_ml_inv_insert \\ fs [flat_def]
    \\ first_x_assum (fn th => mp_tac th \\ match_mp_tac word_ml_inv_rearrange)
    \\ fs[MEM] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[])
  \\ imp_res_tac state_rel_cut_IMP \\ pop_assum mp_tac
  \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` kall_tac \\ strip_tac
  \\ Cases_on `op = WordFromInt` \\ fs[] THEN1 (
    imp_res_tac get_vars_IMP_LENGTH
    \\ fs[do_app]
    \\ every_case_tac \\ fs[]
    \\ clean_tac
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs[LENGTH_EQ_NUM_compute] \\ clean_tac
    \\ fs[state_rel_thm] \\ eval_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
    \\ strip_tac
    \\ fs[wordSemTheory.get_vars_def]
    \\ every_case_tac \\ fs[] \\ clean_tac
    \\ rpt_drule memory_rel_Number_IMP \\ rw[]
    \\ simp[assign_def]
    \\ BasicProvers.TOP_CASE_TAC
    >- simp[]
    \\ simp[list_Seq_def]
    \\ drule(GEN_ALL memory_rel_WordFromInt)
    \\ qpat_abbrev_tac`w64 = i2w i`
    \\ disch_then(qspec_then`w64`mp_tac o CONV_RULE(SWAP_FORALL_CONV))
    \\ qspecl_then[`:'a`,`w64`]strip_assume_tac Word64Rep_DataElement
    \\ simp[]
    \\ qmatch_assum_abbrev_tac`encode_header _ _ len = _`
    \\ `len = LENGTH ws`
    by (
      fs[Word64Rep_def,Abbr`len`]
      \\ IF_CASES_TAC \\ fs[] )
    \\ qunabbrev_tac`len` \\ fs[]
    \\ impl_tac
    >- ( fs[consume_space_def] )
    \\ strip_tac
    \\ `2 < dimindex(:'a)` by fs[good_dimindex_def]
    \\ Cases_on`ws` \\ fs[ADD1]
    \\ fs[store_list_def,consume_space_def]
    \\ rveq \\ eval_tac
    \\ fs[lookup_insert,wordSemTheory.get_var_def,dataSemTheory.get_var_def]
    \\ IF_CASES_TAC
    \\ eval_tac
    \\ simp[wordSemTheory.get_var_def,lookup_insert,
            wordSemTheory.mem_store_def,
            wordSemTheory.set_store_def,FLOOKUP_UPDATE]
    >- (
      conj_tac >- rw[]
      \\ fs[LENGTH_EQ_NUM_compute]
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
      \\ match_mp_tac memory_rel_insert
      \\ fs[inter_insert_ODD_adjust_set_alt]
      \\ fs[make_ptr_def,FAPPLY_FUPDATE_THM,store_list_def]
      \\ rveq
      \\ qmatch_abbrev_tac`memory_rel c _ refs sp st mem _ ((_,w1)::_)`
      \\ qmatch_assum_abbrev_tac`memory_rel c _ refs sp' st mem' _ ((_,w1)::_)`
      \\ match_mp_tac (GEN_ALL memory_rel_less_space)
      \\ qexists_tac`sp'`
      \\ reverse conj_tac >- simp[Abbr`sp`,Abbr`sp'`]
      \\ `mem = mem'`
      by (
        simp[Abbr`mem`,Abbr`mem'`,FUN_EQ_THM,APPLY_UPDATE_THM]
        \\ fs[Word64Rep_def] \\ rveq
        \\ `(63 >< 0) w64 = (Smallnum i >>>2)`
        by (
          fs[Abbr`w64`,Smallnum_i2w]
          \\ cheat (* word proof *) )
        \\ pop_assum SUBST_ALL_TAC
        \\ rw[]
        \\ `F` suffices_by rw[]
        \\ pop_assum mp_tac
        \\ simp[]
        \\ fs[bytes_in_word_def,good_dimindex_def]
        \\ EVAL_TAC \\ fs[dimword_def] )
      \\ rw[])
    \\ qmatch_assum_rename_tac`LENGTH z ≠ 0`
    \\ Cases_on`z` \\ fs[ADD1]
    \\ fs[store_list_def,WORD_MUL_LSL,lookup_insert,FLOOKUP_UPDATE]
    \\ conj_tac >- rw[]
    \\ qpat_x_assum` _ = LENGTH _ + _`mp_tac
    \\ rw[]
    \\ qmatch_assum_rename_tac`2 = LENGTH z + 2`
    \\ `LENGTH z = 0` by decide_tac
    \\ fs[LENGTH_EQ_NUM_compute]
    \\ fs[store_list_def]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert
    \\ fs[inter_insert_ODD_adjust_set_alt]
    \\ fs[make_ptr_def,FAPPLY_FUPDATE_THM]
    \\ rveq
    \\ qmatch_abbrev_tac`memory_rel c _ refs sp st mem _ ((_,w1)::_)`
    \\ qmatch_assum_abbrev_tac`memory_rel c _ refs sp st mem' _ ((_,w2)::_)`
    \\ `mem = mem'`
    by (
      simp[Abbr`mem`,Abbr`mem'`,FUN_EQ_THM,APPLY_UPDATE_THM]
      \\ fs[Word64Rep_def] \\ rveq
      \\ rfs[good_dimindex_def] \\ rfs[]
      \\ qpat_abbrev_tac`w0 = (63 >< _) w64`
      \\ `w0 = 0w`
      by (
        imp_res_tac small_int_IMP_MIN_MAX
        \\ rfs[good_dimindex_def]
        \\ simp[Abbr`w64`]
        \\ qpat_x_assum`dimindex _ = _`assume_tac
        \\ cheat (* word proof *) )
      \\ pop_assum SUBST1_TAC
      \\ rw[]
      \\ TRY (
        `F` suffices_by rw[]
        \\ ntac 2 (pop_assum mp_tac)
        \\ simp[bytes_in_word_def]
        \\ EVAL_TAC
        \\ simp[dimword_def]
        \\ NO_TAC)
      \\ simp[Smallnum_i2w,Abbr`w64`]
      \\ imp_res_tac small_int_IMP_MIN_MAX
      \\ rfs[good_dimindex_def]
      \\ qpat_x_assum`dimindex _ = _`assume_tac
      \\ cheat (* word proof *) )
    \\ `w1 = w2`
    by ( simp[Abbr`w1`,Abbr`w2`,GSYM WORD_MUL_LSL] )
    \\ rw[])
  \\ Cases_on `?tag. op = TagEq tag` \\ fs [] THEN1
   (imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
    \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
    \\ clean_tac \\ fs []
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs [LENGTH_EQ_1] \\ clean_tac
    \\ qpat_x_assum `state_rel c l1 l2 x t [] locs` (fn th => NTAC 2 (mp_tac th))
    \\ strip_tac
    \\ simp_tac std_ss [state_rel_thm] \\ strip_tac \\ fs [] \\ eval_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
    \\ strip_tac \\ fs []
    \\ fs [assign_def,list_Seq_def] \\ eval_tac
    \\ reverse IF_CASES_TAC THEN1
     (eval_tac
      \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
      \\ `n' <> tag` by
       (strip_tac \\ clean_tac
        \\ rpt_drule memory_rel_Block_IMP \\ strip_tac \\ fs []
        \\ CCONTR_TAC \\ fs []
        \\ imp_res_tac encode_header_tag_mask \\ NO_TAC)
      \\ fs [] \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
      \\ match_mp_tac memory_rel_insert \\ fs [inter_insert_ODD_adjust_set_alt]
      \\ match_mp_tac memory_rel_Boolv_F \\ fs [])
    \\ imp_res_tac get_vars_1_imp
    \\ eval_tac \\ fs [wordSemTheory.get_var_def,asmSemTheory.word_cmp_def,
         wordSemTheory.get_var_imm_def,lookup_insert]
    \\ rpt_drule memory_rel_Block_IMP \\ strip_tac \\ fs []
    \\ fs [word_and_one_eq_0_iff |> SIMP_RULE (srw_ss()) []]
    \\ pop_assum mp_tac \\ IF_CASES_TAC \\ fs [] THEN1
     (fs [word_mul_n2w,word_add_n2w] \\ strip_tac
      \\ fs [LESS_DIV_16_IMP,DECIDE ``16 * n = 16 * m <=> n = m:num``]
      \\ IF_CASES_TAC \\ fs [lookup_insert]
      \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
      \\ match_mp_tac memory_rel_insert \\ fs [inter_insert_ODD_adjust_set_alt]
      \\ TRY (match_mp_tac memory_rel_Boolv_T)
      \\ TRY (match_mp_tac memory_rel_Boolv_F) \\ fs [])
    \\ strip_tac \\ fs []
    \\ `!w. word_exp (t with locals := insert 1 (Word w) t.locals)
          (real_addr c (adjust_var a1)) = SOME (Word a)` by
      (strip_tac \\ match_mp_tac (GEN_ALL get_real_addr_lemma)
       \\ fs [wordSemTheory.get_var_def,lookup_insert] \\ NO_TAC) \\ fs []
    \\ rpt_drule encode_header_tag_mask \\ fs []
    \\ fs [LESS_DIV_16_IMP,DECIDE ``16 * n = 16 * m <=> n = m:num``]
    \\ strip_tac \\ fs []
    \\ IF_CASES_TAC \\ fs []
    \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs [inter_insert_ODD_adjust_set_alt]
    \\ TRY (match_mp_tac memory_rel_Boolv_T)
    \\ TRY (match_mp_tac memory_rel_Boolv_F) \\ fs [])
  \\ Cases_on `?tag len. op = TagLenEq tag len` \\ fs [] THEN1
   (imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
    \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
    \\ clean_tac \\ fs []
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs [LENGTH_EQ_1] \\ clean_tac
    \\ qpat_x_assum `state_rel c l1 l2 x t [] locs` (fn th => NTAC 2 (mp_tac th))
    \\ strip_tac
    \\ simp_tac std_ss [state_rel_thm] \\ strip_tac \\ fs [] \\ eval_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
    \\ strip_tac \\ fs []
    \\ fs [assign_def] \\ IF_CASES_TAC \\ fs [] \\ clean_tac
    THEN1
     (reverse IF_CASES_TAC
      \\ fs [LENGTH_NIL]
      \\ imp_res_tac get_vars_1_imp \\ eval_tac
      \\ fs [wordSemTheory.get_var_imm_def,asmSemTheory.word_cmp_def]
      THEN1
       (fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
        \\ imp_res_tac memory_rel_tag_limit
        \\ rpt_drule (DECIDE ``n < m /\ ~(k < m:num) ==> n <> k``) \\ fs []
        \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
        \\ match_mp_tac memory_rel_insert \\ fs []
        \\ match_mp_tac memory_rel_Boolv_F \\ fs [])
      \\ rpt_drule memory_rel_test_nil_eq \\ strip_tac \\ fs []
      \\ IF_CASES_TAC \\ fs []
      \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
      \\ match_mp_tac memory_rel_insert \\ fs []
      \\ TRY (match_mp_tac memory_rel_Boolv_F) \\ fs []
      \\ TRY (match_mp_tac memory_rel_Boolv_T) \\ fs [])
    \\ CASE_TAC \\ fs [] THEN1
     (eval_tac \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
      \\ match_mp_tac memory_rel_insert \\ fs []
      \\ rpt_drule memory_rel_test_none_eq \\ strip_tac \\ fs []
      \\ match_mp_tac memory_rel_Boolv_F \\ fs [])
    \\ fs [list_Seq_def] \\ eval_tac \\ fs [wordSemTheory.get_var_imm_def]
    \\ imp_res_tac get_vars_1_imp \\ eval_tac
    \\ fs [wordSemTheory.get_var_def,lookup_insert,asmSemTheory.word_cmp_def]
    \\ rpt_drule memory_rel_Block_IMP \\ strip_tac \\ fs []
    \\ fs [word_and_one_eq_0_iff |> SIMP_RULE (srw_ss()) []]
    \\ IF_CASES_TAC \\ fs [] THEN1
     (IF_CASES_TAC \\ fs [] \\ drule encode_header_NEQ_0 \\ strip_tac \\ fs []
      \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
      \\ fs [inter_insert_ODD_adjust_set]
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
      \\ match_mp_tac memory_rel_insert \\ fs []
      \\ match_mp_tac memory_rel_Boolv_F \\ fs [])
    \\ `word_exp (t with locals := insert 1 (Word 0w) t.locals)
          (real_addr c (adjust_var a1)) = SOME (Word a)` by
      (match_mp_tac (GEN_ALL get_real_addr_lemma)
       \\ fs [wordSemTheory.get_var_def,lookup_insert]) \\ fs []
    \\ drule (GEN_ALL encode_header_EQ)
    \\ qpat_x_assum `encode_header _ _ _ = _` (assume_tac o GSYM)
    \\ disch_then drule \\ fs [] \\ impl_tac
    \\ TRY (fs [memory_rel_def,heap_in_memory_store_def] \\ NO_TAC) \\ fs []
    \\ disch_then kall_tac \\ fs [DECIDE ``4 * k = 4 * l <=> k = l:num``]
    \\ rw [lookup_insert,adjust_var_11] \\ fs []
    \\ rw [lookup_insert,adjust_var_11] \\ fs []
    \\ fs [inter_insert_ODD_adjust_set]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ TRY (match_mp_tac memory_rel_Boolv_F) \\ fs []
    \\ TRY (match_mp_tac memory_rel_Boolv_T) \\ fs [])
  \\ Cases_on `op = Add` \\ fs [] THEN1
   (imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
    \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
    \\ clean_tac \\ fs []
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs [LENGTH_EQ_2] \\ clean_tac
    \\ fs [get_var_def]
    \\ qpat_x_assum `state_rel c l1 l2 x t [] locs` (fn th => NTAC 2 (mp_tac th))
    \\ strip_tac
    \\ simp_tac std_ss [state_rel_thm] \\ strip_tac \\ fs [] \\ eval_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
    \\ strip_tac \\ fs []
    \\ rpt_drule memory_rel_Number_IMP_Word_2
    \\ strip_tac \\ clean_tac
    \\ rpt_drule memory_rel_Add \\ fs [] \\ strip_tac
    \\ fs [assign_def]
    \\ imp_res_tac get_vars_2_imp
    \\ eval_tac
    \\ fs [wordSemTheory.get_var_def,wordSemTheory.get_var_imm_def]
    \\ eval_tac
    \\ fs [asmSemTheory.word_cmp_def]
    \\ reverse IF_CASES_TAC \\ fs []
    THEN1
      (rpt_drule (evaluate_GiveUp
         |> Q.INST [`t`|->`(t with locals := insert 1 x t.locals)`]
         |> REWRITE_RULE [state_rel_insert_1])
       \\ disch_then (qspec_then `Word (w1 ‖ w2)` strip_assume_tac) \\ fs [])
    \\ fs [lookup_insert,adjust_var_NEQ,adjust_var_11]
    \\ rw [] \\ fs []
    \\ fs [inter_insert_ODD_adjust_set]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,APPEND]
    \\ drule memory_rel_zero_space \\ fs [])
  \\ Cases_on `op = Sub` \\ fs [] THEN1
   (imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
    \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
    \\ clean_tac \\ fs []
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs [LENGTH_EQ_2] \\ clean_tac
    \\ fs [get_var_def]
    \\ qpat_x_assum `state_rel c l1 l2 x t [] locs` (fn th => NTAC 2 (mp_tac th))
    \\ strip_tac
    \\ simp_tac std_ss [state_rel_thm] \\ strip_tac \\ fs [] \\ eval_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
    \\ strip_tac \\ fs []
    \\ rpt_drule memory_rel_Number_IMP_Word_2
    \\ strip_tac \\ clean_tac
    \\ rpt_drule memory_rel_Sub \\ fs [] \\ strip_tac
    \\ fs [assign_def]
    \\ imp_res_tac get_vars_2_imp
    \\ eval_tac
    \\ fs [wordSemTheory.get_var_def,wordSemTheory.get_var_imm_def]
    \\ eval_tac
    \\ fs [asmSemTheory.word_cmp_def]
    \\ reverse IF_CASES_TAC \\ fs []
    THEN1
      (rpt_drule (evaluate_GiveUp
         |> Q.INST [`t`|->`(t with locals := insert 1 x t.locals)`]
         |> REWRITE_RULE [state_rel_insert_1])
       \\ disch_then (qspec_then `Word (w1 ‖ w2)` strip_assume_tac) \\ fs [])
    \\ fs [lookup_insert,adjust_var_NEQ,adjust_var_11]
    \\ rw [] \\ fs []
    \\ fs [inter_insert_ODD_adjust_set]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,APPEND]
    \\ drule memory_rel_zero_space \\ fs [])
  \\ Cases_on `op = LengthByte` \\ fs [] THEN1
   (imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
    \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
    \\ clean_tac \\ fs []
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs [LENGTH_EQ_1] \\ clean_tac
    \\ fs [get_var_def]
    \\ fs [state_rel_thm] \\ eval_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
    \\ strip_tac
    \\ rpt_drule memory_rel_ByteArray_IMP \\ fs [] \\ rw []
    \\ fs [assign_def]
    \\ fs [wordSemTheory.get_vars_def]
    \\ Cases_on `get_var (adjust_var a1) t` \\ fs [] \\ clean_tac
    \\ eval_tac
    \\ fs [wordSemTheory.get_var_def,wordSemTheory.get_var_imm_def]
    \\ fs [asmSemTheory.word_cmp_def,word_and_one_eq_0_iff
             |> SIMP_RULE (srw_ss()) []]
    \\ `shift_length c < dimindex (:α)` by (fs [memory_rel_def] \\ NO_TAC)
    \\ `word_exp t (real_addr c (adjust_var a1)) = SOME (Word a)` by
         (match_mp_tac (GEN_ALL get_real_addr_lemma)
          \\ fs [wordSemTheory.get_var_def] \\ NO_TAC) \\ fs []
    \\ IF_CASES_TAC
    >- ( fs[good_dimindex_def] \\ rfs[shift_def] )
    \\ pop_assum kall_tac
    \\ simp[]
    \\ `2 < dimindex (:'a)` by
         (fs [labPropsTheory.good_dimindex_def] \\ fs [])
    \\ fs [] \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
    \\ fs [WORD_MUL_LSL,WORD_LEFT_ADD_DISTRIB,GSYM word_add_n2w]
    \\ fs [word_mul_n2w]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ fs[good_dimindex_def]
    \\ rfs[shift_def,bytes_in_word_def,WORD_LEFT_ADD_DISTRIB,word_mul_n2w]
    \\ match_mp_tac (IMP_memory_rel_Number_num3
         |> SIMP_RULE std_ss [WORD_MUL_LSL,word_mul_n2w]) \\ fs []
    \\ fs[good_dimindex_def])
  \\ Cases_on `op = IsBlock` \\ fs [] THEN1
   (imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
    \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
    \\ clean_tac \\ fs []
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs [LENGTH_EQ_1] \\ clean_tac
    \\ fs [get_var_def]
    \\ fs [state_rel_thm] \\ eval_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
    \\ strip_tac THEN1
     (imp_res_tac memory_rel_Number_IMP \\ clean_tac
      \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_imm_def]
      \\ every_case_tac \\ fs [] \\ clean_tac \\ fs []
      \\ fs [assign_def] \\ eval_tac
      \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_imm_def,
             asmSemTheory.word_cmp_def,Smallnum_bits]
      \\ fs [] \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
      \\ match_mp_tac memory_rel_insert \\ fs []
      \\ match_mp_tac memory_rel_Boolv_F \\ fs [])
    THEN1
     (rpt_drule memory_rel_Word64_IMP \\ strip_tac \\ clean_tac
      \\ pop_assum kall_tac
      \\ fs[dataSemTheory.get_vars_def,wordSemTheory.get_vars_def]
      \\ every_case_tac \\ fs[] \\ clean_tac
      \\ fs[assign_def] \\ eval_tac
      \\ simp[wordSemTheory.get_var_imm_def,asmSemTheory.word_cmp_def,get_addr_and_1_not_0]
      \\ drule (GEN_ALL(CONV_RULE(LAND_CONV(move_conj_left(same_const``get_real_addr`` o #1 o strip_comb o lhs)))get_real_addr_lemma))
      \\ simp[] \\ disch_then drule \\ simp[] \\ strip_tac
      \\ simp[Once wordSemTheory.get_var_def]
      \\ fs[word_bit_test]
      \\ simp[lookup_insert]
      \\ conj_tac >- rw[]
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,inter_insert_ODD_adjust_set]
      \\ match_mp_tac memory_rel_insert \\ fs []
      \\ match_mp_tac memory_rel_Boolv_F \\ fs [])
    THEN1
     (rpt_drule memory_rel_Block_IMP \\ strip_tac \\ clean_tac
      \\ pop_assum mp_tac \\ IF_CASES_TAC \\ clean_tac \\ strip_tac
      THEN1
       (fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_imm_def]
        \\ every_case_tac \\ fs [] \\ clean_tac \\ fs []
        \\ fs [assign_def] \\ eval_tac
        \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_imm_def,
               asmSemTheory.word_cmp_def,Smallnum_bits]
        \\ fs [word_index_test]
        \\ IF_CASES_TAC \\ rfs [IsBlock_word_lemma]
        \\ fs [] \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
        \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
        \\ match_mp_tac memory_rel_insert \\ fs []
        \\ match_mp_tac memory_rel_Boolv_T \\ fs [])
      \\ fs [word_bit_test]
      \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_imm_def]
      \\ every_case_tac \\ fs [] \\ clean_tac \\ fs []
      \\ fs [assign_def] \\ eval_tac
      \\ fs [wordSemTheory.get_var_def,wordSemTheory.get_var_imm_def,
             asmSemTheory.word_cmp_def,word_index_test]
      \\ `shift_length c < dimindex (:α)` by (fs [memory_rel_def] \\ NO_TAC)
      \\ `word_exp t (real_addr c (adjust_var a1)) = SOME (Word a)` by
           (match_mp_tac (GEN_ALL get_real_addr_lemma)
            \\ fs [wordSemTheory.get_var_def] \\ NO_TAC) \\ fs []
      \\ fs [] \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,inter_insert_ODD_adjust_set]
      \\ match_mp_tac memory_rel_insert \\ fs []
      \\ match_mp_tac memory_rel_Boolv_T \\ fs [])
    \\ rpt_drule memory_rel_RefPtr_IMP \\ strip_tac \\ clean_tac
    \\ fs [word_bit_test,word_index_test]
    \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_imm_def]
    \\ every_case_tac \\ fs [] \\ clean_tac \\ fs []
    \\ fs [assign_def] \\ eval_tac
    \\ fs [wordSemTheory.get_var_def,wordSemTheory.get_var_imm_def,
             asmSemTheory.word_cmp_def,word_index_test]
    \\ `word_exp t (real_addr c (adjust_var a1)) = SOME (Word a)` by
           (match_mp_tac (GEN_ALL get_real_addr_lemma)
            \\ fs [wordSemTheory.get_var_def] \\ NO_TAC) \\ fs []
    \\ fs [] \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC,inter_insert_ODD_adjust_set]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ match_mp_tac memory_rel_Boolv_F \\ fs [])
  \\ Cases_on `op = Length` \\ fs [] THEN1
   (imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
    \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
    \\ clean_tac \\ fs []
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs [LENGTH_EQ_1] \\ clean_tac
    \\ fs [get_var_def]
    \\ fs [state_rel_thm] \\ eval_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
    \\ strip_tac
    \\ rpt_drule memory_rel_ValueArray_IMP \\ fs [] \\ rw []
    \\ fs [assign_def]
    \\ fs [wordSemTheory.get_vars_def]
    \\ Cases_on `get_var (adjust_var a1) t` \\ fs [] \\ clean_tac
    \\ eval_tac
    \\ fs [wordSemTheory.get_var_def,wordSemTheory.get_var_imm_def]
    \\ fs [asmSemTheory.word_cmp_def,word_and_one_eq_0_iff
             |> SIMP_RULE (srw_ss()) []]
    \\ `shift_length c < dimindex (:α)` by (fs [memory_rel_def] \\ NO_TAC)
    \\ `word_exp t (real_addr c (adjust_var a1)) = SOME (Word a)` by
         (match_mp_tac (GEN_ALL get_real_addr_lemma)
          \\ fs [wordSemTheory.get_var_def] \\ NO_TAC) \\ fs []
    \\ fs [GSYM NOT_LESS,GREATER_EQ]
    \\ `c.len_size <> 0` by
        (fs [memory_rel_def,heap_in_memory_store_def] \\ NO_TAC)
    \\ fs [NOT_LESS]
    \\ `~(dimindex (:α) <= 2)` by
           (fs [labPropsTheory.good_dimindex_def] \\ NO_TAC)
    \\ fs [] \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ fs [decode_length_def]
    \\ match_mp_tac IMP_memory_rel_Number_num \\ fs [])
  \\ Cases_on `op = LengthBlock` \\ fs [] THEN1
   (imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
    \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
    \\ clean_tac \\ fs []
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs [LENGTH_EQ_1] \\ clean_tac
    \\ fs [get_var_def]
    \\ fs [state_rel_thm] \\ eval_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
    \\ strip_tac
    \\ drule memory_rel_Block_IMP \\ fs [] \\ rw []
    \\ fs [assign_def]
    \\ fs [wordSemTheory.get_vars_def]
    \\ Cases_on `get_var (adjust_var a1) t` \\ fs [] \\ clean_tac
    \\ eval_tac
    \\ fs [wordSemTheory.get_var_def,wordSemTheory.get_var_imm_def]
    \\ fs [asmSemTheory.word_cmp_def,word_and_one_eq_0_iff
             |> SIMP_RULE (srw_ss()) []]
    \\ reverse (Cases_on `w ' 0`) \\ fs [] THEN1
     (fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
      \\ match_mp_tac memory_rel_insert \\ fs []
      \\ match_mp_tac (IMP_memory_rel_Number |> Q.INST [`i`|->`0`]
            |> SIMP_RULE std_ss [EVAL ``Smallnum 0``])
      \\ fs [] \\ fs [labPropsTheory.good_dimindex_def,dimword_def]
      \\ EVAL_TAC \\ rw [labPropsTheory.good_dimindex_def,dimword_def])
    \\ `shift_length c < dimindex (:α)` by (fs [memory_rel_def] \\ NO_TAC)
    \\ `word_exp t (real_addr c (adjust_var a1)) = SOME (Word a)` by
         (match_mp_tac (GEN_ALL get_real_addr_lemma)
          \\ fs [wordSemTheory.get_var_def] \\ NO_TAC) \\ fs []
    \\ fs [GSYM NOT_LESS,GREATER_EQ]
    \\ `c.len_size <> 0` by
        (fs [memory_rel_def,heap_in_memory_store_def] \\ NO_TAC)
    \\ fs [NOT_LESS]
    \\ `~(dimindex (:α) <= 2)` by
           (fs [labPropsTheory.good_dimindex_def] \\ NO_TAC)
    \\ fs [] \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ fs [decode_length_def]
    \\ match_mp_tac IMP_memory_rel_Number_num \\ fs [])
  \\ Cases_on `op = GreaterEq` \\ fs [] THEN1
   (imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
    \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
    \\ clean_tac \\ fs []
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs [LENGTH_EQ_2] \\ clean_tac
    \\ fs [get_var_def]
    \\ fs [state_rel_thm] \\ eval_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
    \\ strip_tac
    \\ rpt_drule memory_rel_Number_LESS \\ rw [] \\ fs []
    \\ fs [wordSemTheory.get_vars_def] \\ every_case_tac
    \\ fs [wordSemTheory.get_var_imm_def] \\ clean_tac
    \\ fs [assign_def] \\ eval_tac
    \\ fs [wordSemTheory.get_var_imm_def,asmSemTheory.word_cmp_def]
    \\ fs [intLib.COOPER_PROVE `` i >= j:int <=> ~(i < j)``]
    \\ IF_CASES_TAC \\ fs []
    \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ TRY (match_mp_tac memory_rel_Boolv_T \\ fs [] \\ NO_TAC)
    \\ TRY (match_mp_tac memory_rel_Boolv_F \\ fs [] \\ NO_TAC))
  \\ Cases_on `op = Greater` \\ fs [] THEN1
   (imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
    \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
    \\ clean_tac \\ fs []
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs [LENGTH_EQ_2] \\ clean_tac
    \\ fs [get_var_def]
    \\ fs [state_rel_thm] \\ eval_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
    \\ strip_tac
    \\ rpt_drule memory_rel_Number_LESS_EQ \\ rw [] \\ fs []
    \\ fs [wordSemTheory.get_vars_def] \\ every_case_tac
    \\ fs [wordSemTheory.get_var_imm_def] \\ clean_tac
    \\ fs [assign_def] \\ eval_tac
    \\ fs [wordSemTheory.get_var_imm_def,asmSemTheory.word_cmp_def]
    \\ simp [word_less_lemma1]
    \\ fs [intLib.COOPER_PROVE `` i > j:int <=> ~(i <= j)``]
    \\ IF_CASES_TAC \\ fs []
    \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ TRY (match_mp_tac memory_rel_Boolv_T \\ fs [] \\ NO_TAC)
    \\ TRY (match_mp_tac memory_rel_Boolv_F \\ fs [] \\ NO_TAC))
  \\ Cases_on `op = LessEq` \\ fs [] THEN1
   (imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
    \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
    \\ clean_tac \\ fs []
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs [LENGTH_EQ_2] \\ clean_tac
    \\ fs [get_var_def]
    \\ fs [state_rel_thm] \\ eval_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
    \\ strip_tac
    \\ rpt_drule memory_rel_Number_LESS_EQ \\ rw [] \\ fs []
    \\ fs [wordSemTheory.get_vars_def] \\ every_case_tac
    \\ fs [wordSemTheory.get_var_imm_def] \\ clean_tac
    \\ fs [assign_def] \\ eval_tac
    \\ fs [wordSemTheory.get_var_imm_def,asmSemTheory.word_cmp_def]
    \\ fs [WORD_NOT_LESS,intLib.COOPER_PROVE ``~(i < j) <=> j <= i:int``]
    \\ simp [word_less_lemma1]
    \\ IF_CASES_TAC \\ fs []
    \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ TRY (match_mp_tac memory_rel_Boolv_T \\ fs [] \\ NO_TAC)
    \\ TRY (match_mp_tac memory_rel_Boolv_F \\ fs [] \\ NO_TAC))
  \\ Cases_on `op = Less` \\ fs [] THEN1
   (imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
    \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
    \\ clean_tac \\ fs []
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs [LENGTH_EQ_2] \\ clean_tac
    \\ fs [get_var_def]
    \\ fs [state_rel_thm] \\ eval_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
    \\ strip_tac
    \\ rpt_drule memory_rel_Number_LESS \\ rw [] \\ fs []
    \\ fs [wordSemTheory.get_vars_def] \\ every_case_tac
    \\ fs [wordSemTheory.get_var_imm_def] \\ clean_tac
    \\ fs [assign_def] \\ eval_tac
    \\ fs [wordSemTheory.get_var_imm_def,asmSemTheory.word_cmp_def]
    \\ IF_CASES_TAC \\ fs []
    \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ TRY (match_mp_tac memory_rel_Boolv_T \\ fs [] \\ NO_TAC)
    \\ TRY (match_mp_tac memory_rel_Boolv_F \\ fs [] \\ NO_TAC))
  \\ Cases_on `op = Equal` \\ fs [] THEN1
   (imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
    \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
    \\ clean_tac \\ fs []
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs [LENGTH_EQ_2] \\ clean_tac
    \\ fs [get_var_def]
    \\ fs [state_rel_thm] \\ eval_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
    \\ strip_tac
    \\ TRY (rpt_drule memory_rel_Number_EQ) \\ rw [] \\ fs []
    \\ TRY (rpt_drule memory_rel_RefPtr_EQ) \\ rw [] \\ fs []
    \\ TRY (
      `(v1 && 1w) = 0w` by (
        imp_res_tac memory_rel_Number_IMP
        \\ fs[Smallnum_bits]
        \\ NO_TAC))
    \\ fs [wordSemTheory.get_vars_def] \\ every_case_tac
    \\ fs [wordSemTheory.get_var_imm_def] \\ clean_tac
    \\ TRY (
      `∃a x. (v1 && 1w) <> 0w /\ (word_bit 2 x ⇔ word_bit 4 x) ∧
           word_exp t (real_addr c (adjust_var a1)) = SOME (Word a) ∧
           a ∈ t.mdomain ∧ t.memory a = Word x` by (
        imp_res_tac memory_rel_RefPtr_IMP
        \\ fs[word_and_one_eq_0_iff]
        \\ drule (GEN_ALL(CONV_RULE(LAND_CONV(move_conj_left(same_const``get_real_addr`` o #1 o strip_comb o lhs)))get_real_addr_lemma))
        \\ fs[]
        \\ NO_TAC))
    \\ TRY (
      rpt_drule memory_rel_Word64_IMP
      \\ imp_res_tac memory_rel_tl
      \\ rpt_drule memory_rel_Word64_IMP
      \\ rpt strip_tac \\ clean_tac
      \\ fs[assign_def] \\ eval_tac
      \\ fs [wordSemTheory.get_var_imm_def,asmSemTheory.word_cmp_def,get_addr_and_1_not_0]
      \\ IF_CASES_TAC \\ fs[lookup_insert]
      >- (
        conj_tac >- rw[]
        \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
        \\ match_mp_tac memory_rel_insert \\ fs []
        \\ clean_tac \\ fs[]
        \\ qmatch_goalsub_rename_tac`Boolv (w1 = w2)`
        \\ clean_tac
        \\ `w1 = w2`
        by (
          qhdtm_x_assum`memory_rel`kall_tac
          \\ qhdtm_x_assum`memory_rel`mp_tac
          \\ simp[memory_rel_def,word_ml_inv_def,PULL_EXISTS,abs_ml_inv_def,
                  bc_stack_ref_inv_def,v_inv_def,word_addr_def,reachable_refs_def]
          \\ rw[]
          \\ qmatch_assum_rename_tac`heap_lookup p1 heap = _ (_ _ w1)`
          \\ qmatch_assum_rename_tac`heap_lookup p2 heap = _ (_ _ w2)`
          \\ `p1 = p2`
          by (
            match_mp_tac get_addr_inj
            \\ simp[]
            \\ imp_res_tac heap_lookup_LESS
            \\ fs[heap_ok_def]
            \\ fs[heap_in_memory_store_def]
            \\ rfs[]
            \\ conj_tac
            \\ qmatch_abbrev_tac`(p:num) * b < d`
            \\ `p < d DIV b` by metis_tac[LESS_LESS_EQ_TRANS]
            \\ `0 < b` by simp[Abbr`b`]
            \\ `(p + 1) * b ≤ d` by metis_tac[X_LT_DIV]
            \\ DECIDE_TAC)
          \\ fs[] \\ rfs[Word64Rep_inj] )
        \\ simp[]
        \\ match_mp_tac memory_rel_Boolv_T
        \\ simp[] )
      \\ drule (GEN_ALL(CONV_RULE(LAND_CONV(move_conj_left(same_const``get_real_addr`` o #1 o strip_comb o lhs)))get_real_addr_lemma))
      \\ simp[] \\ disch_then kall_tac
      \\ simp[wordSemTheory.get_var_def]
      \\ fs[word_bit_test]
      \\ simp[list_Seq_def]
      \\ eval_tac
      \\ qpat_abbrev_tac`tt = t with locals := _`
      \\ `get_var (adjust_var a1) tt = get_var (adjust_var a1) t`
      by (fs[Abbr`tt`,wordSemTheory.get_var_def,lookup_insert])
      \\ rfs[]
      \\ rpt_drule (GEN_ALL(CONV_RULE(LAND_CONV(move_conj_left(same_const``get_var`` o #1 o strip_comb o lhs)))get_real_addr_lemma))
      \\ simp[Abbr`tt`]
      \\ qpat_abbrev_tac`tt = t with locals := insert 1 _ (insert _ _ _)`
      \\ `get_var (adjust_var a2) tt = get_var (adjust_var a2) t`
      by (fs[Abbr`tt`,wordSemTheory.get_var_def,lookup_insert])
      \\ rfs[]
      \\ rpt_drule (GEN_ALL(CONV_RULE(LAND_CONV(move_conj_left(same_const``get_var`` o #1 o strip_comb o lhs)))get_real_addr_lemma))
      \\ simp[Abbr`tt`]
      \\ simp[wordSemTheory.get_var_imm_def,wordSemTheory.get_var_def,lookup_insert]
      \\ IF_CASES_TAC \\ fs[]
      >- (
        simp[asmSemTheory.word_cmp_def]
        \\ rpt strip_tac
        \\ reverse IF_CASES_TAC
        >- (
          fs[lookup_insert]
          \\ conj_tac >- rw[]
          \\ fs [inter_insert_ODD_adjust_set]
          \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
          \\ match_mp_tac memory_rel_insert \\ fs []
          \\ qmatch_assum_rename_tac`_ w1 ≠ _ w2`
          \\ `w1 ≠ w2`
          by (spose_not_then strip_assume_tac \\ fs[])
          \\ simp[]
          \\ match_mp_tac memory_rel_Boolv_F \\ fs [])
        \\ eval_tac
        \\ qpat_abbrev_tac`tt = t with locals := insert 3 _ (insert _ _ _)`
        \\ `get_var (adjust_var a1) tt = get_var (adjust_var a1) t`
        by (fs[Abbr`tt`,wordSemTheory.get_var_def,lookup_insert])
        \\ rfs[]
        \\ rpt_drule (GEN_ALL(CONV_RULE(LAND_CONV(move_conj_left(same_const``get_var`` o #1 o strip_comb o lhs)))get_real_addr_lemma))
        \\ simp[Abbr`tt`]
        \\ qpat_abbrev_tac`tt = t with locals := insert 1 _ (insert _ _ _)`
        \\ `get_var (adjust_var a2) tt = get_var (adjust_var a2) t`
        by (fs[Abbr`tt`,wordSemTheory.get_var_def,lookup_insert])
        \\ rfs[]
        \\ rpt_drule (GEN_ALL(CONV_RULE(LAND_CONV(move_conj_left(same_const``get_var`` o #1 o strip_comb o lhs)))get_real_addr_lemma))
        \\ simp[Abbr`tt`]
        \\ simp[wordSemTheory.get_var_imm_def,wordSemTheory.get_var_def,lookup_insert]
        \\ rpt strip_tac
        \\ simp[asmSemTheory.word_cmp_def]
        \\ reverse IF_CASES_TAC
        \\ fs[lookup_insert]
        \\ (conj_tac >- rw[])
        \\ fs [inter_insert_ODD_adjust_set]
        \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
        \\ match_mp_tac memory_rel_insert \\ fs []
        >- (
          qmatch_assum_rename_tac`_ w1 ≠ _ w2`
          \\ `w1 ≠ w2`
          by (spose_not_then strip_assume_tac \\ fs[])
          \\ simp[]
          \\ match_mp_tac memory_rel_Boolv_F \\ fs [])
        \\ qmatch_assum_rename_tac`_ w1 = _ w2`
        \\ `w1 = w2`
        by (
          rpt (qpat_x_assum`_ w1 = _ w2`mp_tac)
          \\ fs[good_dimindex_def] \\ rfs[]
          \\ srw_tac[wordsLib.WORD_BIT_EQ_ss][] )
        \\ simp[]
        \\ match_mp_tac memory_rel_Boolv_T \\ fs[])
      \\ simp[asmSemTheory.word_cmp_def]
      \\ qmatch_goalsub_rename_tac`(_ >< _) w1 = _ w2`
      \\ qmatch_goalsub_abbrev_tac`ext w1 = ext w2`
      \\ `(ext w1 = ext w2) ⇔ w1 = w2`
      by (
        `ext w1 = (63 >< 0) ((w2w w1):'a word) ∧ ext w2 = (63 >< 0) ((w2w w2):'a word)`
        by (
          simp[Abbr`ext`]
          \\ conj_tac
          \\ match_mp_tac (GSYM word_extract_w2w)
          \\ fs[good_dimindex_def] )
        \\ pop_assum SUBST_ALL_TAC
        \\ pop_assum SUBST_ALL_TAC
        \\ qmatch_abbrev_tac`v1 = v2 ⇔ _`
        \\ `v1 = (w2w w1) ∧ v2 = (w2w w2)`
        by (
          simp[Abbr`v1`,Abbr`v2`]
          \\ conj_tac
          \\ match_mp_tac WORD_EXTRACT_ID
          \\ Q.ISPEC_THEN`w2w w1`mp_tac w2n_lt
          \\ Q.ISPEC_THEN`w2w w2`mp_tac w2n_lt
          \\ rfs[good_dimindex_def,dimword_def])
        \\ pop_assum SUBST_ALL_TAC
        \\ pop_assum SUBST_ALL_TAC
        \\ simp_tac std_ss [SimpRHS,GSYM w2n_11]
        \\ match_mp_tac EQ_SYM
        \\ match_mp_tac w2n_11_lift
        \\ fs[good_dimindex_def] )
      \\ pop_assum SUBST_ALL_TAC
      \\ eval_tac
      \\ rpt strip_tac
      \\ IF_CASES_TAC \\ fs[lookup_insert]
      \\ (conj_tac >- rw[])
      \\ fs [inter_insert_ODD_adjust_set]
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
      \\ match_mp_tac memory_rel_insert \\ fs []
      \\ TRY (match_mp_tac memory_rel_Boolv_T \\ fs [] \\ NO_TAC)
      \\ TRY (match_mp_tac memory_rel_Boolv_F \\ fs [] \\ NO_TAC))
    \\ fs [assign_def] \\ eval_tac
    \\ fs [wordSemTheory.get_var_imm_def,asmSemTheory.word_cmp_def]
    \\ fs[wordSemTheory.get_var_def,word_bit_test]
    \\ IF_CASES_TAC \\ fs []
    \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
    \\ fs [inter_insert_ODD_adjust_set]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ TRY (match_mp_tac memory_rel_Boolv_T \\ fs [] \\ NO_TAC)
    \\ TRY (match_mp_tac memory_rel_Boolv_F \\ fs [] \\ NO_TAC))
  \\ Cases_on `∃opw. op = WordOp W8 opw` \\ fs[] THEN1 (
    imp_res_tac get_vars_IMP_LENGTH
    \\ fs[do_app]
    \\ every_case_tac \\ fs[]
    \\ clean_tac
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs[quantHeuristicsTheory.LIST_LENGTH_2]
    \\ clean_tac
    \\ fs[state_rel_thm] \\ eval_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
    \\ strip_tac
    \\ imp_res_tac memory_rel_Number_IMP
    \\ imp_res_tac memory_rel_tl
    \\ imp_res_tac memory_rel_Number_IMP
    \\ qhdtm_x_assum`memory_rel`kall_tac
    \\ fs[wordSemTheory.get_vars_def]
    \\ every_case_tac \\ fs[] \\ clean_tac
    \\ simp[assign_def] \\ eval_tac
    \\ fs[wordSemTheory.get_var_def]
    \\ qhdtm_x_assum`$some`mp_tac
    \\ DEEP_INTRO_TAC some_intro \\ fs[]
    \\ strip_tac \\ clean_tac
    \\ Cases_on`opw` \\ simp[] \\ eval_tac \\ fs[lookup_insert]
    \\ (conj_tac >- rw[])
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs[]
    >- ( match_mp_tac memory_rel_And \\ fs[] )
    >- ( match_mp_tac memory_rel_Or \\ fs[] )
    >- ( match_mp_tac memory_rel_Xor \\ fs[] )
    >- (
      qmatch_goalsub_abbrev_tac`Word w`
      \\ qmatch_goalsub_abbrev_tac`Number i`
      \\ `w = Smallnum i`
      by (
        unabbrev_all_tac
        \\ qmatch_goalsub_rename_tac`w2n (w1 + w2)`
        \\ simp[Smallnum_i2w,integer_wordTheory.i2w_def]
        \\ simp[WORD_MUL_LSL]
        \\ ONCE_REWRITE_TAC[GSYM n2w_w2n]
        \\ REWRITE_TAC[w2n_lsr]
        \\ simp[word_mul_n2w,word_add_n2w]
        \\ Cases_on`w1` \\ Cases_on`w2` \\ fs[word_add_n2w]
        \\ fs[good_dimindex_def,dimword_def,GSYM LEFT_ADD_DISTRIB]
        \\ qmatch_goalsub_abbrev_tac`(a * b) MOD f DIV d`
        \\ qspecl_then[`a * b`,`d`,`f DIV d`]mp_tac (GSYM DIV_MOD_MOD_DIV)
        \\ simp[Abbr`a`,Abbr`d`,Abbr`f`] \\ disch_then kall_tac
        \\ qmatch_goalsub_abbrev_tac`d * b DIV f`
        \\ `d * b = (b * (d DIV f)) * f`
        by simp[Abbr`d`,Abbr`f`]
        \\ pop_assum SUBST_ALL_TAC
        \\ qspecl_then[`f`,`b * (d DIV f)`]mp_tac MULT_DIV
        \\ (impl_tac >- simp[Abbr`f`])
        \\ disch_then SUBST_ALL_TAC
        \\ simp[Abbr`d`,Abbr`f`]
        \\ qmatch_goalsub_abbrev_tac`a * b MOD q`
        \\ qspecl_then[`a`,`b`,`q`]mp_tac MOD_COMMON_FACTOR
        \\ (impl_tac >- simp[Abbr`a`,Abbr`q`])
        \\ disch_then SUBST_ALL_TAC
        \\ simp[Abbr`a`,Abbr`q`])
      \\ pop_assum SUBST_ALL_TAC
      \\ match_mp_tac IMP_memory_rel_Number
      \\ fs[]
      \\ fs[Abbr`i`,small_int_def]
      \\ qmatch_goalsub_rename_tac`w2n w`
      \\ Q.ISPEC_THEN`w`mp_tac w2n_lt
      \\ fs[good_dimindex_def,dimword_def] )
    >- (
      qmatch_goalsub_abbrev_tac`Word w`
      \\ qmatch_goalsub_abbrev_tac`Number i`
      \\ `w = Smallnum i`
      by (
        unabbrev_all_tac
        \\ qmatch_goalsub_rename_tac`w2n (w1 + -1w * w2)`
        \\ simp[Smallnum_i2w,integer_wordTheory.i2w_def]
        \\ simp[WORD_MUL_LSL]
        \\ ONCE_REWRITE_TAC[GSYM n2w_w2n]
        \\ REWRITE_TAC[w2n_lsr]
        \\ simp[word_mul_n2w,word_add_n2w]
        \\ REWRITE_TAC[WORD_SUB_INTRO,WORD_MULT_CLAUSES]
        \\ Cases_on`w1` \\ Cases_on`w2`
        \\ REWRITE_TAC[addressTheory.word_arith_lemma2]
        \\ reverse(rw[]) \\ fs[NOT_LESS,GSYM LEFT_SUB_DISTRIB,GSYM RIGHT_SUB_DISTRIB]
        >- (
          qmatch_goalsub_abbrev_tac`(a * b) MOD f DIV d`
          \\ qspecl_then[`a * b`,`d`,`f DIV d`]mp_tac (GSYM DIV_MOD_MOD_DIV)
          \\ (impl_tac >- fs[Abbr`d`,Abbr`f`,good_dimindex_def,dimword_def])
          \\ `d * (f DIV d) = f` by fs[good_dimindex_def,Abbr`f`,Abbr`d`,dimword_def]
          \\ pop_assum SUBST_ALL_TAC
          \\ disch_then (CHANGED_TAC o SUBST_ALL_TAC)
          \\ unabbrev_all_tac
          \\ qmatch_goalsub_abbrev_tac`a * (b * d) DIV d`
          \\ `a * (b * d) DIV d = a * b`
          by (
            qspecl_then[`d`,`a * b`]mp_tac MULT_DIV
            \\ impl_tac >- simp[Abbr`d`]
            \\ simp[] )
          \\ pop_assum SUBST_ALL_TAC
          \\ fs[Abbr`a`,Abbr`d`,dimword_def,good_dimindex_def]
          \\ qmatch_goalsub_abbrev_tac`(a * b) MOD q`
          \\ qspecl_then[`a`,`b`,`q DIV a`](mp_tac o GSYM) MOD_COMMON_FACTOR
          \\ (impl_tac >- simp[Abbr`a`,Abbr`q`])
          \\ simp[Abbr`a`,Abbr`q`] \\ disch_then kall_tac
          \\ `b < 256` by simp[Abbr`b`]
          \\ simp[] )
        \\ simp[word_2comp_n2w]
        \\ qmatch_goalsub_abbrev_tac`(4 * (b * d)) MOD f`
        \\ qmatch_goalsub_abbrev_tac`f - y MOD f`
        \\ `f = d * 2**10`
        by (
          unabbrev_all_tac
          \\ fs[dimword_def,good_dimindex_def] )
        \\ qunabbrev_tac`f`
        \\ pop_assum SUBST_ALL_TAC
        \\ fs[]
        \\ qmatch_goalsub_abbrev_tac`m MOD (1024 * d) DIV d`
        \\ qspecl_then[`m`,`d`,`1024`]mp_tac DIV_MOD_MOD_DIV
        \\ impl_tac >- simp[Abbr`d`] \\ simp[]
        \\ disch_then(CHANGED_TAC o SUBST_ALL_TAC o SYM)
        \\ qspecl_then[`1024 * d`,`(m DIV d) MOD 1024`]mp_tac LESS_MOD
        \\ impl_tac
        >- (
          qspecl_then[`m DIV d`,`1024`]mp_tac MOD_LESS
          \\ impl_tac >- simp[]
          \\ `1024 < 1024 * d`
          by (
            simp[Abbr`d`,ONE_LT_EXP]
            \\ fs[good_dimindex_def] )
          \\ decide_tac )
        \\ disch_then (CHANGED_TAC o SUBST_ALL_TAC)
        \\ fs[Abbr`m`,Abbr`y`]
        \\ qspecl_then[`d`,`4 * b`,`1024`]mp_tac MOD_COMMON_FACTOR
        \\ impl_tac >- simp[Abbr`d`] \\ simp[]
        \\ disch_then(CHANGED_TAC o SUBST_ALL_TAC o SYM)
        \\ qmatch_assum_rename_tac`n2 < 256n`
        \\ `n2 <= 256` by simp[]
        \\ drule LESS_EQ_ADD_SUB
        \\ qmatch_assum_rename_tac`n1 < n2`
        \\ disch_then(qspec_then`n1`(CHANGED_TAC o SUBST_ALL_TAC))
        \\ REWRITE_TAC[LEFT_ADD_DISTRIB]
        \\ simp[LEFT_SUB_DISTRIB,Abbr`b`]
        \\ `4 * (d * n2) - 4 * (d * n1) = (4 * d) * (n2 - n1)` by simp[]
        \\ pop_assum (CHANGED_TAC o SUBST_ALL_TAC)
        \\ `1024 * d - 4 * d * (n2 - n1) = (1024 - 4 * (n2 - n1)) * d` by simp[]
        \\ pop_assum (CHANGED_TAC o SUBST_ALL_TAC)
        \\ `0 < d` by simp[Abbr`d`]
        \\ drule MULT_DIV
        \\ disch_then(CHANGED_TAC o (fn th => REWRITE_TAC[th]))
        \\ simp[])
      \\ pop_assum SUBST_ALL_TAC
      \\ match_mp_tac IMP_memory_rel_Number
      \\ fs[]
      \\ fs[Abbr`i`,small_int_def]
      \\ qmatch_goalsub_rename_tac`w2n w`
      \\ Q.ISPEC_THEN`w`mp_tac w2n_lt
      \\ fs[good_dimindex_def,dimword_def] ))
  \\ Cases_on `∃opw. op = WordOp W64 opw` \\ fs[] THEN1 (
    imp_res_tac get_vars_IMP_LENGTH
    \\ fs[do_app]
    \\ every_case_tac \\ fs[]
    \\ clean_tac
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs[quantHeuristicsTheory.LIST_LENGTH_2]
    \\ clean_tac
    \\ fs[state_rel_thm] \\ eval_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
    \\ strip_tac
    \\ fs[wordSemTheory.get_vars_def]
    \\ every_case_tac \\ fs[] \\ clean_tac
    \\ drule memory_rel_Word64_IMP
    \\ imp_res_tac memory_rel_tl
    \\ drule memory_rel_Word64_IMP
    \\ qhdtm_x_assum`memory_rel`kall_tac
    \\ simp[] \\ ntac 2 strip_tac
    \\ clean_tac
    \\ simp[assign_def]
    \\ BasicProvers.TOP_CASE_TAC
    >- simp[]
    \\ simp[list_Seq_def]
    \\ drule(GEN_ALL memory_rel_WordOp64)
    \\ qpat_abbrev_tac`w64 = opw_lookup _ _ _`
    \\ disch_then(qspec_then`w64`mp_tac o CONV_RULE(SWAP_FORALL_CONV))
    \\ qspecl_then[`:'a`,`w64`]strip_assume_tac Word64Rep_DataElement
    \\ simp[]
    \\ qmatch_assum_abbrev_tac`encode_header _ _ len = _`
    \\ `len = LENGTH ws`
    by (
      fs[Word64Rep_def,Abbr`len`]
      \\ IF_CASES_TAC \\ fs[] )
    \\ qunabbrev_tac`len` \\ fs[]
    \\ impl_tac
    >- ( fs[consume_space_def] )
    \\ strip_tac
    \\ eval_tac
    \\ simp[lookup_insert,wordSemTheory.get_var_def]
    \\ reverse(Cases_on`dimindex(:'a) < 64`) \\ fs[]
    \\ qpat_x_assum`_ = LENGTH ws`(assume_tac o SYM) \\ fs[]
    >- (
      eval_tac
      \\ qmatch_goalsub_abbrev_tac`word_exp tt _`
      \\ `tt.store = t.store` by simp[Abbr`tt`]
      \\ `get_var (adjust_var e1) tt = get_var (adjust_var e1) t`
      by (fs[Abbr`tt`,wordSemTheory.get_var_def,lookup_insert])
      \\ rfs[]
      \\ rpt_drule (GEN_ALL(CONV_RULE(LAND_CONV(move_conj_left(same_const``get_var`` o #1 o strip_comb o lhs)))get_real_addr_lemma))
      \\ `get_var (adjust_var e2) tt = get_var (adjust_var e2) t`
      by (fs[Abbr`tt`,wordSemTheory.get_var_def,lookup_insert])
      \\ rfs[]
      \\ rpt_drule (GEN_ALL(CONV_RULE(LAND_CONV(move_conj_left(same_const``get_var`` o #1 o strip_comb o lhs)))get_real_addr_lemma))
      \\ qpat_abbrev_tac`sow = word_op_CASE opw _ _ _ _ _`
      \\ qpat_abbrev_tac`sw = _ sow _ _ _ _ _`
      \\ `sw = SOME (w2w w64)`
      by (
        simp[Abbr`sow`,Abbr`sw`,Abbr`w64`]
        \\ Cases_on`opw` \\ simp[]
        \\ simp[WORD_w2w_EXTRACT,WORD_EXTRACT_OVER_BITWISE]
        \\ fs[good_dimindex_def,WORD_EXTRACT_OVER_ADD,WORD_EXTRACT_OVER_MUL]
        \\ qpat_abbrev_tac`neg1 = (_ >< _) (-1w)`
        \\ `neg1 = -1w`
        by ( srw_tac[wordsLib.WORD_BIT_EQ_ss][Abbr`neg1`] )
        \\ pop_assum SUBST_ALL_TAC
        \\ simp[] )
      \\ qunabbrev_tac`sw` \\ pop_assum SUBST_ALL_TAC
      \\ simp[wordSemTheory.get_var_def,lookup_insert]
      \\ simp[wordSemTheory.mem_store_def]
      \\ fs[Word64Rep_def] \\ clean_tac
      \\ fs[store_list_def,lookup_insert,wordSemTheory.set_store_def,FLOOKUP_UPDATE]
      \\ ntac 2 strip_tac
      \\ fs[consume_space_def] \\ clean_tac
      \\ fs[]
      \\ conj_tac >- rw[]
      \\ fs[inter_insert_ODD_adjust_set]
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
      \\ match_mp_tac memory_rel_insert
      \\ match_mp_tac (GEN_ALL memory_rel_less_space)
      \\ qexists_tac`x.space - 2` \\ simp[]
      \\ fs[make_ptr_def,FAPPLY_FUPDATE_THM]
      \\ qmatch_abbrev_tac`memory_rel c _ refs sp st mem _ _`
      \\ qmatch_assum_abbrev_tac`memory_rel c _ refs sp st mem' _ _`
      \\ `mem = mem'`
      by (
        simp[Abbr`mem`,Abbr`mem'`,FUN_EQ_THM,APPLY_UPDATE_THM]
        \\ rw[] \\ fs[bytes_in_word_def]
        \\ fs[good_dimindex_def] \\ rfs[]
        \\ pop_assum mp_tac \\ EVAL_TAC
        \\ simp[dimword_def]
        \\ simp[WORD_w2w_EXTRACT] )
      \\ simp[] )
    \\ reverse BasicProvers.CASE_TAC
    >- (
      qpat_abbrev_tac`prg = binop_CASE _ _ _ _ _ _`
      \\ `prg = GiveUp`
      by (
        simp[Abbr`prg`]
        \\ Cases_on`opw` \\ fs[]
        \\ clean_tac \\ fs[] )
      \\ qunabbrev_tac`prg` \\ pop_assum SUBST_ALL_TAC
      \\ qmatch_goalsub_abbrev_tac`evaluate (GiveUp,tt)`
      \\ `∃l1 l2 locs. state_rel c l1 l2 x tt [] locs`
      by (
        fs[state_rel_thm,Abbr`tt`,lookup_insert]
        \\ asm_exists_tac
        \\ fs[inter_insert_ODD_adjust_set_alt] )
      \\ drule evaluate_GiveUp
      \\ strip_tac \\ fs[] )
    \\ eval_tac
    \\ qmatch_goalsub_abbrev_tac`word_exp tt _`
    \\ `tt.store = t.store` by simp[Abbr`tt`]
    \\ `get_var (adjust_var e1) tt = get_var (adjust_var e1) t`
    by (fs[Abbr`tt`,wordSemTheory.get_var_def,lookup_insert])
    \\ rfs[]
    \\ rpt_drule (GEN_ALL(CONV_RULE(LAND_CONV(move_conj_left(same_const``get_var`` o #1 o strip_comb o lhs)))get_real_addr_lemma))
    \\ `get_var (adjust_var e2) tt = get_var (adjust_var e2) t`
    by (fs[Abbr`tt`,wordSemTheory.get_var_def,lookup_insert])
    \\ rfs[]
    \\ rpt_drule (GEN_ALL(CONV_RULE(LAND_CONV(move_conj_left(same_const``get_var`` o #1 o strip_comb o lhs)))get_real_addr_lemma))
    \\ qpat_abbrev_tac`sw = binop_CASE b _ _ _ _ _`
    \\ `sw = SOME ((63 >< 32) w64)`
    by (
      simp[Abbr`sw`,Abbr`w64`]
      \\ Cases_on`opw` \\ fs[]
      \\ clean_tac \\ fs[WORD_EXTRACT_OVER_BITWISE] )
    \\ qunabbrev_tac`sw` \\ pop_assum SUBST_ALL_TAC
    \\ simp[lookup_insert,wordSemTheory.get_var_def,wordSemTheory.mem_store_def]
    \\ fs[Word64Rep_def] \\ clean_tac
    \\ fs[store_list_def]
    \\ ntac 2 strip_tac
    \\ qunabbrev_tac`tt`
    \\ qmatch_goalsub_abbrev_tac`word_exp tt _`
    \\ `tt.store = t.store` by simp[Abbr`tt`]
    \\ `get_var (adjust_var e1) tt = get_var (adjust_var e1) t`
    by (fs[Abbr`tt`,wordSemTheory.get_var_def,lookup_insert])
    \\ rfs[]
    \\ rpt_drule (GEN_ALL(CONV_RULE(LAND_CONV(move_conj_left(same_const``get_var`` o #1 o strip_comb o lhs)))get_real_addr_lemma))
    \\ `get_var (adjust_var e2) tt = get_var (adjust_var e2) t`
    by (fs[Abbr`tt`,wordSemTheory.get_var_def,lookup_insert])
    \\ rfs[]
    \\ rpt_drule (GEN_ALL(CONV_RULE(LAND_CONV(move_conj_left(same_const``get_var`` o #1 o strip_comb o lhs)))get_real_addr_lemma))
    \\ qpat_abbrev_tac`sw = binop_CASE b _ _ _ _ _`
    \\ `sw = SOME ((31 >< 0) w64)`
    by (
      simp[Abbr`sw`,Abbr`w64`]
      \\ Cases_on`opw` \\ fs[]
      \\ clean_tac \\ fs[WORD_EXTRACT_OVER_BITWISE] )
    \\ qunabbrev_tac`sw` \\ pop_assum SUBST_ALL_TAC
    \\ simp[lookup_insert,wordSemTheory.get_var_def,wordSemTheory.mem_store_def]
    \\ simp[WORD_MUL_LSL,lookup_insert,wordSemTheory.set_store_def,FLOOKUP_UPDATE]
    \\ ntac 2 strip_tac
    \\ fs[consume_space_def] \\ clean_tac \\ fs[]
    \\ conj_tac >- rw[]
    \\ fs[inter_insert_ODD_adjust_set]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert
    \\ fs[make_ptr_def,FAPPLY_FUPDATE_THM]
    \\ qmatch_abbrev_tac`memory_rel c _ refs sp st mem _ ((_,w1)::_)`
    \\ qmatch_assum_abbrev_tac`memory_rel c _ refs sp st mem' _ ((_,w2)::_)`
    \\ `mem = mem'`
    by (
      simp[Abbr`mem`,Abbr`mem'`,FUN_EQ_THM,APPLY_UPDATE_THM]
      \\ rw[] \\ fs[bytes_in_word_def]
      \\ fs[good_dimindex_def] \\ rfs[]
      \\ pop_assum mp_tac \\ EVAL_TAC
      \\ simp[dimword_def]
      \\ simp[WORD_w2w_EXTRACT]
      \\ pop_assum mp_tac \\ EVAL_TAC
      \\ simp[dimword_def]
      \\ simp[WORD_w2w_EXTRACT])
    \\ `w1 = w2`
    by ( simp[Abbr`w1`,Abbr`w2`,GSYM WORD_MUL_LSL] )
    \\ simp[] )
  \\ Cases_on `∃sh n. op = WordShift W8 sh n` \\ fs[] THEN1 (
    imp_res_tac get_vars_IMP_LENGTH
    \\ fs[do_app]
    \\ every_case_tac \\ fs[]
    \\ clean_tac
    \\ fs[quantHeuristicsTheory.LIST_LENGTH_2]
    \\ qhdtm_x_assum`$some`mp_tac
    \\ DEEP_INTRO_TAC some_intro \\ fs[]
    \\ strip_tac \\ clean_tac
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs[state_rel_thm] \\ eval_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ drule (memory_rel_get_vars_IMP |> GEN_ALL)
    \\ disch_then drule \\ fs[] \\ strip_tac
    \\ fs[quantHeuristicsTheory.LIST_LENGTH_2]
    \\ clean_tac \\ fs[]
    \\ rpt_drule memory_rel_Number_IMP
    \\ strip_tac \\ clean_tac
    \\ imp_res_tac get_vars_1_imp
    \\ fs[wordSemTheory.get_var_def]
    \\ simp[assign_def]
    \\ BasicProvers.CASE_TAC \\ eval_tac
    >- (
      IF_CASES_TAC
      >- (fs[good_dimindex_def,MIN_DEF] \\ rfs[])
      \\ simp[lookup_insert]
      \\ conj_tac >- rw[]
      \\ pop_assum kall_tac
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
      \\ match_mp_tac memory_rel_insert
      \\ qmatch_goalsub_abbrev_tac`Number i`
      \\ qmatch_goalsub_abbrev_tac`Word w`
      \\ `small_int (:'a) i`
      by (
        simp[Abbr`i`,small_int_def,WORD_MUL_LSL]
        \\ qmatch_goalsub_rename_tac`z * n2w _`
        \\ Cases_on`z` \\ fs[word_mul_n2w]
        \\ fs[good_dimindex_def,dimword_def]
        \\ qmatch_abbrev_tac`a MOD b < d`
        \\ `b < d` by simp[Abbr`b`,Abbr`d`]
        \\ qspecl_then[`a`,`b`]mp_tac MOD_LESS
        \\ (impl_tac >- simp[Abbr`b`])
        \\ decide_tac )
      \\ `w = Smallnum i`
      by (
        simp[Abbr`w`,Abbr`i`]
        \\ simp[Smallnum_i2w,integer_wordTheory.i2w_def]
        \\ qmatch_goalsub_rename_tac`w2n w`
        \\ qmatch_goalsub_rename_tac`w << n`
        \\ Cases_on`n=0`
        >- (
          simp[]
          \\ match_mp_tac lsl_lsr
          \\ simp[GSYM word_mul_n2w,dimword_def]
          \\ Q.ISPEC_THEN`w`mp_tac w2n_lt
          \\ fs[good_dimindex_def] )
        \\ simp[GSYM word_mul_n2w]
        \\ qspecl_then[`n2w(w2n w)`,`2`]mp_tac WORD_MUL_LSL
        \\ simp[] \\ disch_then (SUBST_ALL_TAC o SYM)
        \\ simp[]
        \\ `10 < dimindex(:'a)` by fs[good_dimindex_def]
        \\ simp[]
        \\ qspecl_then[`n2w(w2n (w<<n))`,`2`]mp_tac WORD_MUL_LSL
        \\ simp[] \\ disch_then (SUBST_ALL_TAC o SYM)
        \\ simp[GSYM w2w_def]
        \\ simp[w2w_LSL]
        \\ IF_CASES_TAC
        \\ simp[MIN_DEF]
        \\ simp[word_lsr_n2w]
        \\ simp[WORD_w2w_EXTRACT]
        \\ simp[WORD_EXTRACT_BITS_COMP]
        \\ `MIN (7 - n) 7 = 7 - n` by simp[MIN_DEF]
        \\ pop_assum SUBST_ALL_TAC
        \\ qmatch_abbrev_tac`_ ((7 >< 0) w << m) = _`
        \\ qispl_then[`7n`,`0n`,`m`,`w`](mp_tac o INST_TYPE[beta|->alpha]) WORD_EXTRACT_LSL2
        \\ impl_tac >- ( simp[Abbr`m`] )
        \\ disch_then SUBST_ALL_TAC
        \\ simp[Abbr`m`]
        \\ simp[WORD_BITS_LSL]
        \\ simp[SUB_LEFT_SUB,SUB_RIGHT_SUB]
        \\ qmatch_goalsub_abbrev_tac`_ -- z`
        \\ `z = 0` by simp[Abbr`z`]
        \\ simp[Abbr`z`]
        \\ simp[WORD_BITS_EXTRACT]
        \\ simp[WORD_EXTRACT_COMP_THM,MIN_DEF] )
      \\ simp[Abbr`w`]
      \\ match_mp_tac IMP_memory_rel_Number
      \\ simp[]
      \\ drule memory_rel_tl
      \\ simp_tac std_ss [GSYM APPEND_ASSOC])
    >- (
      IF_CASES_TAC
      >- (fs[good_dimindex_def,MIN_DEF] \\ rfs[])
      \\ simp[lookup_insert]
      \\ conj_tac >- rw[]
      \\ pop_assum kall_tac
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
      \\ match_mp_tac memory_rel_insert
      \\ qmatch_goalsub_abbrev_tac`Number i`
      \\ qmatch_goalsub_abbrev_tac`Word w`
      \\ `small_int (:'a) i`
      by (
        simp[Abbr`i`,small_int_def]
        \\ qmatch_goalsub_rename_tac`z >>> _`
        \\ Cases_on`z` \\ fs[w2n_lsr]
        \\ fs[good_dimindex_def,dimword_def]
        \\ qmatch_abbrev_tac`a DIV b < d`
        \\ `a < d` by simp[Abbr`a`,Abbr`d`]
        \\ qspecl_then[`b`,`a`]mp_tac (SIMP_RULE std_ss [PULL_FORALL]DIV_LESS_EQ)
        \\ (impl_tac >- simp[Abbr`b`])
        \\ decide_tac )
      \\ `w = Smallnum i`
      by (
        simp[Abbr`w`,Abbr`i`]
        \\ simp[Smallnum_i2w,integer_wordTheory.i2w_def]
        \\ simp[GSYM word_mul_n2w]
        \\ REWRITE_TAC[Once ADD_COMM]
        \\ REWRITE_TAC[GSYM LSR_ADD]
        \\ qmatch_goalsub_rename_tac`w2n w`
        \\ qmatch_goalsub_abbrev_tac`4w * ww`
        \\ `4w * ww = ww << 2` by simp[WORD_MUL_LSL]
        \\ pop_assum SUBST_ALL_TAC
        \\ qspecl_then[`ww`,`2`]mp_tac lsl_lsr
        \\ Q.ISPEC_THEN`w`assume_tac w2n_lt
        \\ impl_tac
        >- ( simp[Abbr`ww`] \\ fs[good_dimindex_def,dimword_def] )
        \\ disch_then SUBST_ALL_TAC
        \\ simp[WORD_MUL_LSL]
        \\ AP_TERM_TAC
        \\ simp[Abbr`ww`]
        \\ simp[w2n_lsr]
        \\ `w2n w < dimword(:'a)`
        by ( fs[good_dimindex_def,dimword_def] )
        \\ simp[GSYM n2w_DIV]
        \\ AP_THM_TAC \\ AP_TERM_TAC
        \\ rw[MIN_DEF] \\ fs[]
        \\ simp[LESS_DIV_EQ_ZERO]
        \\ qmatch_goalsub_rename_tac`2n ** k`
        \\ `2n ** 8 <= 2 ** k`
        by ( simp[logrootTheory.LE_EXP_ISO] )
        \\ `256n ≤ 2 ** k` by metis_tac[EVAL``2n ** 8``]
        \\ `w2n w < 2 ** k` by decide_tac
        \\ simp[LESS_DIV_EQ_ZERO] )
      \\ simp[Abbr`w`]
      \\ match_mp_tac IMP_memory_rel_Number
      \\ simp[]
      \\ drule memory_rel_tl
      \\ simp_tac std_ss [GSYM APPEND_ASSOC])
    >- (
      IF_CASES_TAC
      >- (fs[good_dimindex_def,MIN_DEF] \\ rfs[])
      \\ simp[lookup_insert]
      \\ IF_CASES_TAC
      >- (fs[good_dimindex_def,MIN_DEF] \\ rfs[])
      \\ simp[lookup_insert]
      \\ conj_tac >- rw[]
      \\ ntac 2 (pop_assum kall_tac)
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
      \\ match_mp_tac memory_rel_insert
      \\ qmatch_goalsub_abbrev_tac`Number i`
      \\ qmatch_goalsub_abbrev_tac`Word w`
      \\ `small_int (:'a) i`
      by (
        simp[Abbr`i`,small_int_def]
        \\ qmatch_goalsub_rename_tac`z >> _`
        \\ simp[word_asr]
        \\ reverse IF_CASES_TAC
        >- (
          Cases_on`z` \\ fs[w2n_lsr]
          \\ fs[good_dimindex_def,dimword_def]
          \\ qmatch_abbrev_tac`a DIV b < d`
          \\ `a < d` by simp[Abbr`a`,Abbr`d`]
          \\ qspecl_then[`b`,`a`]mp_tac (SIMP_RULE std_ss [PULL_FORALL]DIV_LESS_EQ)
          \\ (impl_tac >- simp[Abbr`b`])
          \\ decide_tac )
        \\ cheat )
      \\ `w = Smallnum i`
      by (
        simp[Abbr`w`,Abbr`i`]
        \\ simp[Smallnum_i2w,integer_wordTheory.i2w_def]
        \\ simp[GSYM word_mul_n2w]
        \\ cheat )
      \\ simp[Abbr`w`]
      \\ match_mp_tac IMP_memory_rel_Number
      \\ simp[]
      \\ drule memory_rel_tl
      \\ simp_tac std_ss [GSYM APPEND_ASSOC]))
  \\ Cases_on `?lab. op = Label lab` \\ fs [] THEN1
   (fs [assign_def] \\ fs [do_app]
    \\ Cases_on `vals` \\ fs []
    \\ qpat_assum `_ = Rval (v,s2)` mp_tac
    \\ IF_CASES_TAC \\ fs []
    \\ rveq \\ fs []
    \\ imp_res_tac get_vars_IMP_LENGTH \\ fs []
    \\ fs [state_rel_thm] \\ eval_tac
    \\ fs [domain_lookup,lookup_map]
    \\ reverse IF_CASES_TAC THEN1
     (`F` by all_tac \\ fs [code_rel_def]
      \\ rename1 `lookup _ s2.code = SOME zzz` \\ PairCases_on `zzz` \\ res_tac
      \\ fs []) \\ fs []
    \\ fs [lookup_insert,FAPPLY_FUPDATE_THM,adjust_var_11,FLOOKUP_UPDATE]
    \\ rw [] \\ fs [] \\ rw [] \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ match_mp_tac memory_rel_CodePtr \\ fs [])
  \\ Cases_on `op = Ref` \\ fs [] THEN1
   (imp_res_tac get_vars_IMP_LENGTH \\ fs []
    \\ fs [assign_def] \\ fs [do_app] \\ every_case_tac \\ fs []
    \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ clean_tac
    \\ fs [consume_space_def] \\ clean_tac
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs [state_rel_thm] \\ eval_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ drule (memory_rel_get_vars_IMP |> GEN_ALL)
    \\ disch_then drule \\ fs [NOT_LESS,DECIDE ``n + 1 <= m <=> n < m:num``]
    \\ strip_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ qabbrev_tac `new = LEAST ptr. ptr ∉ FDOM x.refs`
    \\ `new ∉ FDOM x.refs` by metis_tac [LEAST_NOTIN_FDOM]
    \\ rpt_drule memory_rel_Ref \\ strip_tac
    \\ fs [list_Seq_def] \\ eval_tac
    \\ fs [wordSemTheory.set_store_def]
    \\ qpat_abbrev_tac `t5 = t with <| locals := _ ; store := _ |>`
    \\ pairarg_tac \\ fs []
    \\ `t.memory = t5.memory /\ t.mdomain = t5.mdomain` by
         (unabbrev_all_tac \\ fs []) \\ fs []
    \\ ntac 2 (pop_assum kall_tac)
    \\ drule evaluate_StoreEach
    \\ disch_then (qspecl_then [`3::MAP adjust_var args`,`1`] mp_tac)
    \\ impl_tac THEN1
     (fs [wordSemTheory.get_vars_def,Abbr`t5`,wordSemTheory.get_var_def,
          lookup_insert,get_vars_with_store,get_vars_adjust_var] \\ NO_TAC)
    \\ clean_tac \\ fs [] \\ UNABBREV_ALL_TAC
    \\ fs [lookup_insert,FAPPLY_FUPDATE_THM,adjust_var_11,FLOOKUP_UPDATE]
    \\ rw [] \\ fs [] \\ rw [] \\ fs []
    \\ fs [inter_insert_ODD_adjust_set]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ fs [make_ptr_def])
  \\ Cases_on `op = Update` \\ fs [] THEN1
   (imp_res_tac get_vars_IMP_LENGTH \\ fs []
    \\ fs [do_app] \\ every_case_tac \\ fs [] \\ clean_tac
    \\ fs [INT_EQ_NUM_LEMMA] \\ clean_tac
    \\ fs [integerTheory.NUM_OF_INT,LENGTH_EQ_3] \\ clean_tac
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs [assign_def] \\ eval_tac \\ fs [state_rel_thm]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ drule (memory_rel_get_vars_IMP |> GEN_ALL)
    \\ disch_then drule \\ fs []
    \\ imp_res_tac get_vars_3_IMP \\ fs []
    \\ fs [integerTheory.NUM_OF_INT,LENGTH_EQ_3] \\ clean_tac
    \\ imp_res_tac get_vars_3_IMP \\ fs [] \\ strip_tac
    \\ drule reorder_lemma \\ strip_tac
    \\ drule (memory_rel_Update |> GEN_ALL) \\ fs []
    \\ strip_tac \\ clean_tac
    \\ `word_exp t (real_offset c (adjust_var a2)) = SOME (Word y) /\
        word_exp t (real_addr c (adjust_var a1)) = SOME (Word x')` by
          metis_tac [get_real_offset_lemma,get_real_addr_lemma]
    \\ fs [] \\ eval_tac \\ fs [EVAL ``word_exp s1 Unit``]
    \\ fs [wordSemTheory.mem_store_def]
    \\ fs [lookup_insert,adjust_var_11]
    \\ rw [] \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ match_mp_tac memory_rel_Unit \\ fs []
    \\ first_x_assum (fn th => mp_tac th THEN match_mp_tac memory_rel_rearrange)
    \\ rw [] \\ fs [])
  \\ Cases_on `op = Deref` \\ fs [] THEN1
   (imp_res_tac get_vars_IMP_LENGTH \\ fs []
    \\ fs [do_app] \\ every_case_tac \\ fs [] \\ clean_tac
    \\ fs [INT_EQ_NUM_LEMMA] \\ clean_tac
    \\ fs [integerTheory.NUM_OF_INT,LENGTH_EQ_2] \\ clean_tac
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs [assign_def] \\ eval_tac \\ fs [state_rel_thm]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ drule (memory_rel_get_vars_IMP |> GEN_ALL)
    \\ disch_then drule \\ fs []
    \\ imp_res_tac get_vars_2_IMP \\ fs []
    \\ fs [integerTheory.NUM_OF_INT,LENGTH_EQ_2] \\ clean_tac
    \\ imp_res_tac get_vars_2_IMP \\ fs [] \\ strip_tac
    \\ drule (memory_rel_Deref |> GEN_ALL) \\ fs []
    \\ strip_tac \\ clean_tac
    \\ `word_exp t (real_offset c (adjust_var a2)) = SOME (Word y) /\
        word_exp t (real_addr c (adjust_var a1)) = SOME (Word x')` by
          metis_tac [get_real_offset_lemma,get_real_addr_lemma]
    \\ fs [] \\ eval_tac
    \\ fs [lookup_insert,adjust_var_11]
    \\ rw [] \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ first_x_assum (fn th => mp_tac th THEN match_mp_tac memory_rel_rearrange)
    \\ fs [] \\ rw [] \\ fs [])
  \\ Cases_on `op = UpdateByte` \\ fs[] THEN1 (
    imp_res_tac get_vars_IMP_LENGTH \\ fs[]
    \\ fs[do_app] \\ every_case_tac \\ fs[] \\ clean_tac
    \\ fs[quantHeuristicsTheory.LIST_LENGTH_3] \\ clean_tac
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs[quantHeuristicsTheory.LIST_LENGTH_3] \\ clean_tac
    \\ imp_res_tac get_vars_3_IMP
    \\ fs[bviPropsTheory.bvl_to_bvi_with_refs,
          bviPropsTheory.bvl_to_bvi_id,
          bvi_to_data_refs, data_to_bvi_refs]
    \\ fs[GSYM bvi_to_data_refs]
    \\ fs[data_to_bvi_def]
    \\ fs[state_rel_thm,set_var_def]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ rpt_drule (memory_rel_get_vars_IMP )
    \\ strip_tac
    \\ fs[get_vars_def]
    \\ every_case_tac \\ fs[] \\ clean_tac
    \\ rpt_drule memory_rel_ByteArray_IMP
    \\ strip_tac \\ clean_tac
    \\ rpt_drule (GEN_ALL(CONV_RULE(LAND_CONV(move_conj_left(same_const``get_var`` o #1 o strip_comb o lhs)))get_real_addr_lemma))
    \\ imp_res_tac memory_rel_tl
    \\ rpt_drule memory_rel_Number_IMP
    \\ imp_res_tac memory_rel_tl
    \\ rpt_drule memory_rel_Number_IMP
    \\ ntac 2 (pop_assum kall_tac)
    \\ ntac 2 strip_tac \\ clean_tac
    \\ qpat_x_assum`get_var (adjust_var e2) _ = _`assume_tac
    \\ rpt_drule get_real_byte_offset_lemma
    \\ simp[assign_def,list_Seq_def] \\ eval_tac
    \\ fs[wordSemTheory.get_var_def]
    \\ simp[lookup_insert,wordSemTheory.inst_def]
    \\ `2 < dimindex(:'a)` by fs[good_dimindex_def]
    \\ simp[wordSemTheory.get_var_def,Unit_def]
    \\ eval_tac
    \\ simp[lookup_insert]
    \\ rpt strip_tac
    \\ simp[Smallnum_i2w,GSYM integer_wordTheory.word_i2w_mul]
    \\ qspecl_then[`ii`,`2`](mp_tac o Q.GEN`ii` o SYM) WORD_MUL_LSL
    \\ `i2w 4 = 4w` by EVAL_TAC
    \\ simp[]
    \\ `i2w i << 2 >>> 2 = i2w i`
    by (
      match_mp_tac lsl_lsr
      \\ Cases_on`i`
      \\ fs[small_int_def,X_LT_DIV,dimword_def,integer_wordTheory.i2w_def] )
    \\ pop_assum (CHANGED_TAC o SUBST_ALL_TAC)
    \\ `i2w (&w2n w) << 2 >>> 2 = i2w (&w2n w)`
    by (
      match_mp_tac lsl_lsr
      \\ fs[small_int_def,X_LT_DIV,dimword_def,integer_wordTheory.i2w_def] )
    \\ pop_assum (CHANGED_TAC o SUBST_ALL_TAC)
    \\ `dimindex(:8) ≤ dimindex(:α)` by fs[good_dimindex_def]
    \\ simp[integer_wordTheory.w2w_i2w]
    \\ `i2w i = n2w (Num i)`
    by (
      rw[integer_wordTheory.i2w_def]
      \\ `F` by intLib.COOPER_TAC )
    \\ pop_assum (CHANGED_TAC o SUBST_ALL_TAC)
    \\ disch_then kall_tac
    \\ qpat_x_assum`∀i. _ ⇒ mem_load_byte_aux _ _ _ _ = _`(qspec_then`Num i`mp_tac)
    \\ impl_tac
    >- (
      fs[GSYM integerTheory.INT_OF_NUM]
      \\ REWRITE_TAC[GSYM integerTheory.INT_LT]
      \\ PROVE_TAC[] )
    \\ simp[wordSemTheory.mem_load_byte_aux_def]
    \\ BasicProvers.TOP_CASE_TAC \\ fs[]
    \\ strip_tac
    \\ simp[wordSemTheory.mem_store_byte_aux_def]
    \\ simp[lookup_insert]
    \\ conj_tac >- rw[]
    \\ fs[inter_insert_ODD_adjust_set]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert
    \\ simp[]
    \\ match_mp_tac memory_rel_Unit
    \\ first_x_assum(qspecl_then[`Num i`,`w`]mp_tac)
    \\ impl_tac
    >- (
      fs[GSYM integerTheory.INT_OF_NUM]
      \\ REWRITE_TAC[GSYM integerTheory.INT_LT]
      \\ PROVE_TAC[] )
    \\ simp[theWord_def] \\ strip_tac
    \\ drule memory_rel_tl \\ simp[] \\ strip_tac
    \\ drule memory_rel_tl \\ simp[] \\ strip_tac
    \\ drule memory_rel_tl \\ simp[])
  \\ Cases_on `op = DerefByte` \\ fs[] THEN1 (
    imp_res_tac get_vars_IMP_LENGTH \\ fs[]
    \\ fs[do_app] \\ every_case_tac \\ fs[] \\ clean_tac
    \\ fs[quantHeuristicsTheory.LIST_LENGTH_2] \\ clean_tac
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs[quantHeuristicsTheory.LIST_LENGTH_2] \\ clean_tac
    \\ imp_res_tac get_vars_2_IMP
    \\ fs[bviPropsTheory.bvl_to_bvi_id]
    \\ fs[state_rel_thm,set_var_def]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ rpt_drule (memory_rel_get_vars_IMP )
    \\ strip_tac
    \\ fs[get_vars_def]
    \\ every_case_tac \\ fs[] \\ clean_tac
    \\ fs[data_to_bvi_def]
    \\ rpt_drule memory_rel_ByteArray_IMP
    \\ strip_tac \\ clean_tac
    \\ first_x_assum(qspec_then`ARB`kall_tac)
    \\ rpt_drule (GEN_ALL(CONV_RULE(LAND_CONV(move_conj_left(same_const``get_var`` o #1 o strip_comb o lhs)))get_real_addr_lemma))
    \\ imp_res_tac memory_rel_tl
    \\ rpt_drule memory_rel_Number_IMP
    \\ pop_assum kall_tac
    \\ strip_tac
    \\ clean_tac
    \\ qpat_x_assum`get_var _ _ = SOME (Word(Smallnum _))`assume_tac
    \\ rpt_drule get_real_byte_offset_lemma
    \\ simp[assign_def,list_Seq_def] \\ eval_tac
    \\ simp[wordSemTheory.inst_def]
    \\ eval_tac
    \\ fs[Smallnum_i2w,GSYM integer_wordTheory.word_i2w_mul]
    \\ qspecl_then[`i2w i`,`2`](mp_tac o SYM) WORD_MUL_LSL
    \\ `i2w 4 = 4w` by EVAL_TAC
    \\ simp[]
    \\ `i2w i << 2 >>> 2 = i2w i`
    by (
      match_mp_tac lsl_lsr
      \\ REWRITE_TAC[GSYM integerTheory.INT_LT,
                     GSYM integerTheory.INT_MUL,
                     integer_wordTheory.w2n_i2w]
      \\ simp[]
      \\ reverse(Cases_on`i`) \\ fs[]
      >- (
        fs[dimword_def, integerTheory.INT_MOD0] )
      \\ simp[integerTheory.INT_MOD,dimword_def]
      \\ fs[small_int_def,dimword_def]
      \\ fs[X_LT_DIV] )
    \\ simp[]
    \\ first_x_assum(qspec_then`Num i`mp_tac)
    \\ impl_tac >- ( Cases_on`i` \\ fs[] )
    \\ `i2w i = n2w (Num i)`
    by (
      rw[integer_wordTheory.i2w_def]
      \\ Cases_on`i` \\ fs[] )
    \\ fs[]
    \\ `¬(2 ≥ dimindex(:α))` by fs[good_dimindex_def]
    \\ simp[lookup_insert]
    \\ ntac 4 strip_tac
    \\ conj_tac >- rw[]
    \\ fs[inter_insert_ODD_adjust_set]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert
    \\ qmatch_goalsub_abbrev_tac`(Number j,Word k)`
    \\ `small_int (:α) j ∧ k = Smallnum j`
    by (
      fs[small_int_def,Abbr`j`]
      \\ qmatch_goalsub_abbrev_tac`w2n w8`
      \\ Q.ISPEC_THEN`w8`strip_assume_tac w2n_lt
      \\ conj_tac
      >- ( fs[good_dimindex_def,dimword_def] )
      \\ simp[integer_wordTheory.i2w_def,Smallnum_i2w]
      \\ simp[Abbr`k`,WORD_MUL_LSL]
      \\ simp[GSYM word_mul_n2w]
      \\ simp[w2w_def] )
    \\ simp[]
    \\ match_mp_tac IMP_memory_rel_Number
    \\ fs[])
  \\ Cases_on `op = El` \\ fs [] \\ fs [] \\ clean_tac THEN1
   (imp_res_tac get_vars_IMP_LENGTH \\ fs []
    \\ fs [do_app] \\ every_case_tac \\ fs [] \\ clean_tac
    \\ fs [INT_EQ_NUM_LEMMA] \\ clean_tac
    \\ fs [integerTheory.NUM_OF_INT,LENGTH_EQ_2] \\ clean_tac
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs [assign_def] \\ eval_tac \\ fs [state_rel_thm]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ drule (memory_rel_get_vars_IMP |> GEN_ALL)
    \\ disch_then drule \\ fs []
    \\ imp_res_tac get_vars_2_IMP \\ fs []
    \\ fs [integerTheory.NUM_OF_INT,LENGTH_EQ_2] \\ clean_tac
    \\ imp_res_tac get_vars_2_IMP \\ fs [] \\ strip_tac
    \\ drule (memory_rel_El |> GEN_ALL) \\ fs []
    \\ strip_tac \\ clean_tac
    \\ `word_exp t (real_offset c (adjust_var a2)) = SOME (Word y) /\
        word_exp t (real_addr c (adjust_var a1)) = SOME (Word x')` by
          metis_tac [get_real_offset_lemma,get_real_addr_lemma]
    \\ fs [] \\ eval_tac
    \\ fs [lookup_insert,adjust_var_11]
    \\ rw [] \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ first_x_assum (fn th => mp_tac th THEN match_mp_tac memory_rel_rearrange)
    \\ fs [] \\ rw [] \\ fs [])
  \\ Cases_on `?i. op = Const i` \\ fs [] THEN1
   (var_eq_tac \\ fs [do_app]
    \\ every_case_tac \\ fs []
    \\ rpt var_eq_tac
    \\ fs [assign_def]
    \\ Cases_on `i` \\ fs []
    \\ fs [wordSemTheory.evaluate_def,wordSemTheory.word_exp_def]
    \\ fs [state_rel_def,wordSemTheory.set_var_def,set_var_def,
          lookup_insert,adjust_var_11]
    \\ rw [] \\ fs []
    \\ asm_exists_tac \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac word_ml_inv_insert \\ fs []
    \\ TRY (match_mp_tac word_ml_inv_zero) \\ fs []
    \\ TRY (match_mp_tac word_ml_inv_num) \\ fs []
    \\ TRY (match_mp_tac word_ml_inv_neg_num) \\ fs [])
  \\ Cases_on `op = GlobalsPtr` \\ fs [] THEN1
   (var_eq_tac \\ fs [do_app]
    \\ every_case_tac \\ fs []
    \\ rpt var_eq_tac
    \\ fs [assign_def]
    \\ fs [data_to_bvi_def]
    \\ fs[wordSemTheory.evaluate_def,wordSemTheory.word_exp_def]
    \\ fs [state_rel_def]
    \\ fs [the_global_def,libTheory.the_def]
    \\ fs [FLOOKUP_DEF,wordSemTheory.set_var_def,lookup_insert,
           adjust_var_11,libTheory.the_def,set_var_def]
    \\ rw [] \\ fs []
    \\ asm_exists_tac \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac word_ml_inv_insert \\ fs []
    \\ first_x_assum (fn th => mp_tac th THEN match_mp_tac word_ml_inv_rearrange)
    \\ fs [] \\ rw [] \\ fs [])
  \\ Cases_on `op = SetGlobalsPtr` \\ fs [] THEN1
   (var_eq_tac \\ fs [do_app]
    \\ every_case_tac \\ fs []
    \\ rpt var_eq_tac
    \\ fs [assign_def]
    \\ imp_res_tac get_vars_SING \\ fs []
    \\ `args <> []` by (strip_tac \\ fs [dataSemTheory.get_vars_def])
    \\ fs[wordSemTheory.evaluate_def,wordSemTheory.word_exp_def,Unit_def]
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ Cases_on `ws` \\ fs [LENGTH_NIL] \\ rpt var_eq_tac
    \\ pop_assum (fn th => assume_tac th THEN mp_tac th)
    \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_def]
    \\ every_case_tac \\ fs [] \\ rpt var_eq_tac
    \\ fs [state_rel_def,wordSemTheory.set_var_def,lookup_insert,
           adjust_var_11,libTheory.the_def,set_var_def,bvi_to_data_def,
           wordSemTheory.set_store_def,data_to_bvi_def]
    \\ rpt_drule heap_in_memory_store_IMP_UPDATE
    \\ disch_then (qspec_then `h` assume_tac)
    \\ rw [] \\ fs []
    \\ asm_exists_tac \\ fs [the_global_def,libTheory.the_def]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ drule (GEN_ALL word_ml_inv_get_vars_IMP)
    \\ disch_then drule
    \\ fs [wordSemTheory.get_vars_def,wordSemTheory.get_var_def]
    \\ strip_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac word_ml_inv_insert \\ fs []
    \\ match_mp_tac word_ml_inv_Unit
    \\ pop_assum mp_tac \\ fs []
    \\ match_mp_tac word_ml_inv_rearrange \\ rw [] \\ fs [])
  \\ Cases_on `?tag. op = Cons tag` \\ fs [] \\ fs [] THEN1
   (Cases_on `LENGTH args = 0` THEN1
     (fs [assign_def] \\ IF_CASES_TAC \\ fs []
      \\ fs [LENGTH_NIL] \\ rpt var_eq_tac
      \\ fs [do_app] \\ every_case_tac \\ fs []
      \\ imp_res_tac get_vars_IMP_LENGTH \\ fs []
      \\ Cases_on `vals` \\ fs [] \\ clean_tac
      \\ eval_tac \\ clean_tac
      \\ fs [state_rel_def,lookup_insert,adjust_var_11]
      \\ rw [] \\ fs []
      \\ asm_exists_tac \\ fs []
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
      \\ match_mp_tac word_ml_inv_insert \\ fs []
      \\ fs [word_ml_inv_def,PULL_EXISTS] \\ rw []
      \\ qexists_tac `Data (Word (n2w (16 * tag + 2)))`
      \\ qexists_tac `hs` \\ fs [word_addr_def]
      \\ reverse conj_tac
      THEN1 (fs [GSYM word_mul_n2w,GSYM word_add_n2w,BlockNil_and_lemma])
      \\ `n2w (16 * tag + 2) = BlockNil tag : 'a word` by
           fs [BlockNil_def,WORD_MUL_LSL,word_mul_n2w,word_add_n2w]
      \\ fs [cons_thm_EMPTY])
    \\ fs [assign_def] \\ CASE_TAC \\ fs []
    \\ fs [do_app] \\ every_case_tac \\ fs []
    \\ imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ clean_tac
    \\ fs [consume_space_def] \\ clean_tac
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs [state_rel_thm] \\ eval_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ drule (memory_rel_get_vars_IMP |> GEN_ALL)
    \\ disch_then drule \\ fs [NOT_LESS,DECIDE ``n + 1 <= m <=> n < m:num``]
    \\ strip_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ `vals <> []` by fs [GSYM LENGTH_NIL]
    \\ rpt_drule memory_rel_Cons \\ strip_tac
    \\ fs [list_Seq_def] \\ eval_tac
    \\ fs [wordSemTheory.set_store_def]
    \\ qpat_abbrev_tac `t5 = t with <| locals := _ ; store := _ |>`
    \\ pairarg_tac \\ fs []
    \\ `t.memory = t5.memory /\ t.mdomain = t5.mdomain` by
         (unabbrev_all_tac \\ fs []) \\ fs []
    \\ ntac 2 (pop_assum kall_tac)
    \\ drule evaluate_StoreEach
    \\ disch_then (qspecl_then [`3::MAP adjust_var args`,`1`] mp_tac)
    \\ impl_tac THEN1
     (fs [wordSemTheory.get_vars_def,Abbr`t5`,wordSemTheory.get_var_def,
          lookup_insert,get_vars_with_store,get_vars_adjust_var] \\ NO_TAC)
    \\ clean_tac \\ fs [] \\ UNABBREV_ALL_TAC
    \\ fs [lookup_insert,FAPPLY_FUPDATE_THM,adjust_var_11,FLOOKUP_UPDATE]
    \\ rw [] \\ fs [] \\ rw [] \\ fs []
    \\ fs [inter_insert_ODD_adjust_set]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs []
    \\ fs [make_cons_ptr_def,get_lowerbits_def])
  \\ Cases_on `op = BlockCmp` \\ fs [] THEN1
   (imp_res_tac get_vars_IMP_LENGTH \\ fs [] \\ rw []
    \\ fs [do_app] \\ rfs [] \\ every_case_tac \\ fs []
    \\ clean_tac \\ fs []
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs [LENGTH_EQ_2] \\ clean_tac
    \\ qpat_x_assum `state_rel c l1 l2 x t [] locs` (fn th => NTAC 2 (mp_tac th))
    \\ strip_tac
    \\ simp_tac std_ss [state_rel_thm] \\ strip_tac \\ fs [] \\ eval_tac
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ rpt_drule (memory_rel_get_vars_IMP |> GEN_ALL)
    \\ strip_tac \\ fs []
    \\ fs [assign_def,list_Seq_def]
    \\ imp_res_tac get_vars_2_imp
    \\ rpt_drule memory_rel_Block_IMP \\ strip_tac \\ fs []
    \\ rpt_drule memory_rel_tl \\ strip_tac
    \\ rpt_drule memory_rel_Block_IMP \\ strip_tac \\ fs []
    \\ rename1 `if ll2 = [] then _ else (_:bool)` \\ pop_assum mp_tac
    \\ rename1 `if ll1 = [] then _ else (_:bool)` \\ pop_assum mp_tac
    \\ rpt strip_tac \\ fs [] \\ clean_tac
    \\ eval_tac
    \\ fs [wordSemTheory.get_var_def,asmSemTheory.word_cmp_def,
         wordSemTheory.get_var_imm_def,lookup_insert]
    \\ fs [word_and_one_eq_0_iff |> SIMP_RULE (srw_ss()) []]
    \\ IF_CASES_TAC \\ fs [] \\ clean_tac
    THEN1 (* first argument is nil-cons *)
     (fs [wordSemTheory.get_var_def,asmSemTheory.word_cmp_def,
          wordSemTheory.get_var_imm_def,lookup_insert]
      \\ IF_CASES_TAC \\ fs [] \\ clean_tac
      THEN1 (* nil-cons cmp nil-cons *)
       (fs [lookup_insert,word_mul_n2w,X_LT_DIV,
          DECIDE ``16 * n = 16 * m <=> n = m:num``,
          DECIDE ``16 * (n + 1) ≤ k ==> 16 * n < k:num``]
        \\ IF_CASES_TAC \\ fs [] \\ fs [lookup_insert]
        \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
        \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
        \\ match_mp_tac memory_rel_insert \\ fs [inter_insert_ODD_adjust_set_alt]
        \\ TRY (match_mp_tac memory_rel_Boolv_T)
        \\ TRY (match_mp_tac memory_rel_Boolv_F) \\ fs [])
      \\ rpt_drule word_exp_real_addr_2
      \\ rpt strip_tac \\ fs [lookup_insert]
      \\ IF_CASES_TAC \\ fs []
      THEN1 (imp_res_tac encode_header_IMP_BIT0 \\ fs [])
      \\ fs [GSYM LENGTH_NIL]
      \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
      \\ match_mp_tac memory_rel_insert \\ fs [inter_insert_ODD_adjust_set_alt]
      \\ TRY (match_mp_tac memory_rel_Boolv_F) \\ fs [])
    \\ rpt_drule word_exp_real_addr \\ fs [insert_shadow]
    \\ fs [wordSemTheory.get_var_def,asmSemTheory.word_cmp_def,
          wordSemTheory.get_var_imm_def,lookup_insert]
    \\ IF_CASES_TAC \\ fs [lookup_insert]
    THEN1 (* non-nil-cons cmp nil-cons *)
     (IF_CASES_TAC \\ fs []
      \\ imp_res_tac encode_header_IMP_BIT0 \\ fs []
      \\ fs [GSYM LENGTH_NIL]
      \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
      \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
      \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
      \\ match_mp_tac memory_rel_insert \\ fs [inter_insert_ODD_adjust_set_alt]
      \\ match_mp_tac memory_rel_Boolv_F \\ fs [])
    \\ rpt_drule word_exp_real_addr_2 \\ fs [] \\ fs [lookup_insert]
    \\ IF_CASES_TAC \\ fs [] \\ rpt strip_tac
    \\ fs [lookup_insert,adjust_var_11] \\ rw [] \\ fs []
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs [inter_insert_ODD_adjust_set_alt]
    \\ drule (GEN_ALL encode_header_EQ)
    \\ qpat_x_assum `encode_header _ _ _ = _` kall_tac
    \\ disch_then drule \\ impl_tac
    \\ TRY (fs [memory_rel_def,heap_in_memory_store_def] \\ NO_TAC)
    \\ fs [] \\ rpt strip_tac
    \\ TRY (match_mp_tac memory_rel_Boolv_T) \\ fs []
    \\ TRY (match_mp_tac memory_rel_Boolv_F) \\ fs [])
  \\ Cases_on `∃n. op = FFI n` \\ fs[] THEN1 (
    fs[do_app] \\ clean_tac
    \\ imp_res_tac get_vars_IMP_LENGTH
    \\ every_case_tac \\ fs[] \\ clean_tac
    \\ fs[CONJUNCT2 bvi_to_data_refs,
          SYM(CONJUNCT1 bvi_to_data_refs),
          data_to_bvi_refs,
          bviPropsTheory.bvl_to_bvi_with_refs,
          bviPropsTheory.bvl_to_bvi_id,
          data_to_bvi_ffi,
          bviPropsTheory.bvi_to_bvl_to_bvi_with_ffi,
          data_to_bvi_to_data_with_ffi]
    \\ fs[quantHeuristicsTheory.LIST_LENGTH_2] \\ clean_tac
    \\ imp_res_tac state_rel_get_vars_IMP
    \\ fs[quantHeuristicsTheory.LIST_LENGTH_2] \\ clean_tac
    \\ imp_res_tac get_vars_1_imp
    \\ fs[state_rel_thm,set_var_def]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ rpt_drule (memory_rel_get_vars_IMP )
    \\ strip_tac
    \\ fs[get_vars_def]
    \\ every_case_tac \\ fs[] \\ clean_tac
    \\ rpt_drule memory_rel_ByteArray_IMP
    \\ strip_tac \\ clean_tac
    \\ simp[assign_def,list_Seq_def] \\ eval_tac
    \\ rpt_drule (GEN_ALL(CONV_RULE(LAND_CONV(move_conj_left(same_const``get_var`` o #1 o strip_comb o lhs)))get_real_addr_lemma))
    \\ simp[]
    \\ qpat_abbrev_tac`tt = t with locals := _`
    \\ `get_var (adjust_var e1) tt = get_var (adjust_var e1) t`
    by fs[Abbr`tt`,wordSemTheory.get_var_def,lookup_insert]
    \\ rfs[]
    \\ rpt_drule (GEN_ALL(CONV_RULE(LAND_CONV(move_conj_left(same_const``get_var`` o #1 o strip_comb o lhs)))get_real_addr_lemma))
    \\ `tt.store = t.store` by simp[Abbr`tt`]
    \\ simp[]
    \\ IF_CASES_TAC >- ( fs[shift_def] )
    \\ simp[wordSemTheory.get_var_def,lookup_insert]
    \\ qpat_x_assum`¬_`kall_tac
    \\ BasicProvers.TOP_CASE_TAC
    >- (
      `F` suffices_by rw[]
      \\ pop_assum mp_tac
      \\ BasicProvers.CASE_TAC
      >- ( simp[wordSemTheory.cut_env_def,domain_lookup])
      \\ fs[cut_state_opt_def]
      \\ drule (#1(EQ_IMP_RULE cut_state_eq_some))
      \\ strip_tac
      \\ clean_tac
      \\ simp[wordSemTheory.cut_env_def]
      \\ rw[SUBSET_DEF,domain_lookup]
      \\ fs[dataSemTheory.cut_env_def]
      \\ clean_tac \\ fs[]
      \\ Cases_on`x=0` >- metis_tac[]
      \\ qmatch_assum_abbrev_tac`lookup x ss = SOME _`
      \\ `x ∈ domain ss` by metis_tac[domain_lookup]
      \\ qunabbrev_tac`ss`
      \\ imp_res_tac domain_adjust_set_EVEN
      \\ `∃z. x = adjust_var z`
      by (
        simp[adjust_var_def]
        \\ fs[EVEN_EXISTS]
        \\ Cases_on`m` \\ fs[ADD1,LEFT_ADD_DISTRIB] )
      \\ rveq
      \\ fs[lookup_adjust_var_adjust_set_SOME_UNIT]
      \\ last_x_assum(qspec_then`z`mp_tac)
      \\ simp[lookup_inter]
      \\ fs[IS_SOME_EXISTS]
      \\ disch_then match_mp_tac
      \\ BasicProvers.CASE_TAC
      \\ fs[SUBSET_DEF,domain_lookup]
      \\ res_tac \\ fs[])
    \\ qmatch_goalsub_abbrev_tac`read_bytearray aa len g`
    \\ qmatch_asmsub_rename_tac`LENGTH ls + 3`
    \\ qispl_then[`ls`,`LENGTH ls`,`aa`]mp_tac IMP_read_bytearray_GENLIST
    \\ impl_tac >- simp[]
    \\ `len = LENGTH ls`
    by (
      simp[Abbr`len`]
      \\ rfs[good_dimindex_def] \\ rfs[shift_def]
      \\ simp[bytes_in_word_def,GSYM word_add_n2w]
      \\ simp[dimword_def] )
    \\ qunabbrev_tac`len` \\ fs[]
    \\ rpt strip_tac
    \\ simp[Unit_def]
    \\ eval_tac
    \\ simp[lookup_insert]
    \\ fs[wordSemTheory.cut_env_def] \\ clean_tac
    \\ simp[lookup_inter,lookup_insert,lookup_adjust_var_adjust_set]
    \\ conj_tac >- ( simp[adjust_set_def,lookup_fromAList] )
    \\ fs[bvi_to_dataTheory.op_requires_names_def]
    \\ Cases_on`names_opt`\\fs[]
    \\ conj_tac
    >- (
      fs[cut_state_opt_def]
      \\ rw[]
      \\ first_assum drule
      \\ simp_tac(srw_ss())[IS_SOME_EXISTS] \\ strip_tac \\ fs[]
      \\ BasicProvers.TOP_CASE_TAC \\ simp[]
      \\ drule (#1(EQ_IMP_RULE cut_state_eq_some))
      \\ strip_tac \\ clean_tac
      \\ fs[dataSemTheory.cut_env_def] \\ clean_tac
      \\ fs[lookup_inter_alt,domain_lookup])
    \\ fs[inter_insert_ODD_adjust_set_alt]
    \\ full_simp_tac std_ss [GSYM APPEND_ASSOC]
    \\ match_mp_tac memory_rel_insert \\ fs[]
    \\ match_mp_tac memory_rel_Unit \\ fs[]
    \\ qmatch_goalsub_rename_tac`ByteArray ls'`
    \\ `LENGTH ls' = LENGTH ls`
    by (
      qhdtm_x_assum`call_FFI`mp_tac
      \\ simp[ffiTheory.call_FFI_def]
      \\ BasicProvers.TOP_CASE_TAC \\ simp[]
      \\ BasicProvers.TOP_CASE_TAC \\ simp[]
      \\ BasicProvers.TOP_CASE_TAC \\ simp[]
      \\ rw[] \\ rw[] )
    \\ qmatch_asmsub_abbrev_tac`((RefPtr p,Word w)::vars)`
    \\ `∀n. n ≤ LENGTH ls ⇒
        let new_m = write_bytearray (aa + n2w (LENGTH ls - n)) (DROP (LENGTH ls - n) ls') t.memory t.mdomain t.be in
        memory_rel c t.be (x.refs |+ (p,ByteArray (TAKE (LENGTH ls - n) ls ++ DROP (LENGTH ls - n) ls'))) x.space t.store
          new_m t.mdomain ((RefPtr p,Word w)::vars) ∧
        (∀i v. i < LENGTH ls ⇒
          memory_rel c t.be (x.refs |+ (p,ByteArray (LUPDATE v i (TAKE (LENGTH ls - n) ls ++ DROP (LENGTH ls - n) ls'))))
            x.space t.store
            ((byte_align (aa + n2w i) =+
              Word (set_byte (aa + n2w i) v
                     (theWord (new_m (byte_align (aa + n2w i)))) t.be)) new_m)
             t.mdomain ((RefPtr p,Word w)::vars))`
    by (
      Induct \\ simp[]
      >- (
        simp[DROP_LENGTH_NIL_rwt,wordSemTheory.write_bytearray_def]
        \\ qpat_abbrev_tac`refs = x.refs |+ _`
        \\ `refs = x.refs`
        by(
          simp[Abbr`refs`,FLOOKUP_EXT,FUN_EQ_THM,FLOOKUP_UPDATE]
          \\ rw[] \\ rw[] )
        \\ rw[] )
      \\ strip_tac \\ fs[]
      \\ qpat_abbrev_tac`ls2 = TAKE _ _ ++ _`
      \\ qmatch_asmsub_abbrev_tac`ByteArray ls1`
      \\ `ls2 = LUPDATE (EL (LENGTH ls - SUC n) ls') (LENGTH ls - SUC n) ls1`
      by (
        simp[Abbr`ls1`,Abbr`ls2`,LIST_EQ_REWRITE,EL_APPEND_EQN,EL_LUPDATE]
        \\ rw[] \\ fs[] \\ simp[EL_TAKE,hd_drop,EL_DROP] )
      \\ qunabbrev_tac`ls2` \\ fs[]
      \\ qmatch_goalsub_abbrev_tac`EL i ls'`
      \\ `i < LENGTH ls` by simp[Abbr`i`]
      \\ first_x_assum(qspecl_then[`i`,`EL i ls'`]mp_tac)
      \\ impl_tac >- rw[]
      \\ `DROP i ls' = EL i ls'::DROP(LENGTH ls - n)ls'`
      by (
        Cases_on`ls'` \\ fs[Abbr`i`]
        \\ simp[LIST_EQ_REWRITE,ADD1,EL_DROP,EL_CONS,PRE_SUB1]
        \\ IF_CASES_TAC \\ fs[]
        >- (
          `LENGTH ls = SUC n` by decide_tac \\ simp[ADD1] )
        \\ Cases \\ simp[EL_DROP,ADD1,EL_CONS,PRE_SUB1] )
      \\ first_assum SUBST1_TAC
      \\ qpat_abbrev_tac`wb = write_bytearray _ (_ :: _) _ _ _`
      \\ qpat_abbrev_tac `wb1 = write_bytearray _ _ _ _ _`
      \\ qpat_abbrev_tac`wb2 = _ wb1`
      \\ `wb2 = wb`
      by (
        simp[Abbr`wb2`,Abbr`wb`,wordSemTheory.write_bytearray_def]
        \\ `aa + n2w i + 1w = aa + n2w (LENGTH ls - n)`
        by(
          simp[Abbr`i`,ADD1]
          \\ REWRITE_TAC[GSYM WORD_ADD_ASSOC]
          \\ AP_TERM_TAC
          \\ simp[word_add_n2w] )
        \\ pop_assum SUBST_ALL_TAC \\ simp[]
        \\ simp[wordSemTheory.mem_store_byte_aux_def]
        \\ last_x_assum drule
        \\ simp[Abbr`g`,wordSemTheory.mem_load_byte_aux_def]
        \\ BasicProvers.TOP_CASE_TAC \\ simp[] \\ strip_tac
        \\ qmatch_assum_rename_tac`t.memory _ = Word v`
        \\ `∃v. wb1 (byte_align (aa + n2w i)) = Word v`
        by (
          `isWord (wb1 (byte_align (aa + n2w i)))`
          suffices_by (metis_tac[isWord_def,wordSemTheory.word_loc_nchotomy])
          \\ simp[Abbr`wb1`]
          \\ match_mp_tac write_bytearray_isWord
          \\ simp[isWord_def] )
        \\ simp[theWord_def] )
      \\ qunabbrev_tac`wb2`
      \\ pop_assum SUBST_ALL_TAC
      \\ strip_tac
      \\ conj_tac >- first_assum ACCEPT_TAC
      \\ drule (GEN_ALL memory_rel_ByteArray_IMP)
      \\ simp[FLOOKUP_UPDATE]
      \\ strip_tac
      \\ `LENGTH ls = LENGTH ls1`
      by ( unabbrev_all_tac \\ simp[] )
      \\ metis_tac[] )
    \\ first_x_assum(qspec_then`LENGTH ls`mp_tac)
    \\ simp[Abbr`vars`] \\ strip_tac
    \\ drule memory_rel_tl
    \\ ntac 10 (pop_assum kall_tac)
    \\ match_mp_tac memory_rel_rearrange
    \\ simp[join_env_def,MEM_MAP,PULL_EXISTS,MEM_FILTER,MEM_toAList,EXISTS_PROD,lookup_inter_alt]
    \\ rw[] \\ rw[] \\ metis_tac[])
  \\ Cases_on `op = ToList` \\ fs [] THEN1 (fs [do_app])
  \\ Cases_on `op = AllocGlobal` \\ fs [] THEN1 (fs [do_app])
  \\ Cases_on `?i. op = Global i` \\ fs [] THEN1 (fs [do_app])
  \\ Cases_on `?i. op = SetGlobal i` \\ fs [] THEN1 (fs [do_app])
  \\ `assign c n l dest op args names_opt = (GiveUp,l)` by
        (Cases_on `op` \\ fs [assign_def]
         \\ every_case_tac \\ fs [] \\ NO_TAC) \\ fs []);

val none = ``NONE:(num # ('a wordLang$prog) # num # num) option``

val data_compile_correct = store_thm("data_compile_correct",
  ``!prog (s:'ffi dataSem$state) c n l l1 l2 res s1 (t:('a,'ffi)wordSem$state) locs.
      (dataSem$evaluate (prog,s) = (res,s1)) /\
      res <> SOME (Rerr (Rabort Rtype_error)) /\
      state_rel c l1 l2 s t [] locs /\
      t.termdep > 0
      ==>
      ?t1 res1.
        (wordSem$evaluate (FST (comp c n l prog),t) = (res1,t1)) /\
        (res1 = SOME NotEnoughSpace ==>
           t1.ffi.io_events ≼ s1.ffi.io_events ∧
           (IS_SOME t1.ffi.final_event ⇒ t1.ffi = s1.ffi)) /\
        (res1 <> SOME NotEnoughSpace ==>
         case res of
         | NONE => state_rel c l1 l2 s1 t1 [] locs /\ (res1 = NONE)
         | SOME (Rval v) =>
             ?w. state_rel c l1 l2 s1 t1 [(v,w)] locs /\
                 (res1 = SOME (Result (Loc l1 l2) w))
         | SOME (Rerr (Rraise v)) =>
             ?w l5 l6 ll.
               (res1 = SOME (Exception (mk_loc (jump_exc t)) w)) /\
               (jump_exc t <> NONE ==>
                LASTN (LENGTH s1.stack + 1) locs = (l5,l6)::ll /\
                !i. state_rel c l5 l6 (set_var i v s1)
                       (set_var (adjust_var i) w t1) [] ll)
         | SOME (Rerr (Rabort e)) => (res1 = SOME TimeOut) /\ t1.ffi = s1.ffi)``,
  recInduct dataSemTheory.evaluate_ind \\ rpt strip_tac \\ full_simp_tac(srw_ss())[]
  THEN1 (* Skip *)
   (full_simp_tac(srw_ss())[comp_def,dataSemTheory.evaluate_def,wordSemTheory.evaluate_def]
    \\ srw_tac[][])
  THEN1 (* Move *)
   (full_simp_tac(srw_ss())[comp_def,dataSemTheory.evaluate_def,wordSemTheory.evaluate_def]
    \\ Cases_on `get_var src s.locals` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
    \\ full_simp_tac(srw_ss())[] \\ imp_res_tac state_rel_get_var_IMP \\ full_simp_tac(srw_ss())[]
    \\ full_simp_tac(srw_ss())[wordSemTheory.get_vars_def,wordSemTheory.set_vars_def,alist_insert_def]
    \\ full_simp_tac(srw_ss())[state_rel_def,set_var_def,lookup_insert]
    \\ rpt strip_tac \\ full_simp_tac(srw_ss())[]
    THEN1 (srw_tac[][] \\ Cases_on `n = dest` \\ full_simp_tac(srw_ss())[])
    \\ asm_exists_tac
    \\ full_simp_tac bool_ss [GSYM APPEND_ASSOC]
    \\ imp_res_tac word_ml_inv_get_var_IMP
    \\ match_mp_tac word_ml_inv_insert \\ full_simp_tac(srw_ss())[])
  THEN1 (* Assign *)
   (full_simp_tac(srw_ss())[comp_def,dataSemTheory.evaluate_def,wordSemTheory.evaluate_def]
    \\ imp_res_tac (METIS_PROVE [] ``(if b1 /\ b2 then x1 else x2) = y ==>
                                     b1 /\ b2 /\ x1 = y \/
                                     (b1 ==> ~b2) /\ x2 = y``)
    \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ Cases_on `cut_state_opt names_opt s` \\ full_simp_tac(srw_ss())[]
    \\ Cases_on `get_vars args x.locals` \\ full_simp_tac(srw_ss())[]
    \\ reverse (Cases_on `do_app op x' x`) \\ full_simp_tac(srw_ss())[]
    THEN1 (imp_res_tac do_app_Rerr \\ srw_tac[][])
    \\ Cases_on `a`
    \\ drule (GEN_ALL assign_thm) \\ full_simp_tac(srw_ss())[]
    \\ rpt (disch_then drule)
    \\ disch_then (qspecl_then [`n`,`l`,`dest`] strip_assume_tac)
    \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
    \\ imp_res_tac do_app_io_events_mono \\ rev_full_simp_tac(srw_ss())[]
    \\ `s.ffi = t.ffi` by full_simp_tac(srw_ss())[state_rel_def] \\ full_simp_tac(srw_ss())[]
    \\ `x.ffi = s.ffi` by all_tac
    \\ imp_res_tac do_app_io_events_mono \\ rev_full_simp_tac(srw_ss())[]
    \\ Cases_on `names_opt` \\ full_simp_tac(srw_ss())[cut_state_opt_def] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
    \\ full_simp_tac(srw_ss())[cut_state_def,cut_env_def] \\ every_case_tac \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[])
  THEN1 (* Tick *)
   (full_simp_tac(srw_ss())[comp_def,dataSemTheory.evaluate_def,wordSemTheory.evaluate_def]
    \\ `t.clock = s.clock` by full_simp_tac(srw_ss())[state_rel_def] \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
    \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ rpt (pop_assum mp_tac)
    \\ full_simp_tac(srw_ss())[wordSemTheory.jump_exc_def,wordSemTheory.dec_clock_def] \\ srw_tac[][]
    \\ full_simp_tac(srw_ss())[state_rel_def,dataSemTheory.dec_clock_def,wordSemTheory.dec_clock_def]
    \\ full_simp_tac(srw_ss())[call_env_def,wordSemTheory.call_env_def]
    \\ Q.LIST_EXISTS_TAC [`heap`,`limit`,`a`,`sp`] \\ full_simp_tac(srw_ss())[])
  THEN1 (* MakeSpace *)
   (full_simp_tac(srw_ss())[comp_def,dataSemTheory.evaluate_def,
        wordSemTheory.evaluate_def,
        GSYM alloc_size_def,LET_DEF,wordSemTheory.word_exp_def,
        wordLangTheory.word_op_def,wordSemTheory.get_var_imm_def]
    \\ `?end next.
          FLOOKUP t.store EndOfHeap = SOME (Word end) /\
          FLOOKUP t.store NextFree = SOME (Word next)` by
            full_simp_tac(srw_ss())[state_rel_def,heap_in_memory_store_def]
    \\ full_simp_tac(srw_ss())[wordSemTheory.the_words_def]
    \\ reverse CASE_TAC THEN1
     (every_case_tac \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
      \\ full_simp_tac(srw_ss())[wordSemTheory.set_var_def,state_rel_insert_1]
      \\ match_mp_tac state_rel_cut_env \\ reverse (srw_tac[][])
      \\ full_simp_tac(srw_ss())[add_space_def] \\ match_mp_tac has_space_state_rel
      \\ full_simp_tac(srw_ss())[wordSemTheory.has_space_def,WORD_LO,NOT_LESS,
             asmSemTheory.word_cmp_def])
    \\ Cases_on `dataSem$cut_env names s.locals` \\ full_simp_tac(srw_ss())[]
    \\ srw_tac[][]
    \\ full_simp_tac(srw_ss())[add_space_def,wordSemTheory.word_exp_def,
         wordSemTheory.get_var_def,wordSemTheory.set_var_def]
    \\ Cases_on `(alloc (alloc_size k) (adjust_set names)
         (t with locals := insert 1 (Word (alloc_size k)) t.locals))
             :('a result option)#( ('a,'ffi) wordSem$state)`
    \\ full_simp_tac(srw_ss())[]
    \\ drule (GEN_ALL alloc_lemma)
    \\ rpt (disch_then drule)
    \\ rw [] \\ fs [])
  THEN1 (* Raise *)
   (full_simp_tac(srw_ss())[comp_def,dataSemTheory.evaluate_def,wordSemTheory.evaluate_def]
    \\ Cases_on `get_var n s.locals` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
    \\ full_simp_tac(srw_ss())[] \\ imp_res_tac state_rel_get_var_IMP \\ full_simp_tac(srw_ss())[]
    \\ Cases_on `jump_exc s` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
    \\ imp_res_tac state_rel_jump_exc \\ full_simp_tac(srw_ss())[]
    \\ srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ srw_tac[][mk_loc_def])
  THEN1 (* Return *)
   (full_simp_tac(srw_ss())[comp_def,dataSemTheory.evaluate_def,wordSemTheory.evaluate_def]
    \\ Cases_on `get_var n s.locals` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
    \\ `get_var 0 t = SOME (Loc l1 l2)` by
          full_simp_tac(srw_ss())[state_rel_def,wordSemTheory.get_var_def]
    \\ full_simp_tac(srw_ss())[] \\ imp_res_tac state_rel_get_var_IMP \\ full_simp_tac(srw_ss())[]
    \\ full_simp_tac(srw_ss())[state_rel_def,wordSemTheory.call_env_def,lookup_def,
           dataSemTheory.call_env_def,fromList_def,EVAL ``join_env LN []``,
           EVAL ``toAList (inter (fromList2 []) (insert 0 () LN))``]
    \\ Q.LIST_EXISTS_TAC [`heap`,`limit`,`a`,`sp`] \\ full_simp_tac(srw_ss())[]
    \\ full_simp_tac bool_ss [GSYM APPEND_ASSOC]
    \\ imp_res_tac word_ml_inv_get_var_IMP
    \\ pop_assum mp_tac
    \\ match_mp_tac word_ml_inv_rearrange
    \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[])
  THEN1 (* Seq *)
   (once_rewrite_tac [data_to_wordTheory.comp_def] \\ full_simp_tac(srw_ss())[]
    \\ Cases_on `comp c n l c1` \\ full_simp_tac(srw_ss())[LET_DEF]
    \\ Cases_on `comp c n r c2` \\ full_simp_tac(srw_ss())[LET_DEF]
    \\ full_simp_tac(srw_ss())[dataSemTheory.evaluate_def,wordSemTheory.evaluate_def]
    \\ Cases_on `evaluate (c1,s)` \\ full_simp_tac(srw_ss())[LET_DEF]
    \\ `q'' <> SOME (Rerr (Rabort Rtype_error))` by
         (Cases_on `q'' = NONE` \\ full_simp_tac(srw_ss())[]) \\ full_simp_tac(srw_ss())[]
    \\ fs[GSYM AND_IMP_INTRO]
    \\ qpat_x_assum `state_rel c l1 l2 s t [] locs` (fn th =>
           first_x_assum (fn th1 => mp_tac (MATCH_MP th1 th)))
    \\ fs[]
    \\ strip_tac \\ pop_assum (mp_tac o Q.SPECL [`n`,`l`])
    \\ rpt strip_tac \\ rev_full_simp_tac(srw_ss())[]
    \\ reverse (Cases_on `q'' = NONE`) \\ full_simp_tac(srw_ss())[]
    THEN1 (full_simp_tac(srw_ss())[] \\ rpt strip_tac \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ Cases_on `q''` \\ full_simp_tac(srw_ss())[]
           \\ Cases_on `x` \\ full_simp_tac(srw_ss())[] \\ Cases_on `e` \\ full_simp_tac(srw_ss())[])
    \\ Cases_on `res1 = SOME NotEnoughSpace` \\ full_simp_tac(srw_ss())[]
    THEN1 (full_simp_tac(srw_ss())[]
      \\ imp_res_tac dataPropsTheory.evaluate_io_events_mono \\ full_simp_tac(srw_ss())[]
      \\ imp_res_tac IS_PREFIX_TRANS \\ full_simp_tac(srw_ss())[] \\ metis_tac []) \\ srw_tac[][]
    \\ qpat_x_assum `state_rel c l1 l2 _ _ [] locs` (fn th =>
             first_x_assum (fn th1 => mp_tac (MATCH_MP th1 th)))
    \\ imp_res_tac wordSemTheory.evaluate_clock \\ fs[]
    \\ strip_tac \\ pop_assum (mp_tac o Q.SPECL [`n`,`r`])
    \\ rpt strip_tac \\ rev_full_simp_tac(srw_ss())[] \\ rpt strip_tac \\ full_simp_tac(srw_ss())[]
    \\ BasicProvers.EVERY_CASE_TAC \\ full_simp_tac(srw_ss())[mk_loc_def] \\ full_simp_tac(srw_ss())[]
    \\ imp_res_tac evaluate_mk_loc_EQ \\ full_simp_tac(srw_ss())[]
    \\ imp_res_tac eval_NONE_IMP_jump_exc_NONE_EQ
    \\ full_simp_tac(srw_ss())[jump_exc_inc_clock_EQ_NONE] \\ metis_tac [])
  THEN1 (* If *)
   (once_rewrite_tac [data_to_wordTheory.comp_def] \\ full_simp_tac(srw_ss())[]
    \\ fs [LET_DEF]
    \\ pairarg_tac \\ fs [] \\ rename1 `comp c n4 l c1 = (q4,l4)`
    \\ pairarg_tac \\ fs [] \\ rename1 `comp c _ _ _ = (q5,l5)`
    \\ full_simp_tac(srw_ss())[dataSemTheory.evaluate_def,wordSemTheory.evaluate_def]
    \\ Cases_on `get_var n s.locals` \\ full_simp_tac(srw_ss())[]
    \\ full_simp_tac(srw_ss())[] \\ imp_res_tac state_rel_get_var_IMP
    \\ full_simp_tac(srw_ss())[wordSemTheory.get_var_imm_def,
          asmSemTheory.word_cmp_def]
    \\ imp_res_tac get_var_T_OR_F
    \\ fs[GSYM AND_IMP_INTRO]
    \\ Cases_on `x = Boolv T` \\ full_simp_tac(srw_ss())[] THEN1
     (qpat_x_assum `state_rel c l1 l2 s t [] locs` (fn th =>
               first_x_assum (fn th1 => mp_tac (MATCH_MP th1 th)))
      \\ strip_tac \\ pop_assum (qspecl_then [`n4`,`l`] mp_tac)
      \\ rpt strip_tac \\ rev_full_simp_tac(srw_ss())[])
    \\ Cases_on `x = Boolv F` \\ full_simp_tac(srw_ss())[] THEN1
     (qpat_x_assum `state_rel c l1 l2 s t [] locs` (fn th =>
               first_x_assum (fn th1 => mp_tac (MATCH_MP th1 th)))
      \\ strip_tac \\ pop_assum (qspecl_then [`n4`,`l4`] mp_tac)
      \\ rpt strip_tac \\ rev_full_simp_tac(srw_ss())[]))
  THEN1 (* Call *)
   (`t.clock = s.clock` by fs [state_rel_def]
    \\ once_rewrite_tac [data_to_wordTheory.comp_def] \\ full_simp_tac(srw_ss())[]
    \\ Cases_on `ret`
    \\ full_simp_tac(srw_ss())[dataSemTheory.evaluate_def,wordSemTheory.evaluate_def,
           wordSemTheory.add_ret_loc_def,get_vars_inc_clock]
    THEN1 (* ret = NONE *)
     (full_simp_tac(srw_ss())[wordSemTheory.bad_dest_args_def]
      \\ Cases_on `get_vars args s.locals` \\ full_simp_tac(srw_ss())[]
      \\ imp_res_tac state_rel_0_get_vars_IMP \\ full_simp_tac(srw_ss())[]
      \\ Cases_on `find_code dest x s.code` \\ full_simp_tac(srw_ss())[]
      \\ rename1 `_ = SOME x9` \\ Cases_on `x9` \\ full_simp_tac(srw_ss())[]
      \\ Cases_on `handler` \\ full_simp_tac(srw_ss())[]
      \\ `t.clock = s.clock` by full_simp_tac(srw_ss())[state_rel_def]
      \\ drule (GEN_ALL find_code_thm) \\ rpt (disch_then drule)
      \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
      \\ Cases_on `s.clock = 0` \\ fs[] \\ srw_tac[][] \\ fs[]
      THEN1 (fs[call_env_def,wordSemTheory.call_env_def,state_rel_def])
      \\ Cases_on `evaluate (r,call_env q (dec_clock s))` \\ fs[]
      \\ Cases_on `q'` \\ full_simp_tac(srw_ss())[]
      \\ srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ res_tac
      \\ pop_assum kall_tac
      \\ pop_assum mp_tac \\ impl_tac
      >-
        fs[wordSemTheory.call_env_def,wordSemTheory.dec_clock_def]
      \\ disch_then (qspecl_then [`n1`,`n2`] strip_assume_tac) \\ fs[]
      \\ `t.clock <> 0` by full_simp_tac(srw_ss())[state_rel_def]
      \\ Cases_on `res1` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ fs[]
      \\ every_case_tac \\ full_simp_tac(srw_ss())[mk_loc_def]
      \\ fs [wordSemTheory.jump_exc_def,wordSemTheory.call_env_def,
             wordSemTheory.dec_clock_def]
      \\ BasicProvers.EVERY_CASE_TAC \\ full_simp_tac(srw_ss())[mk_loc_def])
    \\ Cases_on `x` \\ full_simp_tac(srw_ss())[LET_DEF]
    \\ `domain (adjust_set r) <> {}` by fs[adjust_set_def,domain_fromAList]
    \\ Cases_on `handler` \\ full_simp_tac(srw_ss())[wordSemTheory.evaluate_def]
    \\ Cases_on `get_vars args s.locals` \\ full_simp_tac(srw_ss())[]
    \\ imp_res_tac state_rel_get_vars_IMP \\ full_simp_tac(srw_ss())[]
    \\ full_simp_tac(srw_ss())[wordSemTheory.add_ret_loc_def]
    THEN1 (* no handler *)
     (Cases_on `bvlSem$find_code dest x s.code` \\ fs[]
      \\ rename1 `_ = SOME x9` \\ Cases_on `x9` \\ full_simp_tac(srw_ss())[]
      \\ rename1 `_ = SOME (actual_args,called_prog)`
      \\ imp_res_tac bvl_find_code
      \\ `¬bad_dest_args dest (MAP adjust_var args)` by
        (full_simp_tac(srw_ss())[wordSemTheory.bad_dest_args_def]>>
        imp_res_tac get_vars_IMP_LENGTH>>
        metis_tac[LENGTH_NIL])
      \\ Q.MATCH_ASSUM_RENAME_TAC `bvlSem$find_code dest xs s.code = SOME (ys,prog)`
      \\ Cases_on `dataSem$cut_env r s.locals` \\ full_simp_tac(srw_ss())[]
      \\ imp_res_tac cut_env_IMP_cut_env \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
      \\ `t.clock = s.clock` by full_simp_tac(srw_ss())[state_rel_def]
      \\ full_simp_tac(srw_ss())[]
      \\ rpt_drule find_code_thm_ret
      \\ disch_then (qspecl_then [`n`,`l`] strip_assume_tac) \\ fs []
      \\ Cases_on `s.clock = 0` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
      THEN1 (fs[call_env_def,wordSemTheory.call_env_def,state_rel_def])
      \\ Cases_on `evaluate (prog,call_env ys (push_env x F (dec_clock s)))`
      \\ full_simp_tac(srw_ss())[] \\ Cases_on `q'` \\ full_simp_tac(srw_ss())[]
      \\ Cases_on `x' = Rerr (Rabort Rtype_error)` \\ full_simp_tac(srw_ss())[]
      \\ res_tac (* inst ind hyp *)
      \\ pop_assum kall_tac
      \\ pop_assum mp_tac \\ impl_tac >-
        fs[wordSemTheory.call_env_def,wordSemTheory.push_env_def,wordSemTheory.env_to_list_def,wordSemTheory.dec_clock_def]
      \\ disch_then (qspecl_then [`n1`,`n2`] strip_assume_tac)
      \\ full_simp_tac(srw_ss())[]
      \\ Cases_on `res1 = SOME NotEnoughSpace` \\ full_simp_tac(srw_ss())[]
      THEN1
       (`s1.ffi = r'.ffi` by all_tac \\ full_simp_tac(srw_ss())[]
        \\ every_case_tac \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
        \\ full_simp_tac(srw_ss())[set_var_def]
        \\ imp_res_tac dataPropsTheory.pop_env_const \\ full_simp_tac(srw_ss())[]
        \\ imp_res_tac wordPropsTheory.pop_env_const \\ full_simp_tac(srw_ss())[])
      \\ reverse (Cases_on `x'` \\ full_simp_tac(srw_ss())[])
      THEN1 (Cases_on `e` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
        \\ full_simp_tac(srw_ss())[jump_exc_call_env,jump_exc_dec_clock,jump_exc_push_env_NONE]
        \\ Cases_on `jump_exc t = NONE` \\ full_simp_tac(srw_ss())[]
        \\ full_simp_tac(srw_ss())[jump_exc_push_env_NONE_simp]
        \\ `LENGTH r'.stack < LENGTH locs` by ALL_TAC
        \\ imp_res_tac LASTN_TL \\ full_simp_tac(srw_ss())[]
        \\ `LENGTH locs = LENGTH s.stack` by
           (full_simp_tac(srw_ss())[state_rel_def] \\ imp_res_tac LIST_REL_LENGTH \\ full_simp_tac(srw_ss())[]) \\ full_simp_tac(srw_ss())[]
        \\ imp_res_tac eval_exc_stack_shorter)
      \\ Cases_on `pop_env r'` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
      \\ rpt_drule state_rel_pop_env_set_var_IMP \\ fs []
      \\ disch_then (qspec_then `q` strip_assume_tac) \\ fs []
      \\ imp_res_tac evaluate_IMP_domain_EQ \\ full_simp_tac(srw_ss())[])
    (* with handler *)
    \\ PairCases_on `x` \\ full_simp_tac(srw_ss())[]
    \\ `?prog1 h1. comp c n (l + 2) x1 = (prog1,h1)` by METIS_TAC [PAIR]
    \\ fs[wordSemTheory.evaluate_def,wordSemTheory.add_ret_loc_def]
    \\ Cases_on `bvlSem$find_code dest x' s.code` \\ fs[] \\ Cases_on `x` \\ fs[]
    \\ imp_res_tac bvl_find_code
    \\ `¬bad_dest_args dest (MAP adjust_var args)` by
        (full_simp_tac(srw_ss())[wordSemTheory.bad_dest_args_def]>>
        imp_res_tac get_vars_IMP_LENGTH>>
        metis_tac[LENGTH_NIL])
    \\ Q.MATCH_ASSUM_RENAME_TAC `bvlSem$find_code dest xs s.code = SOME (ys,prog)`
    \\ Cases_on `dataSem$cut_env r s.locals` \\ full_simp_tac(srw_ss())[]
    \\ imp_res_tac cut_env_IMP_cut_env \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
    \\ rpt_drule find_code_thm_handler \\ fs []
    \\ disch_then (qspecl_then [`x0`,`n`,`prog1`,`n`,`l`] strip_assume_tac) \\ fs []
    \\ Cases_on `s.clock = 0` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
    THEN1 (fs[call_env_def,wordSemTheory.call_env_def,state_rel_def])
    \\ Cases_on `evaluate (prog,call_env ys (push_env x T (dec_clock s)))`
    \\ full_simp_tac(srw_ss())[] \\ Cases_on `q'` \\ full_simp_tac(srw_ss())[]
    \\ Cases_on `x' = Rerr (Rabort Rtype_error)` \\ full_simp_tac(srw_ss())[]
    \\ res_tac (* inst ind hyp *)
    \\ pop_assum kall_tac
    \\ pop_assum mp_tac \\ impl_tac >-
        fs[wordSemTheory.call_env_def,wordSemTheory.push_env_def,wordSemTheory.env_to_list_def,wordSemTheory.dec_clock_def]
    \\ disch_then (qspecl_then [`n1`,`n2`] strip_assume_tac) \\ fs[]
    \\ Cases_on `res1 = SOME NotEnoughSpace` \\ full_simp_tac(srw_ss())[]
    THEN1 (full_simp_tac(srw_ss())[]
      \\ `r'.ffi.io_events ≼ s1.ffi.io_events ∧
          (IS_SOME t1.ffi.final_event ⇒ r'.ffi = s1.ffi)` by all_tac
      \\ TRY (imp_res_tac IS_PREFIX_TRANS \\ full_simp_tac(srw_ss())[] \\ NO_TAC)
      \\ every_case_tac \\ full_simp_tac(srw_ss())[]
      \\ imp_res_tac dataPropsTheory.evaluate_io_events_mono \\ full_simp_tac(srw_ss())[set_var_def]
      \\ imp_res_tac wordPropsTheory.pop_env_const \\ full_simp_tac(srw_ss())[]
      \\ imp_res_tac dataPropsTheory.pop_env_const \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
      \\ metis_tac [])
    \\ Cases_on `x'` \\ full_simp_tac(srw_ss())[] THEN1
     (Cases_on `pop_env r'` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
      \\ rpt strip_tac \\ full_simp_tac(srw_ss())[]
      \\ rpt_drule state_rel_pop_env_set_var_IMP \\ fs []
      \\ disch_then (qspec_then `q` strip_assume_tac) \\ fs []
      \\ imp_res_tac evaluate_IMP_domain_EQ \\ full_simp_tac(srw_ss())[])
    \\ reverse (Cases_on `e`) \\ full_simp_tac(srw_ss())[]
    THEN1 (full_simp_tac(srw_ss())[] \\ srw_tac[][])
    \\ full_simp_tac(srw_ss())[mk_loc_jump_exc]
    \\ imp_res_tac evaluate_IMP_domain_EQ_Exc \\ full_simp_tac(srw_ss())[]
    \\ qpat_x_assum `!x y z.bbb` (K ALL_TAC)
    \\ full_simp_tac(srw_ss())[jump_exc_push_env_NONE_simp,jump_exc_push_env_SOME]
    \\ imp_res_tac eval_push_env_T_Raise_IMP_stack_length
    \\ `LENGTH s.stack = LENGTH locs` by
         (full_simp_tac(srw_ss())[state_rel_def]
          \\ imp_res_tac LIST_REL_LENGTH \\ fs[]) \\ fs []
    \\ full_simp_tac(srw_ss())[LASTN_ADD1] \\ srw_tac[][]
    \\ first_x_assum (qspec_then `x0` assume_tac)
    \\ res_tac (* inst ind hyp *)
    \\ pop_assum kall_tac
    \\ pop_assum mp_tac \\ impl_tac >-
      (imp_res_tac wordSemTheory.evaluate_clock>>
      fs[wordSemTheory.set_var_def,wordSemTheory.call_env_def,wordSemTheory.push_env_def,wordSemTheory.env_to_list_def,wordSemTheory.dec_clock_def])
    \\ disch_then (qspecl_then [`n`,`l+2`] strip_assume_tac) \\ rfs []
    \\ `jump_exc (set_var (adjust_var x0) w t1) = jump_exc t1` by
          fs[wordSemTheory.set_var_def,wordSemTheory.jump_exc_def]
    \\ full_simp_tac(srw_ss())[] \\ rpt strip_tac \\ full_simp_tac(srw_ss())[]
    \\ imp_res_tac evaluate_IMP_domain_EQ_Exc \\ full_simp_tac(srw_ss())[]
    \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
    \\ Cases_on `res` \\ full_simp_tac(srw_ss())[]
    \\ rpt (CASE_TAC \\ full_simp_tac(srw_ss())[])
    \\ imp_res_tac mk_loc_eq_push_env_exc_Exception \\ full_simp_tac(srw_ss())[]
    \\ imp_res_tac eval_push_env_SOME_exc_IMP_s_key_eq
    \\ imp_res_tac s_key_eq_handler_eq_IMP
    \\ full_simp_tac(srw_ss())[jump_exc_inc_clock_EQ_NONE] \\ metis_tac []));

val compile_correct_lemma = store_thm("compile_correct_lemma",
  ``!(s:'ffi dataSem$state) c l1 l2 res s1 (t:('a,'ffi)wordSem$state) start.
      (dataSem$evaluate (Call NONE (SOME start) [] NONE,s) = (res,s1)) /\
      res <> SOME (Rerr (Rabort Rtype_error)) /\
      t.termdep > 0 /\
      state_rel c l1 l2 s t [] [] ==>
      ?t1 res1.
        (wordSem$evaluate (Call NONE (SOME start) [0] NONE,t) = (res1,t1)) /\
        (res1 = SOME NotEnoughSpace ==>
           t1.ffi.io_events ≼ s1.ffi.io_events ∧
           (IS_SOME t1.ffi.final_event ==> t1.ffi = s1.ffi)) /\
        (res1 <> SOME NotEnoughSpace ==>
         case res of
        | NONE => (res1 = NONE)
        | SOME (Rval v) => t1.ffi = s1.ffi /\
                           ?w. (res1 = SOME (Result (Loc l1 l2) w))
        | SOME (Rerr (Rraise v)) => (?v w. res1 = SOME (Exception v w))
        | SOME (Rerr (Rabort e)) => (res1 = SOME TimeOut) /\ t1.ffi = s1.ffi)``,
  rpt strip_tac
  \\ drule data_compile_correct \\ full_simp_tac(srw_ss())[]
  \\ ntac 2 (disch_then drule) \\ full_simp_tac(srw_ss())[comp_def]
  \\ strip_tac
  \\ qexists_tac `t1`
  \\ qexists_tac `res1`
  \\ full_simp_tac(srw_ss())[] \\ strip_tac \\ full_simp_tac(srw_ss())[]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[state_rel_def]);

val state_rel_ext_def = Define `
  state_rel_ext c l1 l2 s u <=>
    ?t l.
      state_rel c l1 l2 s t [] [] /\
      t.termdep > 0  /\
      (!n v. lookup n t.code = SOME v ==>
             ∃t' k' a' c' col.
             lookup n l = SOME (SND (full_compile_single t' k' a' c' ((n,v),col)))) /\
      u = t with <|code := l;termdep:=0|>`

val compile_correct = store_thm("compile_correct",
  ``!x (s:'ffi dataSem$state) l1 l2 res s1 (t:('a,'ffi)wordSem$state) start.
      (dataSem$evaluate (Call NONE (SOME start) [] NONE,s) = (res,s1)) /\
      res <> SOME (Rerr (Rabort Rtype_error)) /\
      state_rel_ext x l1 l2 s t ==>
      ?ck t1 res1.
        (wordSem$evaluate (Call NONE (SOME start) [0] NONE,
           (inc_clock ck t)) = (res1,t1)) /\
        (res1 = SOME NotEnoughSpace ==>
           t1.ffi.io_events ≼ s1.ffi.io_events ∧
           (IS_SOME t1.ffi.final_event ==> t1.ffi = s1.ffi)) /\
        (res1 <> SOME NotEnoughSpace ==>
         case res of
         | NONE => (res1 = NONE)
         | SOME (Rval v) => t1.ffi = s1.ffi /\
                            ?w. (res1 = SOME (Result (Loc l1 l2) w))
         | SOME (Rerr (Rraise v)) => (?v w. res1 = SOME (Exception v w))
         | SOME (Rerr (Rabort e)) => (res1 = SOME TimeOut) /\ t1.ffi = s1.ffi)``,
  gen_tac
  \\ full_simp_tac(srw_ss())[state_rel_ext_def,PULL_EXISTS] \\ srw_tac[][]
  \\ rename1 `state_rel x0 l1 l2 s t [] []`
  \\ drule compile_word_to_word_thm \\ srw_tac[][]
  \\ drule compile_correct_lemma \\ full_simp_tac(srw_ss())[]
  \\ `state_rel x0 l1 l2 s (t with permute := perm') [] []` by
   (full_simp_tac(srw_ss())[state_rel_def] \\ rev_full_simp_tac(srw_ss())[]
    \\ Cases_on `s.stack` \\ full_simp_tac(srw_ss())[] \\ metis_tac [])
  \\ `(t with permute := perm').termdep > 0` by fs[]
  \\ ntac 2 (disch_then drule) \\ strip_tac
  \\ qexists_tac `clk` \\ full_simp_tac(srw_ss())[]
  \\ qpat_x_assum `let prog = Call NONE (SOME start) [0] NONE in _` mp_tac
  \\ full_simp_tac(srw_ss())[LET_THM] \\ strip_tac
  THEN1 (full_simp_tac(srw_ss())[] \\ every_case_tac \\ full_simp_tac(srw_ss())[])
  \\ pairarg_tac \\ full_simp_tac(srw_ss())[] \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[inc_clock_def]
  \\ strip_tac \\ rpt var_eq_tac \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ every_case_tac \\ full_simp_tac(srw_ss())[]);

val state_rel_ext_with_clock = prove(
  ``state_rel_ext a b c s1 s2 ==>
    state_rel_ext a b c (s1 with clock := k) (s2 with clock := k)``,
  full_simp_tac(srw_ss())[state_rel_ext_def] \\ srw_tac[][]
  \\ drule state_rel_with_clock
  \\ strip_tac \\ asm_exists_tac \\ full_simp_tac(srw_ss())[]
  \\ qexists_tac `l` \\ full_simp_tac(srw_ss())[]);

(* observational semantics preservation *)

val compile_semantics_lemma = Q.store_thm("compile_semantics_lemma",
  `state_rel_ext conf 1 0 (initial_state (ffi:'ffi ffi_state) (fromAList prog) t.clock) t /\
   semantics ffi (fromAList prog) start <> Fail ==>
   semantics t start IN
     extend_with_resource_limit { semantics ffi (fromAList prog) start }`,
  simp[GSYM AND_IMP_INTRO] >> ntac 1 strip_tac >>
  simp[dataSemTheory.semantics_def] >>
  IF_CASES_TAC >> full_simp_tac(srw_ss())[] >>
  DEEP_INTRO_TAC some_intro >> simp[] >>
  conj_tac >- (
    qx_gen_tac`r`>>simp[]>>strip_tac>>
    strip_tac >>
    simp[wordSemTheory.semantics_def] >>
    IF_CASES_TAC >- (
      full_simp_tac(srw_ss())[] >> rveq >> full_simp_tac(srw_ss())[] >>
      rator_x_assum`dataSem$evaluate`kall_tac >>
      last_x_assum(qspec_then`k'`mp_tac)>>simp[] >>
      (fn g => subterm (fn tm => Cases_on`^(assert(has_pair_type)tm)`) (#2 g) g) >>
      strip_tac >>
      drule compile_correct >> simp[] >> full_simp_tac(srw_ss())[] >>
      simp[RIGHT_FORALL_IMP_THM,GSYM AND_IMP_INTRO] >>
      impl_tac >- (
        strip_tac >> full_simp_tac(srw_ss())[] ) >>
      drule(GEN_ALL state_rel_ext_with_clock) >>
      disch_then(qspec_then`k'`strip_assume_tac) >> full_simp_tac(srw_ss())[] >>
      disch_then drule >>
      simp[comp_def] >> strip_tac >>
      qmatch_assum_abbrev_tac`option_CASE (FST p) _ _` >>
      Cases_on`p`>>pop_assum(strip_assume_tac o SYM o REWRITE_RULE[markerTheory.Abbrev_def]) >>
      drule (GEN_ALL wordPropsTheory.evaluate_add_clock) >>
      simp[RIGHT_FORALL_IMP_THM] >>
      impl_tac >- (strip_tac >> full_simp_tac(srw_ss())[]) >>
      disch_then(qspec_then`ck`mp_tac) >>
      fsrw_tac[ARITH_ss][inc_clock_def] >> srw_tac[][] >>
      every_case_tac >> full_simp_tac(srw_ss())[] ) >>
    DEEP_INTRO_TAC some_intro >> simp[] >>
    conj_tac >- (
      srw_tac[][extend_with_resource_limit_def] >> full_simp_tac(srw_ss())[] >>
      Cases_on`s.ffi.final_event`>>full_simp_tac(srw_ss())[] >- (
        Cases_on`r'`>>full_simp_tac(srw_ss())[] >> rveq >>
        drule(dataPropsTheory.evaluate_add_clock)>>simp[]>>
        disch_then(qspec_then`k'`mp_tac)>>simp[]>>strip_tac>>
        drule(compile_correct)>>simp[]>>
        drule(GEN_ALL state_rel_ext_with_clock)>>simp[]>>
        disch_then(qspec_then`k+k'`mp_tac)>>simp[]>>strip_tac>>
        disch_then drule>>
        simp[comp_def]>>strip_tac>>
        `t'.ffi.io_events ≼ t1.ffi.io_events ∧
         (IS_SOME t'.ffi.final_event ⇒ t1.ffi = t'.ffi)` by (
           qmatch_assum_abbrev_tac`evaluate (exps,tt) = (_,t')` >>
           Q.ISPECL_THEN[`exps`,`tt`]mp_tac wordPropsTheory.evaluate_add_clock_io_events_mono >>
           full_simp_tac(srw_ss())[inc_clock_def,Abbr`tt`] >>
           disch_then(qspec_then`k+ck`mp_tac)>>simp[]>>
           fsrw_tac[ARITH_ss][] ) >>
        Cases_on`r = SOME TimeOut` >- (
          every_case_tac >> full_simp_tac(srw_ss())[]>>
          Cases_on`res1=SOME NotEnoughSpace`>>full_simp_tac(srw_ss())[] >> rev_full_simp_tac(srw_ss())[] >>
          full_simp_tac(srw_ss())[] >> rev_full_simp_tac(srw_ss())[] ) >>
        rator_x_assum`wordSem$evaluate`mp_tac >>
        drule(GEN_ALL wordPropsTheory.evaluate_add_clock) >>
        simp[] >>
        disch_then(qspec_then`ck+k`mp_tac) >>
        simp[inc_clock_def] >> ntac 2 strip_tac >>
        rveq >> full_simp_tac(srw_ss())[] >>
        every_case_tac >> full_simp_tac(srw_ss())[] >> srw_tac[][] >>
        full_simp_tac(srw_ss())[] >> rev_full_simp_tac(srw_ss())[] ) >>
      `∃r s'.
        evaluate
          (Call NONE (SOME start) [] NONE, initial_state ffi (fromAList prog) (k + k')) = (r,s') ∧
        s'.ffi = s.ffi` by (
          srw_tac[QUANT_INST_ss[pair_default_qp]][] >>
          metis_tac[dataPropsTheory.evaluate_add_clock_io_events_mono,SND,
                    initial_state_with_simp,IS_SOME_EXISTS,initial_state_simp]) >>
      drule compile_correct >> simp[] >>
      simp[GSYM AND_IMP_INTRO,RIGHT_FORALL_IMP_THM] >>
      impl_tac >- (
        last_x_assum(qspec_then`k+k'`mp_tac)>>srw_tac[][]>>
        strip_tac>>full_simp_tac(srw_ss())[])>>
      drule(GEN_ALL state_rel_ext_with_clock)>>simp[]>>
      disch_then(qspec_then`k+k'`mp_tac)>>simp[]>>strip_tac>>
      disch_then drule>>
      simp[comp_def]>>strip_tac>>
      `t'.ffi.io_events ≼ t1.ffi.io_events ∧
       (IS_SOME t'.ffi.final_event ⇒ t1.ffi = t'.ffi)` by (
        qmatch_assum_abbrev_tac`evaluate (exps,tt) = (_,t')` >>
        Q.ISPECL_THEN[`exps`,`tt`]mp_tac wordPropsTheory.evaluate_add_clock_io_events_mono >>
        full_simp_tac(srw_ss())[inc_clock_def,Abbr`tt`] >>
        disch_then(qspec_then`k+ck`mp_tac)>>simp[]>>
        fsrw_tac[ARITH_ss][] ) >>
      reverse(Cases_on`t'.ffi.final_event`)>>full_simp_tac(srw_ss())[] >- (
        Cases_on`res1=SOME NotEnoughSpace`>>full_simp_tac(srw_ss())[]>>
        full_simp_tac(srw_ss())[]>>rev_full_simp_tac(srw_ss())[]>>
        every_case_tac>>full_simp_tac(srw_ss())[]>>rev_full_simp_tac(srw_ss())[]>>
        rveq>>full_simp_tac(srw_ss())[]>>
        last_x_assum(qspec_then`k+k'`mp_tac) >> simp[]) >>
      Cases_on`r`>>full_simp_tac(srw_ss())[]>>
      rator_x_assum`wordSem$evaluate`mp_tac >>
      drule(GEN_ALL wordPropsTheory.evaluate_add_clock) >>
      simp[RIGHT_FORALL_IMP_THM] >>
      impl_tac >- ( strip_tac >> full_simp_tac(srw_ss())[] ) >>
      disch_then(qspec_then`k+ck`mp_tac) >>
      fsrw_tac[ARITH_ss][inc_clock_def]>> srw_tac[][] >>
      every_case_tac>>full_simp_tac(srw_ss())[]>>rveq>>rev_full_simp_tac(srw_ss())[]>>
      full_simp_tac(srw_ss())[]>>rev_full_simp_tac(srw_ss())[]) >>
    srw_tac[][] >> full_simp_tac(srw_ss())[] >>
    drule compile_correct >> simp[] >>
    simp[RIGHT_FORALL_IMP_THM,GSYM AND_IMP_INTRO] >>
    impl_tac >- (
      last_x_assum(qspec_then`k`mp_tac)>>simp[] >>
      srw_tac[][] >> strip_tac >> full_simp_tac(srw_ss())[] ) >>
    drule(state_rel_ext_with_clock) >> simp[] >> strip_tac >>
    disch_then drule >>
    simp[comp_def] >> strip_tac >>
    first_x_assum(qspec_then`k+ck`mp_tac) >>
    full_simp_tac(srw_ss())[inc_clock_def] >>
    first_x_assum(qspec_then`k+ck`mp_tac) >>
    simp[] >>
    every_case_tac >> full_simp_tac(srw_ss())[] >> srw_tac[][]) >>
  srw_tac[][] >>
  simp[wordSemTheory.semantics_def] >>
  IF_CASES_TAC >- (
    full_simp_tac(srw_ss())[] >> rveq >> full_simp_tac(srw_ss())[] >>
    last_x_assum(qspec_then`k`mp_tac)>>simp[] >>
    (fn g => subterm (fn tm => Cases_on`^(assert(has_pair_type)tm)`) (#2 g) g) >>
    strip_tac >>
    drule compile_correct >> simp[] >>
    simp[RIGHT_FORALL_IMP_THM,GSYM AND_IMP_INTRO] >>
    impl_tac >- ( strip_tac >> full_simp_tac(srw_ss())[] ) >>
    drule(state_rel_ext_with_clock) >>
    simp[] >> strip_tac >>
    disch_then drule >>
    simp[comp_def] >> strip_tac >>
    qmatch_assum_abbrev_tac`option_CASE (FST p) _ _` >>
    Cases_on`p`>>pop_assum(strip_assume_tac o SYM o REWRITE_RULE[markerTheory.Abbrev_def]) >>
    drule (GEN_ALL wordPropsTheory.evaluate_add_clock) >>
    simp[RIGHT_FORALL_IMP_THM] >>
    impl_tac >- (strip_tac >> full_simp_tac(srw_ss())[]) >>
    disch_then(qspec_then`ck`mp_tac) >>
    fsrw_tac[ARITH_ss][inc_clock_def] >> srw_tac[][] >>
    every_case_tac >> full_simp_tac(srw_ss())[] ) >>
  DEEP_INTRO_TAC some_intro >> simp[] >>
  conj_tac >- (
    srw_tac[][extend_with_resource_limit_def] >> full_simp_tac(srw_ss())[] >>
    qpat_x_assum`∀x y. _`(qspec_then`k`mp_tac)>>
    (fn g => subterm (fn tm => Cases_on`^(assert(has_pair_type)tm)`) (#2 g) g) >>
    strip_tac >>
    drule(compile_correct)>>
    simp[RIGHT_FORALL_IMP_THM,GSYM AND_IMP_INTRO] >>
    impl_tac >- (
      strip_tac >> full_simp_tac(srw_ss())[] >>
      last_x_assum(qspec_then`k`mp_tac) >>
      simp[] ) >>
    drule(state_rel_ext_with_clock) >>
    simp[] >> strip_tac >>
    disch_then drule >>
    simp[comp_def] >> strip_tac >>
    `t'.ffi.io_events ≼ t1.ffi.io_events ∧
     (IS_SOME t'.ffi.final_event ⇒ t1.ffi = t'.ffi)` by (
      qmatch_assum_abbrev_tac`evaluate (exps,tt) = (_,t')` >>
      Q.ISPECL_THEN[`exps`,`tt`]mp_tac wordPropsTheory.evaluate_add_clock_io_events_mono >>
      full_simp_tac(srw_ss())[inc_clock_def,Abbr`tt`] >>
      disch_then(qspec_then`ck`mp_tac)>>simp[]) >>
    full_simp_tac(srw_ss())[] >>
    first_assum(qspec_then`k`mp_tac) >>
    first_x_assum(qspec_then`k+ck`mp_tac) >>
    fsrw_tac[ARITH_ss][inc_clock_def] >>
    rator_x_assum`wordSem$evaluate`mp_tac >>
    drule(GEN_ALL wordPropsTheory.evaluate_add_clock)>>
    simp[]>>
    disch_then(qspec_then`ck`mp_tac)>>
    last_x_assum(qspec_then`k`mp_tac) >>
    every_case_tac >> full_simp_tac(srw_ss())[] >> rev_full_simp_tac(srw_ss())[]>>srw_tac[][]>>full_simp_tac(srw_ss())[] >>
    qpat_abbrev_tac`ll = IMAGE _ _` >>
    `lprefix_chain ll` by (
      unabbrev_all_tac >>
      Ho_Rewrite.ONCE_REWRITE_TAC[GSYM o_DEF] >>
      REWRITE_TAC[IMAGE_COMPOSE] >>
      match_mp_tac prefix_chain_lprefix_chain >>
      simp[prefix_chain_def,PULL_EXISTS] >>
      qx_genl_tac[`k1`,`k2`] >>
      qspecl_then[`k1`,`k2`]mp_tac LESS_EQ_CASES >>
      simp[LESS_EQ_EXISTS] >>
      metis_tac[
        dataPropsTheory.evaluate_add_clock_io_events_mono,
        dataPropsTheory.initial_state_with_simp,
        dataPropsTheory.initial_state_simp]) >>
    drule build_lprefix_lub_thm >>
    simp[lprefix_lub_def] >> strip_tac >>
    match_mp_tac (GEN_ALL LPREFIX_TRANS) >>
    simp[LPREFIX_fromList] >>
    QUANT_TAC[("l2",`fromList x`,[`x`])] >>
    simp[from_toList] >>
    asm_exists_tac >> simp[] >>
    first_x_assum irule >>
    simp[Abbr`ll`] >>
    qexists_tac`k`>>simp[] ) >>
  srw_tac[][extend_with_resource_limit_def] >>
  qmatch_abbrev_tac`build_lprefix_lub l1 = build_lprefix_lub l2` >>
  `(lprefix_chain l1 ∧ lprefix_chain l2) ∧ equiv_lprefix_chain l1 l2`
    suffices_by metis_tac[build_lprefix_lub_thm,lprefix_lub_new_chain,unique_lprefix_lub] >>
  conj_asm1_tac >- (
    UNABBREV_ALL_TAC >>
    conj_tac >>
    Ho_Rewrite.ONCE_REWRITE_TAC[GSYM o_DEF] >>
    REWRITE_TAC[IMAGE_COMPOSE] >>
    match_mp_tac prefix_chain_lprefix_chain >>
    simp[prefix_chain_def,PULL_EXISTS] >>
    qx_genl_tac[`k1`,`k2`] >>
    qspecl_then[`k1`,`k2`]mp_tac LESS_EQ_CASES >>
    simp[LESS_EQ_EXISTS] >>
    metis_tac[
      wordPropsTheory.evaluate_add_clock_io_events_mono,
      EVAL``((t:('a,'ffi) wordSem$state) with clock := k).clock``,
      EVAL``((t:('a,'ffi) wordSem$state) with clock := k) with clock := k2``,
      dataPropsTheory.evaluate_add_clock_io_events_mono,
      dataPropsTheory.initial_state_with_simp,
      dataPropsTheory.initial_state_simp]) >>
  simp[equiv_lprefix_chain_thm] >>
  unabbrev_all_tac >> simp[PULL_EXISTS] >>
  pop_assum kall_tac >>
  simp[LNTH_fromList,PULL_EXISTS] >>
  simp[GSYM FORALL_AND_THM] >>
  rpt gen_tac >>
  reverse conj_tac >> strip_tac >- (
    qmatch_assum_abbrev_tac`n < LENGTH (_ (_ (SND p)))` >>
    Cases_on`p`>>pop_assum(assume_tac o SYM o REWRITE_RULE[markerTheory.Abbrev_def]) >>
    drule compile_correct >>
    simp[GSYM AND_IMP_INTRO,RIGHT_FORALL_IMP_THM] >>
    impl_tac >- (
      last_x_assum(qspec_then`k`mp_tac)>>srw_tac[][]>>
      strip_tac >> full_simp_tac(srw_ss())[] ) >>
    drule(state_rel_ext_with_clock) >>
    simp[] >> strip_tac >>
    disch_then drule >>
    simp[comp_def] >> strip_tac >>
    qexists_tac`k+ck`>>full_simp_tac(srw_ss())[inc_clock_def]>>
    Cases_on`res1=SOME NotEnoughSpace`>>full_simp_tac(srw_ss())[]>-(
      first_x_assum(qspec_then`k+ck`mp_tac) >> simp[] >>
      CASE_TAC >> full_simp_tac(srw_ss())[] ) >>
    ntac 2 (pop_assum mp_tac) >>
    CASE_TAC >> full_simp_tac(srw_ss())[] >>
    TRY CASE_TAC >> full_simp_tac(srw_ss())[] >>
    TRY CASE_TAC >> full_simp_tac(srw_ss())[] >>
    strip_tac >> full_simp_tac(srw_ss())[] >>
    rveq >>
    rpt(first_x_assum(qspec_then`k+ck`mp_tac)>>simp[]) ) >>
  (fn g => subterm (fn tm => Cases_on`^(replace_term(#1(dest_exists(#2 g)))(``k:num``)(assert(has_pair_type)tm))`) (#2 g) g) >>
  drule compile_correct >>
  simp[GSYM AND_IMP_INTRO,RIGHT_FORALL_IMP_THM] >>
  impl_tac >- (
    last_x_assum(qspec_then`k`mp_tac)>>srw_tac[][]>>
    strip_tac >> full_simp_tac(srw_ss())[] ) >>
  drule(state_rel_ext_with_clock) >>
  simp[] >> strip_tac >>
  disch_then drule >>
  simp[comp_def] >> strip_tac >>
  full_simp_tac(srw_ss())[inc_clock_def] >>
  Cases_on`res1=SOME NotEnoughSpace`>>full_simp_tac(srw_ss())[]>-(
    first_x_assum(qspec_then`k+ck`mp_tac) >> simp[] >>
    CASE_TAC >> full_simp_tac(srw_ss())[] ) >>
  qmatch_assum_abbrev_tac`n < LENGTH (SND (evaluate (exps,s))).ffi.io_events` >>
  Q.ISPECL_THEN[`exps`,`s`]mp_tac wordPropsTheory.evaluate_add_clock_io_events_mono >>
  disch_then(qspec_then`ck`mp_tac)>>simp[Abbr`s`]>>strip_tac>>
  qexists_tac`k`>>simp[]>>
  `r.ffi.io_events = t1.ffi.io_events` by (
    ntac 5 (pop_assum mp_tac) >>
    CASE_TAC >> full_simp_tac(srw_ss())[] >>
    every_case_tac >> full_simp_tac(srw_ss())[]>>srw_tac[][]>>
    rpt(first_x_assum(qspec_then`k+ck`mp_tac)>>simp[])) >>
  REV_FULL_SIMP_TAC(srw_ss()++ARITH_ss)[]>>
  fsrw_tac[ARITH_ss][IS_PREFIX_APPEND]>>
  simp[EL_APPEND1]);

fun define_abbrev name tm = let
  val vs = free_vars tm |> sort
    (fn v1 => fn v2 => fst (dest_var v1) <= fst (dest_var v2))
  val vars = foldr mk_pair (last vs) (butlast vs)
  val n = mk_var(name,mk_type("fun",[type_of vars, type_of tm]))
  in Define `^n ^vars = ^tm` end

val code_termdep_equiv = prove(
  ``t' with <|code := l; termdep := 0|> = t <=>
    ?x1 x2.
      t.code = l /\ t.termdep = 0 /\ t' = t with <|code := x1; termdep := x2|>``,
  fs [wordSemTheory.state_component_equality] \\ rw [] \\ eq_tac \\ rw [] \\ fs []);

val compile_semantics = save_thm("compile_semantics",let
  val th1 =
    compile_semantics_lemma |> Q.GEN `conf`
    |> SIMP_RULE std_ss [GSYM AND_IMP_INTRO,FORALL_PROD,PULL_EXISTS] |> SPEC_ALL
    |> REWRITE_RULE [state_rel_ext_def]
    |> ONCE_REWRITE_RULE [EQ_SYM_EQ]
    |> SIMP_RULE std_ss [GSYM AND_IMP_INTRO,
         FORALL_PROD,PULL_EXISTS] |> SPEC_ALL
    |> ONCE_REWRITE_RULE [EQ_SYM_EQ]
    |> REWRITE_RULE [ASSUME ``(t:('a,'ffi) wordSem$state).clock =
                              (t':('a,'ffi) wordSem$state).clock``]
    |> (fn th => MATCH_MP th (UNDISCH state_rel_init
            |> Q.INST [`l1`|->`1`,`l2`|->`0`,`code`|->`fromAList prog`,`t`|->`t'`]))
    |> CONV_RULE (RAND_CONV (ONCE_REWRITE_CONV [EQ_SYM_EQ]))
    |> SIMP_RULE std_ss [METIS_PROVE [] ``(!x. P x ==> Q) <=> ((?x. P x) ==> Q)``]
    |> DISCH ``(t':('a,'ffi) wordSem$state).code = code``
    |> SIMP_RULE std_ss [] |> UNDISCH |> UNDISCH
  val def = define_abbrev "code_rel_ext" (th1 |> concl |> dest_imp |> fst)
  in th1 |> REWRITE_RULE [GSYM def,code_termdep_equiv]
         |> SIMP_RULE std_ss [PULL_EXISTS,PULL_FORALL] |> SPEC_ALL
         |> DISCH_ALL |> GEN_ALL |> SIMP_RULE (srw_ss()) []
         |> Q.SPEC `1` |> SIMP_RULE std_ss []
         |> SPEC_ALL
         |> SIMP_RULE std_ss []
         |> UNDISCH
         |> REWRITE_RULE [AND_IMP_INTRO,GSYM CONJ_ASSOC] end);

val data_to_word_lab_pres_lem = prove(``
  ∀c n l p.
  l ≠ 0 ⇒
  let (cp,l') = comp c n l p in
  l ≤ l' ∧
  EVERY (λ(l1,l2). l1 = n ∧ l ≤ l2 ∧ l2 < l') (extract_labels cp) ∧
  ALL_DISTINCT (extract_labels cp)``,
  HO_MATCH_MP_TAC comp_ind>>Cases_on`p`>>rw[]>>
  once_rewrite_tac[comp_def]>>fs[extract_labels_def]
  >-
    (BasicProvers.EVERY_CASE_TAC>>fs[]>>rveq>>fs[extract_labels_def]>>
    rpt(pairarg_tac>>fs[])>>rveq>>fs[extract_labels_def]>>
    fs[EVERY_MEM,FORALL_PROD]>>rw[]>>
    res_tac>>fs[]>>
    CCONTR_TAC>>fs[]>>res_tac>>fs[])
  >-
    (fs[assign_def]>>
    Cases_on`o'`>>
    fs[extract_labels_def,GiveUp_def]>>
    BasicProvers.EVERY_CASE_TAC>>
    fs[extract_labels_def,list_Seq_def]>>
    qpat_abbrev_tac`A = 0w`>>
    qpat_abbrev_tac`ls = 3n::rest`>>
    rpt(pop_assum kall_tac)>>
    qid_spec_tac`A`>>Induct_on`ls`>>
    fs[StoreEach_def,extract_labels_def])
  >>
    (rpt (pairarg_tac>>fs[])>>rveq>>fs[extract_labels_def,EVERY_MEM,FORALL_PROD,ALL_DISTINCT_APPEND]>>
    rw[]>>
    res_tac>>fs[]>>
    CCONTR_TAC>>fs[]>>res_tac>>fs[]));

open match_goal

val data_to_word_compile_lab_pres = store_thm("data_to_word_compile_lab_pres",``
  let (c,p) = compile data_conf word_conf asm_conf prog in
    MAP FST p = MAP FST (stubs(:α) data_conf) ++ MAP FST prog ∧
    EVERY (λn,m,(p:α wordLang$prog).
      let labs = extract_labels p in
      EVERY (λ(l1,l2).l1 = n ∧ l2 ≠ 0) labs ∧
      ALL_DISTINCT labs) p``,
  fs[compile_def]>>
  qpat_abbrev_tac`datap = _ ++ MAP (A B) prog`>>
  assume_tac (compile_to_word_conventions |>GEN_ALL |> Q.SPECL [`word_conf`,`datap`,`asm_conf`])>>
  pairarg_tac>>fs[Abbr`datap`]>>
  fs[EVERY_MEM]>>rw[]
  >-
    (match_mp_tac LIST_EQ>>rw[EL_MAP]>>
    Cases_on`EL x prog`>>Cases_on`r`>>fs[compile_part_def])
  >>
    qmatch_assum_abbrev_tac`MAP FST p = MAP FST p1 ++ MAP FST p2`>>
    full_simp_tac std_ss [GSYM MAP_APPEND]>>
    qabbrev_tac`pp = p1 ++ p2` >>
    qpat_x_assum`MAP A B = _` mp_tac>>simp[Once LIST_EQ_REWRITE]>>
    fs[EL_MAP,MEM_EL,FORALL_PROD]>>
    rw[]>>pop_assum(qspec_then`n` assume_tac)>>
    fs[LIST_REL_EL_EQN,EL_MAP]>>res_tac>>
    pairarg_tac>>fs[]>>
    Cases_on`n < LENGTH p1` >- (
      fs[Abbr`pp`,EL_APPEND1,Abbr`p1`]
      \\ fs[stubs_def,extract_labels_def]
      \\ rpt(match1_tac(mg.au`(n_:num) < _`,(fn(a,t)=>
               Cases_on`^(t"n")`\\fs[]
               \\ imp_res_tac prim_recTheory.SUC_LESS)))>>
      qpat_x_assum`PERM A B` mp_tac >>
      simp[extract_labels_def,RefByte_code_def,FromList_code_def,FromList1_code_def,
           Make_ptr_bits_code_def,Maxout_bits_code_def,
           RefArray_code_def,Replicate_code_def,list_Seq_def,AllocVar_def,
           MakeBytes_def,SmallLsr_def,GiveUp_def] >> rpt IF_CASES_TAC >>
      simp[extract_labels_def,RefByte_code_def,FromList_code_def,FromList1_code_def,
           Make_ptr_bits_code_def,Maxout_bits_code_def,
           RefArray_code_def,Replicate_code_def,list_Seq_def,AllocVar_def,
           MakeBytes_def,SmallLsr_def])>>
    qpat_x_assum`n < LENGTH _`assume_tac >>
    qpat_x_assum`LENGTH p = _`assume_tac >>
    fs[Abbr`pp`,Abbr`p2`,EL_APPEND2,EL_MAP] >>
    Cases_on`EL (n - LENGTH p1) prog`>>Cases_on`r`>>
    Q.SPECL_THEN [`data_conf`,`q`,`1n`,`r'`]assume_tac data_to_word_lab_pres_lem>>
    fs[compile_part_def]>>
    fs[]>>pairarg_tac>>fs[EVERY_MEM,MEM_EL]>>
    reverse CONJ_TAC>-
      metis_tac[ALL_DISTINCT_PERM]>>
    ntac 3 strip_tac>>
    first_x_assum(qspec_then`p_1,p_2` mp_tac)>>
    impl_tac>>simp[]>>
    imp_res_tac PERM_MEM_EQ>>
    ntac 2 (pop_assum kall_tac)>>
    pop_assum (qspec_then `p_1,p_2` assume_tac)>>fs[MEM_EL,EQ_IMP_THM]>>
    metis_tac[]);

val _ = export_theory();
