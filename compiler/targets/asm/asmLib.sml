structure asmLib :> asmLib =
struct

open HolKernel boolLib bossLib
open asmTheory asmSemTheory asmPropsTheory utilsLib

val ERR = Feedback.mk_HOL_ERR "asmLib"

(* compset support -------------------------------------------------------- *)

fun asm_type a s = Type.mk_thy_type {Thy = "asm", Tyop = s, Args = a}
val asm_type0 = asm_type []
val asm_type = asm_type [``:64``]

fun add_asm_compset cmp =
   ( computeLib.add_thms
      [asm_ok_def, inst_ok_def, addr_ok_def, reg_ok_def, arith_ok_def,
       cmp_ok_def, reg_imm_ok_def, addr_offset_ok_def, jump_offset_ok_def,
       cjump_offset_ok_def, loc_offset_ok_def, upd_pc_def, upd_reg_def,
       upd_mem_def, read_reg_def, read_mem_def, assert_def, reg_imm_def,
       binop_upd_def, word_cmp_def, word_shift_def, arith_upd_def, addr_def,
       mem_load_def, write_mem_word_def, mem_store_def, read_mem_word_def,
       mem_op_def, is_test_def, inst_def, jump_to_offset_def, asm_def,
       alignmentTheory.aligned_extract] cmp
   ; utilsLib.add_datatypes
        (List.map asm_type0 ["cmp", "mem_op", "binop", "shift"] @
         List.map asm_type  ["asm_config", "asm", "inst"])
        cmp
   )

(* some rewrites ---------------------------------------------------------- *)

fun read_mem_word n =
   EVAL ``(read_mem_word (b: 'a word) ^n s): 'a word # 'a asm_state``
   |> SIMP_RULE (srw_ss()) []

fun write_mem_word n =
   EVAL ``(write_mem_word (b: 'a word) ^n (d:'b word) s): 'a asm_state``
   |> SIMP_RULE (srw_ss()) []

val asm_ok_rwts =
   [asm_ok_def, inst_ok_def, addr_ok_def, reg_ok_def, arith_ok_def, cmp_ok_def,
    reg_imm_ok_def, addr_offset_ok_def, jump_offset_ok_def, cjump_offset_ok_def,
    loc_offset_ok_def]

val asm_rwts =
   [upd_pc_def, upd_reg_def, upd_mem_def, read_reg_def, read_mem_def,
    assert_def, reg_imm_def, binop_upd_def, word_cmp_def, word_shift_def,
    arith_upd_def, addr_def, mem_load_def, write_mem_word_def, mem_store_def,
    read_mem_word ``1n``, read_mem_word ``4n``, read_mem_word ``8n``,
    write_mem_word ``1n``, write_mem_word ``4n``, write_mem_word ``8n``,
    mem_op_def, inst_def, jump_to_offset_def, asm_def]

(* some custom tools/tactics ---------------------------------------------- *)

fun print_tac s1 s2 gs =
  (print (s2 ^ (if s1 = "" then "" else " (" ^ s1 ^ ")") ^ "\n"); ALL_TAC gs)

fun using_first n thms_tac =
   POP_ASSUM_LIST
      (fn thms =>
          let
             val x = List.rev (List.take (thms, n))
             val y = List.rev (List.drop (thms, n))
          in
             MAP_EVERY assume_tac y
             \\ thms_tac x
             \\ MAP_EVERY assume_tac x
          end)

val (_, mk_bytes_in_memory, dest_bytes_in_memory, _) =
   HolKernel.syntax_fns4 "asmSem" "bytes_in_memory"

val strip_bytes_in_memory =
   Option.map (fn (_, l, _, _) => fst (listSyntax.dest_list l)) o
   Lib.total dest_bytes_in_memory

local
   val bytes_in_memory_concat =
      Q.GENL [`l2`, `l1`]
         (fst (Thm.EQ_IMP_RULE (Drule.SPEC_ALL bytes_in_memory_concat)))
   val w8 = ``:word8``
   val pc = Term.mk_var ("pc", ``:'a word``)
   val mem = Term.mk_var ("mem", ``: 'a word -> word8``)
   val mem_domain = Term.mk_var ("mem_domain", ``: 'a word -> bool``)
in
   fun split_bytes_in_memory_tac n (asl, g) =
      (case List.mapPartial strip_bytes_in_memory asl of
          [] => NO_TAC
        | l :: _ =>
            let
               val l1 = listSyntax.mk_list (List.take (l, n), w8)
               val l2 = listSyntax.mk_list (List.drop (l, n), w8)
               val l = listSyntax.mk_list (l, w8)
               val th =
                  bytes_in_memory_concat
                  |> Drule.ISPECL [l1, l2]
                  |> Conv.CONV_RULE
                       (Conv.LAND_CONV
                          (Conv.RATOR_CONV
                             (Conv.RATOR_CONV
                                (Conv.RAND_CONV listLib.APPEND_CONV)))
                        THENC Conv.RAND_CONV
                                (Conv.RAND_CONV
                                   (Conv.RATOR_CONV
                                      (Conv.RATOR_CONV
                                            (Conv.RATOR_CONV
                                               (Conv.RAND_CONV
                                                  (Conv.DEPTH_CONV
                                                     listLib.LENGTH_CONV)))))))
            in
               qpat_x_assum `asmSem$bytes_in_memory ^pc ^l ^mem ^mem_domain`
                  (fn thm =>
                      let
                         val (th1, th2) =
                            Drule.CONJ_PAIR (Drule.MATCH_MP th thm)
                      in
                         assume_tac th1
                         \\ assume_tac th2
                      end)
            end) (asl, g)
end

local
   fun bit_mod_thm n m =
      let
         val th = bitTheory.BITS_ZERO3 |> Q.SPEC n |> numLib.REDUCE_RULE
         val M = Parse.Term m
         val N = Parse.Term n
      in
         Tactical.prove (
             ``BIT ^M n = BIT ^M (n MOD 2 ** (^N + 1))``,
             simp [bitTheory.BIT_def, GSYM th, bitTheory.BITS_COMP_THM2])
         |> numLib.REDUCE_RULE
      end
   fun nq i = [QUOTE (Int.toString i ^ "n")]
   val th = GSYM wordsTheory.n2w_mod
   fun bit_mod_thms n =
      (th |> Thm.INST_TYPE [Type.alpha |-> fcpSyntax.mk_int_numeric_type n]
          |> CONV_RULE (DEPTH_CONV wordsLib.SIZES_CONV)) ::
      List.tabulate (n, fn j => bit_mod_thm (nq (n - 1)) (nq j))
in
   fun v2w_BIT_n2w i =
      let
         val n = Term.mk_var ("n", numLib.num)
         val ty = fcpSyntax.mk_int_numeric_type i
         val r = wordsSyntax.mk_n2w (n, ty)
         val l = List.tabulate
                    (i, fn j => bitSyntax.mk_bit (numSyntax.term_of_int j, n))
         val v = bitstringSyntax.mk_v2w
                    (listSyntax.mk_list (List.rev l, Type.bool), ty)
         val s =
            numSyntax.mk_numeral (Arbnum.pow (Arbnum.two, Arbnum.fromInt i))
      in
         Tactical.prove(boolSyntax.mk_eq (v, r),
            once_rewrite_tac (bit_mod_thms i)
            \\ qabbrev_tac `m = n MOD ^s`
            \\ `m < ^s` by simp [Abbr `m`]
            \\ full_simp_tac std_ss [wordsTheory.NUMERAL_LESS_THM]
            \\ EVAL_TAC
            ) |> GEN_ALL
      end
end

local
   fun is_byte_eq tm =
      let
        val (l, r) = boolSyntax.dest_eq tm
      in
        (wordsSyntax.is_word_extract l orelse wordsSyntax.is_word_concat l)
        andalso (bitstringSyntax.is_v2w r orelse wordsSyntax.is_n2w r)
      end
   val conv =
      Conv.DEPTH_CONV
         (fn tm => if is_byte_eq tm
                      then blastLib.BBLAST_CONV tm
                   else Conv.NO_CONV tm)
      THENC Conv.DEPTH_CONV bitstringLib.v2w_n2w_CONV
in
   val byte_eq_tac =
      rule_assum_tac
        (Conv.CONV_RULE
           (fn tm =>
               if boolSyntax.is_imp_only tm orelse boolSyntax.is_forall tm
                  then conv tm
               else ALL_CONV tm))
end

local
   fun dest_env P tm =
      case Lib.total boolSyntax.strip_comb tm of
         SOME (env, [n, ms]) =>
            if Lib.total (fst o Term.dest_var) env = SOME "env" andalso
               not (P ms) andalso numSyntax.is_numeral n
               then (n, ms)
            else raise ERR "dest_env" ""
       | _ => raise ERR "dest_env" ""
   val find_the_env =
     let
       val dest_env = dest_env optionSyntax.is_the
       val is_env = Lib.can dest_env
     in
       HolKernel.bvk_find_term (is_env o snd) dest_env
     end
in
   fun find_env P g =
      g |> boolSyntax.strip_conj |> List.last
        |> HolKernel.find_terms (Lib.can (dest_env P))
        |> Lib.mk_set
        |> mlibUseful.sort_map (HolKernel.term_size) Int.compare
        |> Lib.total (dest_env P o List.last)
   fun env_tac f (asl, g) =
      (case find_the_env g of
          SOME t_tm =>
            let
               val (tm2, tac) = f t_tm
            in
               Tactical.SUBGOAL_THEN tm2 (fn th => once_rewrite_tac [th])
               >| [tac, all_tac]
            end
        | NONE => ALL_TAC) (asl, g)
end

local
  fun can_match [QUOTE s] =
        Lib.can (Term.match_term (Parse.Term [QUOTE (s ^ " : 'a asm")]))
    | can_match _ = raise ERR "" ""
  val syntax1 = #4 o HolKernel.syntax_fns1 "asm"
  val syntax2 = #4 o HolKernel.syntax_fns2 "asm"
  val syntax4 = #4 o HolKernel.syntax_fns4 "asm"
in
  val isInst = syntax1 "Inst"
  val isJump = syntax1 "Jump"
  val isJumpCmp = syntax4 "JumpCmp"
  val isCall = syntax1 "Call"
  val isJumpReg = syntax1 "JumpReg"
  val isLoc = syntax2 "Loc"
  val isSkip = can_match `asm$Inst (asm$Const _ _)`
  val isConst = can_match `asm$Inst (asm$Const _ _)`
  val isArith = can_match `asm$Inst (asm$Arith _)`
  val isMem = can_match `asm$Inst (asm$Mem _ _ _)`
  val isBinop = can_match `asm$Inst (asm$Arith (asm$Binop _ _ _ _))`
  val isShift = can_match `asm$Inst (asm$Arith (asm$Shift _ _ _ _))`
  val isAddCarry = can_match `asm$Inst (asm$Arith (asm$AddCarry _ _ _ _))`
end

end
