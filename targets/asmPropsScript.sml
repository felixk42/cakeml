open HolKernel Parse boolLib bossLib
open asmSemTheory

val () = new_theory "asmProps"

(* -- semantics is deterministic if encoding is deterministic enough -- *)

val asm_deterministic_def = Define `
   asm_deterministic enc c =
     !s1 s2 s3. asm_step enc c s1 s2 /\ asm_step enc c s1 s3 ==> (s2 = s3)`

val enc_deterministic_def = Define `
  enc_deterministic enc c =
    !i j s1.
      asm_ok i c /\ asm_ok j c /\ isPREFIX (enc i) (enc j) ==>
        (asm i (s1.pc + n2w (LENGTH (enc i))) s1 =
         asm j (s1.pc + n2w (LENGTH (enc j))) s1)`

val has_decoder_def = Define `
  has_decoder enc c = ?dec. !i x. asm_ok i c ==> (dec (enc i ++ x) = i)`

val bytes_in_memory_IMP = prove(
  ``!xs ys a m dm.
      bytes_in_memory a xs m dm /\ bytes_in_memory a ys m dm ==>
      isPREFIX xs ys \/ isPREFIX ys xs``,
  Induct
  THEN Cases_on `ys`
  THEN SRW_TAC [] []
  THEN METIS_TAC [bytes_in_memory_def])

val decoder_asm_deterministic = Q.store_thm("decoder_asm_deterministic",
   `!enc c. has_decoder enc c ==> asm_deterministic enc c`,
   METIS_TAC [asm_deterministic_def, has_decoder_def, asm_step_def,
              listTheory.APPEND_NIL, bytes_in_memory_IMP,
              rich_listTheory.IS_PREFIX_APPEND]
   )

val enc_deterministic = store_thm("enc_deterministic",
  ``!enc c. enc_deterministic enc c ==> asm_deterministic enc c``,
  SRW_TAC [] [asm_step_def, asm_deterministic_def]
  THEN METIS_TAC [enc_deterministic_def, bytes_in_memory_IMP])

val simple_enc_deterministic = Q.store_thm("simple_enc_deterministic",
   `!enc c.
      (!i j. asm_ok i c /\ asm_ok j c /\ i <> j ==>
             ~isPREFIX (enc i) (enc j)) ==> asm_deterministic enc c`,
   METIS_TAC [enc_deterministic_def, enc_deterministic]
   )

val bytes_in_memory_concat = Q.store_thm("bytes_in_memory_concat",
   `!l1 l2 pc mem mem_domain.
       bytes_in_memory pc (l1 ++ l2) mem mem_domain =
       bytes_in_memory pc l1 mem mem_domain /\
       bytes_in_memory (pc + n2w (LENGTH l1)) l2 mem mem_domain`,
   Induct
   THEN ASM_SIMP_TAC list_ss
         [bytes_in_memory_def, wordsTheory.WORD_ADD_0, wordsTheory.word_add_n2w,
          GSYM wordsTheory.WORD_ADD_ASSOC, arithmeticTheory.ADD1]
   THEN DECIDE_TAC
   )

(* -- well-formedness of encoding -- *)

val offset_monotonic_def = Define `
   offset_monotonic enc c a1 a2 i1 i2 =
   asm_ok i1 c /\ asm_ok i2 c ==>
   (0w <= a1 /\ 0w <= a2 /\ a1 <= a2 ==> LENGTH (enc i1) <= LENGTH (enc i2)) /\
   (a1 < 0w /\ a2 < 0w /\ a2 <= a1 ==> LENGTH (enc i1) <= LENGTH (enc i2))`

val enc_ok_def = Define `
  enc_ok (enc: 'a asm -> word8 list) c =
    (* code alignment and length *)
    (2 EXP c.code_alignment = LENGTH (enc (Inst Skip))) /\
    (!w. asm_ok w c ==> (LENGTH (enc w) MOD 2 EXP c.code_alignment = 0) /\
                        (LENGTH (enc w) <> 0)) /\
    (* label instantiation predictably affects length of code *)
    (!w1 w2. offset_monotonic enc c w1 w2 (Jump w1) (Jump w2)) /\
    (!cmp r ri w1 w2.
       offset_monotonic enc c w1 w2
          (JumpCmp cmp r ri w1) (JumpCmp cmp r ri w2)) /\
    (!w1 w2. offset_monotonic enc c w1 w2 (Call w1) (Call w2)) /\
    (!w1 w2 r. offset_monotonic enc c w1 w2 (Loc r w1) (Loc r w2)) /\
    (* no overlap between instructions with different behaviour *)
    asm_deterministic enc c`

(* -- correctness property to be proved for each backend -- *)

val backend_correct_def = Define `
  backend_correct enc (config:'a asm_config) (next:'b -> 'b) R =
    enc_ok enc config /\
    !s1 s2.
      asm_step enc config s1 s2 ==>
      !state. R s1 state ==> ?n. R s2 (FUNPOW next (n + 1) state)`

val interference_ok_def = Define `
  interference_ok env proj <=>
    !(i:num) ms. proj (env i ms) = proj ms`;

val all_pcs_def = Define `
  (all_pcs a [] = {}) /\
  (all_pcs a (x::xs) = a INSERT all_pcs (a + 1w) xs)`;

val () = Datatype `
  target_funs =
    <| encode : 'a asm -> word8 list
     ; get_pc : 'b -> 'a word
     ; get_reg : 'b -> num -> 'a word
     ; get_byte : 'b -> 'a word -> word8
     ; state_ok : 'b -> bool
     ; state_rel : 'a asm_state -> 'b -> bool
     ; proj : 'a word set -> 'b -> 'c
     ; next : 'b -> 'b
     |>`

val asserts_def = zDefine `
  (asserts 0 next ms P Q <=>
     let ms = next 0 ms in Q ms) /\
  (asserts (SUC n) next ms P Q <=>
     let ms = next (SUC n) ms in
       (P ms /\ asserts n next ms P Q))`

val backend_correct_alt_def = Define `
  backend_correct_alt t (config:'a asm_config) <=>
    enc_ok t.encode config /\
    (!ms1 ms2 s.
        (t.proj s.mem_domain ms1 = t.proj s.mem_domain ms2) ==>
        (t.state_rel s ms1 = t.state_rel s ms2) /\
        (t.state_ok ms1 = t.state_ok ms2)) /\
    (!ms s. t.state_rel s ms ==>
            t.state_ok ms /\ (t.get_pc ms = s.pc) /\
            (!a. a IN s.mem_domain ==> (t.get_byte ms a = s.mem a)) /\
            (!i. i < config.reg_count /\ ~MEM i config.avoid_regs ==>
                 (t.get_reg ms i = s.regs i))) /\
    !s1 i s2 ms.
      asm_step_alt t.encode config s1 i s2 /\ t.state_rel s1 ms ==>
      ?n. !env.
             interference_ok (env:num->'b->'b) (t.proj s1.mem_domain) ==>
             asserts n (\k s. env (n - k) (t.next s)) ms
               (\ms'. t.state_ok ms' /\
                      t.get_pc ms' IN all_pcs s1.pc (t.encode i))
               (\ms'. t.state_rel s2 ms')`

(* lemma for proofs *)

val asserts_eval = save_thm("asserts_eval",let
  fun genlist f 0 = []
    | genlist f n = genlist f (n-1) @ [f (n-1)]
  fun suc_num 0 = ``0:num``
    | suc_num n = mk_comb(``SUC``,suc_num (n-1))
  fun gen_rw n =
    ``asserts ^(suc_num n) next (s:'a) P Q``
    |> ONCE_REWRITE_CONV [asserts_def] |> SIMP_RULE std_ss []
  in LIST_CONJ (genlist gen_rw 20) end);

val () = export_theory ()
