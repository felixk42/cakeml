open preamble ffiTheory BasicProvers
     wordSemTheory labSemTheory labPropsTheory
     lab_to_targetTheory lab_filterProofTheory
     asmTheory asmSemTheory asmPropsTheory
     targetSemTheory targetPropsTheory
local open stack_removeProofTheory in end
open dep_rewrite

val aligned_w2n = stack_removeProofTheory.aligned_w2n;

val _ = new_theory "lab_to_targetProof";

(* TODO: move *)

val LIST_REL_SNOC = Q.store_thm("LIST_REL_SNOC",
  `(LIST_REL R (SNOC x xs) yys ⇔ ∃y ys. yys = SNOC y ys ∧ LIST_REL R xs ys ∧ R x y) ∧
   (LIST_REL R xxs (SNOC y ys) ⇔ ∃x xs. xxs = SNOC x xs ∧ LIST_REL R xs ys ∧ R x y)`,
  rw[LIST_REL_EL_EQN,EQ_IMP_THM] \\ fs[]
  >- (
    Q.ISPEC_THEN`yys`FULL_STRUCT_CASES_TAC SNOC_CASES \\ fs[] \\ rw[]
    >- (first_x_assum(qspec_then`n` mp_tac)\\simp[EL_SNOC])
    \\ first_x_assum(qspec_then`LENGTH xs`mp_tac)\\simp[EL_LENGTH_SNOC] )
  >- (
    last_x_assum (assume_tac o SYM)
    \\ Cases_on`n = LENGTH xs`
    \\ fs[EL_APPEND2,EL_APPEND1,EL_LENGTH_SNOC,EL_SNOC] )
  >- (
    Q.ISPEC_THEN`xxs`FULL_STRUCT_CASES_TAC SNOC_CASES \\ fs[] \\ rw[]
    >- (first_x_assum(qspec_then`n` mp_tac)\\simp[EL_SNOC])
    \\ last_x_assum (assume_tac o SYM)
    \\ first_x_assum(qspec_then`LENGTH ys`mp_tac)\\simp[EL_LENGTH_SNOC] )
  \\ Cases_on`n = LENGTH xs`
  \\ fs[EL_APPEND2,EL_APPEND1,EL_LENGTH_SNOC,EL_SNOC] )

val call_FFI_LENGTH = prove(
  ``(call_FFI st index x = (new_st,new_bytes)) ==>
    (LENGTH x = LENGTH new_bytes)``,
  full_simp_tac(srw_ss())[call_FFI_def] \\ BasicProvers.EVERY_CASE_TAC
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[listTheory.LENGTH_MAP]);

val MOD_2EXP_0_EVEN = Q.store_thm("MOD_2EXP_0_EVEN",
  `∀x y. 0 < x ∧ MOD_2EXP x y = 0 ⇒ EVEN y`,
  rw[EVEN_MOD2,bitTheory.MOD_2EXP_def,MOD_EQ_0_DIVISOR]
  \\ Cases_on`x` \\ fs[EXP]);

val EXP_IMP_ZERO_LT = Q.prove(
  `(2n ** y = x) ⇒ 0 < x`,
  metis_tac[bitTheory.TWOEXP_NOT_ZERO,NOT_ZERO_LT_ZERO]);

val TAKE_FLAT_REPLICATE_LEQ = Q.store_thm("TAKE_FLAT_REPLICATE_LEQ",
  `∀j k ls len.
    len = LENGTH ls ∧ k ≤ j ⇒
    TAKE (k * len) (FLAT (REPLICATE j ls)) = FLAT (REPLICATE k ls)`,
  Induct \\ simp[REPLICATE]
  \\ Cases \\ simp[REPLICATE]
  \\ simp[TAKE_APPEND2] \\ rw[] \\ fs[]
  \\ simp[MULT_SUC]);

(* -- *)

val pos_val_def = Define `
  (pos_val i pos [] = (pos:num)) /\
  (pos_val i pos ((Section k [])::xs) = pos_val i pos xs) /\
  (pos_val i pos ((Section k (y::ys))::xs) =
     if is_Label y
     then pos_val i (pos + line_length y) ((Section k ys)::xs)
     else if i = 0:num then pos
          else pos_val (i-1) (pos + line_length y) ((Section k ys)::xs))`;

val pos_val_ind = theorem"pos_val_ind";

val _ = temp_remove_rules_for_term"step";

val enc_with_nop_def = Define `
  enc_with_nop enc (b:'a asm) bytes =
    let init = enc b in
    let step = enc (asm$Inst Skip) in
      if LENGTH step = 0 then bytes = init else
        let n = (LENGTH bytes - LENGTH init) DIV LENGTH step in
          bytes = init ++ FLAT (REPLICATE n step)`

val enc_with_nop_thm = prove(
  ``enc_with_nop enc (b:'a asm) bytes =
      ?n. bytes = enc b ++ FLAT (REPLICATE n (enc (asm$Inst Skip)))``,
  fs [enc_with_nop_def,LENGTH_NIL]
  \\ IF_CASES_TAC \\ fs [FLAT_REPLICATE_NIL]
  \\ EQ_TAC \\ rw [] THEN1 metis_tac []
  \\ fs [LENGTH_APPEND,LENGTH_FLAT,map_replicate,SUM_REPLICATE]
  \\ fs [GSYM LENGTH_NIL] \\ fs [MULT_DIV]);

val line_ok_def = Define `
  (line_ok (c:'a asm_config) labs pos (Label _ _ l) <=>
     EVEN pos /\ (l = 0)) /\
  (line_ok c labs pos (Asm b bytes l) <=>
     enc_with_nop c.encode b bytes /\
     (LENGTH bytes = l) /\ asm_ok b c) /\
  (line_ok c labs pos (LabAsm Halt w bytes l) <=>
     let w1 = (0w:'a word) - n2w (pos + ffi_offset) in
       enc_with_nop c.encode (Jump w1) bytes /\
       (LENGTH bytes = l) /\ asm_ok (Jump w1) c) /\
  (line_ok c labs pos (LabAsm ClearCache w bytes l) <=>
     let w1 = (0w:'a word) - n2w (pos + 2 * ffi_offset) in
       enc_with_nop c.encode (Jump w1) bytes /\
       (LENGTH bytes = l) /\ asm_ok (Jump w1) c) /\
  (line_ok c labs pos (LabAsm (CallFFI index) w bytes l) <=>
     let w1 = (0w:'a word) - n2w (pos + (3 + index) * ffi_offset) in
       enc_with_nop c.encode (Jump w1) bytes /\
       (LENGTH bytes = l) /\ asm_ok (Jump w1) c) /\
  (line_ok c labs pos (LabAsm (Call v24) w bytes l) <=>
     F (* Call not yet supported *)) /\
  (line_ok c labs pos (LabAsm a w bytes l) <=>
     let target = find_pos (get_label a) labs in
     let w1 = n2w target - n2w pos in
       enc_with_nop c.encode (lab_inst w1 a) bytes /\
       (LENGTH bytes = l) /\ asm_ok (lab_inst w1 a) c)`

val line_ok_ind = theorem"line_ok_ind";

val all_enc_ok_def = Define `
  (all_enc_ok c labs pos [] = T) /\
  (all_enc_ok c labs pos ((Section k [])::xs) <=>
     EVEN pos /\ all_enc_ok c labs pos xs) /\
  (all_enc_ok c labs pos ((Section k (y::ys))::xs) <=>
     line_ok c labs pos y /\
     all_enc_ok c labs (pos + line_length y) ((Section k ys)::xs))`

val all_enc_ok_ind = theorem"all_enc_ok_ind";

val asm_step_nop_def = Define `
  asm_step_nop bytes c s1 i s2 <=>
    bytes_in_memory s1.pc bytes s1.mem s1.mem_domain /\
    enc_with_nop c.encode i bytes /\
    (case c.link_reg of NONE => T | SOME r => s1.lr = r) /\
    (s1.be <=> c.big_endian) /\ s1.align = c.code_alignment /\
    asm i (s1.pc + n2w (LENGTH bytes)) s1 = s2 /\ ~s2.failed /\
    asm_ok i c`

val evaluate_nop_step =
  asm_step_IMP_evaluate_step
    |> SIMP_RULE std_ss [asm_step_def]
    |> SPEC_ALL |> Q.INST [`i`|->`Inst Skip`]
    |> SIMP_RULE (srw_ss()) [asm_def,inst_def,asm_ok_def,inst_ok_def,
         Once upd_pc_def,GSYM CONJ_ASSOC]

val shift_interfer_0 = prove(
  ``shift_interfer 0 = I``,
  full_simp_tac(srw_ss())[shift_interfer_def,FUN_EQ_THM,shift_seq_def,
      machine_config_component_equality]);

val upd_pc_with_pc = prove(
  ``upd_pc s1.pc s1 = s1:'a asm_state``,
  full_simp_tac(srw_ss())[asm_state_component_equality,upd_pc_def]);

val shift_interfer_twice = store_thm("shift_interfer_twice[simp]",
  ``shift_interfer l' (shift_interfer l c) =
    shift_interfer (l + l') c``,
  full_simp_tac(srw_ss())[shift_interfer_def,shift_seq_def,AC ADD_COMM ADD_ASSOC]);

val evaluate_nop_steps = prove(
  ``!n s1 ms1 c.
      backend_correct c.target /\
      c.prog_addresses = s1.mem_domain /\
      interference_ok c.next_interfer (c.target.proj s1.mem_domain) /\
      bytes_in_memory s1.pc
        (FLAT (REPLICATE n (c.target.config.encode (Inst Skip)))) s1.mem
        s1.mem_domain /\
      (case c.target.config.link_reg of NONE => T | SOME r => s1.lr = r) /\
      (s1.be <=> c.target.config.big_endian) /\
      s1.align = c.target.config.code_alignment /\ ~s1.failed /\
      c.target.state_rel (s1:'a asm_state) (ms1:'state) ==>
      ?l ms2.
        !k.
          evaluate c io (k + l) ms1 =
          evaluate (shift_interfer l c) io k ms2 /\
          c.target.state_rel
            (upd_pc
              (s1.pc +
               n2w (n * LENGTH (c.target.config.encode (Inst Skip)))) s1)
            ms2``,
  Induct \\ full_simp_tac(srw_ss())[] THEN1
   (rpt strip_tac \\ Q.LIST_EXISTS_TAC [`0`,`ms1`]
    \\ full_simp_tac(srw_ss())[shift_interfer_0,upd_pc_with_pc])
  \\ rpt strip_tac \\ full_simp_tac(srw_ss())[REPLICATE,bytes_in_memory_APPEND]
  \\ mp_tac evaluate_nop_step \\ full_simp_tac(srw_ss())[] \\ rpt strip_tac
  \\ full_simp_tac(srw_ss())[GSYM PULL_FORALL]
  \\ first_x_assum (mp_tac o
       Q.SPECL [`(upd_pc (s1.pc +
          n2w (LENGTH ((c:('a,'state,'b) machine_config).target.config.encode
            (Inst Skip)))) s1)`,`ms2`,`shift_interfer l c`])
  \\ match_mp_tac IMP_IMP \\ strip_tac
  THEN1 (full_simp_tac(srw_ss())[shift_interfer_def,upd_pc_def,interference_ok_def,shift_seq_def])
  \\ rpt strip_tac
  \\ `(shift_interfer l c).target = c.target` by full_simp_tac(srw_ss())[shift_interfer_def]
  \\ full_simp_tac(srw_ss())[upd_pc_def]
  \\ Q.LIST_EXISTS_TAC [`l'+l`,`ms2'`]
  \\ full_simp_tac std_ss [GSYM WORD_ADD_ASSOC,
       word_add_n2w,AC ADD_COMM ADD_ASSOC,MULT_CLAUSES]
  \\ full_simp_tac(srw_ss())[ADD_ASSOC] \\ rpt strip_tac
  \\ first_x_assum (mp_tac o Q.SPEC `k`)
  \\ first_x_assum (mp_tac o Q.SPEC `k+l'`)
  \\ full_simp_tac(srw_ss())[AC ADD_COMM ADD_ASSOC]);

val asm_step_IMP_evaluate_step_nop = prove(
  ``!c s1 ms1 io i s2 bytes.
      backend_correct c.target /\
      c.prog_addresses = s1.mem_domain /\
      interference_ok c.next_interfer (c.target.proj s1.mem_domain) /\
      bytes_in_memory s1.pc bytes s2.mem s1.mem_domain /\
      asm_step_nop bytes c.target.config s1 i s2 /\
      s2 = asm i (s1.pc + n2w (LENGTH bytes)) s1 /\
      c.target.state_rel (s1:'a asm_state) (ms1:'state) /\
      (!x. i <> Call x) ==>
      ?l ms2.
        !k.
          evaluate c io (k + l) ms1 =
          evaluate (shift_interfer l c) io k ms2 /\
          c.target.state_rel s2 ms2 /\ l <> 0``,
  full_simp_tac(srw_ss())[asm_step_nop_def] \\ rpt strip_tac
  \\ (asm_step_IMP_evaluate_step
      |> SIMP_RULE std_ss [asm_step_def] |> SPEC_ALL |> mp_tac) \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[enc_with_nop_thm]
  \\ match_mp_tac IMP_IMP \\ strip_tac THEN1
   (full_simp_tac(srw_ss())[bytes_in_memory_APPEND] \\ Cases_on `i`
    \\ full_simp_tac(srw_ss())[asm_def,upd_pc_def,jump_to_offset_def,upd_reg_def,
           LET_DEF,assert_def] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[] \\ rev_full_simp_tac(srw_ss())[])
  \\ rpt strip_tac \\ full_simp_tac(srw_ss())[GSYM PULL_FORALL]
  \\ Cases_on `?w. i = Jump w` \\ full_simp_tac(srw_ss())[]
  THEN1 (full_simp_tac(srw_ss())[asm_def] \\ Q.LIST_EXISTS_TAC [`l`,`ms2`] \\ full_simp_tac(srw_ss())[])
  \\ Cases_on `?c n r w. (i = JumpCmp c n r w) /\
                  word_cmp c (read_reg n s1) (reg_imm r s1)` \\ full_simp_tac(srw_ss())[]
  THEN1 (srw_tac[][] \\ full_simp_tac(srw_ss())[asm_def] \\ Q.LIST_EXISTS_TAC [`l`,`ms2`] \\ full_simp_tac(srw_ss())[])
  \\ Cases_on `?r. (i = JumpReg r)` \\ full_simp_tac(srw_ss())[]
  THEN1 (srw_tac[][] \\ full_simp_tac(srw_ss())[asm_def,LET_DEF] \\ Q.LIST_EXISTS_TAC [`l`,`ms2`]
               \\ full_simp_tac(srw_ss())[] \\ rev_full_simp_tac(srw_ss())[])
  \\ qspecl_then
      [`n`,`asm i (s1.pc + n2w (LENGTH (c.target.config.encode i))) s1`,`ms2`,
       `shift_interfer l c`] mp_tac evaluate_nop_steps
  \\ match_mp_tac IMP_IMP \\ strip_tac
  THEN1 (full_simp_tac(srw_ss())[shift_interfer_def] \\ rpt strip_tac
    THEN1 (full_simp_tac(srw_ss())[interference_ok_def,shift_seq_def])
    THEN1
     (Q.ABBREV_TAC
        `mm = (asm i (s1.pc + n2w (LENGTH (c.target.config.encode i))) s1).mem`
      \\ full_simp_tac(srw_ss())[Once (asm_mem_ignore_new_pc |> Q.SPECL [`i`,`0w`])]
      \\ `!w. (asm i w s1).pc = w` by (Cases_on `i` \\ full_simp_tac(srw_ss())[asm_def,upd_pc_def])
      \\ full_simp_tac(srw_ss())[bytes_in_memory_APPEND])
    \\ metis_tac [asm_failed_ignore_new_pc])
  \\ rpt strip_tac \\ full_simp_tac(srw_ss())[GSYM PULL_FORALL]
  \\ Q.LIST_EXISTS_TAC [`l+l'`,`ms2'`]
  \\ full_simp_tac(srw_ss())[PULL_FORALL] \\ strip_tac
  \\ first_x_assum (mp_tac o Q.SPEC `k:num`)
  \\ qpat_x_assum `!k. xx = yy` (mp_tac o Q.SPEC `k+l':num`)
  \\ rpt strip_tac \\ full_simp_tac(srw_ss())[AC ADD_COMM ADD_ASSOC]
  \\ full_simp_tac(srw_ss())[shift_interfer_def]
  \\ qpat_x_assum `c.target.state_rel xx yy` mp_tac
  \\ match_mp_tac (METIS_PROVE [] ``(x = z) ==> (f x y ==> f z y)``)
  \\ Cases_on `i` \\ full_simp_tac(srw_ss())[asm_def]
  \\ full_simp_tac(srw_ss())[LENGTH_FLAT,SUM_REPLICATE,map_replicate]
  \\ full_simp_tac std_ss [GSYM WORD_ADD_ASSOC,word_add_n2w]
  THEN1 (Cases_on `i'` \\ full_simp_tac(srw_ss())[inst_def,upd_pc_def]
    \\ full_simp_tac std_ss [GSYM WORD_ADD_ASSOC,word_add_n2w])
  \\ full_simp_tac(srw_ss())[jump_to_offset_def,upd_pc_def]
  \\ full_simp_tac std_ss [GSYM WORD_ADD_ASSOC,word_add_n2w]);

(* -- *)

val _ = Parse.temp_overload_on("option_ldrop",``λn l. OPTION_JOIN (OPTION_MAP (LDROP n) l)``)

val option_ldrop_0 = prove(
  ``!ll. option_ldrop 0 ll = ll``,
  Cases \\ full_simp_tac(srw_ss())[]);

val option_ldrop_SUC = prove(
  ``!k1 ll. option_ldrop (SUC k1) ll = option_ldrop 1 (option_ldrop k1 ll)``,
  Cases_on `ll` \\ full_simp_tac(srw_ss())[]
  \\ REPEAT STRIP_TAC \\ full_simp_tac(srw_ss())[ADD1] \\ full_simp_tac(srw_ss())[LDROP_ADD]
  \\ Cases_on `LDROP k1 x` \\ full_simp_tac(srw_ss())[]);

val option_ldrop_option_ldrop = prove(
  ``!k1 ll k2.
      option_ldrop k1 (option_ldrop k2 ll) = option_ldrop (k1 + k2) ll``,
  Induct \\ full_simp_tac(srw_ss())[option_ldrop_0]
  \\ REPEAT STRIP_TAC \\ full_simp_tac(srw_ss())[option_ldrop_SUC,ADD_CLAUSES]);

(*
val option_ldrop_lemma = prove(
  ``(call_FFI index x io = (new_bytes,new_io)) /\ new_io <> NONE ==>
    (new_io = option_ldrop 1 io)``,
  full_simp_tac(srw_ss())[call_FFI_def] \\ BasicProvers.EVERY_CASE_TAC
  \\ srw_tac[][]
  \\ Q.MATCH_ASSUM_RENAME_TAC `LTL ll <> NONE`
  \\ `(ll = [||]) \/ ?h t. ll = h:::t` by metis_tac [llistTheory.llist_CASES]
  \\ full_simp_tac(srw_ss())[llistTheory.LDROP1_THM]);
*)

val IMP_IMP2 = METIS_PROVE [] ``a /\ (a /\ b ==> c) ==> ((a ==> b) ==> c)``

val lab_lookup_IMP = prove(
  ``(lab_lookup l1 l2 labs = SOME x) ==>
    (find_pos (Lab l1 l2) labs = x)``,
  full_simp_tac(srw_ss())[lab_lookup_def,find_pos_def,lookup_any_def]
  \\ BasicProvers.EVERY_CASE_TAC);

val has_odd_inst_def = Define `
  (has_odd_inst [] = F) /\
  (has_odd_inst ((Section k [])::xs) = has_odd_inst xs) /\
  (has_odd_inst ((Section k (y::ys))::xs) <=>
     ~EVEN (line_length y) \/ has_odd_inst ((Section k ys)::xs))`

val line_similar_def = Define `
  (line_similar (Label k1 k2 l) (Label k1' k2' l') <=> (k1 = k1') /\ (k2 = k2')) /\
  (line_similar (Asm b bytes l) (Asm b' bytes' l') <=> (b = b')) /\
  (line_similar (LabAsm a w bytes l) (LabAsm a' w' bytes' l') <=> (a = a')) /\
  (line_similar _ _ <=> F)`

val code_similar_def = Define `
  (code_similar [] [] = T) /\
  (code_similar ((Section s1 lines1)::rest1) ((Section s2 lines2)::rest2) <=>
     code_similar rest1 rest2 /\
     EVERY2 line_similar lines1 lines2 /\ (s1 = s2)) /\
  (code_similar _ _ = F)`

val code_similar_ind = theorem "code_similar_ind";

val word_loc_val_def = Define `
  (word_loc_val p labs (Word w) = SOME w) /\
  (word_loc_val p labs (Loc k1 k2) =
     case lab_lookup k1 k2 labs of
     | NONE => NONE
     | SOME q => SOME (p + n2w q))`;

val word8_loc_val_def = Define `
  (word8_loc_val p labs (Byte w) = SOME w) /\
  (word8_loc_val p labs (LocByte k1 k2 n) =
     case lookup k1 labs of
     | NONE => NONE
     | SOME f => case lookup k2 f of
                 | NONE => NONE
                 | SOME q => SOME (w2w (p + n2w q) >> (8 * n)))`;

val bytes_in_mem_def = Define `
  (bytes_in_mem a [] m md k <=> T) /\
  (bytes_in_mem a (b::bs) m md k <=>
     a IN md /\ ~(a IN k) /\ (m a = b) /\
     bytes_in_mem (a+1w) bs m md k)`

val bytes_in_mem_IMP = prove(
  ``!xs p. bytes_in_mem p xs m dm dm1 ==> bytes_in_memory p xs m dm``,
  Induct \\ full_simp_tac(srw_ss())[bytes_in_mem_def,bytes_in_memory_def]);

val has_io_index_def = Define `
  (has_io_index index [] = F) /\
  (has_io_index index ((Section k [])::xs) = has_io_index index xs) /\
  (has_io_index index ((Section k (y::ys))::xs) <=>
     has_io_index index ((Section k ys)::xs) \/
     case y of LabAsm (CallFFI i) _ _ _ => (i = index) | _ => F)`

val asm_write_bytearray_def = Define `
  (asm_write_bytearray a [] (m:'a word -> word8) = m) /\
  (asm_write_bytearray a (x::xs) m = (a =+ x) (asm_write_bytearray (a+1w) xs m))`

val word_loc_val_byte_def = Define `
  word_loc_val_byte p labs m a be =
    case word_loc_val p labs (m (byte_align a)) of
    | SOME w => SOME (get_byte a w be)
    | NONE => NONE`

val state_rel_def = Define `
  state_rel (mc_conf, code2, labs, p, check_pc) (s1:('a,'ffi) labSem$state) t1 ms1 <=>
    mc_conf.target.state_rel t1 ms1 /\ good_dimindex (:'a) /\
    (mc_conf.prog_addresses = t1.mem_domain) /\
    ~(mc_conf.halt_pc IN mc_conf.prog_addresses) /\
    reg_ok s1.ptr_reg mc_conf.target.config /\ (mc_conf.ptr_reg = s1.ptr_reg) /\
    reg_ok s1.len_reg mc_conf.target.config /\ (mc_conf.len_reg = s1.len_reg) /\
    reg_ok s1.link_reg mc_conf.target.config /\
    (!ms2 k index new_bytes t1 x.
       mc_conf.target.state_rel
         (t1 with pc := p - n2w ((3 + index) * ffi_offset)) ms2 /\
       (read_bytearray (t1.regs s1.ptr_reg) (LENGTH new_bytes)
         (\a. if a ∈ t1.mem_domain then SOME (t1.mem a) else NONE) =
           SOME x) ==>
       mc_conf.target.state_rel
         (t1 with
         <|regs := (\a. get_reg_value (s1.io_regs k a) (t1.regs a) I);
           mem := asm_write_bytearray (t1.regs s1.ptr_reg) new_bytes t1.mem;
           pc := t1.regs s1.link_reg|>)
        (mc_conf.ffi_interfer k index new_bytes ms2)) /\
    (!l1 l2 x.
       (lab_lookup l1 l2 labs = SOME x) ==> (1w && (p + n2w x)) = 0w) /\
    (!index.
       has_io_index index s1.code ==>
       ~(p - n2w ((3 + index) * ffi_offset) IN mc_conf.prog_addresses) /\
       ~(p - n2w ((3 + index) * ffi_offset) = mc_conf.halt_pc) /\
       (find_index (p - n2w ((3 + index) * ffi_offset))
          mc_conf.ffi_entry_pcs 0 = SOME index)) /\
    (p - n2w ffi_offset = mc_conf.halt_pc) /\
    interference_ok mc_conf.next_interfer (mc_conf.target.proj t1.mem_domain) /\
    (!q n. ((n2w (2 ** t1.align - 1) && q + n2w n) = 0w:'a word) <=>
           (n MOD 2 ** t1.align = 0)) /\
    (!l1 l2 x2.
       (loc_to_pc l1 l2 s1.code = SOME x2) ==>
       (lab_lookup l1 l2 labs = SOME (pos_val x2 0 code2))) /\
    (!r. word_loc_val p labs (s1.regs r) = SOME (t1.regs r)) /\
    (!a. byte_align a IN s1.mem_domain ==>
         a IN t1.mem_domain /\ a IN s1.mem_domain /\
         (word_loc_val_byte p labs s1.mem a s1.be = SOME (t1.mem a))) /\
    (has_odd_inst code2 ==> (mc_conf.target.config.code_alignment = 0)) /\
    bytes_in_mem p (prog_to_bytes code2)
      t1.mem t1.mem_domain s1.mem_domain /\
    ~s1.failed /\ ~t1.failed /\ (s1.be = t1.be) /\
    (check_pc ==> (t1.pc = p + n2w (pos_val s1.pc 0 code2))) /\
    ((p && n2w (2 ** t1.align - 1)) = 0w) /\
    (case mc_conf.target.config.link_reg of NONE => T | SOME r => t1.lr = r) /\
    (t1.be <=> mc_conf.target.config.big_endian) /\
    (t1.align = mc_conf.target.config.code_alignment) /\
    all_enc_ok mc_conf.target.config labs 0 code2 /\
    code_similar s1.code code2`

val pos_val_0 = prove(
  ``!xs c enc labs pos.
      all_enc_ok c labs pos xs ==> (pos_val 0 pos xs = pos)``,
  Induct \\ full_simp_tac(srw_ss())[pos_val_def] \\ Cases_on `h`
  \\ Induct_on `l` \\ full_simp_tac(srw_ss())[pos_val_def,all_enc_ok_def]
  \\ rpt strip_tac  \\ res_tac  \\ srw_tac[][]
  \\ Cases_on `h` \\ full_simp_tac(srw_ss())[line_ok_def,line_length_def,is_Label_def]);

val prog_to_bytes_lemma = Q.prove(
  `!code2 code1 pc i pos.
      code_similar code1 code2 /\
      all_enc_ok (mc_conf:('a,'state,'b) machine_config).target.config
        labs pos code2 /\
      (asm_fetch_aux pc code1 = SOME i) ==>
      ?bs j bs2.
        (prog_to_bytes code2 = bs ++ line_bytes j ++ bs2) /\
        (LENGTH bs + pos = pos_val pc pos code2) /\
        (LENGTH bs + pos + LENGTH (line_bytes j) = pos_val (pc+1) pos code2) /\
        line_similar i j /\
        line_ok mc_conf.target.config labs (pos_val pc pos code2) j`,
  HO_MATCH_MP_TAC asm_code_length_ind \\ REPEAT STRIP_TAC
  THEN1 (Cases_on `code1` \\ full_simp_tac(srw_ss())[code_similar_def,asm_fetch_aux_def])
  THEN1
   (Cases_on `code1` \\ full_simp_tac(srw_ss())[code_similar_def]
    \\ Cases_on `h` \\ full_simp_tac(srw_ss())[code_similar_def]
    \\ Cases_on `l` \\ full_simp_tac(srw_ss())[asm_fetch_aux_def,pos_val_def] \\ srw_tac[][]
    \\ full_simp_tac(srw_ss())[prog_to_bytes_def,all_enc_ok_def] \\ metis_tac [])
  \\ Cases_on `code1` \\ full_simp_tac(srw_ss())[code_similar_def]
  \\ Cases_on `h` \\ full_simp_tac(srw_ss())[code_similar_def]
  \\ Cases_on`l` \\ full_simp_tac(srw_ss())[asm_fetch_aux_def,pos_val_def]
  \\ rpt var_eq_tac
  \\ Q.MATCH_ASSUM_RENAME_TAC `line_similar x1 x2`
  \\ Q.MATCH_ASSUM_RENAME_TAC `LIST_REL line_similar ys1 ys2`
  \\ `is_Label x2 = is_Label x1` by
    (Cases_on `x1` \\ Cases_on `x2` \\ full_simp_tac(srw_ss())[line_similar_def,is_Label_def])
  \\ full_simp_tac(srw_ss())[] \\ Cases_on `is_Label x1` \\ full_simp_tac(srw_ss())[]
  THEN1
   (full_simp_tac(srw_ss())[prog_to_bytes_def,LET_DEF]
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`(Section k ys1)::t`,`pc`,`i`,
       `(pos + LENGTH (line_bytes x2))`])
    \\ full_simp_tac(srw_ss())[all_enc_ok_def,code_similar_def] \\ rpt strip_tac
    \\ full_simp_tac(srw_ss())[prog_to_bytes_def,LET_DEF]
    \\ Cases_on `x2` \\ full_simp_tac(srw_ss())[line_ok_def,is_Label_def] \\ srw_tac[][]
    \\ full_simp_tac(srw_ss())[line_length_def,line_bytes_def]
    \\ full_simp_tac(srw_ss())[AC ADD_COMM ADD_ASSOC])
  \\ Cases_on `pc = 0` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  THEN1
   (full_simp_tac(srw_ss())[listTheory.LENGTH_NIL] \\ qexists_tac `x2`
    \\ full_simp_tac(srw_ss())[prog_to_bytes_def,LET_DEF,all_enc_ok_def] \\ full_simp_tac(srw_ss())[pos_val_0]
    \\ imp_res_tac pos_val_0
    \\ full_simp_tac(srw_ss())[] \\ Cases_on `x2`
    \\ full_simp_tac(srw_ss())[line_ok_def,is_Label_def,line_bytes_def,line_length_def] \\ srw_tac[][])
  \\ full_simp_tac(srw_ss())[prog_to_bytes_def,LET_DEF]
  \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`(Section k ys1)::t`,`pc-1`,`i`,
       `(pos + LENGTH (line_bytes x2))`])
  \\ full_simp_tac(srw_ss())[all_enc_ok_def,code_similar_def]
  \\ rpt strip_tac \\ full_simp_tac(srw_ss())[]
  \\ Q.LIST_EXISTS_TAC [`line_bytes x2 ++ bs`,
        `j`,`bs2`] \\ full_simp_tac(srw_ss())[] \\ `pc - 1 + 1 = pc` by decide_tac
  \\ full_simp_tac(srw_ss())[AC ADD_COMM ADD_ASSOC])

val prog_to_bytes_lemma = prog_to_bytes_lemma
  |> Q.SPECL [`code2`,`code1`,`pc`,`i`,`0`]
  |> SIMP_RULE std_ss [];

val bytes_in_mem_APPEND = prove(
  ``!xs ys a m md md1.
      bytes_in_mem a (xs ++ ys) m md md1 <=>
      bytes_in_mem a xs m md md1 /\
      bytes_in_mem (a + n2w (LENGTH xs)) ys m md md1``,
  Induct \\ full_simp_tac(srw_ss())[bytes_in_mem_def,ADD1,GSYM word_add_n2w,CONJ_ASSOC]);

val s1 = ``s1:('a,'ffi) labSem$state``;

val IMP_bytes_in_memory = prove(
  ``code_similar code1 code2 /\
    all_enc_ok mc_conf.target.config labs 0 code2 /\
    (asm_fetch_aux pc code1 = SOME i) /\
    bytes_in_mem p (prog_to_bytes code2) m (dm:'a word set) dm1 ==>
    ?j.
      bytes_in_mem (p + n2w (pos_val pc 0 code2)) (line_bytes j) m dm dm1 /\
      line_ok (mc_conf:('a,'state,'b) machine_config).target.config
        labs (pos_val pc 0 code2) j /\
      (pos_val (pc+1) 0 code2 = pos_val pc 0 code2 + LENGTH (line_bytes j)) /\
      line_similar i j``,
  rpt strip_tac
  \\ mp_tac prog_to_bytes_lemma \\ fs[] \\ rpt strip_tac
  \\ fs[bytes_in_mem_APPEND]
  \\ Q.EXISTS_TAC `j` \\ fs[] \\ decide_tac);

val IMP_bytes_in_memory_JumpReg = prove(
  ``code_similar s1.code code2 /\
    all_enc_ok mc_conf.target.config labs 0 code2 /\
    bytes_in_mem p (prog_to_bytes code2) t1.mem t1.mem_domain s1.mem_domain /\
    (asm_fetch s1 = SOME (Asm (JumpReg r1) l n)) ==>
    bytes_in_memory ((p:'a word) + n2w (pos_val s1.pc 0 code2))
      (mc_conf.target.config.encode (JumpReg r1)) t1.mem t1.mem_domain /\
    asm_ok (JumpReg r1) (mc_conf: ('a,'state,'b) machine_config).target.config``,
  fs[asm_fetch_def,LET_DEF]
  \\ Q.SPEC_TAC (`s1.pc`,`pc`) \\ strip_tac
  \\ Q.SPEC_TAC (`s1.code`,`code1`) \\ strip_tac \\ strip_tac
  \\ mp_tac (IMP_bytes_in_memory |> Q.GENL [`dm1`,`i`,`dm`,`m`]) \\ fs[]
  \\ strip_tac \\ res_tac
  \\ Cases_on `j` \\ fs[line_similar_def] \\ srw_tac[][]
  \\ fs[line_ok_def,enc_with_nop_thm] \\ srw_tac[][] \\ fs[]
  \\ imp_res_tac bytes_in_mem_IMP \\ fs[]
  \\ fs[asm_fetch_aux_def,prog_to_bytes_def,LET_DEF,line_bytes_def,
         bytes_in_memory_APPEND]);

val IMP_bytes_in_memory_Jump = prove(
  ``code_similar ^s1.code code2 /\
    all_enc_ok mc_conf.target.config labs 0 code2 /\
    bytes_in_mem p (prog_to_bytes code2) t1.mem t1.mem_domain s1.mem_domain /\
    (asm_fetch s1 = SOME (LabAsm (Jump jtarget) l bytes n)) ==>
    ?tt enc.
      (tt = n2w (find_pos jtarget labs) -
            n2w (pos_val s1.pc 0 code2)) /\
      (enc = mc_conf.target.config.encode (Jump tt)) /\
      bytes_in_memory ((p:'a word) + n2w (pos_val s1.pc 0 code2))
        enc t1.mem t1.mem_domain /\
      asm_ok (Jump tt) (mc_conf: ('a,'state,'b) machine_config).target.config``,
  fs[asm_fetch_def,LET_DEF]
  \\ Q.SPEC_TAC (`s1.pc`,`pc`) \\ strip_tac
  \\ Q.SPEC_TAC (`s1.code`,`code1`) \\ strip_tac \\ strip_tac
  \\ mp_tac (IMP_bytes_in_memory |> Q.GENL [`dm1`,`i`,`dm`,`m`]) \\ fs[]
  \\ strip_tac \\ res_tac
  \\ Cases_on `j` \\ fs[line_similar_def] \\ srw_tac[][]
  \\ fs[line_ok_def,enc_with_nop_thm,LET_DEF] \\ srw_tac[][]
  \\ fs[LET_DEF,lab_inst_def,get_label_def] \\ srw_tac[][]
  \\ imp_res_tac bytes_in_mem_IMP \\ fs[]
  \\ fs[asm_fetch_aux_def,prog_to_bytes_def,LET_DEF,line_bytes_def,
         bytes_in_memory_APPEND]);

val IMP_bytes_in_memory_JumpCmp = prove(
  ``code_similar ^s1.code code2 /\
    all_enc_ok mc_conf.target.config labs 0 code2 /\
    bytes_in_mem p (prog_to_bytes code2) t1.mem t1.mem_domain s1.mem_domain /\
    (asm_fetch s1 = SOME (LabAsm (JumpCmp cmp rr ri jtarget) l bytes n)) ==>
    ?tt enc.
      (tt = n2w (find_pos jtarget labs) -
            n2w (pos_val s1.pc 0 code2)) /\
      (enc = mc_conf.target.config.encode (JumpCmp cmp rr ri tt)) /\
      bytes_in_memory ((p:'a word) + n2w (pos_val s1.pc 0 code2))
        enc t1.mem t1.mem_domain /\
      asm_ok (JumpCmp cmp rr ri tt) (mc_conf: ('a,'state,'b) machine_config).target.config``,
  fs[asm_fetch_def,LET_DEF]
  \\ Q.SPEC_TAC (`s1.pc`,`pc`) \\ strip_tac
  \\ Q.SPEC_TAC (`s1.code`,`code1`) \\ strip_tac \\ strip_tac
  \\ mp_tac (IMP_bytes_in_memory |> Q.GENL [`dm1`,`i`,`dm`,`m`]) \\ fs[]
  \\ strip_tac \\ res_tac
  \\ Cases_on `j` \\ fs[line_similar_def] \\ srw_tac[][]
  \\ fs[line_ok_def,enc_with_nop_thm,LET_DEF] \\ srw_tac[][]
  \\ fs[LET_DEF,lab_inst_def,get_label_def] \\ srw_tac[][]
  \\ imp_res_tac bytes_in_mem_IMP \\ fs[]
  \\ fs[asm_fetch_aux_def,prog_to_bytes_def,LET_DEF,line_bytes_def,
         bytes_in_memory_APPEND]);

val IMP_bytes_in_memory_JumpCmp_1 = prove(
  ``code_similar ^s1.code code2 /\
    all_enc_ok mc_conf.target.config labs 0 code2 /\
    bytes_in_mem p (prog_to_bytes code2) t1.mem t1.mem_domain s1.mem_domain /\
    (asm_fetch s1 = SOME (LabAsm (JumpCmp cmp rr ri jtarget) l bytes n)) ==>
    ?tt bytes.
      (tt = n2w (find_pos jtarget labs) -
            n2w (pos_val s1.pc 0 code2)) /\
      enc_with_nop mc_conf.target.config.encode (JumpCmp cmp rr ri tt) bytes /\
      bytes_in_memory ((p:'a word) + n2w (pos_val s1.pc 0 code2))
        bytes t1.mem t1.mem_domain /\
      (pos_val (s1.pc+1) 0 code2 = pos_val s1.pc 0 code2 + LENGTH bytes) /\
      asm_ok (JumpCmp cmp rr ri tt) (mc_conf: ('a,'state,'b) machine_config).target.config``,
  fs[asm_fetch_def,LET_DEF]
  \\ Q.SPEC_TAC (`s1.pc`,`pc`) \\ strip_tac
  \\ Q.SPEC_TAC (`s1.code`,`code1`) \\ strip_tac \\ strip_tac
  \\ mp_tac (IMP_bytes_in_memory |> Q.GENL [`dm1`,`i`,`dm`,`m`]) \\ fs[]
  \\ strip_tac \\ res_tac
  \\ Cases_on `j` \\ fs[line_similar_def] \\ srw_tac[][]
  \\ fs[line_ok_def,LET_DEF] \\ srw_tac[][]
  \\ Q.EXISTS_TAC `l'` \\ fs[enc_with_nop_thm,PULL_EXISTS,line_length_def]
  \\ qexists_tac `n'` \\ fs[]
  \\ fs[LET_DEF,lab_inst_def,get_label_def] \\ srw_tac[][]
  \\ imp_res_tac bytes_in_mem_IMP \\ fs[]
  \\ fs[asm_fetch_aux_def,prog_to_bytes_def,LET_DEF,line_bytes_def,
         bytes_in_memory_APPEND] \\ srw_tac[][]);

val IMP_bytes_in_memory_Call = prove(
  ``code_similar ^s1.code code2 /\
    all_enc_ok
      (mc_conf: ('a,'state,'b) machine_config).target.config labs 0 code2 /\
    bytes_in_mem p (prog_to_bytes code2) t1.mem
      (t1:'a asm_state).mem_domain s1.mem_domain /\
    (asm_fetch s1 = SOME (LabAsm (Call ww) l bytes n)) ==>
    F``,
  rpt strip_tac
  \\ full_simp_tac(srw_ss())[asm_fetch_def,LET_DEF]
  \\ imp_res_tac IMP_bytes_in_memory
  \\ Cases_on `j` \\ full_simp_tac(srw_ss())[line_similar_def] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[line_ok_def] \\ rev_full_simp_tac(srw_ss())[]);

val IMP_bytes_in_memory_LocValue = prove(
  ``code_similar ^s1.code code2 /\
    all_enc_ok mc_conf.target.config labs 0 code2 /\
    bytes_in_mem p (prog_to_bytes code2) t1.mem t1.mem_domain s1.mem_domain /\
    (asm_fetch s1 = SOME (LabAsm (LocValue reg (Lab l1 l2)) l bytes n)) ==>
    ?tt bytes.
      (tt = n2w (find_pos (Lab l1 l2) labs) -
            n2w (pos_val s1.pc 0 code2)) /\
      enc_with_nop mc_conf.target.config.encode (Loc reg tt) bytes /\
      bytes_in_memory ((p:'a word) + n2w (pos_val s1.pc 0 code2))
        bytes t1.mem t1.mem_domain /\
      (pos_val (s1.pc+1) 0 code2 = pos_val s1.pc 0 code2 + LENGTH bytes) /\
      asm_ok (Loc reg tt) (mc_conf: ('a,'state,'b) machine_config).target.config``,
  fs[asm_fetch_def,LET_DEF]
  \\ Q.SPEC_TAC (`s1.pc`,`pc`) \\ strip_tac
  \\ Q.SPEC_TAC (`s1.code`,`code1`) \\ strip_tac \\ strip_tac
  \\ mp_tac (IMP_bytes_in_memory |> Q.GENL [`dm1`,`i`,`dm`,`m`]) \\ fs[]
  \\ strip_tac \\ res_tac
  \\ Cases_on `j` \\ fs[line_similar_def] \\ srw_tac[][]
  \\ fs[line_ok_def,LET_DEF] \\ srw_tac[][]
  \\ Q.EXISTS_TAC `l'` \\ fs[enc_with_nop_thm,PULL_EXISTS,line_length_def]
  \\ qexists_tac `n'` \\ fs[]
  \\ fs[LET_DEF,lab_inst_def,get_label_def] \\ srw_tac[][]
  \\ imp_res_tac bytes_in_mem_IMP \\ fs[]
  \\ fs[asm_fetch_aux_def,prog_to_bytes_def,LET_DEF,line_bytes_def,
         bytes_in_memory_APPEND] \\ srw_tac[][]);

val IMP_bytes_in_memory_Inst = prove(
  ``code_similar ^s1.code code2 /\
    all_enc_ok mc_conf.target.config labs 0 code2 /\
    bytes_in_mem p (prog_to_bytes code2) t1.mem t1.mem_domain s1.mem_domain /\
    (asm_fetch s1 = SOME (Asm (Inst i) bytes len)) ==>
    ?bytes.
      enc_with_nop mc_conf.target.config.encode (Inst i) bytes /\
      bytes_in_memory ((p:'a word) + n2w (pos_val s1.pc 0 code2))
        bytes t1.mem t1.mem_domain /\
      bytes_in_mem ((p:'a word) + n2w (pos_val s1.pc 0 code2))
        bytes t1.mem t1.mem_domain s1.mem_domain /\
      (pos_val (s1.pc+1) 0 code2 = pos_val s1.pc 0 code2 + LENGTH bytes) /\
      asm_ok (Inst i) (mc_conf: ('a,'state,'b) machine_config).target.config``,
  fs[asm_fetch_def,LET_DEF]
  \\ Q.SPEC_TAC (`s1.pc`,`pc`) \\ strip_tac
  \\ Q.SPEC_TAC (`s1.code`,`code1`) \\ strip_tac \\ strip_tac
  \\ mp_tac (IMP_bytes_in_memory |> Q.GENL [`dm1`,`i`,`dm`,`m`]) \\ fs[]
  \\ strip_tac \\ res_tac
  \\ Cases_on `j` \\ fs[line_similar_def] \\ srw_tac[][]
  \\ fs[line_ok_def,LET_DEF] \\ srw_tac[][]
  \\ Q.EXISTS_TAC `l` \\ fs[enc_with_nop_thm,PULL_EXISTS,line_length_def]
  \\ qexists_tac `n` \\ fs[]
  \\ fs[LET_DEF,lab_inst_def,get_label_def] \\ srw_tac[][]
  \\ imp_res_tac bytes_in_mem_IMP \\ fs[]
  \\ fs[asm_fetch_aux_def,prog_to_bytes_def,LET_DEF,line_bytes_def,
         bytes_in_memory_APPEND] \\ srw_tac[][]);

val IMP_bytes_in_memory_CallFFI = prove(
  ``code_similar ^s1.code code2 /\
    all_enc_ok mc_conf.target.config labs 0 code2 /\
    bytes_in_mem p (prog_to_bytes code2) t1.mem t1.mem_domain s1.mem_domain /\
    (asm_fetch s1 = SOME (LabAsm (CallFFI index) l bytes n)) ==>
    ?tt enc.
      (tt = 0w - n2w (pos_val s1.pc 0 code2 + (3 + index) * ffi_offset)) /\
      (enc = mc_conf.target.config.encode (Jump tt)) /\
      bytes_in_memory ((p:'a word) + n2w (pos_val s1.pc 0 code2))
        enc t1.mem t1.mem_domain /\
      asm_ok (Jump tt) (mc_conf: ('a,'state,'b) machine_config).target.config``,
  fs[asm_fetch_def,LET_DEF]
  \\ Q.SPEC_TAC (`s1.pc`,`pc`) \\ strip_tac
  \\ Q.SPEC_TAC (`s1.code`,`code1`) \\ strip_tac \\ strip_tac
  \\ mp_tac (IMP_bytes_in_memory |> Q.GENL [`dm1`,`i`,`dm`,`m`]) \\ fs[]
  \\ strip_tac \\ res_tac
  \\ Cases_on `j` \\ fs[line_similar_def] \\ srw_tac[][]
  \\ fs[line_ok_def,enc_with_nop_thm,LET_DEF] \\ srw_tac[][]
  \\ fs[LET_DEF,lab_inst_def,get_label_def] \\ srw_tac[][]
  \\ imp_res_tac bytes_in_mem_IMP \\ fs[]
  \\ fs[asm_fetch_aux_def,prog_to_bytes_def,LET_DEF,line_bytes_def,
         bytes_in_memory_APPEND]);

val IMP_bytes_in_memory_Halt = prove(
  ``code_similar ^s1.code code2 /\
    all_enc_ok mc_conf.target.config labs 0 code2 /\
    bytes_in_mem p (prog_to_bytes code2) t1.mem t1.mem_domain s1.mem_domain /\
    (asm_fetch s1 = SOME (LabAsm Halt l bytes n)) ==>
    ?tt enc.
      (tt = 0w - n2w (pos_val s1.pc 0 code2 + ffi_offset)) /\
      (enc = mc_conf.target.config.encode (Jump tt)) /\
      bytes_in_memory ((p:'a word) + n2w (pos_val s1.pc 0 code2))
        enc t1.mem t1.mem_domain /\
      asm_ok (Jump tt) (mc_conf: ('a,'state,'b) machine_config).target.config``,
  fs[asm_fetch_def,LET_DEF]
  \\ Q.SPEC_TAC (`s1.pc`,`pc`) \\ strip_tac
  \\ Q.SPEC_TAC (`s1.code`,`code1`) \\ strip_tac \\ strip_tac
  \\ mp_tac (IMP_bytes_in_memory |> Q.GENL [`dm1`,`i`,`dm`,`m`]) \\ fs[]
  \\ strip_tac \\ res_tac
  \\ Cases_on `j` \\ fs[line_similar_def] \\ srw_tac[][]
  \\ fs[line_ok_def,enc_with_nop_thm,LET_DEF] \\ srw_tac[][]
  \\ fs[LET_DEF,lab_inst_def,get_label_def] \\ srw_tac[][]
  \\ imp_res_tac bytes_in_mem_IMP \\ fs[]
  \\ fs[asm_fetch_aux_def,prog_to_bytes_def,LET_DEF,line_bytes_def,
         bytes_in_memory_APPEND]);

val ADD_MODULUS_LEMMA = prove(
  ``!k m n. 0 < n ==> (m + k * n) MOD n = m MOD n``,
  Induct \\ full_simp_tac(srw_ss())[MULT_CLAUSES,ADD_ASSOC,ADD_MODULUS]);

val line_length_MOD_0 = prove(
  ``backend_correct mc_conf.target /\
    (~EVEN p ==> (mc_conf.target.config.code_alignment = 0)) /\
    line_ok mc_conf.target.config labs p h ==>
    (line_length h MOD 2 ** mc_conf.target.config.code_alignment = 0)``,
  Cases_on `h` \\ TRY (Cases_on `a`) \\ full_simp_tac(srw_ss())[line_ok_def,line_length_def]
  \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[backend_correct_def,target_ok_def,enc_ok_def]
  \\ full_simp_tac(srw_ss())[LET_DEF,enc_with_nop_thm] \\ srw_tac[][LENGTH_FLAT,LENGTH_REPLICATE]
  \\ qpat_x_assum `2 ** nn = xx:num` (ASSUME_TAC o GSYM) \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[LET_DEF,map_replicate,SUM_REPLICATE] \\ srw_tac[][]
  \\ res_tac \\ full_simp_tac(srw_ss())[ADD_MODULUS_LEMMA]);

val pos_val_MOD_0_lemma = prove(
  ``(0 MOD 2 ** mc_conf.target.config.code_alignment = 0)``,
  full_simp_tac(srw_ss())[]);

val pos_val_MOD_0 = prove(
  ``!x pos code2.
      backend_correct mc_conf.target /\
      (has_odd_inst code2 ==> (mc_conf.target.config.code_alignment = 0)) /\
      (~EVEN pos ==> (mc_conf.target.config.code_alignment = 0)) /\
      (pos MOD 2 ** mc_conf.target.config.code_alignment = 0) /\
      all_enc_ok mc_conf.target.config labs pos code2 ==>
      (pos_val x pos code2 MOD 2 ** mc_conf.target.config.code_alignment = 0)``,
  reverse (Cases_on `backend_correct mc_conf.target`)
  \\ asm_simp_tac pure_ss [] THEN1 full_simp_tac(srw_ss())[]
  \\ HO_MATCH_MP_TAC pos_val_ind
  \\ rpt strip_tac \\ full_simp_tac(srw_ss())[pos_val_def] \\ full_simp_tac(srw_ss())[all_enc_ok_def]
  THEN1 (srw_tac[][] \\ full_simp_tac(srw_ss())[PULL_FORALL,AND_IMP_INTRO,has_odd_inst_def])
  \\ Cases_on `is_Label y` \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `x = 0` \\ full_simp_tac(srw_ss())[]
  \\ FIRST_X_ASSUM MATCH_MP_TAC \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[has_odd_inst_def]
  \\ Cases_on `EVEN pos` \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[EVEN_ADD]
  \\ `0:num < 2 ** mc_conf.target.config.code_alignment` by full_simp_tac(srw_ss())[]
  \\ imp_res_tac (GSYM MOD_PLUS)
  \\ pop_assum (fn th => once_rewrite_tac [th])
  \\ imp_res_tac line_length_MOD_0 \\ full_simp_tac(srw_ss())[])
  |> Q.SPECL [`x`,`0`,`y`] |> SIMP_RULE std_ss [GSYM AND_IMP_INTRO]
  |> SIMP_RULE std_ss [pos_val_MOD_0_lemma]
  |> REWRITE_RULE [AND_IMP_INTRO,GSYM CONJ_ASSOC];

val state_rel_weaken = prove(
  ``state_rel (mc_conf,code2,labs,p,T) s1 t1 ms1 ==>
    state_rel (mc_conf,code2,labs,p,F) s1 t1 ms1``,
  full_simp_tac(srw_ss())[state_rel_def] \\ rpt strip_tac \\ full_simp_tac(srw_ss())[] \\ metis_tac []);

val read_bytearray_state_rel = prove(
  ``!n a x.
      state_rel (mc_conf,code2,labs,p,T) s1 t1 ms1 /\
      (read_bytearray a n (mem_load_byte_aux s1.mem s1.mem_domain s1.be) = SOME x) ==>
      (read_bytearray a n
        (\a. if a IN mc_conf.prog_addresses then SOME (t1.mem a) else NONE) =
       SOME x)``,
  Induct
  \\ full_simp_tac(srw_ss())[read_bytearray_def]
  \\ rpt strip_tac
  \\ Cases_on `mem_load_byte_aux s1.mem s1.mem_domain s1.be a` \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `read_bytearray (a + 1w) n (mem_load_byte_aux s1.mem s1.mem_domain s1.be)` \\ full_simp_tac(srw_ss())[]
  \\ res_tac \\ full_simp_tac(srw_ss())[] \\ full_simp_tac(srw_ss())[state_rel_def,mem_load_byte_aux_def]
  \\ Cases_on `s1.mem (byte_align a)` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `a`) \\ full_simp_tac(srw_ss())[]
  \\ rpt strip_tac \\ full_simp_tac(srw_ss())[word_loc_val_def]
  \\ rev_full_simp_tac(srw_ss())[word_loc_val_byte_def,word_loc_val_def]);

val IMP_has_io_index = prove(
  ``(asm_fetch s1 = SOME (LabAsm (CallFFI index) l bytes n)) ==>
    has_io_index index s1.code``,
  full_simp_tac(srw_ss())[asm_fetch_def]
  \\ Q.SPEC_TAC (`s1.pc`,`pc`)
  \\ Q.SPEC_TAC (`s1.code`,`code`)
  \\ HO_MATCH_MP_TAC asm_code_length_ind \\ rpt strip_tac
  \\ full_simp_tac(srw_ss())[asm_fetch_aux_def,has_io_index_def] \\ res_tac
  \\ Cases_on `is_Label y` \\ full_simp_tac(srw_ss())[]
  THEN1 (Cases_on `y` \\ full_simp_tac(srw_ss())[is_Label_def] \\ res_tac)
  \\ Cases_on `pc = 0` \\ full_simp_tac(srw_ss())[] \\ res_tac \\ full_simp_tac(srw_ss())[]);

val bytes_in_mem_asm_write_bytearray_lemma = prove(
  ``!xs p.
      (!a. ~(a IN k) ==> (m1 a = m2 a)) ==>
      bytes_in_mem p xs m1 d k ==>
      bytes_in_mem p xs m2 d k``,
  Induct \\ full_simp_tac(srw_ss())[bytes_in_mem_def]);

val bytes_in_mem_asm_write_bytearray = prove(
  ``state_rel ((mc_conf: ('a,'state,'b) machine_config),code2,labs,p,T) s1 t1 ms1 /\
    (read_bytearray c1 (LENGTH new_bytes) (mem_load_byte_aux s1.mem s1.mem_domain s1.be) = SOME x) ==>
    bytes_in_mem p xs t1.mem t1.mem_domain s1.mem_domain ==>
    bytes_in_mem p xs
      (asm_write_bytearray c1 new_bytes t1.mem) t1.mem_domain s1.mem_domain``,
  STRIP_TAC \\ match_mp_tac bytes_in_mem_asm_write_bytearray_lemma
  \\ POP_ASSUM MP_TAC
  \\ Q.SPEC_TAC (`c1`,`a`)
  \\ Q.SPEC_TAC (`x`,`x`)
  \\ Q.SPEC_TAC (`t1.mem`,`m`)
  \\ Induct_on `new_bytes`
  \\ full_simp_tac(srw_ss())[asm_write_bytearray_def]
  \\ REPEAT STRIP_TAC
  \\ full_simp_tac(srw_ss())[read_bytearray_def]
  \\ BasicProvers.EVERY_CASE_TAC \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[PULL_FORALL]
  \\ res_tac
  \\ POP_ASSUM (fn th => ONCE_REWRITE_TAC [GSYM th])
  \\ full_simp_tac(srw_ss())[mem_load_byte_aux_def]
  \\ BasicProvers.EVERY_CASE_TAC \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ srw_tac[][combinTheory.APPLY_UPDATE_THM]
  \\ full_simp_tac(srw_ss())[state_rel_def] \\ res_tac);

val write_bytearray_NOT_Loc = prove(
  ``!xs c1 s1 a c.
      (s1.mem a = Word c) ==>
      (write_bytearray c1 xs s1.mem s1.mem_domain s1.be) a <> Loc n n0``,
  Induct \\ full_simp_tac(srw_ss())[write_bytearray_def,mem_store_byte_aux_def]
  \\ rpt strip_tac \\ res_tac
  \\ BasicProvers.EVERY_CASE_TAC \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[labSemTheory.upd_mem_def] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[APPLY_UPDATE_THM]
  \\ BasicProvers.EVERY_CASE_TAC \\ full_simp_tac(srw_ss())[] \\ rev_full_simp_tac(srw_ss())[]);

val CallFFI_bytearray_lemma = prove(
  ``byte_align (a:'a word) IN s1.mem_domain /\ good_dimindex (:'a) /\
    a IN t1.mem_domain /\
    a IN s1.mem_domain /\
    (s1.be = mc_conf.target.config.big_endian) /\
    (read_bytearray c1 (LENGTH new_bytes) (mem_load_byte_aux s1.mem s1.mem_domain s1.be) = SOME x) /\
    (word_loc_val_byte p labs s1.mem a mc_conf.target.config.big_endian =
       SOME (t1.mem a)) ==>
    (word_loc_val_byte p labs (write_bytearray c1 new_bytes s1.mem s1.mem_domain s1.be) a
       mc_conf.target.config.big_endian =
     SOME (asm_write_bytearray c1 new_bytes t1.mem a))``,
  Q.SPEC_TAC (`s1`,`s1`) \\ Q.SPEC_TAC (`t1`,`t1`) \\ Q.SPEC_TAC (`c1`,`c1`)
  \\ Q.SPEC_TAC (`x`,`x`) \\ Q.SPEC_TAC (`new_bytes`,`xs`) \\ Induct
  \\ full_simp_tac(srw_ss())[asm_write_bytearray_def,write_bytearray_def,read_bytearray_def]
  \\ rpt strip_tac
  \\ Cases_on `mem_load_byte_aux s1.mem s1.mem_domain s1.be c1` \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `read_bytearray (c1 + 1w) (LENGTH xs) (mem_load_byte_aux s1.mem s1.mem_domain s1.be)`
  \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ qmatch_assum_rename_tac
       `read_bytearray (c1 + 1w) (LENGTH xs) (mem_load_byte_aux s1.mem s1.mem_domain s1.be) = SOME y`
  \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`y`,`c1+1w`,`t1`,`s1`])
  \\ full_simp_tac(srw_ss())[] \\ rpt strip_tac \\ full_simp_tac(srw_ss())[mem_store_byte_aux_def]
  \\ reverse (Cases_on `(write_bytearray (c1 + 1w)
       xs s1.mem s1.mem_domain mc_conf.target.config.big_endian) (byte_align c1)`)
  \\ full_simp_tac(srw_ss())[] THEN1
   (full_simp_tac(srw_ss())[mem_load_byte_aux_def]
    \\ Cases_on `s1.mem (byte_align c1)` \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
    \\ imp_res_tac write_bytearray_NOT_Loc \\ rev_full_simp_tac(srw_ss())[] \\ full_simp_tac(srw_ss())[])
  \\ `byte_align c1 IN s1.mem_domain` by
    (full_simp_tac(srw_ss())[mem_load_byte_aux_def] \\ every_case_tac \\ full_simp_tac(srw_ss())[])
  \\ full_simp_tac(srw_ss())[labSemTheory.upd_mem_def,word_loc_val_byte_def,APPLY_UPDATE_THM]
  \\ Cases_on `a = c1` \\ full_simp_tac(srw_ss())[word_loc_val_def,get_byte_set_byte]
  \\ Cases_on `byte_align c1 = byte_align a` \\ full_simp_tac(srw_ss())[word_loc_val_def]
  \\ full_simp_tac(srw_ss())[get_byte_set_byte_diff]);

val word_cmp_lemma = prove(
  ``state_rel (mc_conf,code2,labs,p,T) s1 t1 ms1 /\
    (word_cmp cmp (read_reg rr s1) (reg_imm ri s1) = SOME x) ==>
    (x = word_cmp cmp (read_reg rr t1) (reg_imm ri t1))``,
  Cases_on `ri` \\ full_simp_tac(srw_ss())[labSemTheory.reg_imm_def,asmSemTheory.reg_imm_def]
  \\ full_simp_tac(srw_ss())[asmSemTheory.read_reg_def]
  \\ Cases_on `s1.regs rr` \\ full_simp_tac(srw_ss())[]
  \\ TRY (Cases_on `s1.regs n`) \\ full_simp_tac(srw_ss())[] \\ Cases_on `cmp`
  \\ full_simp_tac(srw_ss())[labSemTheory.word_cmp_def,asmSemTheory.word_cmp_def]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[state_rel_def]
  \\ first_assum (assume_tac o Q.SPEC `rr:num`)
  \\ first_x_assum (assume_tac o Q.SPEC `n:num`)
  \\ rev_full_simp_tac(srw_ss())[word_loc_val_def] \\ srw_tac[][]
  \\ BasicProvers.EVERY_CASE_TAC \\ full_simp_tac(srw_ss())[]
  \\ rpt (qpat_x_assum `1w = xxx` (fn th => full_simp_tac(srw_ss())[GSYM th]))
  \\ rpt (qpat_x_assum `p + n2w xxx = t1.regs rr` (fn th => full_simp_tac(srw_ss())[GSYM th]))
  \\ res_tac \\ full_simp_tac(srw_ss())[]);

val bytes_in_mem_IMP_memory = prove(
  ``!xs a.
      (!a. ~(a IN dm1) ==> m a = m1 a) ==>
      bytes_in_mem a xs m dm dm1 ==>
      bytes_in_memory a xs m1 dm``,
  Induct \\ full_simp_tac(srw_ss())[bytes_in_memory_def,bytes_in_mem_def]);

val state_rel_shift_interfer = prove(
  ``state_rel (mc_conf,code2,labs,p,T) s1 t1 x ==>
    state_rel (shift_interfer l mc_conf,code2,labs,p,T) s1 t1 x``,
  full_simp_tac(srw_ss())[state_rel_def,shift_interfer_def]
  \\ rpt strip_tac \\ full_simp_tac(srw_ss())[] \\ rev_full_simp_tac(srw_ss())[] \\ res_tac
  \\ full_simp_tac(srw_ss())[interference_ok_def,shift_seq_def]);

val state_rel_clock = prove(
  ``state_rel x s1 t1 ms ==>
    state_rel x (s1 with clock := k) (t1) ms``,
  PairCases_on `x`
  \\ full_simp_tac(srw_ss())[state_rel_def]
  \\ full_simp_tac(srw_ss())[] \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ metis_tac []);

val arith_upd_lemma = Q.prove(
  `(∀r. word_loc_val p labs (read_reg r s1) = SOME (t1.regs r)) ∧ ¬(arith_upd a s1).failed ⇒
   ∀r. word_loc_val p labs (read_reg r (arith_upd a s1)) =
       SOME ((arith_upd a t1).regs r)`,
  Cases_on`a`>>srw_tac[][arith_upd_def]>- (
    every_case_tac >> full_simp_tac(srw_ss())[] >>
    EVAL_TAC >> srw_tac[][] >>
    metis_tac[] )
  >- (
    pop_assum mp_tac >>
    reverse BasicProvers.TOP_CASE_TAC >- EVAL_TAC >>
    reverse BasicProvers.TOP_CASE_TAC >- EVAL_TAC >>
    qmatch_assum_rename_tac`read_reg rr _ = _` >>
    first_assum(qspec_then`rr`mp_tac) >>
    first_assum(SUBST1_TAC) >>
    EVAL_TAC >> strip_tac >>
    Cases_on`b` >> EVAL_TAC >> srw_tac[][] >> full_simp_tac(srw_ss())[] >>
    EVAL_TAC >>
    qpat_x_assum`_ = Word c`mp_tac >>
    Cases_on`r` >> EVAL_TAC >> srw_tac[][] >>
    qmatch_assum_rename_tac`read_reg r2 _ = _` >>
    first_x_assum(qspec_then`r2`mp_tac) >>
    simp[] >> EVAL_TAC >> srw_tac[][])
  >- (
    EVAL_TAC >>
    every_case_tac >> full_simp_tac(srw_ss())[APPLY_UPDATE_THM] >> srw_tac[][] >>
    pop_assum mp_tac >>
    EVAL_TAC >>
    qmatch_assum_rename_tac`read_reg r _ = _` >>
    first_x_assum(qspec_then`r`mp_tac) >>
    simp[] >> EVAL_TAC >> srw_tac[][] )
  >> (
    unabbrev_all_tac
    \\ first_assum(qspec_then`n0`mp_tac)
    \\ first_assum(qspec_then`n1`mp_tac)
    \\ first_assum(qspec_then`n2`mp_tac)
    \\ first_assum(qspec_then`n3`mp_tac)
    \\ first_x_assum(qspec_then`r`mp_tac)
    \\ every_case_tac \\ fs[]
    \\ EVAL_TAC \\ rw[] \\ EVAL_TAC \\ fs[]
    \\ fs[read_reg_def]
    \\ fs[labSemTheory.assert_def]));

val MULT_ADD_LESS_MULT = prove(
  ``!m n k l j. m < l /\ n < k /\ j <= k ==> m * j + n < l * k:num``,
  rpt strip_tac
  \\ `SUC m <= l` by asm_rewrite_tac [GSYM LESS_EQ]
  \\ `m * k + k <= l * k` by asm_simp_tac bool_ss [LE_MULT_RCANCEL,GSYM MULT]
  \\ `m * j <= m * k` by asm_simp_tac bool_ss [LE_MULT_LCANCEL]
  \\ decide_tac);

val aligned_IMP_ADD_LESS_dimword = prove(
  ``aligned k (x:'a word) /\ k <= dimindex (:'a) ==>
    w2n x + (2 ** k - 1) < dimword (:'a)``,
  Cases_on `x` \\ fs [aligned_w2n,dimword_def] \\ rw []
  \\ full_simp_tac std_ss [ONCE_REWRITE_RULE [ADD_COMM]LESS_EQ_EXISTS]
  \\ pop_assum (fn th => full_simp_tac std_ss [th])
  \\ full_simp_tac std_ss [MOD_EQ_0_DIVISOR]
  \\ var_eq_tac
  \\ full_simp_tac std_ss [EXP_ADD]
  \\ match_mp_tac MULT_ADD_LESS_MULT \\ fs []);

val aligned_2_imp = store_thm("aligned_2_imp",
  ``aligned 2 (x:'a word) /\ dimindex (:'a) = 32 ==>
    byte_align x = x ∧
    byte_align (x + 1w) = x ∧
    byte_align (x + 2w) = x ∧
    byte_align (x + 3w) = x``,
  rw [alignmentTheory.byte_align_def, GSYM alignmentTheory.aligned_def]
  \\ match_mp_tac alignmentTheory.align_add_aligned
  \\ simp [wordsTheory.dimword_def])

val aligned_2_not_eq = store_thm("aligned_2_not_eq",
  ``aligned 2 (x:'a word) ∧ dimindex(:'a) = 32 ∧
    x ≠ byte_align a ⇒
    x ≠ a ∧
    x+1w ≠ a ∧
    x+2w ≠ a ∧
    x+3w ≠ a``,
  metis_tac[aligned_2_imp])

val aligned_3_imp = store_thm("aligned_3_imp",
  ``aligned 3 (x:'a word) /\ dimindex (:'a) = 64 ==>
    byte_align x = x ∧
    byte_align (x + 1w) = x ∧
    byte_align (x + 2w) = x ∧
    byte_align (x + 3w) = x ∧
    byte_align (x + 4w) = x ∧
    byte_align (x + 5w) = x ∧
    byte_align (x + 6w) = x ∧
    byte_align (x + 7w) = x``,
  rw [alignmentTheory.byte_align_def, GSYM alignmentTheory.aligned_def]
  \\ match_mp_tac alignmentTheory.align_add_aligned
  \\ simp [wordsTheory.dimword_def])

val aligned_3_not_eq = store_thm("aligned_3_not_eq",
  ``aligned 3 (x:'a word) ∧ dimindex(:'a) = 64 ∧
    x ≠ byte_align a ⇒
    x ≠ a ∧
    x+1w ≠ a ∧
    x+2w ≠ a ∧
    x+3w ≠ a ∧
    x+4w ≠ a ∧
    x+5w ≠ a ∧
    x+6w ≠ a ∧
    x+7w ≠ a``,
    metis_tac[aligned_3_imp])

val ADD_MOD_EQ_LEMMA = prove(
  ``k MOD d = 0 /\ n < d ==> (k + n) MOD d = n``,
  rw [] \\ `0 < d` by decide_tac
  \\ fs [MOD_EQ_0_DIVISOR]
  \\ pop_assum kall_tac
  \\ drule MOD_MULT
  \\ fs []);

val dimword_eq_32_imp_or_bytes = prove(
  ``dimindex (:'a) = 32 ==>
    (w2w ((w2w (x:'a word)):word8) ‖
     w2w ((w2w (x ⋙ 8)):word8) ≪ 8 ‖
     w2w ((w2w (x ⋙ 16)):word8) ≪ 16 ‖
     w2w ((w2w (x ⋙ 24)):word8) ≪ 24) = x``,
  srw_tac [wordsLib.WORD_BIT_EQ_ss, boolSimps.CONJ_ss] [])

val dimword_eq_64_imp_or_bytes = prove(
  ``dimindex (:'a) = 64 ==>
    (w2w ((w2w (x:'a word)):word8) ‖
     w2w ((w2w (x ⋙ 8)):word8) ≪ 8 ‖
     w2w ((w2w (x ⋙ 16)):word8) ≪ 16 ‖
     w2w ((w2w (x ⋙ 24)):word8) ≪ 24 ‖
     w2w ((w2w (x ⋙ 32)):word8) ≪ 32 ‖
     w2w ((w2w (x ⋙ 40)):word8) ≪ 40 ‖
     w2w ((w2w (x ⋙ 48)):word8) ≪ 48 ‖
     w2w ((w2w (x ⋙ 56)):word8) ≪ 56) = x``,
  srw_tac [wordsLib.WORD_BIT_EQ_ss, boolSimps.CONJ_ss] [])

val byte_align_32_eq = prove(``
  dimindex (:'a) = 32 ⇒
  byte_align (a:'a word) +n2w (w2n a MOD 4) = a``,
  Cases_on`a`>>
  rw[alignmentTheory.byte_align_def]>>
  fs[alignmentTheory.align_w2n,word_add_n2w]>>rfs[dimword_def]>>
  Q.SPEC_THEN `4n` mp_tac DIVISION>>
  fs[]>>disch_then (Q.SPEC_THEN`n` assume_tac)>>
  simp[])

val byte_align_64_eq = prove(``
  dimindex (:'a) = 64 ⇒
  byte_align (a:'a word) +n2w (w2n a MOD 8) = a``,
  Cases_on`a`>>
  rw[alignmentTheory.byte_align_def]>>
  fs[alignmentTheory.align_w2n,word_add_n2w]>>rfs[dimword_def]>>
  Q.SPEC_THEN `8n` mp_tac DIVISION>>
  fs[]>>disch_then (Q.SPEC_THEN`n` assume_tac)>>
  simp[])

val byte_align_32_IMP = prove(``
  dimindex(:'a) = 32 ⇒
  (byte_align a = a ⇒ w2n a MOD 4 = 0) ∧
  (byte_align a + (1w:'a word) = a ⇒ w2n a MOD 4 = 1) ∧
  (byte_align a + (2w:'a word) = a ⇒ w2n a MOD 4 = 2) ∧
  (byte_align a + (3w:'a word) = a ⇒ w2n a MOD 4 = 3)``,
  rw[]>>imp_res_tac byte_align_32_eq>>fs[]>>
  qpat_x_assum`A=a` mp_tac>>
  qabbrev_tac`ba = byte_align a`>>
  qabbrev_tac`ca = w2n a MOD 4`>>
  first_x_assum(qspec_then`a` (SUBST1_TAC o SYM))>>
  unabbrev_all_tac>>
  fs[dimword_def,addressTheory.WORD_EQ_ADD_CANCEL]>>
  Q.ISPECL_THEN[`32n`,`w2n a MOD 4`] assume_tac bitTheory.MOD_ZERO_GT>>
  fs[]>>
  Q.ISPECL_THEN [`w2n a`,`4n`] assume_tac MOD_LESS>>
  DECIDE_TAC)

val MOD4_CASES = prove(``
  ∀n. n MOD 4 = 0 ∨ n MOD 4 = 1 ∨ n MOD 4 = 2 ∨ n MOD 4 = 3``,
  rw[]>>`n MOD 4 < 4` by fs []
  \\ IMP_RES_TAC (DECIDE
       ``n < 4 ==> (n = 0) \/ (n = 1) \/ (n = 2) \/ (n = 3:num)``)
  \\ fs [])

val byte_align_32_CASES = prove(``
  dimindex(:'a) = 32 ⇒
  byte_align a + (3w:'a word) = a ∨
  byte_align a + (2w:'a word) = a ∨
  byte_align a + (1w:'a word) = a ∨
  byte_align a = a``,
  rw[]>>imp_res_tac byte_align_32_eq>>
  pop_assum(qspec_then`a` assume_tac)>>
  Q.SPEC_THEN `w2n a` mp_tac MOD4_CASES>>rw[]>>
  fs[])

val MOD8_CASES = prove(``
  ∀n. n MOD 8 = 0 ∨ n MOD 8 = 1 ∨ n MOD 8 = 2 ∨ n MOD 8 = 3 ∨
      n MOD 8 = 4 ∨ n MOD 8 = 5 ∨ n MOD 8 = 6 ∨ n MOD 8 = 7``,
  rw[]>>`n MOD 8 < 8` by fs []
  \\ IMP_RES_TAC (DECIDE
       ``n < 8 ==> (n = 0) \/ (n = 1) \/ (n = 2) \/ (n = 3:num) \/
                   (n = 4) \/ (n = 5) \/ (n = 6) \/ (n = 7)``)
  \\ fs [])

val byte_align_64_CASES = prove(``
  dimindex(:'a) = 64 ⇒
  byte_align a + (7w:'a word) = a ∨
  byte_align a + (6w:'a word) = a ∨
  byte_align a + (5w:'a word) = a ∨
  byte_align a + (4w:'a word) = a ∨
  byte_align a + (3w:'a word) = a ∨
  byte_align a + (2w:'a word) = a ∨
  byte_align a + (1w:'a word) = a ∨
  byte_align a = a``,
  rw[]>>imp_res_tac byte_align_64_eq>>
  pop_assum(qspec_then`a` assume_tac)>>
  Q.SPEC_THEN `w2n a` mp_tac MOD8_CASES>>rw[]>>
  fs[])

val byte_align_64_IMP = prove(``
  dimindex(:'a) = 64 ⇒
  (byte_align a + (7w:'a word) = a ⇒ w2n a MOD 8 = 7) ∧
  (byte_align a + (6w:'a word) = a ⇒ w2n a MOD 8 = 6) ∧
  (byte_align a + (5w:'a word) = a ⇒ w2n a MOD 8 = 5) ∧
  (byte_align a + (4w:'a word) = a ⇒ w2n a MOD 8 = 4) ∧
  (byte_align a + (3w:'a word) = a ⇒ w2n a MOD 8 = 3) ∧
  (byte_align a + (2w:'a word) = a ⇒ w2n a MOD 8 = 2) ∧
  (byte_align a + (1w:'a word) = a ⇒ w2n a MOD 8 = 1) ∧
  (byte_align a = a ⇒ w2n a MOD 8 = 0)``,
  rw[]>>imp_res_tac byte_align_64_eq>>fs[]>>
  qpat_x_assum`A=a` mp_tac>>
  qabbrev_tac`ba = byte_align a`>>
  qabbrev_tac`ca = w2n a MOD 8`>>
  first_x_assum(qspec_then`a` (SUBST1_TAC o SYM))>>
  unabbrev_all_tac>>
  fs[dimword_def,addressTheory.WORD_EQ_ADD_CANCEL]>>
  Q.ISPECL_THEN[`64n`,`w2n a MOD 8`] assume_tac bitTheory.MOD_ZERO_GT>>
  fs[]>>
  Q.ISPECL_THEN [`w2n a`,`8n`] assume_tac MOD_LESS>>
  DECIDE_TAC)

val Inst_lemma = Q.prove(
  `~(asm_inst i s1).failed /\
   state_rel ((mc_conf: ('a,'state,'b) machine_config),code2,labs,p,T) s1 t1 ms1 /\
   (pos_val (s1.pc + 1) 0 code2 = pos_val s1.pc 0 code2 + LENGTH bytes') ==>
   ~(inst i t1).failed /\
    (!a. ~(a IN s1.mem_domain) ==> (inst i t1).mem a = t1.mem a) /\
   (mc_conf.target.state_rel
      (upd_pc (t1.pc + n2w (LENGTH bytes')) (inst i t1)) ms2 ==>
    state_rel (mc_conf,code2,labs,p,T)
      (inc_pc (dec_clock (asm_inst i s1)))
      (upd_pc (t1.pc + n2w (LENGTH (bytes':word8 list))) (inst i t1)) ms2)`,
  Cases_on `i` \\ full_simp_tac(srw_ss())[asm_inst_def,inst_def]
  THEN1
   (full_simp_tac(srw_ss())[state_rel_def,inc_pc_def,shift_interfer_def,upd_pc_def,dec_clock_def]
    \\ rpt strip_tac \\ rev_full_simp_tac(srw_ss())[] \\ res_tac \\ full_simp_tac(srw_ss())[GSYM word_add_n2w])
  THEN1
   (full_simp_tac(srw_ss())[state_rel_def,inc_pc_def,shift_interfer_def,upd_pc_def,
        dec_clock_def,asmSemTheory.upd_reg_def,labSemTheory.upd_reg_def]
    \\ rpt strip_tac \\ rev_full_simp_tac(srw_ss())[] \\ res_tac \\ full_simp_tac(srw_ss())[GSYM word_add_n2w]
    \\ full_simp_tac(srw_ss())[APPLY_UPDATE_THM] \\ srw_tac[][word_loc_val_def])
  THEN1
   (strip_tac >>
    conj_asm1_tac >- (
      Cases_on`a`>> full_simp_tac(srw_ss())[asmSemTheory.arith_upd_def,labSemTheory.arith_upd_def] >>
      every_case_tac >> full_simp_tac(srw_ss())[labSemTheory.assert_def] >> srw_tac[][] >>
      full_simp_tac(srw_ss())[reg_imm_def,binop_upd_def,labSemTheory.binop_upd_def] >>
      full_simp_tac(srw_ss())[upd_reg_def,labSemTheory.upd_reg_def,state_rel_def] >>
      TRY (Cases_on`b`)>>EVAL_TAC >> full_simp_tac(srw_ss())[state_rel_def] >>
      unabbrev_all_tac \\ fs[]
      \\ first_assum(qspec_then`n1`mp_tac)
      \\ first_assum(qspec_then`n2`mp_tac)
      \\ first_x_assum(qspec_then`n3`mp_tac)
      \\ simp[word_loc_val_def] \\ ntac 3 strip_tac
      \\ rveq \\ fs[asmSemTheory.read_reg_def]) >>
    srw_tac[][] >>
    simp[inc_pc_dec_clock] >>
    simp[dec_clock_def] >>
    match_mp_tac state_rel_clock >>
    full_simp_tac(srw_ss())[state_rel_def] >>
    simp[GSYM word_add_n2w] >>
    fsrw_tac[ARITH_ss][] >>
    conj_tac >- metis_tac[] >>
    conj_tac >- ( srw_tac[][] >> first_x_assum drule >> simp[] ) >>
    match_mp_tac arith_upd_lemma >> srw_tac[][])
  \\ strip_tac >>
  Cases_on`m`>>fs[mem_op_def,labSemTheory.assert_def]
  >-
    (`good_dimindex(:'a)` by fs[state_rel_def]>>
    fs[good_dimindex_def]>>
    Cases_on`a`>>last_x_assum mp_tac>>
    fs[mem_load_byte_def,labSemTheory.assert_def,labSemTheory.upd_reg_def,dec_clock_def,assert_def,read_mem_word_def_compute,mem_load_def,upd_reg_def,upd_pc_def,mem_load_byte_aux_def,labSemTheory.addr_def,addr_def,read_reg_def,labSemTheory.mem_load_def]>>
    TOP_CASE_TAC>>fs[]>>
    pop_assum mp_tac>>TOP_CASE_TAC>>fs[]>>
    ntac 2 strip_tac>>fs[state_rel_def]>>
    `t1.regs n' = c'` by
      (first_x_assum(qspec_then`n'` assume_tac)>>
      rfs[word_loc_val_def])>>
    fs[]
    >-
      (`aligned 2 x` by fs [aligned_w2n]>>
       drule aligned_2_imp>>
       disch_then (strip_assume_tac o UNDISCH)>>
      `byte_align (x+1w) ∈ s1.mem_domain ∧
       byte_align (x+2w) ∈ s1.mem_domain ∧
       byte_align (x+3w) ∈ s1.mem_domain ∧
       byte_align x ∈ s1.mem_domain` by fs[]>>
       IF_CASES_TAC>>simp[GSYM word_add_n2w]>>
       (rw[]
       >-
         metis_tac[]
       >-
         metis_tac[]
       >-
         (Cases_on`n=r`>>fs[APPLY_UPDATE_THM,word_loc_val_def]>>
          fs[asmSemTheory.read_mem_def]>>
          res_tac>>
          fs[word_loc_val_byte_def]>>
          ntac 4 (FULL_CASE_TAC>>fs[])>>
          rfs[get_byte_def,byte_index_def]>>rveq>>
          Cases_on `c + t1.regs n'`>>
          rename1 `k < dimword (:α)`>>
          drule aligned_IMP_ADD_LESS_dimword >>
          full_simp_tac std_ss [] \\ fs [] >>
          strip_tac \\ fs [word_add_n2w] >>
          rfs [ADD_MOD_EQ_LEMMA] >>
          rpt (qpat_x_assum `w2w _ = _` (mp_tac o GSYM)) >>
          imp_res_tac dimword_eq_32_imp_or_bytes >> fs [])))
    >>
      `aligned 3 x` by fs [aligned_w2n]>>
       drule aligned_3_imp>>
       disch_then (strip_assume_tac o UNDISCH)>>
      `byte_align (x+1w) ∈ s1.mem_domain ∧
       byte_align (x+2w) ∈ s1.mem_domain ∧
       byte_align (x+3w) ∈ s1.mem_domain ∧
       byte_align (x+4w) ∈ s1.mem_domain ∧
       byte_align (x+5w) ∈ s1.mem_domain ∧
       byte_align (x+6w) ∈ s1.mem_domain ∧
       byte_align (x+7w) ∈ s1.mem_domain ∧
       byte_align x ∈ s1.mem_domain` by fs[]>>
       IF_CASES_TAC>>simp[GSYM word_add_n2w]>>
       (rw[]
       >-
         metis_tac[]
       >-
         metis_tac[]
       >-
         (Cases_on`n=r`>>fs[APPLY_UPDATE_THM,word_loc_val_def]>>
          fs[asmSemTheory.read_mem_def]>>
          res_tac>>
          fs[word_loc_val_byte_def]>>
          ntac 8 (FULL_CASE_TAC>>fs[])>>
          rfs[get_byte_def,byte_index_def]>>rveq>>
          Cases_on `c + t1.regs n'`>>
          rename1 `k < dimword (:α)`>>
          drule aligned_IMP_ADD_LESS_dimword >>
          full_simp_tac std_ss [] \\ fs [] >>
          strip_tac \\ fs [word_add_n2w] >>
          rfs [ADD_MOD_EQ_LEMMA] >>
          rpt (qpat_x_assum `w2w _ = _` (mp_tac o GSYM)) >>
          imp_res_tac dimword_eq_64_imp_or_bytes >> fs [])))
  >- (*Load8*)
    (Cases_on`a`>>last_x_assum mp_tac>>
    fs[mem_load_byte_def,labSemTheory.assert_def,labSemTheory.upd_reg_def,dec_clock_def,state_rel_def,assert_def,read_mem_word_def_compute,mem_load_def,upd_reg_def,upd_pc_def,mem_load_byte_aux_def,labSemTheory.addr_def,addr_def,read_reg_def]>>
    ntac 2 (TOP_CASE_TAC>>fs[])>>
    ntac 2 (pop_assum mp_tac)>>
    ntac 2 (TOP_CASE_TAC>>fs[])>>
    ntac 2 strip_tac>>
    res_tac>>fs[word_loc_val_byte_def]>>
    FULL_CASE_TAC>>fs[]>>
    first_assum(qspec_then`n'` assume_tac)>>
    qpat_x_assum`A=Word c'` SUBST_ALL_TAC>>
    fs[word_loc_val_def,GSYM word_add_n2w,alignmentTheory.aligned_extract]>>
    rw[]
    >- metis_tac[]
    >-
      (Cases_on`n=r`>>fs[APPLY_UPDATE_THM,word_loc_val_def]>>
      fs[asmSemTheory.read_mem_def]>>
      rfs[word_loc_val_def]))
  >-
    (*Store*)
    (`good_dimindex(:'a)` by fs[state_rel_def]>>
    fs[good_dimindex_def]>>
    Cases_on`a`>>last_x_assum mp_tac>>
    fs[mem_store_byte_def,labSemTheory.assert_def,mem_store_byte_aux_def,mem_store_def,labSemTheory.addr_def,addr_def,write_mem_word_def_compute,upd_pc_def,read_reg_def,assert_def,upd_mem_def,dec_clock_def,labSemTheory.mem_store_def,read_reg_def,labSemTheory.upd_mem_def]>>
    TOP_CASE_TAC>>fs[]>>
    pop_assum mp_tac>>TOP_CASE_TAC>>fs[]>>
    ntac 2 strip_tac>>fs[state_rel_def]>>
    `t1.regs n' = c'` by
      (first_x_assum(qspec_then`n'` assume_tac)>>
      rfs[word_loc_val_def])>>
    fs[]
    >-
      (`aligned 2 x` by fs [aligned_w2n]>>
       drule aligned_2_imp>>
       disch_then (strip_assume_tac o UNDISCH)>>
       `byte_align (x+1w) ∈ s1.mem_domain ∧
       byte_align (x+2w) ∈ s1.mem_domain ∧
       byte_align (x+3w) ∈ s1.mem_domain ∧
       byte_align x ∈ s1.mem_domain` by fs[]>>
       IF_CASES_TAC>>simp[GSYM word_add_n2w]>>
       (rw[]
       >-
         (simp[APPLY_UPDATE_THM]>>
         res_tac>>fs[]>>
         rpt(IF_CASES_TAC>>fs[]))
       >-
         metis_tac[]
       >-
         metis_tac[]
       >-
         (simp[word_loc_val_byte_def,APPLY_UPDATE_THM]>>
         IF_CASES_TAC>>fs[]
         >-
           (fs[get_byte_def,byte_index_def]>>
           drule byte_align_32_IMP>>
           rpt IF_CASES_TAC>>fs[]>>
           metis_tac[byte_align_32_CASES])
         >>
           res_tac>>
           imp_res_tac aligned_2_not_eq>>fs[word_loc_val_byte_def])
       >-
         (match_mp_tac (GEN_ALL bytes_in_mem_asm_write_bytearray_lemma|>REWRITE_RULE[AND_IMP_INTRO])>>HINT_EXISTS_TAC>>fs[]>>
         rw[APPLY_UPDATE_THM]>>
         rfs[])))
     >>
       (`aligned 3 x` by fs [aligned_w2n]>>
       drule aligned_3_imp>>
       disch_then (strip_assume_tac o UNDISCH)>>
       `byte_align (x+1w) ∈ s1.mem_domain ∧
       byte_align (x+2w) ∈ s1.mem_domain ∧
       byte_align (x+3w) ∈ s1.mem_domain ∧
       byte_align (x+4w) ∈ s1.mem_domain ∧
       byte_align (x+5w) ∈ s1.mem_domain ∧
       byte_align (x+6w) ∈ s1.mem_domain ∧
       byte_align (x+7w) ∈ s1.mem_domain ∧
       byte_align x ∈ s1.mem_domain` by fs[]>>
       IF_CASES_TAC>>simp[GSYM word_add_n2w]>>
       (rw[]
       >-
         (simp[APPLY_UPDATE_THM]>>
         res_tac>>fs[]>>
         rpt(IF_CASES_TAC>>fs[]))
       >-
         metis_tac[]
       >-
         metis_tac[]
       >-
         (simp[word_loc_val_byte_def,APPLY_UPDATE_THM]>>
         IF_CASES_TAC>>fs[]
         >-
           (fs[get_byte_def,byte_index_def]>>
           drule byte_align_64_IMP>>
           rpt IF_CASES_TAC>>fs[]>>
           metis_tac[byte_align_64_CASES])
         >>
           res_tac>>
           imp_res_tac aligned_3_not_eq>>fs[word_loc_val_byte_def])
       >-
         (match_mp_tac (GEN_ALL bytes_in_mem_asm_write_bytearray_lemma|>REWRITE_RULE[AND_IMP_INTRO])>>HINT_EXISTS_TAC>>fs[]>>
         rw[APPLY_UPDATE_THM]>>
         rfs[]))))
  >-
    (Cases_on`a`>>last_x_assum mp_tac>>
    fs[mem_store_byte_def,labSemTheory.assert_def,mem_store_byte_aux_def,mem_store_def,labSemTheory.addr_def,addr_def,write_mem_word_def_compute,upd_pc_def,read_reg_def,assert_def,upd_mem_def,dec_clock_def]>>
    ntac 3 (TOP_CASE_TAC>>fs[])>>
    ntac 3 (pop_assum mp_tac)>>
    ntac 2 (TOP_CASE_TAC>>fs[])>>
    ntac 3 strip_tac>>
    fs[state_rel_def]>>
    res_tac>>fs[word_loc_val_byte_def]>>
    FULL_CASE_TAC>>fs[]>>
    first_assum(qspec_then`n'` assume_tac)>>
    qpat_x_assum`A=Word c''` SUBST_ALL_TAC>>
    fs[word_loc_val_def,GSYM word_add_n2w,alignmentTheory.aligned_extract]>>
    rw[]
    >-
      (fs[APPLY_UPDATE_THM]>>
      IF_CASES_TAC>>fs[])
    >- metis_tac[]
    >-
      (simp[APPLY_UPDATE_THM]>>
      IF_CASES_TAC>>fs[word_loc_val_def]>>
      IF_CASES_TAC>>fs[]
      >-
        (simp[get_byte_set_byte]>>
        first_x_assum(qspec_then`n` assume_tac)>>rfs[word_loc_val_def])
      >>
      simp[get_byte_set_byte_diff]>>
      first_x_assum(qspec_then`a` mp_tac)>>
      TOP_CASE_TAC>>rfs[word_loc_val_def])
    >-
      (match_mp_tac (GEN_ALL bytes_in_mem_asm_write_bytearray_lemma|>REWRITE_RULE[AND_IMP_INTRO])>>HINT_EXISTS_TAC>>fs[]>>
      rw[APPLY_UPDATE_THM]>>
      rfs[])))

val state_rel_ignore_io_events = prove(
  ``state_rel (mc_conf,code2,labs,p,T) s1 t1 ms1 ==>
    state_rel (mc_conf,code2,labs,p,T) (s1 with ffi := io) t1 ms1``,
  full_simp_tac(srw_ss())[state_rel_def] \\ rpt strip_tac
  \\ res_tac \\ rev_full_simp_tac(srw_ss())[] \\ full_simp_tac(srw_ss())[]);

val compile_correct = Q.prove(
  `!^s1 res (mc_conf: ('a,'state,'b) machine_config) s2 code2 labs t1 ms1.
     (evaluate s1 = (res,s2)) /\ (res <> Error) /\
     s1.ffi.final_event = NONE /\
     backend_correct mc_conf.target /\
     state_rel (mc_conf,code2,labs,p,T) s1 t1 ms1 ==>
     ?k t2 ms2.
       (evaluate mc_conf s1.ffi (s1.clock + k) ms1 =
          ((case s2.ffi.final_event of NONE => res
            | SOME e => Halt (FFI_outcome e)),
           ms2,s2.ffi))`,
  HO_MATCH_MP_TAC labSemTheory.evaluate_ind \\ NTAC 2 STRIP_TAC
  \\ ONCE_REWRITE_TAC [labSemTheory.evaluate_def]
  \\ Cases_on `s1.clock = 0` \\ full_simp_tac(srw_ss())[]
  \\ REPEAT (Q.PAT_X_ASSUM `T` (K ALL_TAC)) \\ REPEAT STRIP_TAC
  THEN1 (Q.EXISTS_TAC `0` \\ full_simp_tac(srw_ss())[Once targetSemTheory.evaluate_def]
         \\ metis_tac [state_rel_weaken])
  \\ Cases_on `asm_fetch s1` \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `x` \\ full_simp_tac(srw_ss())[] \\ Cases_on `a` \\ full_simp_tac(srw_ss())[]
  \\ REPEAT (Q.PAT_X_ASSUM `T` (K ALL_TAC)) \\ full_simp_tac(srw_ss())[LET_DEF]
  THEN1 (* Asm Inst *)
   (qmatch_assum_rename_tac `asm_fetch s1 = SOME (Asm (Inst i) bytes len)`
    \\ mp_tac IMP_bytes_in_memory_Inst \\ full_simp_tac(srw_ss())[]
    \\ match_mp_tac IMP_IMP \\ strip_tac
    THEN1 (full_simp_tac(srw_ss())[state_rel_def] \\ imp_res_tac bytes_in_mem_IMP \\ full_simp_tac(srw_ss())[])
    \\ rpt strip_tac \\ pop_assum mp_tac \\ pop_assum mp_tac
    \\ qpat_abbrev_tac `jj = asm$Inst i` \\ rpt strip_tac
    \\ (Q.ISPECL_THEN [`mc_conf`,`t1`,`ms1`,`s1.ffi`,`jj`]MP_TAC
         asm_step_IMP_evaluate_step_nop) \\ full_simp_tac(srw_ss())[]
    \\ strip_tac \\ pop_assum (mp_tac o Q.SPEC `bytes'`)
    \\ `~(asm_inst i s1).failed` by (rpt strip_tac \\ full_simp_tac(srw_ss())[])
    \\ MATCH_MP_TAC IMP_IMP \\ STRIP_TAC THEN1
     (imp_res_tac Inst_lemma \\ pop_assum (K all_tac)
      \\ full_simp_tac(srw_ss())[state_rel_def,asm_def,LET_DEF] \\ unabbrev_all_tac \\ full_simp_tac(srw_ss())[]
      \\ full_simp_tac(srw_ss())[asm_step_nop_def,asm_def,LET_DEF]
      \\ full_simp_tac(srw_ss())[asm_def,upd_pc_def,upd_reg_def]
      \\ qpat_x_assum `bytes_in_mem ww bytes' t1.mem
            t1.mem_domain s1.mem_domain` mp_tac
      \\ match_mp_tac bytes_in_mem_IMP_memory \\ full_simp_tac(srw_ss())[])
    \\ rpt strip_tac \\ full_simp_tac(srw_ss())[]
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`shift_interfer l mc_conf`,
         `code2`,`labs`,
         `(asm jj (t1.pc + n2w (LENGTH (bytes':word8 list))) t1)`,`ms2`])
    \\ MATCH_MP_TAC IMP_IMP \\ STRIP_TAC THEN1
     (unabbrev_all_tac \\ rpt strip_tac \\ full_simp_tac(srw_ss())[asm_def]
      THEN1 (full_simp_tac(srw_ss())[inc_pc_def,dec_clock_def,asm_inst_consts])
      THEN1 (full_simp_tac(srw_ss())[shift_interfer_def])
      \\ full_simp_tac(srw_ss())[GSYM PULL_FORALL]
      \\ match_mp_tac state_rel_shift_interfer
      \\ imp_res_tac Inst_lemma \\ full_simp_tac(srw_ss())[])
    \\ rpt strip_tac \\ full_simp_tac(srw_ss())[inc_pc_def,dec_clock_def,labSemTheory.upd_reg_def]
    \\ FIRST_X_ASSUM (Q.SPEC_THEN `s1.clock - 1 + k` mp_tac)
    \\ rpt strip_tac
    \\ Q.EXISTS_TAC `k + l - 1` \\ full_simp_tac(srw_ss())[]
    \\ `^s1.clock - 1 + k + l = ^s1.clock + (k + l - 1)` by decide_tac
    \\ full_simp_tac(srw_ss())[asm_inst_consts])
  THEN1 (* Asm JumpReg *)
   (Cases_on `read_reg n' s1` \\ full_simp_tac(srw_ss())[]
    \\ qmatch_assum_rename_tac `read_reg r1 s1 = Loc l1 l2`
    \\ Cases_on `loc_to_pc l1 l2 s1.code` \\ full_simp_tac(srw_ss())[]
    \\ (Q.ISPECL_THEN [`mc_conf`,`t1`,`ms1`, `s1.ffi`, `JumpReg r1`]MP_TAC
         asm_step_IMP_evaluate_step) \\ full_simp_tac(srw_ss())[]
    \\ MATCH_MP_TAC IMP_IMP \\ STRIP_TAC THEN1
     (full_simp_tac(srw_ss())[state_rel_def,asm_def,LET_DEF]
      \\ full_simp_tac(srw_ss())[asm_step_def,asm_def,LET_DEF]
      \\ imp_res_tac bytes_in_mem_IMP
      \\ full_simp_tac(srw_ss())[IMP_bytes_in_memory_JumpReg,asmSemTheory.upd_pc_def,
             asmSemTheory.assert_def]
      \\ imp_res_tac IMP_bytes_in_memory_JumpReg \\ full_simp_tac(srw_ss())[]
      \\ full_simp_tac(srw_ss())[asmSemTheory.read_reg_def]
      \\ full_simp_tac(srw_ss())[interference_ok_def,shift_seq_def]
      \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `r1:num`)
      \\ strip_tac \\ rev_full_simp_tac(srw_ss())[]
      \\ full_simp_tac(srw_ss())[word_loc_val_def]
      \\ Cases_on `lab_lookup l1 l2 labs` \\ full_simp_tac(srw_ss())[]
      \\ Q.PAT_X_ASSUM `xx = t1.regs r1` (fn th => full_simp_tac(srw_ss())[GSYM th])
      \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`l1`,`l2`]) \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
      \\ full_simp_tac(srw_ss())[alignmentTheory.aligned_bitwise_and]
      \\ match_mp_tac pos_val_MOD_0 \\ full_simp_tac(srw_ss())[])
    \\ rpt strip_tac
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`shift_interfer l' mc_conf`,
         `code2`,`labs`,`(asm (JumpReg r1)
            (t1.pc + n2w (LENGTH (mc_conf.target.config.encode (JumpReg r1)))) t1)`,`ms2`])
    \\ MATCH_MP_TAC IMP_IMP \\ STRIP_TAC THEN1
     (full_simp_tac(srw_ss())[shift_interfer_def,state_rel_def,asm_def,LET_DEF] \\ rev_full_simp_tac(srw_ss())[]
      \\ full_simp_tac(srw_ss())[asmSemTheory.upd_pc_def,asmSemTheory.assert_def,
             asmSemTheory.read_reg_def,dec_clock_def,labSemTheory.upd_pc_def,
             labSemTheory.assert_def]
      \\ full_simp_tac(srw_ss())[interference_ok_def,shift_seq_def]
      \\ FIRST_X_ASSUM (K ALL_TAC o Q.SPEC `r1:num`)
      \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `r1:num`)
      \\ strip_tac \\ rev_full_simp_tac(srw_ss())[]
      \\ full_simp_tac(srw_ss())[word_loc_val_def]
      \\ Cases_on `lab_lookup l1 l2 labs` \\ full_simp_tac(srw_ss())[]
      \\ Q.PAT_X_ASSUM `xx = t1.regs r1` (fn th => full_simp_tac(srw_ss())[GSYM th])
      \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`l1`,`l2`]) \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
      \\ RES_TAC \\ full_simp_tac(srw_ss())[] \\ rpt strip_tac \\ res_tac \\ srw_tac[][]
      \\ full_simp_tac(srw_ss())[alignmentTheory.aligned_bitwise_and]
      \\ match_mp_tac pos_val_MOD_0 \\ full_simp_tac(srw_ss())[])
    \\ rpt strip_tac
    \\ FIRST_X_ASSUM (Q.SPEC_THEN `s1.clock - 1 + k`MP_TAC) \\ srw_tac[][]
    \\ `s1.clock - 1 + k + l' = s1.clock + (k + l' - 1)` by DECIDE_TAC
    \\ Q.EXISTS_TAC `k + l' - 1` \\ full_simp_tac(srw_ss())[]
    \\ Q.EXISTS_TAC `t2` \\ full_simp_tac(srw_ss())[state_rel_def,shift_interfer_def])
  THEN1 (* Jump *)
   (qmatch_assum_rename_tac
         `asm_fetch s1 = SOME (LabAsm (Jump jtarget) l1 l2 l3)`
    \\ qmatch_assum_rename_tac
         `asm_fetch s1 = SOME (LabAsm (Jump jtarget) l bytes n)`
    \\ Cases_on `get_pc_value jtarget s1` \\ full_simp_tac(srw_ss())[]
    \\ mp_tac IMP_bytes_in_memory_Jump \\ full_simp_tac(srw_ss())[]
    \\ match_mp_tac IMP_IMP \\ strip_tac
    THEN1 (full_simp_tac(srw_ss())[state_rel_def] \\ imp_res_tac bytes_in_mem_IMP \\ full_simp_tac(srw_ss())[])
    \\ rpt strip_tac \\ pop_assum mp_tac
    \\ qpat_abbrev_tac `jj = asm$Jump lll` \\ rpt strip_tac
    \\ (Q.ISPECL_THEN [`mc_conf`,`t1`,`ms1`,`s1.ffi`,`jj`]MP_TAC
         asm_step_IMP_evaluate_step) \\ full_simp_tac(srw_ss())[]
    \\ MATCH_MP_TAC IMP_IMP \\ STRIP_TAC THEN1
     (full_simp_tac(srw_ss())[state_rel_def,asm_def,LET_DEF]
      \\ full_simp_tac(srw_ss())[asm_step_def,asm_def,LET_DEF]
      \\ imp_res_tac bytes_in_mem_IMP
      \\ full_simp_tac(srw_ss())[asmSemTheory.jump_to_offset_def,asmSemTheory.upd_pc_def]
      \\ rev_full_simp_tac(srw_ss())[] \\ unabbrev_all_tac
      \\ full_simp_tac(srw_ss())[asmSemTheory.jump_to_offset_def,asmSemTheory.upd_pc_def,asm_def])
    \\ rpt strip_tac
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`shift_interfer l' mc_conf`,
         `code2`,`labs`,
         `(asm jj (t1.pc + n2w (LENGTH (mc_conf.target.config.encode jj))) t1)`,`ms2`])
    \\ MATCH_MP_TAC IMP_IMP \\ STRIP_TAC THEN1
     (unabbrev_all_tac
      \\ full_simp_tac(srw_ss())[shift_interfer_def,state_rel_def,asm_def,LET_DEF] \\ rev_full_simp_tac(srw_ss())[]
      \\ full_simp_tac(srw_ss())[asmSemTheory.upd_pc_def,asmSemTheory.assert_def,
             asmSemTheory.read_reg_def, dec_clock_def,labSemTheory.upd_pc_def,
             labSemTheory.assert_def,asm_def,
             jump_to_offset_def]
      \\ full_simp_tac(srw_ss())[interference_ok_def,shift_seq_def,read_reg_def]
      \\ rewrite_tac [GSYM word_add_n2w,GSYM word_sub_def,WORD_SUB_PLUS,
            WORD_ADD_SUB] \\ full_simp_tac(srw_ss())[get_pc_value_def]
      \\ Cases_on `jtarget` \\ full_simp_tac(srw_ss())[]
      \\ qmatch_assum_rename_tac `loc_to_pc l1 l2 s1.code = SOME x`
      \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`l1`,`l2`]) \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
      \\ imp_res_tac lab_lookup_IMP \\ full_simp_tac(srw_ss())[] \\ metis_tac [])
    \\ rpt strip_tac
    \\ FIRST_X_ASSUM (Q.SPEC_THEN `s1.clock - 1 + k`MP_TAC) \\ srw_tac[][]
    \\ `s1.clock - 1 + k + l' = s1.clock + (k + l' - 1)` by DECIDE_TAC
    \\ Q.EXISTS_TAC `k + l' - 1` \\ full_simp_tac(srw_ss())[]
    \\ Q.EXISTS_TAC `t2` \\ full_simp_tac(srw_ss())[state_rel_def,shift_interfer_def])
  THEN1 (* JumpCmp *)
   (qmatch_assum_rename_tac
         `asm_fetch s1 = SOME (LabAsm (JumpCmp cmp rr ri jtarget) l1 l2 l3)`
    \\ qmatch_assum_rename_tac
         `asm_fetch s1 = SOME (LabAsm (JumpCmp cmp rr ri jtarget) l bytes n)`
    \\ `word_cmp cmp (read_reg rr s1) (labSem$reg_imm ri s1) =
        SOME (asmSem$word_cmp cmp (read_reg rr t1) (reg_imm ri t1))` by
     (Cases_on `word_cmp cmp (read_reg rr s1) (reg_imm ri s1)` \\ full_simp_tac(srw_ss())[]
      \\ imp_res_tac word_cmp_lemma \\ full_simp_tac(srw_ss())[])
    \\ full_simp_tac(srw_ss())[]
    \\ Cases_on `word_cmp cmp (read_reg rr t1) (reg_imm ri t1)` \\ full_simp_tac(srw_ss())[]
    THEN1
     (Cases_on `get_pc_value jtarget s1` \\ full_simp_tac(srw_ss())[]
      \\ mp_tac IMP_bytes_in_memory_JumpCmp \\ full_simp_tac(srw_ss())[]
      \\ match_mp_tac IMP_IMP \\ strip_tac
      THEN1 (full_simp_tac(srw_ss())[state_rel_def] \\ imp_res_tac bytes_in_mem_IMP \\ full_simp_tac(srw_ss())[])
      \\ rpt strip_tac \\ pop_assum mp_tac
      \\ qpat_abbrev_tac `jj = asm$JumpCmp cmp rr ri lll` \\ rpt strip_tac
      \\ (Q.ISPECL_THEN [`mc_conf`,`t1`,`ms1`,`s1.ffi`,`jj`]mp_tac
           asm_step_IMP_evaluate_step) \\ full_simp_tac(srw_ss())[]
      \\ MATCH_MP_TAC IMP_IMP \\ STRIP_TAC THEN1
       (full_simp_tac(srw_ss())[state_rel_def,asm_def,LET_DEF]
        \\ unabbrev_all_tac \\ full_simp_tac(srw_ss())[asm_step_def,asm_def,LET_DEF]
        \\ imp_res_tac bytes_in_mem_IMP
        \\ full_simp_tac(srw_ss())[asmSemTheory.jump_to_offset_def,asmSemTheory.upd_pc_def]
        \\ rev_full_simp_tac(srw_ss())[] \\ unabbrev_all_tac
        \\ full_simp_tac(srw_ss())[asmSemTheory.jump_to_offset_def,asmSemTheory.upd_pc_def,asm_def])
      \\ rpt strip_tac
      \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`shift_interfer l' mc_conf`,
           `code2`,`labs`,
           `(asm jj (t1.pc + n2w (LENGTH (mc_conf.target.config.encode jj))) t1)`,`ms2`])
      \\ MATCH_MP_TAC IMP_IMP \\ STRIP_TAC THEN1
       (unabbrev_all_tac
        \\ full_simp_tac(srw_ss())[shift_interfer_def,state_rel_def,asm_def,LET_DEF] \\ rev_full_simp_tac(srw_ss())[]
        \\ full_simp_tac(srw_ss())[asmSemTheory.upd_pc_def,asmSemTheory.assert_def,
               asmSemTheory.read_reg_def, dec_clock_def,labSemTheory.upd_pc_def,
               labSemTheory.assert_def,asm_def,
               jump_to_offset_def]
        \\ full_simp_tac(srw_ss())[interference_ok_def,shift_seq_def,read_reg_def]
        \\ rewrite_tac [GSYM word_add_n2w,GSYM word_sub_def,WORD_SUB_PLUS,
              WORD_ADD_SUB] \\ full_simp_tac(srw_ss())[get_pc_value_def]
        \\ Cases_on `jtarget` \\ full_simp_tac(srw_ss())[]
        \\ qmatch_assum_rename_tac `loc_to_pc l1 l2 s1.code = SOME x`
        \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`l1`,`l2`]) \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
        \\ imp_res_tac lab_lookup_IMP \\ full_simp_tac(srw_ss())[] \\ metis_tac [])
      \\ rpt strip_tac
      \\ FIRST_X_ASSUM (Q.SPEC_THEN `s1.clock - 1 + k`MP_TAC) \\ srw_tac[][]
      \\ `s1.clock - 1 + k + l' = s1.clock + (k + l' - 1)` by DECIDE_TAC
      \\ Q.EXISTS_TAC `k + l' - 1` \\ full_simp_tac(srw_ss())[]
      \\ Q.EXISTS_TAC `t2` \\ full_simp_tac(srw_ss())[state_rel_def,shift_interfer_def])
    \\ mp_tac (IMP_bytes_in_memory_JumpCmp_1) \\ full_simp_tac(srw_ss())[]
    \\ match_mp_tac IMP_IMP \\ strip_tac
    THEN1 (full_simp_tac(srw_ss())[state_rel_def] \\ imp_res_tac bytes_in_mem_IMP \\ full_simp_tac(srw_ss())[])
    \\ rpt strip_tac \\ pop_assum mp_tac \\ pop_assum mp_tac
    \\ qpat_abbrev_tac `jj = asm$JumpCmp cmp rr ri lll` \\ rpt strip_tac
    \\ (Q.ISPECL_THEN [`mc_conf`,`t1`,`ms1`,`s1.ffi`,`jj`]mp_tac
         asm_step_IMP_evaluate_step_nop) \\ full_simp_tac(srw_ss())[]
    \\ strip_tac \\ pop_assum (mp_tac o Q.SPEC `bytes'`)
    \\ MATCH_MP_TAC IMP_IMP \\ STRIP_TAC THEN1
     (full_simp_tac(srw_ss())[state_rel_def,asm_def,LET_DEF] \\ unabbrev_all_tac \\ full_simp_tac(srw_ss())[]
      \\ full_simp_tac(srw_ss())[asm_step_nop_def,asm_def,LET_DEF]
      \\ full_simp_tac(srw_ss())[asm_def,upd_pc_def,upd_reg_def])
    \\ rpt strip_tac
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`shift_interfer l' mc_conf`,
         `code2`,`labs`,
         `(asm jj (t1.pc + n2w (LENGTH (bytes':word8 list))) t1)`,`ms2`])
    \\ MATCH_MP_TAC IMP_IMP \\ STRIP_TAC THEN1
     (unabbrev_all_tac
      \\ full_simp_tac(srw_ss())[shift_interfer_def,state_rel_def,asm_def,LET_DEF] \\ rev_full_simp_tac(srw_ss())[]
      \\ full_simp_tac(srw_ss())[asmSemTheory.upd_pc_def,asmSemTheory.assert_def,
             asmSemTheory.read_reg_def, dec_clock_def,labSemTheory.upd_pc_def,
             labSemTheory.assert_def,asm_def,
             jump_to_offset_def,inc_pc_def,asmSemTheory.upd_reg_def,
             labSemTheory.upd_reg_def]
      \\ full_simp_tac(srw_ss())[interference_ok_def,shift_seq_def,read_reg_def]
      \\ rewrite_tac [GSYM word_add_n2w,GSYM word_sub_def,WORD_SUB_PLUS,
            WORD_ADD_SUB] \\ full_simp_tac(srw_ss())[get_pc_value_def]
      \\ rpt strip_tac \\ res_tac \\ full_simp_tac(srw_ss())[])
    \\ rpt strip_tac \\ full_simp_tac(srw_ss())[inc_pc_def,dec_clock_def,labSemTheory.upd_reg_def]
    \\ FIRST_X_ASSUM (Q.SPEC_THEN `s1.clock - 1 + k`mp_tac)
    \\ rpt strip_tac
    \\ Q.EXISTS_TAC `k + l' - 1` \\ full_simp_tac(srw_ss())[]
    \\ `s1.clock - 1 + k + l' = s1.clock + (k + l' - 1)` by decide_tac \\ full_simp_tac(srw_ss())[])
  THEN1 (* Call *)
   (qmatch_assum_rename_tac
         `asm_fetch s1 = SOME (LabAsm (Call lab) x1 x2 x3)`
    \\ Cases_on `lab`
    \\ qmatch_assum_rename_tac
         `asm_fetch s1 = SOME (LabAsm (Call (Lab l1 l2)) l bytes len)`
    \\ (Q.SPECL_THEN [`Lab l1 l2`,`len`]mp_tac
            (Q.GENL[`n`,`ww`]IMP_bytes_in_memory_Call))
    \\ match_mp_tac IMP_IMP \\ strip_tac \\ full_simp_tac(srw_ss())[]
    \\ full_simp_tac(srw_ss())[state_rel_def] \\ imp_res_tac bytes_in_mem_IMP \\ full_simp_tac(srw_ss())[])
  THEN1 (* LocValue *)
   (qmatch_assum_rename_tac
         `asm_fetch s1 = SOME (LabAsm (LocValue reg lab) x1 x2 x3)`
    \\ Cases_on `lab`
    \\ qmatch_assum_rename_tac
         `asm_fetch s1 = SOME (LabAsm (LocValue reg (Lab l1 l2)) ww bytes len)`
    \\ full_simp_tac(srw_ss())[lab_to_loc_def]
    \\ mp_tac (Q.INST [`l`|->`ww`,`n`|->`len`]
               IMP_bytes_in_memory_LocValue) \\ full_simp_tac(srw_ss())[]
    \\ match_mp_tac IMP_IMP \\ strip_tac
    THEN1 (full_simp_tac(srw_ss())[state_rel_def]
           \\ imp_res_tac bytes_in_mem_IMP \\ full_simp_tac(srw_ss())[])
    \\ rpt strip_tac \\ pop_assum mp_tac
    \\ Cases_on `get_pc_value (Lab l1 l2) s1` \\ fs []
    \\ qpat_abbrev_tac `jj = asm$Loc reg lll` \\ rpt strip_tac
    \\ (Q.ISPECL_THEN [`mc_conf`,`t1`,`ms1`,`s1.ffi`,`jj`]mp_tac
         asm_step_IMP_evaluate_step_nop) \\ full_simp_tac(srw_ss())[]
    \\ strip_tac \\ pop_assum (mp_tac o Q.SPEC `bytes'`)
    \\ MATCH_MP_TAC IMP_IMP \\ STRIP_TAC THEN1
     (full_simp_tac(srw_ss())[state_rel_def,asm_def,LET_DEF]
      \\ unabbrev_all_tac \\ full_simp_tac(srw_ss())[]
      \\ full_simp_tac(srw_ss())[asm_step_nop_def,asm_def,LET_DEF]
      \\ full_simp_tac(srw_ss())[asm_def,upd_pc_def,upd_reg_def])
    \\ rpt strip_tac
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`shift_interfer l mc_conf`,
         `code2`,`labs`,
         `(asm jj (t1.pc + n2w (LENGTH (bytes':word8 list))) t1)`,`ms2`])
    \\ MATCH_MP_TAC IMP_IMP \\ STRIP_TAC THEN1
     (unabbrev_all_tac
      \\ full_simp_tac(srw_ss())[shift_interfer_def,state_rel_def,asm_def,LET_DEF]
      \\ rev_full_simp_tac(srw_ss())[]
      \\ full_simp_tac(srw_ss())[asmSemTheory.upd_pc_def,asmSemTheory.assert_def,
             asmSemTheory.read_reg_def, dec_clock_def,labSemTheory.upd_pc_def,
             labSemTheory.assert_def,asm_def,
             jump_to_offset_def,inc_pc_def,asmSemTheory.upd_reg_def,
             labSemTheory.upd_reg_def]
      \\ full_simp_tac(srw_ss())[interference_ok_def,shift_seq_def,read_reg_def]
      \\ rewrite_tac [GSYM word_add_n2w,GSYM word_sub_def,WORD_SUB_PLUS,
            WORD_ADD_SUB] \\ full_simp_tac(srw_ss())[get_pc_value_def]
      \\ full_simp_tac(srw_ss())[APPLY_UPDATE_THM] \\ srw_tac[][word_loc_val_def]
      \\ res_tac \\ full_simp_tac(srw_ss())[]
      \\ Cases_on `lab_lookup l1 l2 labs` \\ full_simp_tac(srw_ss())[]
      \\ imp_res_tac lab_lookup_IMP \\ srw_tac[][])
    \\ rpt strip_tac
    \\ full_simp_tac(srw_ss())[inc_pc_def,dec_clock_def,labSemTheory.upd_reg_def]
    \\ FIRST_X_ASSUM (Q.SPEC_THEN`s1.clock - 1 + k`mp_tac)
    \\ rpt strip_tac
    \\ Q.EXISTS_TAC `k + l - 1` \\ fs[]
    \\ `s1.clock - 1 + k + l = k + (l + s1.clock) − 1` by decide_tac \\ fs [])
  THEN1 (* CallFFI *)
   (qmatch_assum_rename_tac `asm_fetch s1 = SOME (LabAsm (CallFFI n') l1 l2 l3)`
    \\ qmatch_assum_rename_tac
         `asm_fetch s1 = SOME (LabAsm (CallFFI index) l bytes n)`
    \\ Cases_on `s1.regs s1.len_reg` \\ full_simp_tac(srw_ss())[]
    \\ Cases_on `s1.regs s1.link_reg` \\ full_simp_tac(srw_ss())[]
    \\ Cases_on `s1.regs s1.ptr_reg` \\ full_simp_tac(srw_ss())[]
    \\ Cases_on `read_bytearray c' (w2n c) (mem_load_byte_aux s1.mem s1.mem_domain s1.be)`
    \\ full_simp_tac(srw_ss())[]
    \\ qmatch_assum_rename_tac
         `read_bytearray c1 (w2n c2) (mem_load_byte_aux s1.mem s1.mem_domain s1.be) = SOME x`
    \\ qmatch_assum_rename_tac `s1.regs s1.link_reg = Loc n1 n2`
    \\ Cases_on `call_FFI s1.ffi index x` \\ full_simp_tac(srw_ss())[]
    \\ qmatch_assum_rename_tac
         `call_FFI s1.ffi index x = (new_ffi,new_bytes)`
    \\ mp_tac IMP_bytes_in_memory_CallFFI \\ full_simp_tac(srw_ss())[]
    \\ match_mp_tac IMP_IMP \\ strip_tac
    THEN1 (full_simp_tac(srw_ss())[state_rel_def]
           \\ imp_res_tac bytes_in_mem_IMP \\ full_simp_tac(srw_ss())[])
    \\ rpt strip_tac \\ pop_assum mp_tac
    \\ qpat_abbrev_tac `jj = asm$Jump lll` \\ rpt strip_tac
    \\ (Q.ISPECL_THEN [`mc_conf`,`t1`,`ms1`,`s1.ffi`,`jj`]mp_tac
         asm_step_IMP_evaluate_step) \\ full_simp_tac(srw_ss())[]
    \\ MATCH_MP_TAC IMP_IMP \\ STRIP_TAC THEN1
     (full_simp_tac(srw_ss())[state_rel_def,asm_def,LET_DEF]
      \\ full_simp_tac(srw_ss())[asm_step_def,asm_def,LET_DEF]
      \\ imp_res_tac bytes_in_mem_IMP
      \\ full_simp_tac(srw_ss())[asmSemTheory.jump_to_offset_def,
           asmSemTheory.upd_pc_def]
      \\ rev_full_simp_tac(srw_ss())[] \\ unabbrev_all_tac
      \\ full_simp_tac(srw_ss())[asmSemTheory.jump_to_offset_def,
           asmSemTheory.upd_pc_def,asm_def])
    \\ rpt strip_tac
    \\ Cases_on `loc_to_pc n1 n2 s1.code` \\ full_simp_tac(srw_ss())[]
    \\ qmatch_assum_rename_tac `loc_to_pc n1 n2 s1.code = SOME new_pc`
    \\ `mc_conf.target.get_pc ms2 = p - n2w ((3 + index) * ffi_offset)` by
     (full_simp_tac(srw_ss())[GSYM PULL_FORALL]
      \\ full_simp_tac(srw_ss())[state_rel_def] \\ rev_full_simp_tac(srw_ss())[]
      \\ full_simp_tac(srw_ss())[backend_correct_def,target_ok_def]
      \\ Q.PAT_X_ASSUM `!ms s. mc_conf.target.state_rel s ms ==> bbb` imp_res_tac
      \\ full_simp_tac(srw_ss())[] \\ unabbrev_all_tac
      \\ full_simp_tac(srw_ss())[asm_def,asmSemTheory.jump_to_offset_def,
           asmSemTheory.upd_pc_def]
      \\ rewrite_tac [GSYM word_sub_def,WORD_SUB_PLUS,
           GSYM word_add_n2w,WORD_ADD_SUB]) \\ full_simp_tac(srw_ss())[]
    \\ `has_io_index index s1.code` by
          (imp_res_tac IMP_has_io_index \\ NO_TAC)
    \\ `~(mc_conf.target.get_pc ms2 IN mc_conf.prog_addresses) /\
        ~(mc_conf.target.get_pc ms2 = mc_conf.halt_pc) /\
        (find_index (mc_conf.target.get_pc ms2) mc_conf.ffi_entry_pcs 0 =
           SOME index)` by
      (full_simp_tac(srw_ss())[state_rel_def]
       \\ Q.PAT_X_ASSUM `!kk. has_io_index kk s1.code ==> bbb` imp_res_tac
       \\ rev_full_simp_tac(srw_ss())[] \\ NO_TAC)
    \\ `(mc_conf.target.get_reg ms2 mc_conf.ptr_reg = t1.regs mc_conf.ptr_reg) /\
        (mc_conf.target.get_reg ms2 mc_conf.len_reg = t1.regs mc_conf.len_reg) /\
        !a. a IN mc_conf.prog_addresses ==>
            (mc_conf.target.get_byte ms2 a = t1.mem a)` by
     (full_simp_tac(srw_ss())[GSYM PULL_FORALL]
      \\ full_simp_tac(srw_ss())[state_rel_def] \\ rev_full_simp_tac(srw_ss())[]
      \\ full_simp_tac(srw_ss())[backend_correct_def,target_ok_def]
      \\ Q.PAT_X_ASSUM `!ms s. mc_conf.target.state_rel s ms ==> bbb` imp_res_tac
      \\ full_simp_tac(srw_ss())[backend_correct_def |> REWRITE_RULE [GSYM reg_ok_def]]
      \\ unabbrev_all_tac \\ full_simp_tac(srw_ss())[state_rel_def,asm_def,
           jump_to_offset_def,asmSemTheory.upd_pc_def,AND_IMP_INTRO]
      \\ rpt strip_tac \\ first_x_assum match_mp_tac
      \\ full_simp_tac(srw_ss())[reg_ok_def] \\ NO_TAC)
    \\ full_simp_tac(srw_ss())[]
    \\ `(t1.regs mc_conf.ptr_reg = c1) /\
        (t1.regs mc_conf.len_reg = c2)` by
     (full_simp_tac(srw_ss())[state_rel_def]
      \\ Q.PAT_X_ASSUM `!r. word_loc_val p labs (s1.regs r) = SOME (t1.regs r)`
           (fn th =>
          MP_TAC (Q.SPEC `(mc_conf: ('a,'state,'b) machine_config).ptr_reg` th)
          \\ MP_TAC (Q.SPEC `(mc_conf: ('a,'state,'b) machine_config).len_reg` th))
      \\ Q.PAT_X_ASSUM `xx = s1.ptr_reg` (ASSUME_TAC o GSYM)
      \\ Q.PAT_X_ASSUM `xx = s1.len_reg` (ASSUME_TAC o GSYM)
      \\ full_simp_tac(srw_ss())[word_loc_val_def] \\ NO_TAC)
    \\ full_simp_tac(srw_ss())[]
    \\ imp_res_tac read_bytearray_state_rel \\ full_simp_tac(srw_ss())[]
    \\ reverse(Cases_on `new_ffi.final_event = NONE`) THEN1
     (imp_res_tac evaluate_pres_final_event \\ full_simp_tac(srw_ss())[]
      \\ rev_full_simp_tac(srw_ss())[]
      \\ FIRST_X_ASSUM (Q.SPEC_THEN `s1.clock`mp_tac) \\ rpt strip_tac
      \\ Q.EXISTS_TAC `l'` \\ full_simp_tac(srw_ss())[ADD_ASSOC]
      \\ once_rewrite_tac [targetSemTheory.evaluate_def]
      \\ full_simp_tac(srw_ss())[]
      \\ full_simp_tac(srw_ss())[shift_interfer_def,LET_DEF]
      \\ BasicProvers.CASE_TAC >> full_simp_tac(srw_ss())[])
      \\ full_simp_tac(srw_ss())[]
    \\ FIRST_X_ASSUM (Q.SPECL_THEN [
         `shift_interfer l' mc_conf with
          ffi_interfer := shift_seq 1 mc_conf.ffi_interfer`,
         `code2`,`labs`,
         `t1 with <| pc := p + n2w (pos_val new_pc 0 (code2:'a sec list)) ;
                     mem := asm_write_bytearray c1 new_bytes t1.mem ;
                     regs := \a. get_reg_value (s1.io_regs 0 a) (t1.regs a) I |>`,
         `mc_conf.ffi_interfer 0 index new_bytes ms2`]mp_tac)
    \\ MATCH_MP_TAC IMP_IMP \\ STRIP_TAC THEN1
     (rpt strip_tac
      THEN1 (full_simp_tac(srw_ss())[backend_correct_def,shift_interfer_def]
             \\ metis_tac [])
      \\ unabbrev_all_tac
      \\ imp_res_tac bytes_in_mem_asm_write_bytearray
      \\ full_simp_tac(srw_ss())[state_rel_def,shift_interfer_def,
             asm_def,jump_to_offset_def,
             asmSemTheory.upd_pc_def] \\ rev_full_simp_tac(srw_ss())[]
      \\ rewrite_tac [GSYM word_add_n2w,GSYM word_sub_def,WORD_SUB_PLUS,
            WORD_ADD_SUB] \\ full_simp_tac(srw_ss())[get_pc_value_def]
      \\ full_simp_tac bool_ss [GSYM word_add_n2w,GSYM word_sub_def,WORD_SUB_PLUS,
            WORD_ADD_SUB] \\ full_simp_tac(srw_ss())[get_pc_value_def]
      \\ `interference_ok (shift_seq l' mc_conf.next_interfer)
            (mc_conf.target.proj t1.mem_domain)` by
               (full_simp_tac(srw_ss())[interference_ok_def,shift_seq_def]
                \\ NO_TAC) \\ full_simp_tac(srw_ss())[]
      \\ `p + n2w (pos_val new_pc 0 code2) = t1.regs s1.link_reg` by
       (Q.PAT_X_ASSUM `!r. word_loc_val p labs (s1.regs r) = SOME (t1.regs r)`
           (Q.SPEC_THEN `s1.link_reg`mp_tac)
        \\ full_simp_tac(srw_ss())[word_loc_val_def]
        \\ Cases_on `lab_lookup n1 n2 labs` \\ full_simp_tac(srw_ss())[]
        \\ ONCE_REWRITE_TAC [EQ_SYM_EQ] \\ full_simp_tac(srw_ss())[]
        \\ res_tac \\ full_simp_tac(srw_ss())[]) \\ full_simp_tac(srw_ss())[]
      \\ `w2n c2 = LENGTH new_bytes` by
       (imp_res_tac read_bytearray_LENGTH
        \\ imp_res_tac call_FFI_LENGTH \\ full_simp_tac(srw_ss())[])
      \\ res_tac \\ full_simp_tac(srw_ss())[] \\ rpt strip_tac
      THEN1
       (full_simp_tac(srw_ss())[PULL_FORALL,AND_IMP_INTRO]
        \\ rev_full_simp_tac(srw_ss())[]
        \\ Q.PAT_X_ASSUM `t1.regs s1.ptr_reg = c1` (ASSUME_TAC o GSYM)
        \\ full_simp_tac(srw_ss())[] \\ first_x_assum match_mp_tac
        \\ full_simp_tac(srw_ss())[] \\ qexists_tac `new_io`
        \\ full_simp_tac(srw_ss())[option_ldrop_0])
      THEN1
       (full_simp_tac(srw_ss())[shift_seq_def,PULL_FORALL,AND_IMP_INTRO])
      THEN1 res_tac
      THEN1
       (Cases_on `s1.io_regs 0 r`
        \\ full_simp_tac(srw_ss())[get_reg_value_def,word_loc_val_def])
      \\ qpat_x_assum `!a.
           byte_align a IN s1.mem_domain ==> bbb` (MP_TAC o Q.SPEC `a`)
      \\ full_simp_tac(srw_ss())[] \\ REPEAT STRIP_TAC
      \\ match_mp_tac (SIMP_RULE std_ss [] CallFFI_bytearray_lemma)
      \\ full_simp_tac(srw_ss())[])
    \\ rpt strip_tac
    \\ FIRST_X_ASSUM (Q.SPEC_THEN `s1.clock + k`mp_tac) \\ rpt strip_tac
    \\ Q.EXISTS_TAC `k + l'` \\ full_simp_tac(srw_ss())[ADD_ASSOC]
    \\ Q.LIST_EXISTS_TAC [`ms2'`] \\ full_simp_tac(srw_ss())[]
    \\ simp_tac std_ss [Once evaluate_def]
    \\ full_simp_tac(srw_ss())[shift_interfer_def]
    \\ full_simp_tac(srw_ss())[AC ADD_COMM ADD_ASSOC,AC MULT_COMM MULT_ASSOC]
    \\ rev_full_simp_tac(srw_ss())[LET_DEF]
    \\ `k + s1.clock - 1 = k + (s1.clock - 1)` by decide_tac
    \\ full_simp_tac(srw_ss())[])
  THEN1 (* Halt *)
   (srw_tac[][]
    \\ qmatch_assum_rename_tac `asm_fetch s1 = SOME (LabAsm Halt l1 l2 l3)`
    \\ qmatch_assum_rename_tac `asm_fetch s1 = SOME (LabAsm Halt l bytes n)`
    \\ mp_tac IMP_bytes_in_memory_Halt \\ full_simp_tac(srw_ss())[]
    \\ match_mp_tac IMP_IMP \\ strip_tac
    THEN1 (full_simp_tac(srw_ss())[state_rel_def]
           \\ imp_res_tac bytes_in_mem_IMP \\ full_simp_tac(srw_ss())[])
    \\ rpt strip_tac \\ pop_assum mp_tac
    \\ qpat_abbrev_tac `jj = asm$Jump lll` \\ rpt strip_tac
    \\ (Q.ISPECL_THEN [`mc_conf`,`t1`,`ms1`,`s1.ffi`,`jj`]mp_tac
         asm_step_IMP_evaluate_step) \\ full_simp_tac(srw_ss())[]
    \\ MATCH_MP_TAC IMP_IMP2 \\ STRIP_TAC THEN1
     (full_simp_tac(srw_ss())[state_rel_def,asm_def,LET_DEF]
      \\ full_simp_tac(srw_ss())[asm_step_def,asm_def,LET_DEF]
      \\ imp_res_tac bytes_in_mem_IMP
      \\ full_simp_tac(srw_ss())[asmSemTheory.jump_to_offset_def,
            asmSemTheory.upd_pc_def]
      \\ rev_full_simp_tac(srw_ss())[] \\ unabbrev_all_tac
      \\ full_simp_tac(srw_ss())[asmSemTheory.jump_to_offset_def,
            asmSemTheory.upd_pc_def,asm_def])
    \\ rpt strip_tac
    \\ unabbrev_all_tac \\ full_simp_tac(srw_ss())[asm_def]
    \\ FIRST_X_ASSUM (Q.SPEC_THEN `s1.clock`mp_tac) \\ srw_tac[][]
    \\ Q.EXISTS_TAC `l'` \\ full_simp_tac(srw_ss())[]
    \\ once_rewrite_tac [evaluate_def] \\ full_simp_tac(srw_ss())[]
    \\ full_simp_tac(srw_ss())[shift_interfer_def]
    \\ `mc_conf.target.get_pc ms2 = mc_conf.halt_pc` by
     (full_simp_tac(srw_ss())[backend_correct_def,target_ok_def] \\ res_tac
      \\ full_simp_tac(srw_ss())[]
      \\ full_simp_tac(srw_ss())[jump_to_offset_def,asmSemTheory.upd_pc_def]
      \\ full_simp_tac(srw_ss())[state_rel_def]
      \\ rewrite_tac [GSYM word_add_n2w,GSYM word_sub_def,WORD_SUB_PLUS,
           WORD_ADD_SUB] \\ full_simp_tac(srw_ss())[])
    \\ `~(mc_conf.target.get_pc ms2 IN t1.mem_domain)` by
            full_simp_tac(srw_ss())[state_rel_def]
    \\ full_simp_tac(srw_ss())[state_rel_def,jump_to_offset_def,
          asmSemTheory.upd_pc_def]
    \\ Cases_on `s1.regs s1.ptr_reg` \\ full_simp_tac(srw_ss())[]
    \\ `word_loc_val p labs (s1.regs s1.ptr_reg) =
         SOME (t1.regs s1.ptr_reg)` by full_simp_tac(srw_ss())[]
    \\ Cases_on `s1.regs s1.ptr_reg`
    \\ full_simp_tac(srw_ss())[word_loc_val_def] \\ srw_tac[][]
    \\ `s1 = s2` by (Cases_on `t1.regs s1.ptr_reg = 0w`
    \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]) \\ srw_tac[][]
    \\ full_simp_tac(srw_ss())[backend_correct_def,target_ok_def]
    \\ res_tac \\ full_simp_tac(srw_ss())[]
    \\ pop_assum (qspec_then `s1.ptr_reg` mp_tac)
    \\ pop_assum (qspec_then `s1.ptr_reg` mp_tac)
    \\ full_simp_tac(srw_ss())[reg_ok_def]
    \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]));

(* relating observable semantics *)

val init_ok_def = Define `
  init_ok (mc_conf, p) s ms <=>
    s.ffi.final_event = NONE /\
    ?code2 labs t1.
      state_rel (mc_conf,code2,labs,p,T) s t1 ms`

val evaluate_ignore_clocks = prove(
  ``evaluate mc_conf ffi k ms = (r1,ms1,st1) /\ r1 <> TimeOut /\
    evaluate mc_conf ffi k' ms = (r2,ms2,st2) /\ r2 <> TimeOut ==>
    (r1,ms1,st1) = (r2,ms2,st2)``,
  srw_tac[][] \\ imp_res_tac evaluate_add_clock \\ full_simp_tac(srw_ss())[]
  \\ pop_assum (qspec_then `k'` mp_tac)
  \\ pop_assum (qspec_then `k` mp_tac)
  \\ full_simp_tac(srw_ss())[AC ADD_ASSOC ADD_COMM])

val machine_sem_EQ_sem = Q.store_thm("machine_sem_EQ_sem",
  `!mc_conf p (ms:'state) ^s1.
     backend_correct mc_conf.target /\
     init_ok (mc_conf,p) s1 ms /\ semantics s1 <> Fail ==>
     machine_sem mc_conf s1.ffi ms = { semantics s1 }`,
  simp[GSYM AND_IMP_INTRO] >>
  rpt gen_tac >> ntac 2 strip_tac >>
  full_simp_tac(srw_ss())[init_ok_def] >>
  simp[semantics_def] >>
  IF_CASES_TAC >> full_simp_tac(srw_ss())[] >>
  DEEP_INTRO_TAC some_intro >>
  conj_tac
  >- (
    qx_gen_tac`ffi`>>strip_tac>> full_simp_tac(srw_ss())[]
    \\ drule compile_correct \\ full_simp_tac(srw_ss())[]
    \\ `r ≠ Error` by (Cases_on`r`>>every_case_tac>>
                    full_simp_tac(srw_ss())[]>>metis_tac[FST]) >> simp[]
    \\ disch_then drule
    \\ imp_res_tac state_rel_clock
    \\ pop_assum (qspec_then `k` assume_tac)
    \\ disch_then drule \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
    \\ full_simp_tac(srw_ss())[machine_sem_def,EXTENSION] \\ full_simp_tac(srw_ss())[IN_DEF]
    \\ Cases \\ full_simp_tac(srw_ss())[machine_sem_def]
    THEN1 (disj1_tac \\ qexists_tac `k+k'` \\ full_simp_tac(srw_ss())[] \\ every_case_tac \\ full_simp_tac(srw_ss())[])
    THEN1
     (eq_tac THEN1
       (srw_tac[][] \\ every_case_tac \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
        \\ drule (GEN_ALL evaluate_ignore_clocks) \\ full_simp_tac(srw_ss())[]
        \\ pop_assum (K all_tac)
        \\ disch_then drule \\ full_simp_tac(srw_ss())[])
      \\ srw_tac[][] \\ every_case_tac \\ full_simp_tac(srw_ss())[] \\ asm_exists_tac \\ full_simp_tac(srw_ss())[])
    \\ CCONTR_TAC \\ full_simp_tac(srw_ss())[FST_EQ_EQUIV]
    \\ PairCases_on `z`
    \\ drule (GEN_ALL evaluate_ignore_clocks) \\ full_simp_tac(srw_ss())[]
    \\ every_case_tac \\ full_simp_tac(srw_ss())[]
    \\ pop_assum (K all_tac)
    \\ asm_exists_tac \\ full_simp_tac(srw_ss())[])
  \\ full_simp_tac(srw_ss())[machine_sem_def,EXTENSION] \\ full_simp_tac(srw_ss())[IN_DEF]
  \\ strip_tac
  \\ Cases \\ full_simp_tac(srw_ss())[machine_sem_def]
  \\ imp_res_tac state_rel_clock
  THEN1 (
    qmatch_abbrev_tac`a ∧ b ⇔ c` >>
    `a` by (
      unabbrev_all_tac >> gen_tac >>
      qspec_then `s1 with clock := k` mp_tac compile_correct >>
      Cases_on`evaluate (s1 with clock := k)`>>simp[]>>
      last_assum(qspec_then`k`mp_tac)>>
      pop_assum mp_tac >> simp_tac(srw_ss())[] >>
      ntac 2 strip_tac >>
      disch_then drule >>
      first_x_assum(qspec_then`k`strip_assume_tac) >>
      disch_then drule >> strip_tac >>
      first_x_assum(qspec_then`k`mp_tac)>>simp[]>>
      strip_tac >>
      spose_not_then strip_assume_tac >>
      Cases_on`r.ffi.final_event`>>full_simp_tac(srw_ss())[]>>
      Cases_on`q`>>full_simp_tac(srw_ss())[]>>
      `∃x y z. evaluate mc_conf s1.ffi k ms = (x,y,z)` by metis_tac[PAIR] >>
      `x = TimeOut` by (
        spose_not_then strip_assume_tac >>
        drule (GEN_ALL evaluate_add_clock) >>
        simp[] >> qexists_tac`k'`>>simp[] ) >>
      full_simp_tac(srw_ss())[] >>
      metis_tac[evaluate_add_clock_io_events_mono,SND,option_CASES,
                IS_SOME_EXISTS,LESS_EQ_EXISTS]) >>
    simp[] >> full_simp_tac(srw_ss())[Abbr`a`] >>
    unabbrev_all_tac >> simp[] >>
    qmatch_abbrev_tac`lprefix_lub l1 l ⇔ l = build_lprefix_lub l2` >>
    `lprefix_chain l1 ∧ lprefix_chain l2` by (
      unabbrev_all_tac >>
      conj_tac >>
      Ho_Rewrite.ONCE_REWRITE_TAC[GSYM o_DEF] >>
      REWRITE_TAC[IMAGE_COMPOSE] >>
      match_mp_tac prefix_chain_lprefix_chain >>
      simp[prefix_chain_def,PULL_EXISTS] >>
      qx_genl_tac[`k1`,`k2`] >>
      qspecl_then[`k1`,`k2`]mp_tac LESS_EQ_CASES >>
      metis_tac[
        targetPropsTheory.evaluate_add_clock_io_events_mono,
        labPropsTheory.evaluate_add_clock_io_events_mono
        |> Q.SPEC`s with clock := k` |> SIMP_RULE (srw_ss())[],
        LESS_EQ_EXISTS]) >>
    `equiv_lprefix_chain l1 l2` by (
      simp[equiv_lprefix_chain_thm] >>
      unabbrev_all_tac >> simp[PULL_EXISTS] >>
      ntac 2 (pop_assum kall_tac) >>
      simp[LNTH_fromList,PULL_EXISTS] >>
      simp[GSYM FORALL_AND_THM] >>
      rpt gen_tac >>
      qspec_then `s1 with clock := k` mp_tac compile_correct >>
      Cases_on`evaluate (s1 with clock := k)`>>full_simp_tac(srw_ss())[] >>
      last_assum(qspec_then`k`mp_tac)>>
      pop_assum mp_tac >> simp_tac(srw_ss())[] >>
      ntac 2 strip_tac >>
      disch_then drule >>
      first_x_assum(qspec_then`k`(fn th => assume_tac th >> disch_then drule)) >>
      strip_tac >>
      reverse conj_tac >> strip_tac >- (
        qexists_tac`k+k'`>>simp[] ) >>
      qmatch_assum_abbrev_tac`n < (LENGTH (_ ffi))` >>
      qexists_tac`k`>>simp[] >>
      `ffi.io_events ≼ r.ffi.io_events` by (
        qunabbrev_tac`ffi` >>
        metis_tac[
          targetPropsTheory.evaluate_add_clock_io_events_mono,
          SND,LESS_EQ_EXISTS] ) >>
      full_simp_tac(srw_ss())[IS_PREFIX_APPEND] >>
      simp[EL_APPEND1]) >>
    metis_tac[build_lprefix_lub_thm,unique_lprefix_lub,lprefix_lub_new_chain])
  THEN1 (
    spose_not_then strip_assume_tac >> var_eq_tac >>
    qspec_then `s1 with clock := k` mp_tac compile_correct >>
    Cases_on`evaluate (s1 with clock := k)`>>simp[]>>
    last_assum(qspec_then`k`mp_tac)>>
    pop_assum mp_tac >> simp_tac(srw_ss())[] >> rpt strip_tac >>
    asm_exists_tac >> simp[] >>
    first_x_assum(qspec_then`k`strip_assume_tac) >>
    asm_exists_tac >> simp[] >>
    rpt gen_tac >>
    drule (GEN_ALL evaluate_add_clock) >> simp[] >>
    disch_then kall_tac >>
    first_x_assum(qspec_then`k`mp_tac) >> simp[] >>
    Cases_on`r.ffi.final_event`>>full_simp_tac(srw_ss())[])
  \\ CCONTR_TAC \\ full_simp_tac(srw_ss())[FST_EQ_EQUIV]
  \\ last_x_assum (qspec_then `k` mp_tac) \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `evaluate (s1 with clock := k)` \\ full_simp_tac(srw_ss())[]
  \\ drule compile_correct
  \\ Cases_on `q = Error` \\ full_simp_tac(srw_ss())[]
  \\ asm_exists_tac \\ full_simp_tac(srw_ss())[]
  \\ first_x_assum (qspec_then `k` assume_tac)
  \\ asm_exists_tac \\ full_simp_tac(srw_ss())[] \\ gen_tac
  \\ PairCases_on `z`
  \\ drule (GEN_ALL evaluate_add_clock) \\ full_simp_tac(srw_ss())[]
  \\ every_case_tac \\ full_simp_tac(srw_ss())[]);

(* syntactic properties of remove_labels *)

val good_syntax_def = Define `
  good_syntax mc_conf (code:'a sec list) (l:num_set) = T`

val good_syntax_filter_skip = store_thm("good_syntax_filter_skip[simp]",
  ``good_syntax c (filter_skip prog) l = good_syntax c prog l``,
  srw_tac[][good_syntax_def]);

val lines_ok_def = Define`
  (lines_ok c labs pos [] = T) ∧
  (lines_ok c labs pos (y::ys) ⇔
   line_ok c labs pos y ∧
   lines_ok c labs (pos + line_length y) ys)`;

val all_enc_ok_cons = Q.store_thm("all_enc_ok_cons",
  `∀ls pos.
   all_enc_ok c labs pos (Section k ls::xs) ⇔
   all_enc_ok c labs (pos + SUM (MAP line_length ls)) xs ∧
   EVEN (pos + SUM (MAP line_length ls)) ∧
   lines_ok c labs pos ls`,
  Induct >> srw_tac[][all_enc_ok_def,lines_ok_def] >>
  simp[] >> metis_tac[]);

val line_similar_sym = Q.store_thm("line_similar_sym",
  `line_similar l1 l2 ⇒ line_similar l2 l1`,
  Cases_on`l1`>>Cases_on`l2`>>EVAL_TAC>>srw_tac[][]);

val code_similar_sym = Q.store_thm("code_similar_sym",
  `∀code1 code2. code_similar code1 code2 ⇒ code_similar code2 code1`,
  Induct >> simp[code_similar_def]
  >> Cases_on`code2`>>simp[code_similar_def]
  >> Cases >> simp[code_similar_def]
  >> Cases_on`h` >> simp[code_similar_def]
  >> srw_tac[][]
  >> match_mp_tac (GEN_ALL (MP_CANON EVERY2_sym))
  >> metis_tac[line_similar_sym]);

val line_similar_refl = Q.store_thm("line_similar_refl[simp]",
  `∀l. line_similar l l`,
  Cases >> EVAL_TAC);

val line_similar_trans = prove(
  ``line_similar x y /\ line_similar y z ==> line_similar x z``,
  Cases_on `x` \\ Cases_on `y` \\ Cases_on `z` \\ fs[line_similar_def]);

val EVERY2_TRANS = prove(
  ``!xs ys zs. EVERY2 P xs ys /\ EVERY2 P ys zs /\
               (!x y z. P x y /\ P y z ==> P x z) ==> EVERY2 P xs zs``,
  Induct \\ fs [PULL_EXISTS] \\ rw [] \\ res_tac \\ fs []);

val code_similar_trans = store_thm("code_similar_trans",
  ``!c1 c2 c3. code_similar c1 c2 /\ code_similar c2 c3 ==> code_similar c1 c3``,
  HO_MATCH_MP_TAC code_similar_ind \\ fs [] \\ rw []
  \\ Cases_on `c3` \\ fs [code_similar_def] \\ rw []
  \\ Cases_on `h` \\ fs [code_similar_def] \\ rw []
  \\ metis_tac [line_similar_trans,EVERY2_TRANS]);

val code_similar_refl = Q.store_thm("code_similar_refl[simp]",
  `∀code. code_similar code code`,
  Induct >> simp[code_similar_def] >>
  Cases >> simp[code_similar_def] >>
  match_mp_tac EVERY2_refl >> simp[]);

val line_similar_add_nop = prove(``
  ∀ls ls' h.
  LIST_REL line_similar ls ls' ⇒
  LIST_REL line_similar ls (add_nop h ls')``,
  Induct_on`ls`>>rw[add_nop_def]>>
  Cases_on`y`>>Cases_on`h`>>fs[add_nop_def,line_similar_def])

val line_similar_pad_section = Q.store_thm("line_similar_pad_section",
  `∀nop l2 aux l1.
     LIST_REL line_similar l1 (REVERSE aux ++ l2) ⇒
     LIST_REL line_similar l1 (pad_section nop l2 aux)`,
   ho_match_mp_tac pad_section_ind >>
   srw_tac[][pad_section_def] >>
   first_x_assum match_mp_tac>>
   imp_res_tac LIST_REL_LENGTH >> full_simp_tac(srw_ss())[] >>
   qmatch_assum_rename_tac`LIST_REL _ ls (_ ++ _)` >>
   qmatch_assum_abbrev_tac`LENGTH ls = m + _` >>
   qispl_then[`m`,`ls`]strip_assume_tac TAKE_DROP >>
   ONCE_REWRITE_TAC[GSYM APPEND_ASSOC] >>
   `m < LENGTH ls` by DECIDE_TAC>>
   qpat_x_assum`LIST_REL A B C` mp_tac>>
   first_x_assum (SUBST1_TAC o SYM) >>
   strip_tac>>
   match_mp_tac EVERY2_APPEND_suff >>
   drule LIST_REL_APPEND_IMP >>
   rw[]
   >-
     (`LIST_REL line_similar aux (add_nop nop aux)` by
       (match_mp_tac line_similar_add_nop>>
       match_mp_tac EVERY2_refl>>
       fs[line_similar_refl])>>
      ho_match_mp_tac LIST_REL_trans>>HINT_EXISTS_TAC>>
      metis_tac[line_similar_trans,LIST_REL_REVERSE_EQ])
   >>
     TRY(Cases_on`x`)>>TRY(Cases_on`x'`)>>fs[line_similar_def]);

val code_similar_pad_code = Q.store_thm("code_similar_pad_code",
  `∀code1 code2.
   code_similar code1 code2 ⇒
   code_similar code1 (pad_code nop code2)`,
  Induct
  >- ( Cases >> simp[code_similar_def,pad_code_def] )
  >> Cases_on`code2` >- simp[code_similar_def]
  >> Cases >> simp[code_similar_def]
  >> Cases_on`h` >> simp[code_similar_def,pad_code_def]
  >> strip_tac >> rveq >>
  match_mp_tac line_similar_pad_section>>
  simp[]);

val LIST_REL_enc_line = prove(``
  ∀ls ls'.
  LIST_REL line_similar ls ls' ⇔
  LIST_REL line_similar (MAP (enc_line enc len) ls) ls'`` ,
  Induct>>rw[]>>Cases_on`h`>>rw[enc_line_def,EQ_IMP_THM]>>Cases_on`y`>>
  fs[line_similar_def])

val code_similar_enc_sec_list = Q.store_thm("code_similar_enc_sec_list[simp]",
  `∀code1 code2 n.
     code_similar (enc_sec_list n code1) code2 ⇔
     code_similar code1 code2`,
   simp[enc_sec_list_def]
   >> Induct >> simp[]
   >> Cases_on`code2`>>simp[code_similar_def]
   >> Cases_on`h`>>simp[code_similar_def]
   >> Cases>>simp[code_similar_def,enc_sec_def]>>
   rw[EQ_IMP_THM]>>
   metis_tac[LIST_REL_enc_line])

val label_zero_def = Define`
  (label_zero (Label _ _ n) ⇔ n = 0) ∧
  (label_zero _ ⇔ T)`;
val _ = export_rewrites["label_zero_def"];

val sec_label_zero_def = Define`
  sec_label_zero (Section _ ls) = EVERY label_zero ls`;

val pos_val_0_0 = Q.store_thm("pos_val_0_0",
  `EVERY sec_label_zero ls ⇒ pos_val 0 0 ls = 0`,
  Induct_on`ls`>>srw_tac[][pos_val_def]>>full_simp_tac(srw_ss())[]
  >> Cases_on`h`>>srw_tac[][pos_val_def]
  >> Induct_on`l`
  >> srw_tac[][pos_val_def]
  >> full_simp_tac(srw_ss())[sec_label_zero_def]
  >> Cases_on`h`>>full_simp_tac(srw_ss())[]
  >> srw_tac[][line_length_def]);

val add_nop_label_zero = prove(``
  ∀ls.
  EVERY label_zero ls ⇒
  EVERY label_zero (add_nop nop ls)``,
  Induct>>fs[add_nop_def]>>rw[]>>
  Cases_on`h`>>fs[add_nop_def]);

val EVERY_label_zero_pad_section = Q.store_thm("EVERY_label_zero_pad_section[simp]",
  `∀nop xs aux.
     EVERY label_zero aux ⇒
     EVERY label_zero (pad_section nop xs aux)`,
  ho_match_mp_tac pad_section_ind
  >> srw_tac[][pad_section_def]
  >> srw_tac[][EVERY_REVERSE]>>
  first_assum match_mp_tac>>fs[add_nop_label_zero]);

val EVERY_label_zero_add_nop = prove(
  ``!xs. EVERY label_zero (add_nop nop xs) = EVERY label_zero xs``,
  Induct \\ fs [add_nop_def,EVERY_REVERSE]
  \\ Cases \\ fs [add_nop_def,EVERY_REVERSE]);

val EVERY_sec_label_zero_pad_code = Q.store_thm("EVERY_sec_label_zero_pad_code[simp]",
  `∀nop ls. EVERY sec_label_zero (pad_code nop ls)`,
  ho_match_mp_tac pad_code_ind
  \\ srw_tac[][pad_code_def] \\ fs []
  \\ srw_tac[][sec_label_zero_def]
  \\ unabbrev_all_tac \\ fs []
  \\ fs [EVERY_REVERSE,EVERY_label_zero_add_nop]);

val sec_length_add = Q.store_thm("sec_length_add",
  `∀ls n m. sec_length ls (n+m) = sec_length ls n + m`,
  ho_match_mp_tac sec_length_ind >>
  simp[sec_length_def]);

val code_similar_nil = Q.store_thm("code_similar_nil",
  `(code_similar [] l ⇔ l = []) ∧
   (code_similar l [] ⇔ l = [])`,
   Cases_on`l`>>EVAL_TAC);

val code_similar_loc_to_pc = Q.store_thm("code_similar_loc_to_pc",
  `∀l1 l2 c1 c2. code_similar c1 c2 ⇒
     loc_to_pc l1 l2 c1 = loc_to_pc l1 l2 c2`,
  ho_match_mp_tac loc_to_pc_ind
  >> simp[code_similar_nil]
  >> srw_tac[][]
  >> Cases_on`c2`>>full_simp_tac(srw_ss())[code_similar_def]
  >> Cases_on`h`>>full_simp_tac(srw_ss())[code_similar_def]
  >> Cases_on`xs`>>full_simp_tac(srw_ss())[]
  >- (
    srw_tac[][Once loc_to_pc_def]
    >> srw_tac[][Once loc_to_pc_def,SimpRHS]
    >> first_x_assum (match_mp_tac o MP_CANON)
    >> full_simp_tac(srw_ss())[] )
  \\ rveq
  \\ simp[Once loc_to_pc_def]
  \\ simp[Once loc_to_pc_def,SimpRHS]
  \\ match_mp_tac COND_CONG \\ simp[]
  \\ disch_then assume_tac
  \\ match_mp_tac COND_CONG \\ simp[]
  \\ conj_asm1_tac >- (
    Cases_on`h`>>Cases_on`y`>>full_simp_tac(srw_ss())[line_similar_def] )
  \\ disch_then assume_tac
  \\ match_mp_tac COND_CONG
  \\ conj_asm1_tac >- (
    Cases_on`h`>>Cases_on`y`>>full_simp_tac(srw_ss())[line_similar_def] )
  \\ srw_tac[][] >> full_simp_tac(srw_ss())[] >>
  rveq >> rev_full_simp_tac(srw_ss())[]
  \\ TRY (ntac 2 AP_THM_TAC >> AP_TERM_TAC)
  \\ first_x_assum (match_mp_tac o MP_CANON)
  \\ srw_tac[][code_similar_def]);

val LENGTH_pad_bytes = Q.store_thm("LENGTH_pad_bytes",
  `0 < LENGTH nop ∧ LENGTH bytes ≤ l ⇒
    LENGTH (pad_bytes bytes l nop) = l`,
  srw_tac[][pad_bytes_def] >> srw_tac[][] >> fsrw_tac[ARITH_ss][]
  \\ match_mp_tac LENGTH_TAKE
  \\ simp[LENGTH_FLAT,SUM_MAP_LENGTH_REPLICATE]
  \\ Cases_on`LENGTH nop`>>full_simp_tac(srw_ss())[]>>simp[MULT,Once MULT_COMM]);

val line_ok_alignment = Q.store_thm("line_ok_alignment",
  `∀c labs pos line.
   enc_ok c
   ∧ line_ok c labs pos line
   ∧ ODD (line_length line)
   ⇒ c.code_alignment = 0`,
  ho_match_mp_tac line_ok_ind
  \\ srw_tac[][line_ok_def,line_length_def,LET_THM]
  \\ full_simp_tac(srw_ss())[enc_ok_def]
  \\ rename1 `asm_ok b c`
  \\ qpat_x_assum `!w. xxx /\ yyy` (qspec_then `b` mp_tac)
  \\ full_simp_tac(srw_ss())[enc_with_nop_thm]
  \\ rveq >> full_simp_tac(srw_ss())[]
  \\ srw_tac[][]
  \\ spose_not_then (assume_tac o MATCH_MP (#2(EQ_IMP_RULE (SPEC_ALL EXP2_EVEN))))
  \\ rev_full_simp_tac(srw_ss())[LENGTH_FLAT_REPLICATE]
  \\ full_simp_tac(srw_ss())[ODD_ADD,ODD_EVEN,EVEN_MULT]
  \\ imp_res_tac EXP_IMP_ZERO_LT
  \\ imp_res_tac MOD_EQ_0_DIVISOR
  \\ full_simp_tac(srw_ss())[EVEN_MULT]);

val has_odd_inst_alignment = Q.store_thm("has_odd_inst_alignment",
  `∀c labs pos code.
   enc_ok c
   ∧ all_enc_ok c labs pos code
   ∧ has_odd_inst code
   ⇒ c.code_alignment = 0`,
  ho_match_mp_tac all_enc_ok_ind
  \\ simp[all_enc_ok_def,has_odd_inst_def]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ metis_tac[line_ok_alignment,ODD_EVEN]);

val enc_lines_again_IMP_similar = prove(``
  ∀labs pos enc lines acc ok lines' ok' curr.
  enc_lines_again labs pos enc lines (acc,ok) = (lines',ok') ⇒
  LIST_REL line_similar curr (REVERSE acc) ⇒
  LIST_REL line_similar (curr++lines) lines'``,
  Induct_on`lines`>>fs[enc_lines_again_def]>>rw[]>>
  fs[AND_IMP_INTRO]>>
  `curr ++ h ::lines = SNOC h curr ++ lines` by fs[]>>
  pop_assum SUBST1_TAC>>
  first_assum match_mp_tac>>
  Cases_on`h`>>fs[enc_lines_again_def]>>EVERY_CASE_TAC>>
  asm_exists_tac>>fs[SNOC_APPEND,line_similar_def])

val enc_secs_again_IMP_similar = prove(
  ``∀pos labs enc code code1 ok.
  enc_secs_again pos labs enc code = (code1,ok) ==> code_similar code code1``,
  ho_match_mp_tac enc_secs_again_ind>>fs[enc_secs_again_def]>>rw[]>>
  ntac 2 (pairarg_tac>>fs[])>>
  rveq>>fs[code_similar_def]>>
  imp_res_tac enc_lines_again_IMP_similar>>
  fs[]);

val lines_upd_lab_len_AUX = prove(
  ``!l aux pos.
      REVERSE aux ++ lines_upd_lab_len pos l [] =
      lines_upd_lab_len pos l aux``,
  Induct \\ fs [lines_upd_lab_len_def]
  \\ Cases \\ simp_tac std_ss [lines_upd_lab_len_def,LET_DEF]
  \\ pop_assum (fn th => once_rewrite_tac [GSYM th]) \\ fs []) |> GSYM

val line_similar_lines_upd_lab_len = prove(
  ``!l aux pos l1.
      LIST_REL line_similar (lines_upd_lab_len pos l []) l1 =
      LIST_REL line_similar l l1``,
  Induct \\ fs [lines_upd_lab_len_def]
  \\ Cases \\ fs [lines_upd_lab_len_def]
  \\ once_rewrite_tac [lines_upd_lab_len_AUX]
  \\ fs [] \\ rw [] \\ eq_tac \\ rw []
  \\ Cases_on `y` \\ fs [line_similar_def]);

val code_similar_upd_lab_len = prove(
  ``!code pos code1.
      code_similar (upd_lab_len pos code) code1 = code_similar code code1``,
  Induct \\ fs [code_similar_def] \\ Cases
  \\ Cases_on `code1` \\ fs [upd_lab_len_def,code_similar_def]
  \\ Cases_on `h` \\ fs [upd_lab_len_def,code_similar_def]
  \\ rw [] \\ fs [line_similar_lines_upd_lab_len]);

(*Remove tail recursion*)
val enc_lines_again_simp_def = Define`
  (enc_lines_again_simp labs pos enc [] = ([],T)) ∧
  (enc_lines_again_simp labs pos enc (LabAsm a w bytes l::xs) =
    let w1 = get_jump_offset a labs pos
    in
      if w = w1 then
        let (rest,ok) = enc_lines_again_simp labs (pos + l) enc xs in
          (LabAsm a w bytes l::rest,ok)
      else
        let bs = enc (lab_inst w1 a) in
        let l1 = MAX (LENGTH bs) l in
        let (rest,ok) = enc_lines_again_simp labs (pos + l1) enc xs in
          (LabAsm a w1 bs l1::rest,l1 = l ∧ ok)) ∧
  (enc_lines_again_simp labs pos enc (Label k1 k2 l::xs) =
    let (rest,ok) = enc_lines_again_simp labs (pos + l) enc xs in
    (Label k1 k2 l::rest,ok)) ∧
  (enc_lines_again_simp labs pos enc (Asm x1 x2 l::xs) =
    let (rest,ok) = enc_lines_again_simp labs (pos + l) enc xs in
    (Asm x1 x2 l::rest,ok))`

val enc_lines_again_simp_ind = theorem"enc_lines_again_simp_ind";

val enc_lines_again_simp_EQ = prove(``
  ∀labs pos enc ls acc b.
  let (ls',flag) = enc_lines_again_simp labs pos enc ls in
  enc_lines_again labs pos enc ls (acc,b) = (REVERSE acc ++ ls',b ∧ flag)``,
  ho_match_mp_tac enc_lines_again_simp_ind >>
  fs[enc_lines_again_simp_def,enc_lines_again_def]>>rw[]>>
  rpt(pairarg_tac>>fs[])>>
  rw[EQ_IMP_THM]>>fs[])

(*
val enc_lines_again_simp_lemma = prove(``
  ∀labs pos enc lines lines' acc n.
  enc_lines_again_simp labs pos enc lines = (lines',T) ⇒
  asm_line_labs pos lines acc = asm_line_labs pos lines' acc ∧
  sec_length lines n = sec_length lines' n``,
  ho_match_mp_tac enc_lines_again_simp_ind >>
  fs[enc_lines_again_simp_def]>>rw[]>>
  pairarg_tac>>fs[]>>
  rveq>>fs[asm_line_labs_def,full_sec_length_def]>>
  fs[sec_length_def])

val enc_lines_again_T_IMP = prove(``
  enc_lines_again labs pos enc lines ([],T) = (lines',T) ⇒
  sec_labs pos lines = sec_labs pos lines' ∧
  full_sec_length lines = full_sec_length lines'``,
  strip_tac>>
  Q.ISPECL_THEN[`labs`,`pos`,`enc`,`lines`,`[]:'a line list`,`T`] assume_tac enc_lines_again_simp_EQ>>
  fs[]>>pairarg_tac>>fs[]>>
  `flag = T` by fs[]>>
  pop_assum SUBST_ALL_TAC>>
  imp_res_tac enc_lines_again_simp_lemma>>
  fs[sec_labs_def,full_sec_length_def])
*)

(*
val enc_secs_again_T_IMP = prove(``
  ∀pos code enc labs sec_list acc.
  enc_secs_again pos labs enc code = (sec_list,T) ⇒
  compute_labels pos code acc = compute_labels pos sec_list acc``,
  Induct_on`code`>>fs[enc_secs_again_def]>>rw[]>>
  Cases_on`h`>>fs[compute_labels_def]>>
  pairarg_tac>>fs[enc_secs_again_def]>>
  ntac 2 (pairarg_tac>>fs[])>>
  rveq>>fs[compute_labels_def]>>
  pairarg_tac>>fs[]>>
  imp_res_tac enc_lines_again_T_IMP>>
  fs[]>>
  res_tac>>
  fs[full_sec_length_def,]
  metis_tac[]
  fs[])
*)

val lab_lookup_insert = store_thm("lab_lookup_insert",
  ``lab_lookup l1 l2 (lab_insert k1 k2 pos labs) =
    if k1 = l1 /\ k2 = l2 then SOME pos else lab_lookup l1 l2 labs``,
  fs [lab_lookup_def,lab_insert_def,lookup_insert]
  \\ Cases_on `l1 = k1` \\ fs [lookup_insert] \\ rw []
  \\ every_case_tac \\ fs [] \\ fs [lookup_def]);

(*
val compute_labels_simp_def = Define`
  (compute_labels_simp pos [] = LN) ∧
  (compute_labels_simp pos (Section k lines::rest) =
    let (labs,new_pos) = sec_labs pos lines in
    let new_pos' = pos + full_sec_length lines in
    let result = compute_labels_simp new_pos' rest in
      insert k labs result)`

val compute_labels_simp_EQ = prove(``
  ∀pos ls acc.
   wf acc ⇒
  let res = compute_labels pos ls acc in
  let res' = (compute_labels_simp pos ls) in
  wf res ∧
  wf res' ∧
  res = union acc res'``,
  HO_MATCH_MP_TAC compute_labels_ind>>fs[compute_labels_simp_def,compute_labels_def,wf_def]>>
  ntac 7 strip_tac>>
  pairarg_tac>>fs[]>>
  dep_rewrite.DEP_REWRITE_TAC[spt_eq_thm] >>
  fs[wf_union,wf_insert,wf_def]>>
  fs[lookup_union,lookup_insert,lookup_def]>>
  rw[]>>EVERY_CASE_TAC>>fs[])
*)

(*Extract only the bytes part of all_enc_ok*)
val bytes_len_match_def = Define`
  (bytes_len_match (Label _ _ l) ⇔ l = 0) ∧
  (bytes_len_match (Asm _ b l) ⇔ LENGTH b = l) ∧
  (bytes_len_match (LabAsm _ _ b l) ⇔ LENGTH b = l)`

val all_bytes_len_match_def = Define`
  (all_bytes_len_match [] = T) ∧
  (all_bytes_len_match (Section k ls ::xs) ⇔
  EVERY bytes_len_match ls ∧ all_bytes_len_match xs)`

val all_bytes_len_match_pos_val_0 = prove(``
  ∀ls pos.
  all_bytes_len_match ls ⇒
  pos_val 0 pos ls = pos``,
  Induct>>fs[pos_val_def]>>Induct>>Induct_on`l`>>fs[pos_val_def,all_bytes_len_match_def]>>rw[]>>
  Cases_on`h`>>
  fs[line_length_def,bytes_len_match_def,is_Label_def])

(*

val lab_lookup_compute_labels_simp_lemma = prove(``
  ∀l1 l2 sec_list x2 conf enc labs nop pos l.
  all_bytes_len_match sec_list ∧
  loc_to_pc l1 l2 sec_list = SOME x2 ==>
  lab_lookup l1 l2 (compute_labels_simp pos sec_list) =
  SOME (pos_val x2 pos sec_list)``,
  ho_match_mp_tac loc_to_pc_ind>>fs[Once loc_to_pc_def]>>
  rw[]>>
  pop_assum mp_tac>>
  simp[Once loc_to_pc_def]
  \\ IF_CASES_TAC \\ fs []
  \\ fs [compute_labels_simp_def]
  \\ pairarg_tac \\ fs []
  \\ ...)

val lab_lookup_compute_labels = prove(
  ``∀l1 l2 sec_list x2 conf enc labs nop pos.
   (* all_enc_ok conf enc labs pos (pad_code nop sec_list) ∧ *)
      loc_to_pc l1 l2 sec_list = SOME x2 ==>
      lab_lookup l1 l2 (compute_labels pos sec_list LN) =
      SOME (pos_val x2 pos sec_list)``,
  ...)

*)

val asm_line_labs_acc = Q.store_thm("asm_line_labs_acc",
  `∀pos xs acc acc' pos'.
     asm_line_labs pos xs acc = (acc',pos') ⇒
     ∀k v. lookup k acc = SOME v ⇒ lookup k acc' = SOME v`,
  ho_match_mp_tac asm_line_labs_ind
  \\ rw[asm_line_labs_def] \\ fs[]
  \\ first_x_assum match_mp_tac
  \\ rw[lookup_union]);

val has_label_def = Define `
  (has_label l1 l2 [] = F) /\
  (has_label l1 l2 (Section k xs::rest) <=>
     k = l1 /\ l2 = 0 \/
     has_label l1 l2 rest \/
     l2 ≠ 0 ∧ ?x. MEM (Label l1 l2 x) xs)`

(*
val sec_names_compute_labels_simp = prove(``
  ∀n ls x.
  MEM x (sec_names ls) ⇔
  x ∈ domain (compute_labels_simp n ls)``,
  ho_match_mp_tac (theorem "compute_labels_simp_ind")>>
  rw[compute_labels_simp_def,sec_names_def]>>
  pairarg_tac>>fs[])
*)
(*

val compute_labels_simp_has_label = prove(``
  ∀pos sec_list l1 l2.
  ALL_DISTINCT(sec_names sec_list) ∧
  has_label l1 l2 sec_list ⇒
  IS_SOME (lab_lookup l1 l2 (compute_labels_simp pos sec_list))``,
  ho_match_mp_tac (theorem "compute_labels_simp_ind")>>
  rw[compute_labels_simp_def,sec_names_def,has_label_def]>>
  pairarg_tac>>fs[lab_lookup_def,sec_labs_def]>>
  imp_res_tac asm_line_labs_acc>>
  fs[lookup_insert]
  >-
    (pop_assum(qspecl_then[`pos`,`0n`] assume_tac)>>rfs[])
  >-
    (res_tac>>pop_assum mp_tac>>
    FULL_CASE_TAC>>fs[]>> strip_tac>>
    IF_CASES_TAC>>fs[]>>
    metis_tac[domain_lookup,sec_names_compute_labels_simp])
  >>
    IF_CASES_TAC>>fs[]
    >-
      (*should be true because of asm_line_labs*)
      ...
    >>
    (*probably false*)
    ...)

*)

val lab_lookup_sec_labels = prove(
  ``!lines pos labs l1 l2.
      lab_lookup l1 l2 (section_labels pos lines labs) =
      case lab_lookup l1 l2 (section_labels pos lines LN) of
      | SOME x => SOME x
      | NONE => lab_lookup l1 l2 labs``,
  once_rewrite_tac [EQ_SYM_EQ]
  \\ Induct \\ fs [] \\ fs [section_labels_def]
  THEN1 (fs [lab_lookup_def,lookup_def])
  \\ rw [] \\ Cases_on `h`
  \\ simp_tac std_ss [section_labels_def,lab_lookup_insert]
  \\ TRY IF_CASES_TAC \\ asm_rewrite_tac [] \\ fs []
  \\ simp_tac std_ss [section_labels_def,lab_lookup_insert]
  \\ TRY IF_CASES_TAC \\ asm_rewrite_tac [] \\ fs []
  \\ simp_tac std_ss [section_labels_def,lab_lookup_insert]);

val compute_labels_has_label = prove(
  ``!sec_list pos l1 l2.
      has_label l1 l2 sec_list ==>
      IS_SOME (lab_lookup l1 l2 (compute_labels_alt pos sec_list))``,
  Induct THEN1 (fs [has_label_def])
  \\ Cases \\ fs [has_label_def] \\ rpt gen_tac
  \\ Cases_on `l2 = 0` \\ fs [] THEN1
   (fs [compute_labels_alt_def,LET_THM,lab_lookup_insert]
    \\ IF_CASES_TAC \\ fs [] \\ rw [] \\ res_tac
    \\ once_rewrite_tac [lab_lookup_sec_labels]
    \\ every_case_tac \\ fs [])
  \\ strip_tac THEN1
   (fs [compute_labels_alt_def,LET_THM,lab_lookup_insert]
    \\ once_rewrite_tac [lab_lookup_sec_labels]
    \\ every_case_tac \\ fs [])
  \\ pop_assum mp_tac
  \\ fs [compute_labels_alt_def,LET_THM,lab_lookup_insert]
  \\ qspec_tac (`compute_labels_alt (pos + sec_length l 0) sec_list`,`labs`)
  \\ qspec_tac (`pos`,`pos`)
  \\ Induct_on `l` \\ fs []
  \\ Cases \\ fs [section_labels_def,lab_lookup_insert]
  \\ rw [] \\ fs[lab_lookup_insert]
  \\ rw[]);

val loc_to_pc_has_label = prove(
  ``!l1 l2 sec_list.
      IS_SOME (loc_to_pc l1 l2 sec_list) ==> has_label l1 l2 sec_list``,
  ho_match_mp_tac loc_to_pc_ind \\ rpt strip_tac \\ fs []
  \\ pop_assum mp_tac
  \\ once_rewrite_tac [loc_to_pc_def] \\ fs []
  \\ Cases_on `l2 = 0` \\ fs []
  THEN1
   (IF_CASES_TAC \\ fs [has_label_def]
    \\ Cases_on `xs` \\ fs []
    \\ Cases_on `h` \\ fs [is_Label_def]
    \\ rw [] \\ fs []
    \\ every_case_tac \\ fs [])
  \\ Cases_on `xs` \\ fs []
  \\ strip_tac \\ fs []
  \\ fs [has_label_def]
  \\ Cases_on `h` \\ fs [is_Label_def]
  \\ every_case_tac \\ fs [] \\ metis_tac []);

val IS_SOME_lab_lookup_compute_labels = prove(
  ``ALL_DISTINCT (sec_names sec_list) ∧
    IS_SOME (loc_to_pc l1 l2 sec_list) ==>
    IS_SOME (lab_lookup l1 l2 (compute_labels_alt pos sec_list))``,
  metis_tac [compute_labels_has_label,loc_to_pc_has_label]);

(*

val IS_SOME_lab_lookup_compute_labels = prove(
  ``IS_SOME (lab_lookup l1 l2 (compute_labels pos sec_list LN)) <=>
    IS_SOME (loc_to_pc l1 l2 sec_list)``,
  qspecl_then[`pos`,`sec_list`,`LN`]mp_tac compute_labels_simp_EQ
  \\ rw[CONJUNCT1 wf_def]
  \\ rpt (pop_assum kall_tac)
  \\ map_every qid_spec_tac [`pos`,`sec_list`,`l2`,`l1`]
  \\ ho_match_mp_tac loc_to_pc_ind
  \\ rw[compute_labels_simp_def]
  >- ( EVAL_TAC \\ simp[lookup_def] )
  \\ pairarg_tac \\ fs[]
  \\ fs[lab_lookup_def]
  \\ simp[lookup_insert]
  \\ IF_CASES_TAC \\ fs[]
  >- (
    rveq
    \\ simp[Once loc_to_pc_def]
    \\ IF_CASES_TAC \\ fs[]
    >- (
      fs[sec_labs_def]
      \\ imp_res_tac asm_line_labs_acc
      \\ fs[lookup_insert,lookup_def] )
    \\ BasicProvers.TOP_CASE_TAC \\ fs[]
    >- (
      first_assum(qspec_then`pos`mp_tac)
      \\ BasicProvers.CASE_TAC \\ fs[]
      \\ fs[sec_labs_def,asm_line_labs_def]
      \\ rw[lookup_insert,lookup_def]
      \\ Cases_on`loc_to_pc k l2 sec_list`\\fs[]
      \\ ... )
    \\ BasicProvers.TOP_CASE_TAC \\ fs[]
    >- (
      rw[]
      \\ fs[sec_labs_def]
      \\ fs[asm_line_labs_def]
      \\ imp_res_tac asm_line_labs_acc
      \\ fs[lookup_union,lookup_insert,lookup_def]
      \\ first_x_assum(qspec_then`l2`mp_tac o CONV_RULE SWAP_FORALL_CONV)
      \\ simp[] )
    \\ ... )
  \\ ...);

*)

val MEM_all_labels = prove(
  ``MEM (l1,l2,pos) (all_labels labs) <=> lab_lookup l1 l2 labs = SOME pos``,
  rw[lab_lookup_def,all_labels_def,MEM_FLAT,MEM_MAP,PULL_EXISTS,MEM_toAList,EXISTS_PROD]
  \\ CASE_TAC);

val loc_to_pc_comp_thm = prove(
  ``!l1 l2 sec_list.
      loc_to_pc_comp l1 l2 sec_list = loc_to_pc l1 l2 sec_list``,
  recInduct loc_to_pc_comp_ind \\ rw []
  \\ once_rewrite_tac [loc_to_pc_def,loc_to_pc_comp_def] \\ fs []
  \\ IF_CASES_TAC \\ fs []
  \\ TOP_CASE_TAC \\ fs [CONJ_ASSOC]
  \\ TOP_CASE_TAC \\ fs [CONJ_ASSOC]
  \\ TOP_CASE_TAC \\ fs [CONJ_ASSOC])

val lab_lookup_compute_labels_test = prove(
  ``∀pos sec_list l1 l2 x2 c labs nop.
      all_enc_ok c labs pos sec_list /\
      loc_to_pc l1 l2 sec_list = SOME x2 ==>
      lab_lookup l1 l2 (compute_labels_alt pos sec_list) =
      SOME (pos_val x2 pos sec_list)``,
  ho_match_mp_tac compute_labels_alt_ind>>fs[]>>
  CONJ_TAC
  >-
    (rw[]>>
    fs[compute_labels_alt_def,loc_to_pc_def])
  >>
  Induct_on`lines`>>fs[]>>rw[]
  >-
    (fs[loc_to_pc_def,compute_labels_alt_def,sec_length_def,section_labels_def,pos_val_def,all_enc_ok_def]>>
    Cases_on`k=l1`>>fs[lab_lookup_def,lab_insert_def,lookup_insert]
    >-
      (IF_CASES_TAC>>fs[]>>rveq
      >-
        metis_tac[GSYM pos_val_0]
      >>
        res_tac>>
        FULL_CASE_TAC>>fs[])
    >> metis_tac[])
  >>
    pop_assum mp_tac>>simp[Once loc_to_pc_def]>>
    fs[compute_labels_alt_def,sec_length_def,section_labels_def,pos_val_def,all_enc_ok_def]>>
    Cases_on`k=l1`>>fs[lab_lookup_def,lab_insert_def,lookup_insert]
    >-
      (*In the current section*)
      (IF_CASES_TAC>>fs[]>>rveq
      >-
        (strip_tac>>rveq>>IF_CASES_TAC>>fs[]>>
        Cases_on`h`>>fs[line_ok_def,line_length_def]>>
        rfs[]>>
        metis_tac[GSYM pos_val_0])
      >>
      Cases_on`h`>>fs[section_labels_def]
      >-
        (fs[line_length_def,line_ok_def]>>
        Cases_on`n=k`>>fs[lab_insert_def,lookup_insert]
        >-
          (IF_CASES_TAC>>fs[lookup_insert,line_length_def]
          >-
            (rw[]>>
            metis_tac[pos_val_0])
          >>
            first_x_assum(qspecl_then[`pos`,`k`,`sec_list`] mp_tac)>>
            fs[sec_length_def,line_ok_def,sec_length_add]>>
            impl_tac>-
              metis_tac[]>>
            rw[]>>
            res_tac>>rfs[lookup_insert])
        >>
          first_x_assum(qspecl_then[`pos`,`k`,`sec_list`] mp_tac)>>
          fs[sec_length_def,line_ok_def,sec_length_add]>>
          impl_tac>-
            metis_tac[]>>
          rw[]>>
          res_tac>>rfs[lookup_insert])
      >-
        (TOP_CASE_TAC>>fs[line_length_def]>>
        first_x_assum(qspecl_then[`pos+LENGTH l`,`k`,`sec_list`] mp_tac)>>
        fs[sec_length_def,line_ok_def,sec_length_add]>>
        impl_tac>-
          metis_tac[]>>
        strip_tac>>
        rveq>>fs[]>>
        res_tac>>
        rfs[lookup_insert]>>
        rw[]>>
        simp[])
      >>
        `n = LENGTH l` by
          (Cases_on`a`>>fs[line_ok_def])>>
        TOP_CASE_TAC>>fs[line_length_def]>>
        first_x_assum(qspecl_then[`pos+LENGTH l`,`k`,`sec_list`] mp_tac)>>
        fs[sec_length_def,line_ok_def,sec_length_add]>>
        impl_tac>-
          metis_tac[]>>
        strip_tac>>
        rveq>>fs[]>>
        res_tac>>
        rfs[lookup_insert]>>
        rw[]>>
        simp[])
    >>
      Cases_on`h`>>fs[section_labels_def]
      >-
        (fs[line_length_def,line_ok_def,sec_length_def]>>
        fs[lab_insert_def]>>
        Cases_on`n=l1`>>fs[lookup_insert]
        >-
          (Cases_on`l2=n0`>>fs[]
          >-
            (IF_CASES_TAC>>rw[]
            >-
              metis_tac[pos_val_0]
            >>
            first_x_assum(qspecl_then[`pos`,`k`,`sec_list`] mp_tac)>>
            fs[sec_length_def,line_ok_def,sec_length_add]>>
            impl_tac>-
              metis_tac[]>>
            rw[]>>
            res_tac>>rfs[lookup_insert]>>
            pop_assum mp_tac>>
            TOP_CASE_TAC>>fs[])
          >>
          first_x_assum(qspecl_then[`pos`,`k`,`sec_list`] mp_tac)>>
          fs[sec_length_def,line_ok_def,sec_length_add]>>
          impl_tac>-
            metis_tac[]>>
          rw[]>>
          res_tac>>rfs[lookup_insert]>>
          pop_assum mp_tac>>
          TOP_CASE_TAC>>fs[])
        >>
          first_x_assum(qspecl_then[`pos`,`k`,`sec_list`] mp_tac)>>
          fs[sec_length_def,line_ok_def,sec_length_add]>>
          impl_tac>-
            metis_tac[]>>
          rw[]>>
          res_tac>>rfs[lookup_insert])
      >-
        (TOP_CASE_TAC>>fs[line_length_def]>>
        first_x_assum(qspecl_then[`pos+LENGTH l`,`k`,`sec_list`] mp_tac)>>
        fs[sec_length_def,line_ok_def,sec_length_add]>>
        impl_tac>-
          metis_tac[]>>
        strip_tac>>
        rveq>>fs[]>>
        res_tac>>
        rfs[lookup_insert]>>
        rw[]>>
        simp[])
      >>
        `n = LENGTH l` by
          (Cases_on`a`>>fs[line_ok_def])>>
        TOP_CASE_TAC>>fs[line_length_def]>>
        first_x_assum(qspecl_then[`pos+LENGTH l`,`k`,`sec_list`] mp_tac)>>
        fs[sec_length_def,line_ok_def,sec_length_add]>>
        impl_tac>-
          metis_tac[]>>
        strip_tac>>
        rveq>>fs[]>>
        res_tac>>
        rfs[lookup_insert]>>
        rw[]>>
        simp[]);

(*For a single section*)
val all_enc_ok_lab_lookup_even_lem = prove(``
  ∀lines c labs pos l1 l2 x lab k.
  all_enc_ok c labs pos [Section k lines] ∧
  (∀l1 l2 x. lab_lookup l1 l2 lab = SOME x ⇒ EVEN x) ∧
  lab_lookup l1 l2 (section_labels pos lines lab) = SOME x ⇒
  EVEN x``,
  Induct>>rw[section_labels_def]
  >-
    metis_tac[]
  >>
  Cases_on`h`>>TRY(Cases_on`a`)>>fs[section_labels_def,all_enc_ok_def,line_length_def,line_ok_def]
  >-
    (Cases_on`n0=0`>>fs[]>>rfs[]>- metis_tac[]>>fs[lab_lookup_insert]>>
    EVERY_CASE_TAC>>fs[]>>
    metis_tac[])
  >>
    (rveq>>fs[]>>
    metis_tac[]))

val all_enc_ok_split = prove(``
  ∀c labs pos k lines xs.
  all_enc_ok c labs pos (Section k lines::xs) ⇒
  all_enc_ok c labs pos [Section k lines] ∧
  all_enc_ok c labs (pos + sec_length lines 0) xs``,
  Induct_on`lines`>>rw[all_enc_ok_def,sec_length_def,all_enc_ok_def]>>
  Cases_on`h`>>TRY(Cases_on`a`)>>fs[sec_length_def,sec_length_add,line_length_def,line_ok_def]>>rveq>>rfs[]>>
  metis_tac[ADD_ASSOC])

val all_enc_ok_even = prove(``
  ∀lines pos.
  all_enc_ok c labs pos [Section k lines] ⇒
  EVEN (sec_length lines pos)``,
  Induct>>fs[all_enc_ok_def,sec_length_def]>>Cases>>
  TRY(Cases_on`a`)>>
  rw[]>>fs[line_ok_def,line_length_def,sec_length_add,sec_length_def]>>
  rfs[]>>
  `n + sec_length lines pos = sec_length lines (n + pos)` by
    metis_tac[sec_length_add,ADD_COMM]>>
  fs[])

val all_enc_ok_lab_lookup_even = prove(
  ``∀c labs pos sec_list l1 l2 x.
      all_enc_ok c labs pos sec_list ∧
      lab_lookup l1 l2 (compute_labels_alt pos sec_list) = SOME x ∧
      EVEN pos ⇒
      EVEN x``,
  Induct_on`sec_list`>>
  fs[all_enc_ok_def,compute_labels_alt_def,lab_lookup_insert]>>
  rw[]
  >-
    fs[lab_lookup_def,lookup_def]
  >>
  Cases_on`h`>>fs[compute_labels_alt_def,lab_lookup_insert]>>
  EVERY_CASE_TAC>>rveq>>fs[]>>
  imp_res_tac all_enc_ok_split>>
  match_mp_tac all_enc_ok_lab_lookup_even_lem>>
  first_assum (match_exists_tac o concl)>>
  fs[CONJ_COMM]>>
  first_assum (match_exists_tac o concl)>>fs[]>>rw[]>>
  first_assum match_mp_tac>>
  first_assum (match_exists_tac o concl)>>
  fs[GSYM PULL_EXISTS]>>
  (reverse CONJ_TAC>-
    (first_assum (match_exists_tac o concl)>>fs[CONJ_COMM]))>>
  Q.SPECL_THEN [`l`,`0`,`pos`] assume_tac (GSYM sec_length_add)>>
  fs[]>>
  metis_tac[all_enc_ok_even]);

val line_enc_with_nop_def = Define`
  (line_enc_with_nop enc labs pos (Asm b bytes len) ⇔
    enc_with_nop enc b bytes ∧ LENGTH bytes = len) ∧
  (line_enc_with_nop enc labs pos (LabAsm Halt _ bytes len) ⇔
    enc_with_nop enc (Jump (-n2w (pos + ffi_offset))) bytes ∧
    LENGTH bytes = len) ∧
  (line_enc_with_nop enc labs pos (LabAsm ClearCache _ bytes len) ⇔
    enc_with_nop enc (Jump (-n2w (pos + 2 * ffi_offset))) bytes ∧
    LENGTH bytes = len) ∧
  (line_enc_with_nop enc labs pos (LabAsm (CallFFI i) _ bytes len) ⇔
    enc_with_nop enc (Jump (-n2w (pos + (i + 3) * ffi_offset))) bytes ∧
    LENGTH bytes = len) ∧
  (line_enc_with_nop enc labs pos (LabAsm (Jump l) _ bytes len) ⇔
    enc_with_nop enc (Jump (n2w (find_pos l labs) + -n2w pos)) bytes ∧
    LENGTH bytes = len) ∧
  (line_enc_with_nop enc labs pos (LabAsm (JumpCmp a b c l) _ bytes len) ⇔
    enc_with_nop enc (JumpCmp a b c (n2w (find_pos l labs) + -n2w pos)) bytes ∧
    LENGTH bytes = len) ∧
  (line_enc_with_nop enc labs pos (LabAsm (LocValue k l) _ bytes len) ⇔
    enc_with_nop enc (Loc k (n2w (find_pos l labs) + -n2w pos)) bytes ∧
    LENGTH bytes = len) ∧
  (line_enc_with_nop enc labs pos (LabAsm _ _ bytes len) ⇔ LENGTH bytes = len) ∧
  (line_enc_with_nop enc labs pos (Label _ _ len) ⇔ len = 0)`;

val line_enc_with_nop_ind = theorem"line_enc_with_nop_ind";

val line_encd0_def = Define`
  (line_encd0 enc (Asm b bytes len) ⇔
    enc b = bytes ∧ len = LENGTH bytes) ∧
  (line_encd0 enc (LabAsm l w bytes len) ⇔
     enc (lab_inst w l) = bytes ∧ LENGTH bytes ≤ len ∧
     (∃w'. len = LENGTH (enc (lab_inst w' l)))) ∧
  (line_encd0 enc _ ⇔ T)`;

val sec_encd0_def = Define`
  sec_encd0 enc (Section _ ls) = EVERY (line_encd0 enc) ls`;
val _ = export_rewrites["sec_encd0_def"];

val _ = overload_on("all_encd0",``λenc l. EVERY (sec_encd0 enc) l``);

val line_len_def = Define`
  (line_len (Label _ _ l) = l) ∧
  (line_len (Asm _ _ l) = l) ∧
  (line_len (LabAsm _ _ _ l) = l)`;
val _ = export_rewrites["line_len_def"];

val line_length_leq_def = Define`
  (line_length_leq (LabAsm _ _ bytes l) ⇔
    LENGTH bytes ≤ l) ∧
  (line_length_leq (Asm _ bytes l) ⇔
    LENGTH bytes ≤ l) ∧
  (line_length_leq _ ⇔ T)`;
val _ = export_rewrites["line_length_leq_def"];

val sec_length_leq_def = Define`
  sec_length_leq (Section _ ls) = EVERY line_length_leq ls`;
val _ = export_rewrites["sec_length_leq_def"];

val _ = overload_on("all_length_leq",``λl. EVERY sec_length_leq l``);

val line_encd_def = Define`
  (line_encd enc labs pos (Asm b bytes len) ⇔
    enc b = bytes ∧ len = LENGTH bytes) ∧
  (line_encd enc labs pos (LabAsm Halt _ bytes len) ⇔
    enc (Jump (-n2w (pos + ffi_offset))) = bytes ∧
    LENGTH bytes ≤ len) ∧
  (line_encd enc labs pos (LabAsm ClearCache _ bytes len) ⇔
    enc (Jump (-n2w (pos + 2 * ffi_offset))) = bytes ∧
    LENGTH bytes ≤ len) ∧
  (line_encd enc labs pos (LabAsm (CallFFI i) _ bytes len) ⇔
    enc (Jump (-n2w (pos + (i + 3) * ffi_offset))) = bytes ∧
    LENGTH bytes ≤ len) ∧
  (line_encd enc labs pos (LabAsm (Jump l) _ bytes len) ⇔
    enc (Jump (n2w (find_pos l labs) + -n2w pos)) = bytes ∧
    LENGTH bytes ≤ len) ∧
  (line_encd enc labs pos (LabAsm (JumpCmp a b c l) _ bytes len) ⇔
    enc (JumpCmp a b c (n2w (find_pos l labs) + -n2w pos)) = bytes ∧
    LENGTH bytes ≤ len) ∧
  (line_encd enc labs pos (LabAsm (LocValue k l) _ bytes len) ⇔
    enc (Loc k (n2w (find_pos l labs) + -n2w pos)) = bytes ∧
    LENGTH bytes ≤ len) ∧
  (line_encd enc labs pos (LabAsm (Call l) _ bytes len) ⇔
    enc (Call (n2w (find_pos l labs) + -n2w pos)) = bytes ∧
    LENGTH bytes ≤ len) ∧
  (line_encd enc labs pos _ ⇔ T)`;

val line_encd_ind = theorem"line_encd_ind";

val lines_encd_def = Define`
  (lines_encd enc labs pos [] ⇔ T) ∧
  (lines_encd enc labs pos (l::ls) ⇔
   line_encd enc labs pos l ∧
   lines_encd enc labs (pos+line_len l) ls)`;

val all_encd_def = Define`
  (all_encd enc labs pos [] ⇔ T) ∧
  (all_encd enc labs pos (Section k ls::ss) ⇔
   lines_encd enc labs pos ls ∧
   all_encd enc labs (pos + SUM (MAP line_len ls)) ss)`;

val line_offset_ok_def = Define`
  (line_offset_ok labs pos (LabAsm a w bytes _) ⇔
    w = get_jump_offset a labs pos) ∧
  (line_offset_ok _ _ _ ⇔ T)`;

val lines_offset_ok_def = Define`
  (lines_offset_ok labs pos [] ⇔ T) ∧
  (lines_offset_ok labs pos (l::ls) ⇔
   line_offset_ok labs pos l ∧
   lines_offset_ok labs (pos + line_len l) ls)`;

val offset_ok_def = Define`
  (offset_ok labs pos [] ⇔ T) ∧
  (offset_ok labs pos (Section k ls::ss) ⇔
   lines_offset_ok labs pos ls ∧
   offset_ok labs (pos + SUM (MAP line_len ls)) ss)`;

val offset_ok_ind = theorem"offset_ok_ind";

val line_ok_light_imp_line_ok = Q.store_thm("line_ok_light_imp_line_ok",
  `∀c labs pos line.
     line_enc_with_nop c.encode labs pos line ∧
     line_offset_ok labs pos line ∧
     line_ok_light c line ∧ (is_Label line ⇒ EVEN pos) ⇒
     line_ok c labs pos line`,
  ho_match_mp_tac line_ok_ind
  \\ rw[line_ok_def,line_ok_light_def,get_label_def,lab_inst_def,line_enc_with_nop_def,
        line_offset_ok_def,get_jump_offset_def] \\ fs[]);

val all_enc_with_nop_def = Define`
  (all_enc_with_nop enc labs pos [] ⇔ T) ∧
  (all_enc_with_nop enc labs pos (Section k []::xs) ⇔
   all_enc_with_nop enc labs pos xs) ∧
  (all_enc_with_nop enc labs pos (Section k (y::ys)::xs) ⇔
   line_enc_with_nop enc labs pos y ∧
   all_enc_with_nop enc labs (pos + line_length y) (Section k ys::xs))`;

val all_enc_with_nop_ind = theorem"all_enc_with_nop_ind";

val even_labels_def = Define`
  (even_labels pos [] ⇔ T) ∧
  (even_labels pos (Section _ []::ls) ⇔ even_labels pos ls) ∧
  (even_labels pos (Section k (y::ys)::ls) ⇔
   (is_Label y ⇒ EVEN pos) ∧
   even_labels (pos + line_len y) (Section k ys::ls))`;

val even_labels_ind = theorem"even_labels_ind";

val lines_even_labels_def = Define`
  (lines_even_labels pos [] ⇔ T) ∧
  (lines_even_labels pos (y::ys) ⇔
   (is_Label y ⇒ EVEN pos) ∧
   lines_even_labels (pos + line_len y) ys)`;

val even_labels_alt = Q.store_thm("even_labels_alt",
  `(even_labels pos [] ⇔ T) ∧
   (even_labels pos (Section _ ls::ss) ⇔
    lines_even_labels pos ls ∧
    even_labels (pos + SUM (MAP line_len ls)) ss)`,
  rw[even_labels_def]
  \\ qid_spec_tac `pos`
  \\ Induct_on`ls`
  \\ rw[even_labels_def,lines_even_labels_def]
  \\ Cases_on`h` \\ fs[line_length_def]
  \\ metis_tac[]);

val even_labels_strong_def = Define`
  (even_labels_strong pos [] ⇔ T) ∧
  (even_labels_strong pos (Section _ []::ls) ⇔
    EVEN pos ∧ even_labels_strong pos ls) ∧
  (even_labels_strong pos (Section k (y::ys)::ls) ⇔
   (is_Label y ⇒ EVEN pos) ∧
   even_labels_strong (pos + line_len y) (Section k ys::ls))`;

val even_labels_ends_imp_strong = Q.store_thm("even_labels_ends_imp_strong",
  `∀pos code.
    even_labels pos code ∧
    EVERY sec_ends_with_label code ∧
    EVERY sec_label_zero code
    ⇒
    even_labels_strong pos code`,
  Induct_on`code`
  \\ simp[even_labels_def,even_labels_strong_def,sec_ends_with_label_def]
  \\ Cases \\ simp[sec_ends_with_label_def,sec_label_zero_def]
  \\ Induct_on`l` \\ fs[]
  \\ fs[even_labels_def,even_labels_strong_def]
  \\ Cases_on`l` \\ fs[even_labels_def,even_labels_strong_def]
  \\ Cases \\ fs[EVEN_ADD] \\ rw[] \\ fs[]);

val line_lab_len_pos_ok_def = Define`
  (line_lab_len_pos_ok pos (Label _ _ l) ⇔
     if EVEN pos then l = 0 else l = 1) ∧
  (line_lab_len_pos_ok _ _ ⇔ T)`;

val lab_len_pos_ok_def = Define`
  (lab_len_pos_ok pos [] ⇔ T) ∧
  (lab_len_pos_ok pos (l::ls) ⇔
     line_lab_len_pos_ok pos l ∧
     lab_len_pos_ok (pos + line_len l) ls)`;

val all_lab_len_pos_ok_def = Define`
  (all_lab_len_pos_ok _ [] ⇔ T) ∧
  (all_lab_len_pos_ok pos (Section k ls::ss) ⇔
   lab_len_pos_ok pos ls ∧
   all_lab_len_pos_ok (pos + sec_length ls 0) ss)`;

val all_lab_len_pos_ok_ind = theorem"all_lab_len_pos_ok_ind";

val line_length_ok_def = Define`
  line_length_ok l ⇔ LENGTH (line_bytes l) = line_len l`;

val sec_length_ok_def = Define`
  sec_length_ok (Section _ ls) = EVERY line_length_ok ls`;

val line_enc_with_nop_length_ok = Q.store_thm("line_enc_with_nop_length_ok",
  `∀enc labs pos line.
    line_enc_with_nop enc labs pos line ⇒ line_length_ok line`,
  recInduct line_enc_with_nop_ind
  \\ rw[line_enc_with_nop_def,line_length_ok_def,line_length_def,line_bytes_def]);

val line_enc_with_nop_label_zero = Q.store_thm("line_enc_with_nop_label_zero",
  `∀enc labs pos line.
    line_enc_with_nop enc labs pos line ⇒ label_zero line`,
  recInduct line_enc_with_nop_ind
  \\ rw[line_enc_with_nop_def]);

val all_enc_ok_light_imp_all_enc_ok = Q.store_thm("all_enc_ok_light_imp_all_enc_ok",
  `∀c labs pos code.
    all_enc_with_nop c.encode labs pos code ∧
    all_enc_ok_light c code ∧
    even_labels_strong pos code ∧
    offset_ok labs pos code
    ⇒
    all_enc_ok c labs pos code`,
  ho_match_mp_tac all_enc_ok_ind
  \\ rw[all_enc_ok_def,all_enc_with_nop_def,
        even_labels_strong_def,line_ok_light_imp_line_ok,
        offset_ok_def,lines_offset_ok_def]
  \\ imp_res_tac line_enc_with_nop_length_ok
  \\ imp_res_tac line_enc_with_nop_label_zero
  \\ fs[line_length_ok_def,line_length_def,sec_ends_with_label_def]
  \\ first_x_assum match_mp_tac
  \\ Cases_on`y` \\ fs[even_labels_alt,line_length_def]);

val lines_enc_with_nop_def = Define`
  (lines_enc_with_nop enc labs pos [] ⇔ T) ∧
  (lines_enc_with_nop enc labs pos (l::ls) ⇔
   line_enc_with_nop enc labs pos l ∧
   lines_enc_with_nop enc labs (pos+line_length l) ls)`;

val all_enc_with_nop_alt = Q.store_thm("all_enc_with_nop_alt",
  `(all_enc_with_nop enc labs pos [] ⇔ T) ∧
   (all_enc_with_nop enc labs pos (Section k ls::ss) ⇔
    lines_enc_with_nop enc labs pos ls ∧
    all_enc_with_nop enc labs (pos + SUM (MAP line_length ls)) ss)`,
  rw[all_enc_with_nop_def]
  \\ map_every qid_spec_tac[`pos`,`ls`]
  \\ Induct \\ rw[all_enc_with_nop_def,lines_enc_with_nop_def]
  \\ rw[EQ_IMP_THM]);

val line_length_add_nop1 = Q.store_thm("line_length_add_nop1",
  `∀nop ls.
   ¬EVERY is_Label ls ⇒
   SUM (MAP line_length (add_nop nop ls)) =
   SUM (MAP line_length ls) + LENGTH nop`,
  ho_match_mp_tac add_nop_ind
  \\ rw[add_nop_def,line_length_def]);

val line_length_add_nop = Q.store_thm("line_length_add_nop",
  `∀nop ls.
   EVERY is_Label ls ⇒
   SUM (MAP line_length (add_nop nop ls)) =
   SUM (MAP line_length ls)`,
  ho_match_mp_tac add_nop_ind
  \\ rw[add_nop_def,line_length_def]);

val EXISTS_not_Label_add_nop = Q.store_thm("EXISTS_not_Label_add_nop[simp]",
  `∀nop acc.
     EXISTS ($~ o is_Label) (add_nop nop acc) ⇔ EXISTS ($~ o is_Label) acc`,
  ho_match_mp_tac add_nop_ind \\ rw[add_nop_def]);

val EVERY_is_Label_add_nop = Q.store_thm("EVERY_is_Label_add_nop[simp]",
  `∀nop acc.
     EVERY is_Label (add_nop nop acc) ⇔ EVERY is_Label acc`,
  ho_match_mp_tac add_nop_ind \\ rw[add_nop_def]);

val add_nop_append = Q.store_thm("add_nop_append",
  `∀nop l1 l2.
    add_nop nop (l1++l2) = if EVERY is_Label l1 then l1 ++ add_nop nop l2 else add_nop nop l1 ++ l2`,
  ho_match_mp_tac add_nop_ind
  \\ rw[add_nop_def] \\ rw[] \\ fs[add_nop_def]);

val pad_section_acc1 = Q.store_thm("pad_section_acc1",
  `∀nop code aux aux2.
    ¬EVERY is_Label aux ⇒
    pad_section nop code (aux++aux2) =
      REVERSE aux2 ++ pad_section nop code aux`,
  ho_match_mp_tac pad_section_ind
  \\ rw[pad_section_def] \\ rw[] \\ fs[]
  \\ fs[add_nop_append]
  \\ rw[] \\ fs[]
  >- (metis_tac[NOT_EVERY])
  \\ first_x_assum match_mp_tac
  \\ Induct_on`aux` \\ fs[add_nop_def]
  \\ Cases \\ fs[add_nop_def]);

val lines_enc_with_nop_append = Q.store_thm("lines_enc_with_nop_append",
  `∀enc labs pos l1 l2.
   lines_enc_with_nop enc labs pos (l1 ++ l2) ⇔
   lines_enc_with_nop enc labs pos l1 ∧
   lines_enc_with_nop enc labs (pos + SUM (MAP line_length l1)) l2`,
  Induct_on`l1` \\ rw[lines_enc_with_nop_def,EQ_IMP_THM]);

val lines_enc_with_nop_pad_section = Q.store_thm("lines_enc_with_nop_pad_section",
  `∀enc labs l pos aux.
   0 < LENGTH (enc (Inst Skip)) ∧
   lines_enc_with_nop enc labs pos (REVERSE aux) ∧
   lines_encd enc labs (pos + SUM (MAP line_length aux)) l ∧
   EVERY line_length_ok l
   ⇒
   lines_enc_with_nop enc labs pos (pad_section (enc (Inst Skip)) l aux)`,
  Induct_on`l` \\ simp[lines_enc_with_nop_def,pad_section_def,lines_encd_def]
  \\ Cases \\ rw[pad_section_def,line_length_def]
  \\ first_x_assum match_mp_tac
  \\ fs[line_length_def,lines_enc_with_nop_append,line_length_ok_def]
  \\ fs[lines_enc_with_nop_def,line_length_add_nop1,line_enc_with_nop_def,line_encd_def,LENGTH_pad_bytes]
  \\ TRY (
    simp[enc_with_nop_thm,pad_bytes_def]
    \\ qexists_tac`0` \\ simp[REPLICATE] \\ NO_TAC)
  \\ TRY (
    Cases_on`a`\\fs[line_enc_with_nop_def,line_encd_def]
    \\ rw[enc_with_nop_thm,pad_bytes_def,MAP_REVERSE,SUM_REVERSE]
    \\ qexists_tac`0` \\ simp[REPLICATE] \\ NO_TAC)
  \\ fs[line_bytes_def]);

val sec_length_sum_line_len = Q.store_thm("sec_length_sum_line_len",
  `∀ls n.
    sec_length ls n = SUM (MAP line_len ls) + n`,
  ho_match_mp_tac sec_length_ind \\ rw[sec_length_def]);

val sec_length_sum_line_length = Q.store_thm("sec_length_sum_line_length",
  `∀ls n.
    EVERY line_length_ok ls ⇒
    (sec_length ls n = SUM (MAP line_length ls) + n)`,
  ho_match_mp_tac sec_length_ind
  \\ rw[sec_length_def,line_length_def]
  \\ fs[line_length_ok_def,line_bytes_def,line_length_def]);

val line_len_add_nop1 = Q.store_thm("line_len_add_nop1",
  `∀nop ls. ¬(EVERY is_Label ls) ⇒
    SUM (MAP line_len (add_nop nop ls)) =
    SUM (MAP line_len ls) + 1`,
  recInduct add_nop_ind \\ rw[add_nop_def]);

val line_len_add_nop = Q.store_thm("line_len_add_nop",
  `∀nop ls. EVERY is_Label ls ⇒
    SUM (MAP line_len (add_nop nop ls)) =
    SUM (MAP line_len ls)`,
  recInduct add_nop_ind \\ rw[add_nop_def]);

val enc_sec_list_encd0 = Q.store_thm("enc_sec_list_encd0",
  `∀ls. all_encd0 enc (enc_sec_list enc ls)`,
  Induct \\ fs[enc_sec_list_def]
  \\ Cases \\ simp[enc_sec_def,EVERY_MAP]
  \\ simp[EVERY_MEM]
  \\ Cases \\ simp[enc_line_def,line_encd0_def]
  \\ metis_tac[]);

val enc_lines_again_encd0 = Q.store_thm("enc_lines_again_encd0",
  `∀labs pos enc lines acc ok res ok'.
    enc_lines_again labs pos enc lines (acc,ok) = (res,ok') ∧
    EVERY (line_encd0 enc) lines ∧
    EVERY (line_encd0 enc) acc ⇒
    EVERY (line_encd0 enc) res`,
  recInduct enc_lines_again_ind
  \\ rw[enc_lines_again_def]
  \\ rw[EVERY_REVERSE] \\ fs[]
  \\ fs[line_encd0_def]
  \\ first_x_assum match_mp_tac
  \\ rw[MAX_DEF] \\ metis_tac[]);

val enc_secs_again_encd0 = Q.store_thm("enc_secs_again_encd0",
  `∀pos labs enc ls res ok.
    enc_secs_again pos labs enc ls = (res,ok) ∧
    all_encd0 enc ls ⇒
    all_encd0 enc res`,
  ho_match_mp_tac enc_secs_again_ind
  \\ rw[enc_secs_again_def] \\ rw[]
  \\ pairarg_tac \\ fs[]
  \\ pairarg_tac \\ fs[]
  \\ fs[] \\ rw[]
  \\ match_mp_tac enc_lines_again_encd0
  \\ asm_exists_tac \\ fs[]);

val enc_lines_again_simp_offset_ok = Q.store_thm("enc_lines_again_simp_offset_ok",
  `∀labs pos enc lines res ok.
    enc_lines_again_simp labs pos enc lines = (res,ok)
    ⇒
    lines_offset_ok labs pos res`,
  ho_match_mp_tac enc_lines_again_simp_ind
  \\ rw[enc_lines_again_simp_def]
  \\ fs[lines_offset_ok_def]
  \\ pairarg_tac \\ fs[]
  \\ rveq \\ fs[lines_offset_ok_def]
  \\ fs[line_offset_ok_def]);

val enc_secs_again_offset_ok = Q.store_thm("enc_secs_again_offset_ok",
  `∀pos labs enc ls res ok.
    enc_secs_again pos labs enc ls = (res,ok) ⇒
    offset_ok labs pos res`,
  ho_match_mp_tac enc_secs_again_ind
  \\ rw[enc_secs_again_def]
  \\ fs[offset_ok_def]
  \\ pairarg_tac \\ fs[]
  \\ pairarg_tac \\ fs[]
  \\ rveq \\ fs[offset_ok_def,sec_length_sum_line_len]
  \\ match_mp_tac enc_lines_again_simp_offset_ok
  \\ qspecl_then[`labs`,`pos`,`enc`,`lines`,`[]`,`T`]mp_tac enc_lines_again_simp_EQ
  \\ simp[] \\ pairarg_tac \\ fs[] \\ metis_tac[]);

val label_one_def = Define`
  (label_one (Label _ _ n) ⇔ n ≤ 1) ∧
  (label_one _ ⇔ T)`;
val _ = export_rewrites["label_one_def"];

val sec_label_one_def = Define`
  sec_label_one (Section _ ls) = EVERY label_one ls`;
val _ = export_rewrites["sec_label_one_def"];

val line_aligned_def = Define`
  line_aligned m l ⇔
    line_len l MOD m = 0 ∧
    line_length l MOD m = 0`;

val sec_aligned_def = Define`
  sec_aligned noplen (Section _ ls) = EVERY (line_aligned noplen) ls`;
val _ = export_rewrites["sec_aligned_def"];

val line_length_pad_section1 = Q.store_thm("line_length_pad_section1",
  `∀nop ls acc.
   LENGTH nop = 1 ∧
   EVERY label_one ls ∧
   EVERY line_length_leq ls ∧
   ¬EVERY is_Label acc ∧
   SUM (MAP line_length acc) = SUM (MAP line_len acc)
   ⇒
   SUM (MAP line_length (pad_section nop ls acc)) =
   SUM (MAP line_len ls) + SUM (MAP line_len acc)`,
  recInduct pad_section_ind
  \\ rw[pad_section_def]
  \\ fs[MAP_REVERSE,SUM_REVERSE,line_length_def,LENGTH_pad_bytes]
  \\ fs[line_length_add_nop1,line_len_add_nop1]);

val EVERY_is_Label_add_nop = Q.store_thm("EVERY_is_Label_add_nop",
  `∀nop ls. EVERY is_Label ls ⇒ add_nop nop ls = ls`,
  recInduct add_nop_ind \\ rw[add_nop_def]);

val pad_section_label_prefix = Q.store_thm("pad_section_label_prefix",
  `∀nop ls acc l1 l2.
    ls = l1 ++ l2 ∧
    EVERY is_Label l1 ∧
    EVERY is_Label acc
    ⇒
    pad_section nop ls acc =
    pad_section nop l2 (REVERSE (MAP (λx. case x of Label l1 l2 _ => Label l1 l2 0) l1) ++ acc)`,
  recInduct pad_section_ind
  \\ rw[pad_section_def]
  \\ qmatch_assum_rename_tac`_::_ = ll ++ _`
  \\ Cases_on`ll` \\ fs[pad_section_def] \\ rw[pad_section_def]
  \\ rw[EVERY_is_Label_add_nop] \\ fs[]);

val label_prefix_zero_def = Define`
  label_prefix_zero ls ⇔
     (∀n. n < LENGTH ls ∧ (∀m. m ≤ n ⇒ is_Label (EL m ls)) ⇒
        ∀m. m ≤ n ⇒ line_len (EL m ls) = 0)`;

val sec_label_prefix_zero_def = Define`
  sec_label_prefix_zero (Section k ls) ⇔ label_prefix_zero ls`;
val _ = export_rewrites["sec_label_prefix_zero_def"];

val label_prefix_zero_cons = Q.store_thm("label_prefix_zero_cons",
  `(label_prefix_zero (Label l1 l2 len::ls) ⇔ ((len = 0) ∧ label_prefix_zero ls)) ∧
   (label_prefix_zero (Asm a b c::ls) ⇔ T) ∧
   (label_prefix_zero (LabAsm d e f g::ls) ⇔ T)`,
  rw[label_prefix_zero_def]
  \\ TRY (
    Cases_on`n` \\ fs[]
    \\ first_x_assum(qspec_then`0`mp_tac)
    \\ simp[] \\ NO_TAC)
  \\ rw[EQ_IMP_THM]
  >- ( first_x_assum(qspec_then`0`mp_tac) \\ simp[] )
  >- (
    last_x_assum(qspec_then`SUC m`mp_tac) \\ simp[]
    \\ impl_tac >- (Cases \\ simp[])
    \\ disch_then(qspec_then`SUC m`mp_tac) \\ simp[] )
  \\ Cases_on`m` \\ fs[]
  \\ Cases_on`n` \\ fs[]
  \\ first_x_assum(match_mp_tac o MP_CANON)
  \\ first_assum(part_match_exists_tac (last o strip_conj) o concl)
  \\ simp[]
  \\ qx_gen_tac`z` \\ strip_tac
  \\ first_x_assum(qspec_then`SUC z`mp_tac)
  \\ simp[]);

val line_length_pad_section = Q.store_thm("line_length_pad_section",
  `∀nop ls acc.
   LENGTH nop = 1 ∧
   EVERY label_one ls ∧
   EVERY line_length_leq ls ∧
   SUM (MAP line_length acc) = SUM (MAP line_len acc) ∧
   EVERY is_Label acc ∧ label_prefix_zero ls
   ⇒
   SUM (MAP line_length (pad_section nop ls acc)) =
   SUM (MAP line_len ls) + SUM (MAP line_len acc)`,
  recInduct pad_section_ind
  \\ rw[pad_section_def]
  \\ fs[MAP_REVERSE,SUM_REVERSE,line_length_def,LENGTH_pad_bytes,label_prefix_zero_cons]
  \\ fs[line_length_add_nop,line_len_add_nop]
  \\ qmatch_goalsub_abbrev_tac`pad_section nop xs acc'`
  \\ qspecl_then[`nop`,`xs`,`acc'`]mp_tac line_length_pad_section1
  \\ simp[Abbr`acc'`,line_length_def,LENGTH_pad_bytes]);

(*
val tm = ``[Label 0 1 0; Label 0 2 1; Label 0 3 0; Label 0 4 1]``;
val tm = ``[Label 0 1 0; Label 0 2 1; Label 0 3 0; Label 0 4 1; Asm a [b] 1]``;
val tm = ``[Asm a [b] 1; Label 0 1 0; Label 0 2 1; Label 0 3 0; Label 0 4 1]``;
val th = EVAL ``pad_section nop ^tm  []``
val tm2 = th |> concl |> rhs
EVAL ``SUM (MAP line_length ^tm)``
EVAL ``SUM (MAP line_length ^tm2)``
*)

val enc_lines_again_simp_encd = Q.store_thm("enc_lines_again_simp_encd",
  `∀labs pos enc lines res.
    enc_lines_again_simp labs pos enc lines = (res,T) ∧
    EVERY label_one lines ∧
    EVERY (line_encd0 enc) lines
    ⇒
    lines_encd enc labs pos res`,
  ho_match_mp_tac enc_lines_again_simp_ind
  \\ rw[enc_lines_again_simp_def]
  \\ fs[lines_encd_def]
  \\ pairarg_tac \\ fs[]
  \\ rveq \\ simp[lines_encd_def]
  \\ fs[line_encd0_def,line_encd_def,line_length_def]
  \\ TRY (
    qmatch_assum_abbrev_tac`MAX l1 l = l`
    \\ `l1 ≤ l` by fs[MAX_DEF])
  \\ Cases_on`a` \\ fs[line_encd_def,get_jump_offset_def,lab_inst_def,get_label_def]);

val enc_lines_again_simp_len = Q.store_thm("enc_lines_again_simp_len",
  `∀labs pos enc lines res.
    enc_lines_again_simp labs pos enc lines = (res,T) ⇒
    MAP line_len res = MAP line_len lines`,
  recInduct enc_lines_again_simp_ind
  \\ rw[enc_lines_again_simp_def]
  \\ pairarg_tac \\ fs[] \\ rveq \\ fs[]);

val enc_secs_again_encd = Q.store_thm("enc_secs_again_encd",
  `∀pos labs enc ls res.
    enc_secs_again pos labs enc ls = (res,T) ∧
    EVERY sec_label_one ls ∧
    EVERY (sec_encd0 enc) ls
    ⇒
    all_encd enc labs pos res`,
  recInduct enc_secs_again_ind
  \\ rw[enc_secs_again_def]
  \\ fs[all_encd_def]
  \\ rpt(pairarg_tac \\ fs[])
  \\ rveq \\ fs[all_encd_def,sec_length_sum_line_len]
  \\ qspecl_then[`labs`,`pos`,`enc`,`lines`,`[]`,`T`]mp_tac enc_lines_again_simp_EQ
  \\ simp[] \\ pairarg_tac \\ fs[] \\ strip_tac \\ rveq
  \\ imp_res_tac enc_lines_again_simp_len \\ fs[]
  \\ imp_res_tac enc_lines_again_simp_encd);

val lines_upd_lab_len_label_one = Q.store_thm("lines_upd_lab_len_label_one",
  `∀pos ls acc.
    EVERY label_one acc ⇒
    EVERY label_one (lines_upd_lab_len pos ls acc)`,
  recInduct lines_upd_lab_len_ind
  \\ rw[lines_upd_lab_len_def] \\ fs[EVERY_REVERSE]);

val upd_lab_len_label_one = Q.store_thm("upd_lab_len_label_one",
  `∀pos ss. EVERY sec_label_one (upd_lab_len pos ss)`,
  ho_match_mp_tac upd_lab_len_ind
  \\ rw[upd_lab_len_def]
  \\ rw[lines_upd_lab_len_label_one]);

val lines_upd_lab_len_encd0 = Q.store_thm("lines_upd_lab_len_encd0",
  `∀pos ls acc.
    EVERY (line_encd0 enc) ls ∧
    EVERY (line_encd0 enc) acc ⇒
    EVERY (line_encd0 enc) (lines_upd_lab_len pos ls acc)`,
  recInduct lines_upd_lab_len_ind
  \\ rw[lines_upd_lab_len_def]
  \\ fs[EVERY_REVERSE,line_encd0_def]);

val upd_lab_len_encd0 = Q.store_thm("upd_lab_len_encd0",
  `∀pos ss. all_encd0 enc ss ⇒ all_encd0 enc (upd_lab_len pos ss)`,
  recInduct upd_lab_len_ind
  \\ rw[upd_lab_len_def] \\ fs[]
  \\ match_mp_tac lines_upd_lab_len_encd0
  \\ fs[]);

val label_prefix_zero_append_suff = Q.store_thm("label_prefix_zero_append_suff",
  `∀l1 l2.
   label_prefix_zero l1 ∧ label_prefix_zero l2 ⇒
   label_prefix_zero (l1 ++ l2)`,
  Induct
  >- simp[label_prefix_zero_def]
  \\ Cases \\ simp[label_prefix_zero_cons]);

val label_prefix_zero_append_suff2 = Q.store_thm("label_prefix_zero_append_suff2",
  `∀l1 l2.
   label_prefix_zero l1 ∧ EXISTS ($~ o is_Label) l1 ⇒
   label_prefix_zero (l1 ++ l2)`,
  Induct
  >- simp[label_prefix_zero_def]
  \\ Cases \\ simp[label_prefix_zero_cons]);

val lines_upd_lab_len_label_prefix_zero = Q.store_thm("lines_upd_lab_len_label_prefix_zero",
  `∀pos ls acc.
    (EVERY is_Label acc ⇒ EVEN pos) ∧ label_prefix_zero (REVERSE acc) ⇒
    label_prefix_zero (lines_upd_lab_len pos ls acc)`,
  recInduct lines_upd_lab_len_ind
  \\ rw[lines_upd_lab_len_def]
  \\ first_x_assum match_mp_tac \\ fs[EVEN_ADD]
  \\ TRY (
    match_mp_tac label_prefix_zero_append_suff \\ fs[]
    \\ fs[label_prefix_zero_def] \\ NO_TAC)
  \\ match_mp_tac label_prefix_zero_append_suff2
  \\ simp[EXISTS_REVERSE]);

val EVEN_sec_length_lines_upd_lab_len = Q.store_thm("EVEN_sec_length_lines_upd_lab_len",
  `∀pos lines acc.
    (if NULL lines then
     EVEN pos ∧ EVEN (SUM (MAP line_len acc))
    else is_Label (LAST lines) ∧
         EVEN (pos + (SUM (MAP line_len acc))))
    ⇒
    EVEN (SUM (MAP line_len (lines_upd_lab_len pos lines acc)))`,
  recInduct lines_upd_lab_len_ind
  \\ rw[lines_upd_lab_len_def,MAP_REVERSE,SUM_REVERSE]
  \\ Cases_on`xs` \\ fs[]
  \\ first_x_assum match_mp_tac
  \\ fs[EVEN_ADD,EVEN_MULT]);

val upd_lab_len_label_prefix_zero = Q.store_thm("upd_lab_len_label_prefix_zero",
  `∀pos ss.
    EVEN pos ∧ EVERY sec_ends_with_label ss ⇒
    EVERY sec_label_prefix_zero (upd_lab_len pos ss)`,
  recInduct upd_lab_len_ind
  \\ rw[upd_lab_len_def]
  \\ fs[EVEN_ADD]
  >- (
    match_mp_tac lines_upd_lab_len_label_prefix_zero
    \\ simp[label_prefix_zero_def] )
  \\ first_x_assum match_mp_tac
  \\ fs[sec_ends_with_label_def]
  \\ simp[sec_length_sum_line_len]
  \\ match_mp_tac EVEN_sec_length_lines_upd_lab_len
  \\ simp[EVEN_ADD]);

val lines_upd_lab_len_similar = Q.store_thm("lines_upd_lab_len_similar",
  `∀pos lines aux.
    LIST_REL line_similar (lines_upd_lab_len pos lines aux) (REVERSE aux ++ lines)`,
  recInduct lines_upd_lab_len_ind
  \\ rw[lines_upd_lab_len_def] \\ fs[]
  \\ TRY (
    match_mp_tac EVERY2_REVERSE
    \\ simp[LIST_REL_EL_EQN,line_similar_refl] )
  \\ match_mp_tac EVERY2_TRANS
  \\ asm_exists_tac \\ simp[]
  \\ (reverse conj_tac >- metis_tac[line_similar_trans])
  \\ once_rewrite_tac[GSYM APPEND_ASSOC]
  \\ match_mp_tac EVERY2_APPEND_suff
  \\ simp[line_similar_def]
  \\ conj_tac
  \\ TRY (match_mp_tac EVERY2_REVERSE)
  \\ simp[LIST_REL_EL_EQN,line_similar_refl]);

val upd_lab_len_ends_with_label = Q.store_thm("upd_lab_len_ends_with_label",
  `∀pos ss.
    EVERY sec_ends_with_label ss ⇒
    EVERY sec_ends_with_label (upd_lab_len pos ss)`,
  recInduct upd_lab_len_ind
  \\ rw[upd_lab_len_def]
  \\ fs[sec_ends_with_label_def]
  \\ qspecl_then[`pos`,`lines`,`[]`]mp_tac lines_upd_lab_len_similar
  \\ simp[]
  \\ Q.ISPEC_THEN`lines`FULL_STRUCT_CASES_TAC SNOC_CASES \\ fs[]
  \\ fs[LIST_REL_SNOC]
  \\ strip_tac \\ fs[SNOC_APPEND]
  \\ Cases_on`x` \\ Cases_on`x'` \\ fs[line_similar_def]);

val line_encd_length_leq = Q.store_thm("line_encd_length_leq",
  `∀enc labs pos l. line_encd enc labs pos l ⇒ line_length_leq l`,
  recInduct line_encd_ind \\ rw[line_encd_def,line_length_leq_def]);

val lines_encd_length_leq = Q.store_thm("lines_encd_length_leq",
  `∀enc labs pos ls. lines_encd enc labs pos ls ⇒ EVERY line_length_leq ls`,
  Induct_on`ls` \\ rw[lines_encd_def]
  \\ metis_tac[line_encd_length_leq]);

val all_encd_length_leq = Q.store_thm("all_encd_length_leq",
  `∀enc labs pos ls. all_encd enc labs pos ls ⇒ all_length_leq ls`,
  Induct_on`ls` \\ simp[]
  \\ Cases \\ simp[all_encd_def]
  \\ metis_tac[lines_encd_length_leq]);

val enc_with_nop_pad_bytes_length = Q.store_thm("enc_with_nop_pad_bytes_length",
  `enc_with_nop enc x (pad_bytes (enc x) (LENGTH (enc x)) (enc (Inst Skip)))`,
  rw[enc_with_nop_thm,pad_bytes_def]
  \\ qexists_tac`0` \\ simp[REPLICATE] )

val enc_with_nop_pad_bytes = Q.store_thm("enc_with_nop_pad_bytes",
  `nop = enc (Inst Skip) ∧ LENGTH (enc x) ≤ len ∧
   LENGTH (enc x) MOD (LENGTH nop) = 0 ∧
   len MOD (LENGTH nop) = 0 ∧
   0 < LENGTH nop
   ⇒ enc_with_nop enc x (pad_bytes (enc x) len nop)`,
  rw[enc_with_nop_thm,pad_bytes_def]
  >- (qexists_tac`0` \\ simp[REPLICATE])
  \\ simp[TAKE_APPEND2]
  \\ drule (GEN_ALL MOD_EQ_0_DIVISOR)
  \\ disch_then (drule o #1 o EQ_IMP_RULE o SPEC_ALL)
  \\ qpat_x_assum`LENGTH _ MOD _ = _`assume_tac
  \\ drule (GEN_ALL MOD_EQ_0_DIVISOR)
  \\ disch_then (drule o #1 o EQ_IMP_RULE o SPEC_ALL)
  \\ rw[] \\ rw[] \\ fs[]
  \\ fs[NOT_LESS_EQUAL]
  \\ fs[GSYM RIGHT_SUB_DISTRIB]
  \\ qmatch_goalsub_rename_tac`a:num - b`
  \\ qexists_tac`a-b`
  \\ once_rewrite_tac[MULT_COMM]
  \\ match_mp_tac TAKE_FLAT_REPLICATE_LEQ \\ simp[]
  \\ match_mp_tac LESS_EQ_TRANS
  \\ qexists_tac`a * LENGTH (enc (Inst Skip))`
  \\ simp[]);

val lines_enc_with_nop_length_ok = Q.store_thm("lines_enc_with_nop_length_ok",
  `∀enc labs pos ls. lines_enc_with_nop enc labs pos ls ⇒ EVERY line_length_ok ls`,
  Induct_on`ls` \\ simp[lines_enc_with_nop_def]
  \\ Cases \\ simp[line_length_ok_def,line_bytes_def,line_enc_with_nop_def,line_length_def]
  \\ rw[]
  \\ TRY(first_x_assum match_mp_tac \\ metis_tac[])
  \\ Cases_on`a` \\ fs[line_enc_with_nop_def]);

val add_nop_labels = Q.store_thm("add_nop_labels",
  `∀nop ls. EVERY is_Label ls ⇒ add_nop nop ls = ls`,
  recInduct add_nop_ind \\ rw[add_nop_def]);

val lines_enc_with_nop_add_nop = Q.store_thm("lines_enc_with_nop_add_nop",
  `∀enc labs pos ls.
    LENGTH (enc (Inst Skip)) = 1 ∧
    lines_enc_with_nop enc labs pos (REVERSE ls) ⇒
    lines_enc_with_nop enc labs pos
      (REVERSE (add_nop (enc (Inst Skip)) ls))`,
  Induct_on`ls`
  \\ rw[lines_enc_with_nop_def,add_nop_def]
  \\ simp[add_nop_append,REVERSE_APPEND,lines_enc_with_nop_append,lines_enc_with_nop_def]
  \\ Cases_on`h`\\fs[add_nop_def,line_enc_with_nop_def,EVERY_REVERSE]
  \\ rw[] \\ fs[lines_enc_with_nop_append,REVERSE_APPEND,lines_enc_with_nop_def,line_enc_with_nop_def]
  \\ fs[line_length_def]
  >- (
    fs[enc_with_nop_thm,LENGTH_EQ_NUM_compute]
    \\ qmatch_goalsub_rename_tac`REPLICATE z`
    \\ qexists_tac`SUC z`
    \\ simp[REPLICATE_GENLIST,GENLIST] )
  \\ Cases_on`a` \\ fs[line_enc_with_nop_def]
  \\ fs[enc_with_nop_thm,LENGTH_EQ_NUM_compute]
  \\ qmatch_goalsub_rename_tac`REPLICATE z`
  \\ qexists_tac`SUC z`
  \\ simp[REPLICATE_GENLIST,GENLIST] )

val lines_enc_with_nop_pad_section1 = Q.store_thm("lines_enc_with_nop_pad_section1",
  `∀nop code aux pos.
    nop = enc (Inst Skip) ∧ LENGTH nop = 1 ∧
    lines_encd enc labs (pos + (SUM (MAP line_len aux))) code ∧
    lines_enc_with_nop enc labs pos (REVERSE aux) ∧
    ¬EVERY is_Label aux ∧
    EVERY label_one code
    ⇒
    lines_enc_with_nop enc labs pos (pad_section nop code aux)`,
  recInduct pad_section_ind
  \\ rw[pad_section_def,lines_enc_with_nop_append]
  \\ fs[lines_enc_with_nop_def,line_enc_with_nop_def]
  \\ first_x_assum match_mp_tac
  \\ fs[lines_encd_def]
  \\ fs[line_encd_def]
  \\ fs[line_len_add_nop1,LENGTH_pad_bytes]
  >- (
    `len=1` by simp[] \\ fs[]
    \\ match_mp_tac lines_enc_with_nop_add_nop
    \\ fs[])
  >- (
    rveq
    \\ MATCH_ACCEPT_TAC enc_with_nop_pad_bytes_length )
  >- (
    imp_res_tac lines_enc_with_nop_length_ok
    \\ imp_res_tac sec_length_sum_line_length
    \\ first_x_assum(qspec_then`0`mp_tac)
    \\ rw[sec_length_sum_line_len]
    \\ Cases_on`y` \\ fs[line_encd_def,line_enc_with_nop_def]
    \\ rveq \\ fs[MAP_REVERSE,SUM_REVERSE,LENGTH_pad_bytes]
    \\ qmatch_abbrev_tac`enc_with_nop enc x (pad_bytes (enc x) len nop)`
    \\ match_mp_tac enc_with_nop_pad_bytes \\ fs[]));

val lines_enc_with_nop_pad_section = Q.store_thm("lines_enc_with_nop_pad_section",
  `∀nop code aux pos.
    nop = enc (Inst Skip) ∧ LENGTH nop = 1 ∧
    lines_encd enc labs (pos + SUM (MAP line_len aux)) code ∧
    lines_enc_with_nop enc labs pos (REVERSE aux) ∧
    EVERY is_Label aux ∧ EVERY label_one code ∧ label_prefix_zero code ⇒
    lines_enc_with_nop enc labs pos (pad_section nop code aux)`,
  recInduct pad_section_ind
  \\ rw[pad_section_def,lines_enc_with_nop_append]
  \\ rfs[EVERY_is_Label_add_nop,label_prefix_zero_cons]
  \\ TRY (
    first_x_assum match_mp_tac
    \\ fs[lines_encd_def,line_encd_def,lines_enc_with_nop_def,line_enc_with_nop_def] )
  \\ match_mp_tac lines_enc_with_nop_pad_section1
  \\ simp[lines_enc_with_nop_append]
  \\ TRY (qmatch_goalsub_rename_tac`LabAsm y` \\ Cases_on`y`)
  \\ fs[lines_encd_def,lines_enc_with_nop_def,line_enc_with_nop_def,LENGTH_pad_bytes,line_encd_def]
  \\ rveq \\ TRY (MATCH_ACCEPT_TAC enc_with_nop_pad_bytes_length)
  \\ imp_res_tac lines_enc_with_nop_length_ok
  \\ imp_res_tac sec_length_sum_line_length
  \\ first_x_assum(qspec_then`0`mp_tac)
  \\ rw[sec_length_sum_line_len]
  \\ fs[MAP_REVERSE,SUM_REVERSE]
  \\ match_mp_tac enc_with_nop_pad_bytes \\ fs[]);

val lines_enc_with_nop_pad_section01 = Q.store_thm("lines_enc_with_nop_pad_section01",
  `∀nop code aux pos.
    nop = enc (Inst Skip) ∧ 0 < LENGTH nop ∧
    EVERY (line_aligned (LENGTH nop)) code ∧
    lines_encd enc labs (pos + SUM (MAP line_len aux)) code ∧
    lines_enc_with_nop enc labs pos (REVERSE aux) ∧
    ¬EVERY is_Label aux ∧ EVERY label_zero code ⇒
    lines_enc_with_nop enc labs pos (pad_section nop code aux)`,
  recInduct pad_section_ind
  \\ rw[pad_section_def,lines_enc_with_nop_def]
  \\ first_x_assum match_mp_tac
  \\ fs[lines_enc_with_nop_append,lines_enc_with_nop_def,line_enc_with_nop_def]
  \\ fs[lines_encd_def,line_encd_def,LENGTH_pad_bytes]
  \\ rveq
  \\ TRY (MATCH_ACCEPT_TAC enc_with_nop_pad_bytes_length)
  \\ fs[line_aligned_def,line_length_def]
  \\ Cases_on`y`
  \\ fs[lines_encd_def,line_encd_def,LENGTH_pad_bytes,line_enc_with_nop_def]
  \\ rveq
  \\ imp_res_tac lines_enc_with_nop_length_ok
  \\ imp_res_tac sec_length_sum_line_length
  \\ first_x_assum(qspec_then`0`mp_tac)
  \\ rw[sec_length_sum_line_len]
  \\ fs[MAP_REVERSE,SUM_REVERSE]
  \\ match_mp_tac enc_with_nop_pad_bytes \\ fs[]);

val lines_enc_with_nop_pad_section0 = Q.store_thm("lines_enc_with_nop_pad_section0",
  `∀nop code aux pos.
    nop = enc (Inst Skip) ∧ 0 < LENGTH nop ∧
    EVERY (line_aligned (LENGTH nop)) code ∧
    lines_encd enc labs (pos + SUM (MAP line_len aux)) code ∧
    lines_enc_with_nop enc labs pos (REVERSE aux) ∧
    EVERY is_Label aux ∧ EVERY label_zero code ⇒
    lines_enc_with_nop enc labs pos (pad_section nop code aux)`,
  recInduct pad_section_ind
  \\ rw[pad_section_def,lines_enc_with_nop_def]
  \\ TRY (
    first_x_assum match_mp_tac
    \\ fs[lines_enc_with_nop_append,lines_enc_with_nop_def,line_enc_with_nop_def,lines_encd_def])
  \\ match_mp_tac lines_enc_with_nop_pad_section01
  \\ fs[lines_enc_with_nop_append,lines_encd_def,
        lines_enc_with_nop_def,line_enc_with_nop_def,line_encd_def]
  \\ rveq \\ fs[LENGTH_pad_bytes]
  \\ TRY (MATCH_ACCEPT_TAC enc_with_nop_pad_bytes_length)
  \\ fs[line_aligned_def,line_length_def]
  \\ Cases_on`y`
  \\ fs[line_enc_with_nop_def,line_encd_def,LENGTH_pad_bytes]
  \\ rveq
  \\ imp_res_tac lines_enc_with_nop_length_ok
  \\ imp_res_tac sec_length_sum_line_length
  \\ first_x_assum(qspec_then`0`mp_tac)
  \\ rw[sec_length_sum_line_len]
  \\ fs[MAP_REVERSE,SUM_REVERSE]
  \\ match_mp_tac enc_with_nop_pad_bytes \\ fs[]);

val label_zero_line_length_pad_section = Q.store_thm("label_zero_line_length_pad_section",
  `∀nop ls acc.
   0 < LENGTH nop ∧
   EVERY label_zero ls ∧
   MAP line_length acc = MAP line_len acc ∧
   EVERY line_length_leq ls
   ⇒
   MAP line_length (pad_section nop ls acc) =
   MAP line_len (REVERSE acc ++ ls)`,
  recInduct pad_section_ind
  \\ rw[pad_section_def,line_length_def,MAP_REVERSE]
  \\ fs[pad_section_def]
  \\ fs[LENGTH_pad_bytes]);

val all_enc_with_nop_pad_code = Q.store_thm("all_enc_with_nop_pad_code",
  `∀nop code pos.
   0 < LENGTH nop ∧ nop = enc (Inst Skip) ∧
   (LENGTH nop ≠ 1 ⇒ EVERY (sec_aligned (LENGTH nop)) code ∧ EVERY sec_label_zero code) ∧
   EVERY sec_label_one code ∧
   EVERY sec_length_leq code ∧
   EVERY sec_label_prefix_zero code ∧
   all_encd enc labs pos code ⇒
   all_enc_with_nop enc labs pos (pad_code nop code)`,
  recInduct pad_code_ind
  \\ reverse(rw[pad_code_def,all_enc_with_nop_alt,all_encd_def])
  \\ fs[]
  >- (
    first_x_assum match_mp_tac
    \\ fs[sec_label_zero_def]
    \\ Cases_on`LENGTH (enc (Inst Skip)) = 1`
    >- (
      qspecl_then[`enc (Inst Skip)`,`xs`,`[]`]mp_tac line_length_pad_section
      \\ simp[] )
    \\ fs[label_zero_line_length_pad_section])
  \\ Cases_on`LENGTH (enc (Inst Skip)) = 1`
  >- (
    match_mp_tac lines_enc_with_nop_pad_section
    \\ fs[lines_enc_with_nop_def] )
  \\ match_mp_tac lines_enc_with_nop_pad_section0
  \\ fs[sec_label_zero_def,lines_enc_with_nop_def]);

val enc_lines_again_simp_label_one = Q.store_thm("enc_lines_again_simp_label_one",
  `∀labs pos enc ls res ok.
    enc_lines_again_simp labs pos enc ls = (res,ok) ∧
    EVERY label_one ls ⇒
    EVERY label_one res`,
  recInduct enc_lines_again_simp_ind
  \\ rw[enc_lines_again_simp_def] \\ fs[]
  \\ pairarg_tac \\ fs[] \\ rveq \\ fs[]);

val enc_secs_again_label_one = Q.store_thm("enc_secs_again_label_one",
  `∀pos labs enc lines res ok.
    enc_secs_again pos labs enc lines = (res,ok) ∧
    EVERY sec_label_one lines ⇒
    EVERY sec_label_one res`,
  recInduct enc_secs_again_ind
  \\ rw[enc_secs_again_def] \\ fs[]
  \\ rpt(pairarg_tac \\ fs[])
  \\ rveq \\ fs[]
  \\ match_mp_tac enc_lines_again_simp_label_one
  \\ qspecl_then[`labs`,`pos`,`enc`,`lines`,`[]`,`T`]mp_tac enc_lines_again_simp_EQ
  \\ simp[] \\ pairarg_tac \\ rw[]
  \\ metis_tac[]);

val enc_lines_again_simp_label_zero = Q.store_thm("enc_lines_again_simp_label_zero",
  `∀labs pos enc ls res ok.
    enc_lines_again_simp labs pos enc ls = (res,ok) ∧
    EVERY label_zero ls ⇒
    EVERY label_zero res`,
  recInduct enc_lines_again_simp_ind
  \\ rw[enc_lines_again_simp_def] \\ fs[]
  \\ pairarg_tac \\ fs[] \\ rveq \\ fs[]);

val enc_secs_again_label_zero = Q.store_thm("enc_secs_again_label_zero",
  `∀pos labs enc lines res ok.
    enc_secs_again pos labs enc lines = (res,ok) ∧
    EVERY sec_label_zero lines ⇒
    EVERY sec_label_zero res`,
  recInduct enc_secs_again_ind
  \\ rw[enc_secs_again_def] \\ fs[]
  \\ rpt(pairarg_tac \\ fs[])
  \\ rveq \\ fs[sec_label_zero_def]
  \\ match_mp_tac enc_lines_again_simp_label_zero
  \\ qspecl_then[`labs`,`pos`,`enc`,`lines`,`[]`,`T`]mp_tac enc_lines_again_simp_EQ
  \\ simp[] \\ pairarg_tac \\ rw[]
  \\ metis_tac[]);

val enc_lines_again_simp_aligned = Q.store_thm("enc_lines_again_simp_aligned",
  `∀labs pos enc ls res ok.
    (∀a. LENGTH (enc a) MOD len = 0) ∧
    enc_lines_again_simp labs pos enc ls = (res,ok) ∧
    EVERY (line_aligned len) ls ⇒
    EVERY (line_aligned len) res`,
  recInduct enc_lines_again_simp_ind
  \\ rw[enc_lines_again_simp_def] \\ fs[]
  \\ pairarg_tac \\ fs[] \\ rveq \\ fs[]
  \\ fs[line_aligned_def,line_length_def,MAX_DEF]
  \\ IF_CASES_TAC \\ fs[]);

val enc_secs_again_aligned = Q.store_thm("enc_secs_again_aligned",
  `∀pos labs enc lines res ok.
    (∀a. LENGTH (enc a) MOD len = 0) ∧
    enc_secs_again pos labs enc lines = (res,ok) ∧
    EVERY (sec_aligned len) lines ⇒
    EVERY (sec_aligned len) res`,
  recInduct enc_secs_again_ind
  \\ rw[enc_secs_again_def] \\ fs[]
  \\ rpt(pairarg_tac \\ fs[])
  \\ rveq \\ fs[]
  \\ match_mp_tac enc_lines_again_simp_aligned
  \\ qspecl_then[`labs`,`pos`,`enc`,`lines`,`[]`,`T`]mp_tac enc_lines_again_simp_EQ
  \\ simp[] \\ pairarg_tac \\ rw[]
  \\ metis_tac[]);

val enc_lines_again_simp_label_prefix_zero = Q.store_thm("enc_lines_again_simp_label_prefix_zero",
  `∀labs pos enc ls res ok.
    enc_lines_again_simp labs pos enc ls = (res,ok) ∧
    label_prefix_zero ls ⇒
    label_prefix_zero res`,
  recInduct enc_lines_again_simp_ind
  \\ rw[enc_lines_again_simp_def]
  \\ rpt(pairarg_tac \\ fs[]) \\ fs[]
  \\ rveq \\ fs[label_prefix_zero_cons]);

val enc_secs_again_label_prefix_zero = Q.store_thm("enc_secs_again_label_prefix_zero",
  `∀pos labs enc lines res ok.
    enc_secs_again pos labs enc lines = (res,ok) ∧
    EVERY sec_label_prefix_zero lines ⇒
    EVERY sec_label_prefix_zero res`,
  recInduct enc_secs_again_ind
  \\ rw[enc_secs_again_def] \\ fs[]
  \\ rpt(pairarg_tac \\ fs[]) \\ rveq \\ fs[]
  \\ match_mp_tac enc_lines_again_simp_label_prefix_zero
  \\ qspecl_then[`labs`,`pos`,`enc`,`lines`,`[]`,`T`]mp_tac enc_lines_again_simp_EQ
  \\ simp[] \\ pairarg_tac \\ rw[]
  \\ metis_tac[]);

val enc_lines_again_simp_ends_with_label = Q.store_thm("enc_lines_again_simp_ends_with_label",
  `∀labs pos enc ls res ok.
    enc_lines_again_simp labs pos enc ls = (res,ok) ∧
    ¬NULL ls ∧ is_Label (LAST ls) ⇒
    ¬NULL res ∧ is_Label (LAST res)`,
  recInduct enc_lines_again_simp_ind
  \\ rw[enc_lines_again_simp_def]
  \\ rpt(pairarg_tac \\ fs[]) \\ fs[]
  \\ rveq \\ fs[LAST_CONS_cond]
  \\ rw[] \\ fs[NULL_EQ] \\ rw[] \\ fs[]
  \\ every_case_tac \\ fs[]
  \\ fs[enc_lines_again_simp_def]);

val enc_secs_again_ends_with_label = Q.store_thm("enc_secs_again_ends_with_label",
  `∀pos labs enc lines res ok.
    enc_secs_again pos labs enc lines = (res,ok) ∧
    EVERY sec_ends_with_label lines ⇒
    EVERY sec_ends_with_label res`,
  recInduct enc_secs_again_ind
  \\ rw[enc_secs_again_def] \\ fs[]
  \\ rpt(pairarg_tac \\ fs[]) \\ rveq \\ fs[]
  \\ fs[sec_ends_with_label_def]
  \\ match_mp_tac enc_lines_again_simp_ends_with_label
  \\ qspecl_then[`labs`,`pos`,`enc`,`lines`,`[]`,`T`]mp_tac enc_lines_again_simp_EQ
  \\ simp[] \\ pairarg_tac \\ rw[]
  \\ metis_tac[]);

val enc_sec_list_ends_with_label = Q.store_thm("enc_sec_list_ends_with_label",
  `∀enc code.
   EVERY sec_ends_with_label code ⇒
   EVERY sec_ends_with_label (enc_sec_list enc code)`,
  Induct_on`code` \\ fs[enc_sec_list_def]
  \\ Cases \\ fs[enc_sec_def,sec_ends_with_label_def]
  \\ Induct_on`l` \\ fs[LAST_CONS_cond]
  \\ Cases \\ gen_tac \\ IF_CASES_TAC \\ fs[enc_line_def,NULL_EQ]);

val lines_upd_lab_len_encd0_label_zero = Q.store_thm("lines_upd_lab_len_encd0_label_zero",
  `∀pos lines aux.
    enc_ok c ∧ enc = c.encode ∧ c.code_alignment ≠ 0 ∧
    EVERY (line_encd0 enc) lines ∧ EVEN pos ∧
    EVERY label_zero aux ⇒
    EVERY label_zero (lines_upd_lab_len pos lines aux)`,
  recInduct lines_upd_lab_len_ind
  \\ rw[lines_upd_lab_len_def,EVERY_REVERSE]
  \\ first_x_assum match_mp_tac
  \\ fs[EVEN_ADD,line_encd0_def]
  \\ fs[enc_ok_def]
  \\ rfs[GSYM bitTheory.MOD_2EXP_def]
  \\ metis_tac[MOD_2EXP_0_EVEN,NOT_ZERO_LT_ZERO]);

val upd_lab_len_encd0_label_zero = Q.store_thm("upd_lab_len_encd0_label_zero",
  `∀pos code.
    enc_ok c ∧ enc = c.encode ∧ c.code_alignment ≠ 0 ∧
    all_encd0 enc code ∧ EVEN pos ∧ EVERY sec_ends_with_label code ⇒
    EVERY sec_label_zero (upd_lab_len pos code)`,
  recInduct upd_lab_len_ind
  \\ rw[upd_lab_len_def,sec_label_zero_def] \\ fs[EVEN_ADD]
  \\ TRY (
    first_x_assum match_mp_tac
    \\ simp[sec_length_sum_line_len]
    \\ match_mp_tac EVEN_sec_length_lines_upd_lab_len
    \\ fs[EVEN_ADD,sec_ends_with_label_def] )
  \\ match_mp_tac (GEN_ALL lines_upd_lab_len_encd0_label_zero)
  \\ fs[] \\ asm_exists_tac \\ fs[]);

val all_encd0_aligned = Q.store_thm("all_encd0_aligned",
  `∀c enc code.
   enc_ok c ∧ enc = c.encode ∧
   all_encd0 enc code ∧
   EVERY sec_label_zero code ⇒
   EVERY (sec_aligned (LENGTH (enc (Inst Skip)))) code`,
  ntac 2 gen_tac
  \\ Induct \\ simp[]
  \\ Cases \\ simp[sec_label_zero_def]
  \\ strip_tac \\ fs[]
  \\ Induct_on`l` \\ fs[]
  \\ Cases
  \\ fs[line_encd0_def,line_aligned_def,line_length_def,enc_ok_def]
  \\ strip_tac \\ rfs[] \\ rveq \\ fs[] \\ rw[]
  \\ match_mp_tac ZERO_MOD
  \\ simp[]
  \\ metis_tac[bitTheory.ZERO_LT_TWOEXP]);

val line_len_pad_section0 = Q.store_thm("line_len_pad_section0",
  `∀nop ls aux.
   EVERY label_zero ls ⇒
   SUM (MAP line_len (pad_section nop ls aux)) =
   SUM (MAP line_len ls) + SUM (MAP line_len aux)`,
  recInduct pad_section_ind
  \\ rw[pad_section_def,MAP_REVERSE,SUM_REVERSE]);

val lines_even_labels_append = Q.store_thm("lines_even_labels_append",
  `∀l1 l2 pos.
    lines_even_labels pos (l1 ++ l2) ⇔
    lines_even_labels pos l1 ∧
    lines_even_labels (pos + SUM (MAP line_len l1)) l2`,
  Induct \\ simp[lines_even_labels_def]
  \\ fsrw_tac[DNF_ss][EQ_IMP_THM] \\ rw[]
  \\ full_simp_tac std_ss [ADD_COMM]
  \\ full_simp_tac std_ss [ADD_ASSOC]
  \\ metis_tac[]);

val lines_upd_lab_len_pos_ok = Q.store_thm("lines_upd_lab_len_pos_ok",
  `∀pos lines.
    lab_len_pos_ok pos (lines_upd_lab_len pos lines [])`,
  Induct_on`lines`
  \\ simp[lines_upd_lab_len_def,lab_len_pos_ok_def]
  \\ reverse Cases \\ simp[lines_upd_lab_len_def]
  \\ simp[Once lines_upd_lab_len_AUX,lab_len_pos_ok_def]
  \\ simp[line_lab_len_pos_ok_def] )

val upd_lab_len_pos_ok = Q.store_thm("upd_lab_len_pos_ok",
  `∀pos code.
    all_lab_len_pos_ok pos (upd_lab_len pos code)`,
  recInduct upd_lab_len_ind
  \\ rw[all_lab_len_pos_ok_def,upd_lab_len_def,lines_upd_lab_len_pos_ok])

val enc_lines_again_simp_pos_ok = Q.store_thm("enc_lines_again_simp_pos_ok",
  `∀labs pos enc lines res.
    enc_lines_again_simp labs pos enc lines = (res,T) ∧
    lab_len_pos_ok pos lines ⇒
    lab_len_pos_ok pos res`,
  recInduct enc_lines_again_simp_ind
  \\ rw[enc_lines_again_simp_def] \\ fs[]
  \\ pairarg_tac \\ fs[] \\ rveq
  \\ fs[lab_len_pos_ok_def]
  \\ fs[line_lab_len_pos_ok_def]);

val enc_secs_again_pos_ok = Q.store_thm("enc_secs_again_pos_ok",
  `∀pos labs enc code res.
    enc_secs_again pos labs enc code = (res,T) ∧
    all_lab_len_pos_ok pos code ⇒
    all_lab_len_pos_ok pos res`,
  recInduct enc_secs_again_ind
  \\ rw[enc_secs_again_def] \\ fs[]
  \\ rpt(pairarg_tac \\ fs[]) \\ rveq
  \\ qspecl_then[`labs`,`pos`,`enc`,`lines`,`[]`,`T`]mp_tac enc_lines_again_simp_EQ
  \\ rw[] \\ pairarg_tac \\ fs[] \\ rveq
  \\ imp_res_tac enc_lines_again_simp_len
  \\ fs[sec_length_sum_line_len,all_lab_len_pos_ok_def]
  \\ imp_res_tac enc_lines_again_simp_pos_ok);

val lab_len_pos_ok_append = Q.store_thm("lab_len_pos_ok_append",
  `∀l1 pos l2.
   lab_len_pos_ok pos (l1 ++ l2) ⇔
   lab_len_pos_ok pos l1 ∧
   lab_len_pos_ok (pos + SUM (MAP line_len l1)) l2`,
  Induct \\ simp[lab_len_pos_ok_def]
  \\ metis_tac[]);

val label_zero_pos_ok_lines_even_labels = Q.store_thm("label_zero_pos_ok_lines_even_labels",
  `∀pos ls.
    EVERY label_zero ls ∧
    lab_len_pos_ok pos ls
    ⇒
    lines_even_labels pos ls`,
  Induct_on`ls` \\ simp[lines_even_labels_def,lab_len_pos_ok_def]
  \\ Cases \\ simp[line_lab_len_pos_ok_def]
  \\ rpt strip_tac \\ rfs[]);

val label_zero_pos_ok_even_labels = Q.store_thm("label_zero_pos_ok_even_labels",
  `∀pos code.
   EVERY sec_label_zero code ∧
   all_lab_len_pos_ok pos code
   ⇒
   even_labels pos code`,
  recInduct all_lab_len_pos_ok_ind
  \\ rw[all_lab_len_pos_ok_def,even_labels_alt,
        sec_length_sum_line_len,sec_label_zero_def]
  \\ match_mp_tac label_zero_pos_ok_lines_even_labels
  \\ fs[]);

val lab_len_pos_ok_even_prefix_zero = Q.store_thm("lab_len_pos_ok_even_prefix_zero",
  `∀pos ls.
    EVEN pos ∧
    lab_len_pos_ok pos ls ⇒
    label_prefix_zero ls`,
  Induct_on`ls`
  >- rw[lab_len_pos_ok_def,label_prefix_zero_def]
  \\ Cases
  \\ rw[lab_len_pos_ok_def,label_prefix_zero_cons,line_lab_len_pos_ok_def]
  \\ fs[] \\ metis_tac[]);

val pad_section_pos_ok = Q.store_thm("pad_section_pos_ok",
  `∀nop lines aux pos.
    lab_len_pos_ok (pos + SUM (MAP line_len aux)) lines  ∧
    lab_len_pos_ok pos (REVERSE aux) ∧
    EVERY label_zero aux ∧
    ((NULL aux ∨ is_Label (HD aux)) ⇒ label_prefix_zero lines)
    ⇒
    lab_len_pos_ok pos (pad_section nop lines aux)`,
  recInduct pad_section_ind
  \\ rw[pad_section_def,lab_len_pos_ok_def]
  \\ fs[pad_section_def]
  \\ first_x_assum match_mp_tac
  \\ fs[lab_len_pos_ok_append,SUM_REVERSE,MAP_REVERSE]
  \\ fs[lab_len_pos_ok_def,line_lab_len_pos_ok_def,label_prefix_zero_cons]
  \\ rfs[]
  >- (
    match_mp_tac lab_len_pos_ok_even_prefix_zero
    \\ metis_tac[] )
  \\ fs[EVEN_ADD]
  \\ `¬EVERY is_Label aux`
  by ( Cases_on`aux` \\ fs[])
  \\ fs[line_len_add_nop1,EVEN_ADD,add_nop_label_zero]
  \\ reverse conj_tac
  >- (
    match_mp_tac lab_len_pos_ok_even_prefix_zero
    \\ first_assum(part_match_exists_tac(last o strip_conj) o concl)
    \\ fs[EVEN_ADD]
    \\ metis_tac[] )
  \\ reverse conj_tac >- metis_tac[]
  \\ pop_assum kall_tac
  \\ Cases_on`aux`\\fs[]
  \\ Cases_on`h` \\ fs[add_nop_def,lab_len_pos_ok_append]
  \\ fs[lab_len_pos_ok_def,line_lab_len_pos_ok_def]);

(*
  val code = ``[Label a1 b1 0; Label a2 b2 0; Asm x3 [b3] 1; Label a4 b4 1; Label a5 b5 0]``
  EVAL ``lab_len_pos_ok 0 ^code``
  EVAL ``(pad_section nop ^code [])``
  EVAL ``lab_len_pos_ok 0 (pad_section nop ^code [])``

  [Label a1 b1 0; Label a2 b2 0; Asm x3 [b3] 1; Label a4 b4 1; Label a5 b5 0]
  []

  [Label a2 b2 0; Asm x3 [b3] 1; Label a4 b4 1; Label a5 b5 0]
  [Label a1 b1 0]

  [Asm x3 [b3] 1; Label a4 b4 1; Label a5 b5 0]
  [Label a2 b2 0; Label a1 b1 0]

  [Label a4 b4 1; Label a5 b5 0]
  [Asm x3 [b3] 1; Label a2 b2 0; Label a1 b1 0]

  [Label a5 b5 0]
  [Label a4 b4 0; Asm x3 [b3;nop] 2; Label a2 b2 0; Label a1 b1 0]
*)

val line_len_pad_section1 = Q.store_thm("line_len_pad_section1",
  `∀nop xs aux.
   LENGTH nop = 1 ∧
   EVERY label_one xs ∧
   ¬EVERY is_Label aux
   ⇒
   SUM (MAP line_len (pad_section nop xs aux)) =
   SUM (MAP line_len xs) + SUM (MAP line_len aux)`,
  recInduct pad_section_ind
  \\ rw[pad_section_def,MAP_REVERSE,SUM_REVERSE,line_len_add_nop1]);

val line_len_pad_section = Q.store_thm("line_len_pad_section",
  `∀nop xs aux.
    LENGTH nop = 1 ∧
    EVERY label_one xs ∧
    (EVERY is_Label aux ⇒ label_prefix_zero xs)
    ⇒
    SUM (MAP line_len (pad_section nop xs aux)) =
    SUM (MAP line_len xs) + SUM (MAP line_len aux)`,
  recInduct pad_section_ind
  \\ rw[pad_section_def,SUM_REVERSE,MAP_REVERSE,label_prefix_zero_cons]
  \\ fs[line_len_add_nop1]
  \\ `len=1` by decide_tac \\ fs[]
  \\ first_x_assum match_mp_tac
  \\ metis_tac[NOT_EVERY]);

val all_lab_len_pos_ok_pad_code = Q.store_thm("all_lab_len_pos_ok_pad_code",
  `∀nop code pos.
    all_lab_len_pos_ok pos code ∧
    (LENGTH nop ≠ 1 ⇒ EVERY sec_label_zero code) ∧
    EVERY sec_label_one code ∧
    EVERY sec_label_prefix_zero code
    ⇒
    all_lab_len_pos_ok pos (pad_code nop code)`,
  recInduct pad_code_ind
  \\ rw[all_lab_len_pos_ok_def,pad_code_def]
  >- (
    match_mp_tac pad_section_pos_ok
    \\ simp[lab_len_pos_ok_def] )
  \\ first_x_assum match_mp_tac \\ fs[]
  \\ reverse(Cases_on`LENGTH nop = 1`) \\ fs[]
  >- (
    fs[sec_length_sum_line_len,sec_label_zero_def,line_len_pad_section0] )
  \\ fs[sec_length_sum_line_len]
  \\ qspecl_then[`nop`,`xs`,`[]`]mp_tac line_len_pad_section
  \\ simp[]);

val lines_offset_ok_append = Q.store_thm("lines_offset_ok_append",
  `∀labs pos l1 l2.
    lines_offset_ok labs pos (l1 ++ l2) ⇔
    lines_offset_ok labs pos l1 ∧
    lines_offset_ok labs (pos + SUM (MAP line_len l1)) l2`,
  Induct_on`l1` \\ rw[lines_offset_ok_def,EQ_IMP_THM]);

val lines_offset_ok_pad_section = Q.store_thm("lines_offset_ok_pad_section",
  `∀nop lines aux labs pos.
    lab_len_pos_ok (pos + SUM (MAP line_len aux)) lines ∧
    lab_len_pos_ok pos (REVERSE aux) ∧ EVERY label_zero aux ∧
    (¬NULL lines ∧ is_Label (HD lines) ∧ line_len (HD lines) = 1 ⇒
     ¬NULL aux ∧ ¬is_Label (HD aux)) ∧
    lines_offset_ok labs pos (REVERSE aux ++ lines) ⇒
    lines_offset_ok labs pos (pad_section nop lines aux)`,
  recInduct pad_section_ind
  \\ rw[pad_section_def,lines_offset_ok_append,lines_offset_ok_def,
        lab_len_pos_ok_append,lab_len_pos_ok_def,line_lab_len_pos_ok_def]
  \\ fs[MAP_REVERSE,SUM_REVERSE,SUM_APPEND]
  \\ TRY (
    first_x_assum match_mp_tac \\ fs[line_offset_ok_def]
    \\ spose_not_then strip_assume_tac
    \\ Cases_on`xs` \\ fs[lab_len_pos_ok_def]
    \\ Cases_on`h` \\ fs[line_lab_len_pos_ok_def]
    \\ NO_TAC)
  \\ Cases_on`aux` \\ fs[]
  \\ Cases_on`h`
  \\ fs[lines_offset_ok_append,MAP_REVERSE,SUM_REVERSE,add_nop_def,
        lines_offset_ok_def,line_offset_ok_def]
  \\ first_x_assum match_mp_tac
  \\ fs[lab_len_pos_ok_append,lab_len_pos_ok_def,line_lab_len_pos_ok_def,EVEN_ADD]
  \\ (conj_tac >- metis_tac[])
  \\ spose_not_then strip_assume_tac
  \\ Cases_on`xs` \\ fs[lab_len_pos_ok_def]
  \\ Cases_on`h` \\ fs[line_lab_len_pos_ok_def]
  \\ fs[EVEN_ADD]
  \\ metis_tac[]);

val offset_ok_pad_code = Q.store_thm("offset_ok_pad_code",
  `∀labs pos code.
    (LENGTH nop ≠ 1 ⇒ EVERY sec_label_zero code) ∧
    EVERY sec_label_one code ∧
    EVERY sec_label_prefix_zero code ∧
    all_lab_len_pos_ok pos code ∧
    offset_ok labs pos code ⇒
    offset_ok labs pos (pad_code nop code)`,
  recInduct offset_ok_ind
  \\ rw[offset_ok_def,pad_code_def,sec_label_zero_def]
  \\ fs[]
  \\ `SUM (MAP line_len (pad_section nop ls [])) =
      SUM (MAP line_len ls)`
  by (
    Cases_on`LENGTH nop = 1` \\ fs[]
    >- simp[line_len_pad_section]
    \\ simp[line_len_pad_section0] )
  \\ fs[all_lab_len_pos_ok_def,sec_length_sum_line_len]
  \\ qspecl_then[`nop`,`ls`,`[]`,`labs`,`pos`]mp_tac lines_offset_ok_pad_section
  \\ fs[lab_len_pos_ok_def]
  \\ disch_then match_mp_tac
  \\ spose_not_then strip_assume_tac
  \\ Cases_on`ls` \\ fs[]
  \\ Cases_on`h` \\ fs[label_prefix_zero_cons]);

val all_enc_with_nop_label_zero = Q.store_thm("all_enc_with_nop_label_zero",
  `∀enc labs pos ls.
    all_enc_with_nop enc labs pos ls ⇒
    EVERY sec_label_zero ls`,
  recInduct all_enc_with_nop_ind
  \\ rw[all_enc_with_nop_def,sec_label_zero_def]
  \\ metis_tac[line_enc_with_nop_label_zero]);

val pad_code_ends_with_label = Q.store_thm("pad_code_ends_with_label",
  `∀nop ls.
    EVERY sec_ends_with_label ls ⇒
    EVERY sec_ends_with_label (pad_code nop ls)`,
  recInduct pad_code_ind
  \\ simp[pad_code_def,sec_ends_with_label_def]
  \\ rpt gen_tac \\ ntac 2 strip_tac
  \\ qspecl_then[`nop`,`xs`,`[]`,`xs`]mp_tac line_similar_pad_section
  \\ simp[]
  \\ impl_tac >- ( metis_tac[EVERY2_refl,line_similar_refl] )
  \\ Q.ISPEC_THEN`xs`FULL_STRUCT_CASES_TAC SNOC_CASES \\ fs[]
  \\ rw[LIST_REL_SNOC,SNOC_APPEND] \\ fs[]
  \\ Cases_on`x`
  \\ Cases_on`y` \\ fs[line_similar_def]);

val enc_lines_again_section_labels = Q.store_thm("enc_lines_again_section_labels",
  `∀labs pos enc lines res acc.
    enc_lines_again_simp labs pos enc lines = (res,T) ⇒
    section_labels pos lines acc = section_labels pos res acc`,
  recInduct enc_lines_again_simp_ind
  \\ rw[enc_lines_again_simp_def,section_labels_def]
  \\ rpt(pairarg_tac \\ fs[])
  \\ rw[section_labels_def]);

val enc_secs_again_compute_labels = Q.store_thm("enc_secs_again_compute_labels",
  `∀pos labs enc secs res.
   enc_secs_again pos labs enc secs = (res,T)
   ⇒
   compute_labels_alt pos res =
   compute_labels_alt pos secs`,
  recInduct enc_secs_again_ind
  \\ rw[enc_secs_again_def]
  \\ rpt(pairarg_tac \\ fs[])
  \\ rw[compute_labels_alt_def]
  \\ AP_TERM_TAC
  \\ qspecl_then[`labs`,`pos`,`enc`,`lines`,`[]`,`T`]mp_tac enc_lines_again_simp_EQ
  \\ simp[] \\ pairarg_tac \\ fs[] \\ strip_tac \\ rveq
  \\ imp_res_tac enc_lines_again_simp_len
  \\ fs[sec_length_sum_line_len]
  \\ imp_res_tac enc_lines_again_section_labels
  \\ simp[]);

val section_labels_append = Q.store_thm("section_labels_append",
  `∀pos l1 labs l2.
    section_labels pos (l1 ++ l2) labs =
    section_labels pos l1 (section_labels (pos + (SUM (MAP line_len l1))) l2 labs)`,
  recInduct section_labels_ind
  \\ rw[section_labels_def]);

(*
  val code = ``[Label 1 1 0; Label 1 2 0; Asm x3 [b3] 1; Label 1 3 1; Label 1 4 0]``
  EVAL ``section_labels 0 ^code LN``
  EVAL ``(pad_section nop ^code [])``
  EVAL ``section_labels 0 (pad_section nop ^code []) LN``

  [Label 1 1 0; Label 1 2 0; Asm x3 [b3] 1; Label 1 3 1; Label 1 4 0]
  []

  [Label 1 2 0; Asm x3 [b3] 1; Label 1 3 1; Label 1 4 0]
  [Label 1 1 0]

  [Asm x3 [b3] 1; Label 1 3 1; Label 1 4 0]
  [Label 1 2 0; Label 1 1 0]

  [Label 1 3 1; Label 1 4 0]
  [Asm x3 [b3] 1; Label 1 2 0; Label 1 1 0]

  [Label 1 4 0]
  [Label 1 3 0; Asm x3 [b3;nop] 2; Label 1 2 0; Label 1 1 0]
*)

val pad_section_labels = Q.store_thm("pad_section_labels",
  `∀nop lines aux pos labs.
    lab_len_pos_ok (pos + SUM (MAP line_len aux)) lines ∧
    lab_len_pos_ok pos (REVERSE aux) ∧ EVERY label_zero aux ∧
    (¬NULL lines ∧ is_Label (HD lines) ∧ line_len (HD lines) = 1 ⇒
     ¬NULL aux ∧ ¬is_Label (HD aux))
    ⇒
    section_labels pos (pad_section nop lines aux) labs =
    section_labels pos (REVERSE aux ++ lines) labs`,
  recInduct pad_section_ind
  \\ rw[section_labels_def,pad_section_def,section_labels_append,
        lab_len_pos_ok_append,lab_len_pos_ok_def,line_lab_len_pos_ok_def,
        label_prefix_zero_cons]
  \\ fs[MAP_REVERSE,SUM_REVERSE,line_len_add_nop1,SUM_APPEND]
  \\ rw[] \\ fs[]
  \\ TRY (
    first_x_assum match_mp_tac \\ fs[]
    \\ spose_not_then strip_assume_tac
    \\ Cases_on`xs` \\ fs[lab_len_pos_ok_def]
    \\ Cases_on`h` \\ fs[line_lab_len_pos_ok_def] )
  \\ Cases_on`aux` \\ fs[]
  \\ Cases_on`h` \\ fs[section_labels_append,MAP_REVERSE,SUM_REVERSE,add_nop_def,section_labels_def]
  \\ first_x_assum match_mp_tac
  \\ fs[lab_len_pos_ok_append,lab_len_pos_ok_def,line_lab_len_pos_ok_def,EVEN_ADD]
  \\ (conj_tac >- metis_tac[])
  \\ spose_not_then strip_assume_tac
  \\ Cases_on`xs` \\ fs[lab_len_pos_ok_def]
  \\ Cases_on`h` \\ fs[line_lab_len_pos_ok_def]
  \\ fs[EVEN_ADD]
  \\ metis_tac[]);

val pad_code_compute_labels = Q.store_thm("pad_code_compute_labels",
  `∀pos code.
    EVERY sec_label_one code ∧
    (LENGTH nop ≠ 1 ⇒ EVERY sec_label_zero code) ∧
    EVERY sec_label_prefix_zero code ∧
    all_lab_len_pos_ok pos code
    ⇒
    compute_labels_alt pos (pad_code nop code) =
    compute_labels_alt pos code`,
  recInduct compute_labels_alt_ind
  \\ rw[compute_labels_alt_def,pad_code_def,all_lab_len_pos_ok_def]
  \\ fs[sec_length_sum_line_len,sec_label_zero_def]
  \\ AP_TERM_TAC
  \\ `SUM (MAP line_len (pad_section nop lines [])) =
      SUM (MAP line_len lines)`
  by (
    Cases_on`LENGTH nop = 1` \\ fs[]
    >- simp[line_len_pad_section]
    \\ simp[line_len_pad_section0] )
  \\ fs[]
  \\ qpat_abbrev_tac`labs = compute_labels_alt _ _`
  \\ qspecl_then[`nop`,`lines`,`[]`,`pos`,`labs`]mp_tac pad_section_labels
  \\ fs[lab_len_pos_ok_def]
  \\ disch_then match_mp_tac
  \\ spose_not_then strip_assume_tac
  \\ Cases_on`lines` \\ fs[]
  \\ Cases_on`h` \\ fs[label_prefix_zero_cons]);

val remove_labels_loop_thm = Q.prove(
  `∀n c code code2 labs.
    remove_labels_loop n c code = SOME (code2,labs) ∧
    good_syntax mc_conf code LN ∧
    EVERY sec_ends_with_label code ∧
    all_encd0 mc_conf.target.config.encode code ∧
    c = mc_conf.target.config ∧
    enc_ok mc_conf.target.config
    ⇒
    all_enc_ok mc_conf.target.config labs 0 code2 /\
    code_similar code code2 /\ (pos_val 0 0 code2 = 0) /\
    (has_odd_inst code2 ⇒ mc_conf.target.config.code_alignment = 0) /\
    (!l1 l2 x. lab_lookup l1 l2 labs = SOME x ==> EVEN x) /\
    !l1 l2 x2.
      loc_to_pc l1 l2 code = SOME x2 ==>
      lab_lookup l1 l2 labs = SOME (pos_val x2 0 code2)`,
  HO_MATCH_MP_TAC remove_labels_loop_ind  >> rpt gen_tac >> strip_tac
  >> simp[Once remove_labels_loop_def]
  >> rpt gen_tac
  >> pairarg_tac \\ fs []
  >> reverse IF_CASES_TAC >> full_simp_tac(srw_ss())[]
  >> strip_tac >> rveq THEN1
   (full_simp_tac(srw_ss())[]
    >> last_x_assum mp_tac
    >> impl_tac >- (
      srw_tac[][good_syntax_def]
      >- (
        match_mp_tac enc_secs_again_ends_with_label
        \\ metis_tac[] )
      \\ match_mp_tac enc_secs_again_encd0
      \\ metis_tac[] )
    >> simp[] >> strip_tac >> fs []
    >> drule enc_secs_again_IMP_similar
    >> metis_tac [code_similar_trans,code_similar_loc_to_pc])
  \\ pairarg_tac \\ fs []
  \\ rpt var_eq_tac \\ fs []
  \\ qmatch_abbrev_tac`all_enc_ok c labs 0 (pad_code nop sec_list) ∧ _`
  \\ qmatch_assum_abbrev_tac`enc_secs_again 0 labs0 enc code = (code1,T)`
  \\ qpat_x_assum`Abbrev(code1 = _)`kall_tac
  \\ `all_encd0 enc code1` by imp_res_tac enc_secs_again_encd0
  \\ qmatch_assum_abbrev_tac`enc_secs_again 0 labs enc code2 = (sec_list,T)`
  \\ `EVERY sec_label_one code2` by metis_tac[upd_lab_len_label_one]
  \\ `all_encd0 enc code2` by metis_tac[upd_lab_len_encd0,enc_secs_again_encd0]
  \\ `all_encd enc labs 0 sec_list` by metis_tac[enc_secs_again_encd]
  \\ `LENGTH nop ≠ 1 ⇒
      EVERY (sec_aligned (LENGTH nop)) sec_list ∧
      EVERY sec_label_zero sec_list`
  by (
    strip_tac
    \\ qmatch_assum_abbrev_tac`enc_ok c`
    \\ `c.code_alignment ≠ 0`
    by ( strip_tac \\ fs[enc_ok_def] )
    \\ `EVERY sec_ends_with_label code1`
    by metis_tac[enc_secs_again_ends_with_label]
    \\ `EVERY sec_label_zero code2`
    by (
      simp[Abbr`code2`]
      \\ match_mp_tac (GEN_ALL upd_lab_len_encd0_label_zero)
      \\ asm_exists_tac \\ fs[] )
    \\ reverse conj_tac
    >- metis_tac[enc_secs_again_label_zero]
    \\ match_mp_tac enc_secs_again_aligned
    \\ fs[enc_ok_def] \\ rfs[]
    \\ CONV_TAC(RESORT_EXISTS_CONV(sort_vars["enc"]))
    \\ qexists_tac`enc` \\ simp[]
    \\ asm_exists_tac \\ simp[]
    \\ simp[Abbr`nop`]
    \\ match_mp_tac all_encd0_aligned
    \\ fs[enc_ok_def]
    \\ metis_tac[])
  \\ `EVERY sec_label_one sec_list` by metis_tac[enc_secs_again_label_one]
  \\ `all_length_leq sec_list` by metis_tac[all_encd_length_leq]
  \\ `EVERY sec_label_prefix_zero code2`
  by (
    simp[Abbr`code2`]
    \\ match_mp_tac upd_lab_len_label_prefix_zero
    \\ simp[]
    \\ match_mp_tac enc_secs_again_ends_with_label
    \\ asm_exists_tac \\ fs[])
  \\ `EVERY sec_label_prefix_zero sec_list`
  by metis_tac[enc_secs_again_label_prefix_zero]
  \\ `all_lab_len_pos_ok 0 sec_list`
  by metis_tac[enc_secs_again_pos_ok,upd_lab_len_pos_ok]
  \\ conj_asm1_tac
  >- (
    match_mp_tac all_enc_ok_light_imp_all_enc_ok \\ fs[]
    \\ conj_asm1_tac
    >- (
      match_mp_tac all_enc_with_nop_pad_code
      \\ fs[enc_ok_def]
      \\ first_x_assum(CHANGED_TAC o SUBST1_TAC o SYM)
      \\ simp[] )
    \\ conj_tac
    >- (
      match_mp_tac even_labels_ends_imp_strong
      \\ reverse conj_asm2_tac
      >- metis_tac[enc_secs_again_ends_with_label,upd_lab_len_ends_with_label,
                   pad_code_ends_with_label,all_enc_with_nop_label_zero]
      \\ match_mp_tac label_zero_pos_ok_even_labels \\ fs[]
      \\ match_mp_tac all_lab_len_pos_ok_pad_code \\ fs[])
    \\ match_mp_tac offset_ok_pad_code \\ fs[]
    \\ metis_tac[enc_secs_again_offset_ok])
  \\ conj_asm1_tac
  THEN1 (imp_res_tac enc_secs_again_IMP_similar \\
         metis_tac [code_similar_trans,code_similar_sym,code_similar_upd_lab_len,code_similar_pad_code])
  \\ conj_tac THEN1 (match_mp_tac pos_val_0_0 \\ simp[])
  \\ conj_tac THEN1
   (strip_tac
    \\ match_mp_tac has_odd_inst_alignment
    \\ asm_exists_tac \\ srw_tac[][]
    \\ asm_exists_tac \\ srw_tac[][])
  \\ drule pad_code_compute_labels
  \\ disch_then(qspec_then`0`mp_tac)
  \\ impl_tac >- fs[]
  \\ drule enc_secs_again_compute_labels \\ fs[]
  \\ rw [Abbr`labs`]
  THEN1 (
    match_mp_tac all_enc_ok_lab_lookup_even>>
    first_assum (match_exists_tac o concl)>>fs[]>>
    metis_tac[])
  \\ qhdtm_assum`compute_labels_alt`sym_sub_tac
  \\ fs [] \\ match_mp_tac (lab_lookup_compute_labels_test |> GEN_ALL)
  \\ fs[GSYM PULL_EXISTS]
  \\ CONJ_TAC>- metis_tac[]
  \\ qpat_x_assum `_ = SOME x2` (fn th => fs [GSYM th])
  \\ match_mp_tac code_similar_loc_to_pc
  \\ match_mp_tac code_similar_sym
  \\ match_mp_tac code_similar_pad_code
  \\ imp_res_tac enc_secs_again_IMP_similar
  \\ fs [code_similar_upd_lab_len,Abbr`code2`]
  \\ metis_tac [code_similar_trans]);

val loc_to_pc_enc_sec_list = Q.store_thm("loc_to_pc_enc_sec_list[simp]",
  `∀l1 l2 code.
     loc_to_pc l1 l2 (enc_sec_list e code) = loc_to_pc l1 l2 code`,
  simp[enc_sec_list_def]
  >> ho_match_mp_tac loc_to_pc_ind
  >> srw_tac[][]
  >> srw_tac[][Once loc_to_pc_def,enc_sec_def]
  >> srw_tac[][Once loc_to_pc_def,SimpRHS]
  >> match_mp_tac EQ_SYM
  >> BasicProvers.TOP_CASE_TAC
  >- full_simp_tac(srw_ss())[]
  >> simp[]
  >> IF_CASES_TAC
  >- full_simp_tac(srw_ss())[enc_line_def]
  >> IF_CASES_TAC
  >- (
    Cases_on`h`>>full_simp_tac(srw_ss())[enc_line_def]
    >> rev_full_simp_tac(srw_ss())[enc_sec_def] >> full_simp_tac(srw_ss())[])
  >> IF_CASES_TAC
  >- ( Cases_on`h`>>full_simp_tac(srw_ss())[enc_line_def,LET_THM] )
  >> IF_CASES_TAC
  >- ( Cases_on`h`>>full_simp_tac(srw_ss())[enc_line_def,LET_THM] )
  >> full_simp_tac(srw_ss())[] >> rev_full_simp_tac(srw_ss())[enc_sec_def]
  >> BasicProvers.TOP_CASE_TAC >> full_simp_tac(srw_ss())[]);

val remove_labels_thm = Q.store_thm("remove_labels_thm",
  `good_syntax mc_conf code LN /\
   EVERY sec_ends_with_label code /\
   enc_ok mc_conf.target.config /\
   remove_labels clock mc_conf.target.config code = SOME (code2,labs) ==>
   all_enc_ok mc_conf.target.config labs 0 code2 /\
   code_similar code code2 /\ (pos_val 0 0 code2 = 0) /\
   (has_odd_inst code2 ⇒ mc_conf.target.config.code_alignment = 0) /\
   (!l1 l2 x. lab_lookup l1 l2 labs = SOME x ==> EVEN x) /\
   !l1 l2 x2.
     loc_to_pc l1 l2 code = SOME x2 ==>
     lab_lookup l1 l2 labs = SOME (pos_val x2 0 code2)`,
  simp[remove_labels_def]
  >> strip_tac
  >> drule (GEN_ALL remove_labels_loop_thm)
  >> disch_then(qspec_then`mc_conf`mp_tac)
  >> impl_tac
  >- (
    simp[good_syntax_def,enc_sec_list_encd0]
    \\ match_mp_tac enc_sec_list_ends_with_label
    \\ fs[])
  >> strip_tac >> simp[] >> full_simp_tac(srw_ss())[]
  >> rw [] >> res_tac);

(* introducing make_init *)

val set_bytes_def = Define `
  (set_bytes a be [] = 0w) /\
  (set_bytes a be (b::bs) = set_byte a b (set_bytes (a+1w) be bs) be) `

val make_word_def = Define `
  make_word be m (a:'a word) =
    if dimindex (:'a) = 32 then
      Word (set_bytes a be [m a; m (a+1w); m (a+2w); m (a+3w)])
    else
      Word (set_bytes a be [m a; m (a+1w); m (a+2w); m (a+3w);
                            m (a+4w); m (a+5w); m (a+6w); m (a+7w)]) `

val make_init_def = Define `
  make_init mc_conf (ffi:'ffi ffi_state) save_regs io_regs t m dm (ms:'state) code =
    <| regs       := \k. Word ((t.regs k):'a word)
     ; mem        := m
     ; mem_domain := dm
     ; pc         := 0
     ; be         := mc_conf.target.config.big_endian
     ; ffi        := ffi
     ; io_regs    := \n k. if k IN save_regs then NONE else (io_regs n k)
     ; code       := code
     ; clock      := 0
     ; failed     := F
     ; ptr_reg    := mc_conf.ptr_reg
     ; len_reg    := mc_conf.len_reg
     ; link_reg   := case mc_conf.target.config.link_reg of SOME n => n | _ => 0
     |>`;

val IMP_LEMMA = METIS_PROVE [] ``(a ==> b) ==> (b ==> c) ==> (a ==> c)``

val good_init_state_def = Define `
  good_init_state (mc_conf: ('a,'state,'b) machine_config) t m ms
        ffi ffi_index_limit bytes io_regs save_regs dm <=>
    ffi.final_event = NONE /\
    byte_aligned (t.regs mc_conf.ptr_reg) /\
    mc_conf.target.state_rel t ms /\ ~t.failed /\
    good_dimindex (:'a) /\
    mc_conf.prog_addresses = t.mem_domain /\
    mc_conf.halt_pc NOTIN mc_conf.prog_addresses /\
    t.be = mc_conf.target.config.big_endian /\
    t.pc = mc_conf.target.get_pc ms /\
    t.align = mc_conf.target.config.code_alignment /\
    (1w && mc_conf.target.get_pc ms) = 0w /\
    (n2w (2 ** t.align - 1) && mc_conf.target.get_pc ms) = 0w /\
    reg_ok mc_conf.ptr_reg mc_conf.target.config /\
    reg_ok mc_conf.len_reg mc_conf.target.config /\
    reg_ok (case mc_conf.target.config.link_reg of NONE => 0 | SOME n => n)
      mc_conf.target.config /\
    (!index.
       index < ffi_index_limit ==>
       mc_conf.target.get_pc ms - n2w ((3 + index) * ffi_offset) NOTIN
       mc_conf.prog_addresses /\
       mc_conf.target.get_pc ms - n2w ((3 + index) * ffi_offset) <>
       mc_conf.halt_pc /\
       find_index
         (mc_conf.target.get_pc ms - n2w ((3 + index) * ffi_offset))
         mc_conf.ffi_entry_pcs 0 = SOME index) /\
    mc_conf.target.get_pc ms - n2w ffi_offset = mc_conf.halt_pc /\
    interference_ok mc_conf.next_interfer (mc_conf.target.proj t.mem_domain) /\
    (!q n.
       (n2w (2 ** t.align - 1) && q + (n2w n):'a word) = 0w <=>
       n MOD 2 ** t.align = 0) /\
    dm SUBSET t.mem_domain /\
    (case mc_conf.target.config.link_reg of NONE => T | SOME r => t.lr = r) /\
    code_loaded bytes mc_conf ms /\
    bytes_in_mem (mc_conf.target.get_pc ms) bytes t.mem t.mem_domain dm /\
    (!ms2 k index new_bytes t1 x.
       mc_conf.target.state_rel
         (t1 with
          pc := -n2w ((3 + index) * ffi_offset) + mc_conf.target.get_pc ms)
       ms2 /\
       read_bytearray (t1.regs mc_conf.ptr_reg) (LENGTH new_bytes)
         (\a. if a IN t1.mem_domain then SOME (t1.mem a) else NONE) =
       SOME x ==>
       mc_conf.target.state_rel
        (t1 with
         <|regs :=
            (\a.
             get_reg_value
               (if a IN save_regs then NONE else io_regs k a)
               (t1.regs a) I);
           mem := asm_write_bytearray (t1.regs mc_conf.ptr_reg) new_bytes t1.mem;
           pc := t1.regs (case mc_conf.target.config.link_reg of NONE => 0
                  | SOME n => n)|>)
        (mc_conf.ffi_interfer k index new_bytes ms2)) /\
    !a labs.
      word_loc_val_byte (mc_conf.target.get_pc ms) labs m a
        mc_conf.target.config.big_endian = SOME (t.mem a)`

val LESS_find_ffi_index_limit = store_thm("LESS_find_ffi_index_limit",
  ``!code i. has_io_index i code ==> i < find_ffi_index_limit code``,
  recInduct find_ffi_index_limit_ind
  \\ fs [find_ffi_index_limit_def,has_io_index_def]
  \\ rpt strip_tac \\ CASE_TAC \\ fs [] \\ CASE_TAC \\ fs []);

val aligned_1_intro = prove(
  ``((1w && w) = 0w) <=> aligned 1 w``,
  fs [alignmentTheory.aligned_bitwise_and]);

val IMP_state_rel_make_init = prove(
  ``good_syntax mc_conf code LN /\
    EVERY sec_ends_with_label code /\
    enc_ok mc_conf.target.config /\
    remove_labels clock mc_conf.target.config code =
      SOME (code2,labs) /\
    (!a. byte_align a ∈ dm ==> a ∈ dm) /\
    good_init_state mc_conf t m ms ffi (find_ffi_index_limit code)
      (prog_to_bytes code2) io_regs save_regs dm ==>
    state_rel ((mc_conf: ('a,'state,'b) machine_config),code2,labs,
        mc_conf.target.get_pc ms,T)
      (make_init mc_conf (ffi:'ffi ffi_state)
         save_regs io_regs t m dm ms code) t ms``,
  srw_tac[][] \\ drule remove_labels_thm
  \\ full_simp_tac(srw_ss())[] \\ srw_tac[][]
  \\ full_simp_tac(srw_ss())[state_rel_def,make_init_def,
        word_loc_val_def,PULL_EXISTS]
  \\ full_simp_tac(srw_ss())[good_init_state_def,LESS_find_ffi_index_limit]
  \\ fs [aligned_1_intro]
  \\ `aligned 1 (mc_conf.target.get_pc ms)` by
         fs [alignmentTheory.aligned_bitwise_and]
  \\ fs [alignmentTheory.aligned_add_sub]
  \\ fs [alignmentTheory.aligned_1_lsb]
  \\ fs [EVEN_ODD,GSYM CONJ_ASSOC]
  \\ conj_tac THEN1 (rw [] \\ res_tac)
  \\ ntac 2 strip_tac \\ res_tac \\ fs [SUBSET_DEF]);

val semantics_make_init = save_thm("semantics_make_init",
  machine_sem_EQ_sem |> SPEC_ALL |> REWRITE_RULE [GSYM AND_IMP_INTRO]
  |> UNDISCH |> REWRITE_RULE []
  |> SIMP_RULE std_ss [init_ok_def,PULL_EXISTS,GSYM CONJ_ASSOC,GSYM AND_IMP_INTRO]
  |> SPEC_ALL |> Q.GEN `s1` |> Q.GEN `p`
  |> Q.GEN `t1` |> Q.SPEC `t`
  |> Q.SPEC `(mc_conf: ('a,'state,'b) machine_config).target.get_pc ms`
  |> Q.SPEC `make_init (mc_conf: ('a,'state,'b) machine_config)
       ffi save_regs io_regs t m dm (ms:'state) code`
  |> SIMP_RULE std_ss [EVAL ``(make_init mc_conf ffi s i t m dm ms code).ffi``]
  |> UNDISCH |> MATCH_MP (MATCH_MP IMP_LEMMA IMP_state_rel_make_init)
  |> DISCH_ALL |> REWRITE_RULE [AND_IMP_INTRO,GSYM CONJ_ASSOC]);

val make_init_filter_skip = store_thm("make_init_filter_skip",
  ``semantics (make_init mc_conf ffi save_regs io_regs t m dm ms (filter_skip code)) =
    semantics (make_init mc_conf ffi save_regs io_regs t m dm ms code)``,
  match_mp_tac filter_skip_semantics \\ full_simp_tac(srw_ss())[make_init_def]);

val find_ffi_index_limit_filter_skip = store_thm("find_ffi_index_limit_filter_skip",
  ``!code. find_ffi_index_limit (filter_skip code) = find_ffi_index_limit code``,
  recInduct find_ffi_index_limit_ind
  \\ fs [lab_filterTheory.filter_skip_def,find_ffi_index_limit_def]
  \\ rpt strip_tac \\ every_case_tac
  \\ fs [lab_filterTheory.not_skip_def,find_ffi_index_limit_def]);

val implements_intro_gen = store_thm("implements_intro_gen",
  ``(b /\ x <> Fail ==> y = {x}) ==> b ==> implements y {x}``,
  full_simp_tac(srw_ss())[semanticsPropsTheory.implements_def]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ full_simp_tac(srw_ss())[semanticsPropsTheory.extend_with_resource_limit_def]);

val semantics_compile_lemma = store_thm("semantics_compile_lemma",
  ``ffi.final_event = NONE /\
    backend_correct mc_conf.target /\
    good_syntax mc_conf code LN /\
    EVERY sec_ends_with_label code /\
    c.asm_conf = mc_conf.target.config /\
    compile c code = SOME (bytes,ffi_limit) /\
    (!a. byte_align a ∈ dm ==> a ∈ dm) /\
    good_init_state mc_conf t m ms ffi ffi_limit bytes io_regs save_regs dm /\
    semantics (make_init mc_conf ffi save_regs io_regs t m dm ms code) <> Fail ==>
    machine_sem mc_conf ffi ms =
    {semantics (make_init mc_conf ffi save_regs io_regs t m dm ms code)}``,
  full_simp_tac(srw_ss())[compile_def,compile_lab_def,GSYM AND_IMP_INTRO]
  \\ CASE_TAC \\ full_simp_tac(srw_ss())[LET_DEF]
  \\ PairCases_on `x` \\ full_simp_tac(srw_ss())[]
  \\ srw_tac[][] \\ full_simp_tac(srw_ss())[]
  \\ once_rewrite_tac [GSYM make_init_filter_skip] \\ srw_tac[][]
  \\ match_mp_tac (GEN_ALL semantics_make_init) \\ full_simp_tac(srw_ss())[]
  \\ fs []
  \\ qexists_tac `x1`
  \\ qexists_tac `x0`
  \\ qexists_tac `c.init_clock`
  \\ full_simp_tac(srw_ss())[backend_correct_def,target_ok_def]
  \\ full_simp_tac(srw_ss())[find_ffi_index_limit_filter_skip]
  \\ fs [make_init_filter_skip,sec_ends_with_label_filter_skip])
  |> REWRITE_RULE [CONJ_ASSOC]
  |> MATCH_MP implements_intro_gen
  |> REWRITE_RULE [GSYM CONJ_ASSOC]

val good_init_state_good_dimindex = Q.store_thm("good_init_state_good_dimindex",
  `good_init_state (mc_conf:(α,β,γ)machine_config) (t:α asm_state) m (ms:β) (ffi:'ffi ffi_state) ffi_limit bytes io_regs save_regs dm ⇒
   good_dimindex (:α)`,
  rw[good_init_state_def]);

val semantics_compile = save_thm("semantics_compile",let
  val th0 = MATCH_MP implements_align_dm (UNDISCH good_init_state_good_dimindex)
  val th1 = MATCH_MP semanticsPropsTheory.implements_trans th0
  val th2 = MATCH_MP th1 (semantics_compile_lemma |> UNDISCH
                          |> INST_TYPE[alpha|->``:'ffi``,beta|->alpha,delta|->gamma,gamma|->beta])
                     |> DISCH_ALL
  val th3 = th2 |> SIMP_RULE (srw_ss()) [align_dm_def,make_init_def]
                |> REWRITE_RULE [GSYM make_init_def]
                |> REWRITE_RULE [AND_IMP_INTRO]
  in th3 end);

val _ = export_theory();
