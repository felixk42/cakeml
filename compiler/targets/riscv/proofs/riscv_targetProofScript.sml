open HolKernel Parse boolLib bossLib
open asmLib riscv_stepLib riscv_targetTheory;

val () = new_theory "riscv_targetProof"

val () = wordsLib.guess_lengths()

(* some lemmas ---------------------------------------------------------- *)

val riscv_asm_state =
   REWRITE_RULE [DECIDE ``1 < i = i <> 0n /\ i <> 1``] riscv_asm_state_def

val bytes_in_memory_thm = Q.prove(
   `!w s state a b c d.
      riscv_asm_state s state /\
      bytes_in_memory s.pc [a; b; c; d] s.mem s.mem_domain ==>
      (state.exception = NoException) /\
      ((state.c_MCSR state.procID).mstatus.VM = 0w) /\
      ((state.c_MCSR state.procID).mcpuid.ArchBase = 2w) /\
      (state.c_NextFetch state.procID = NONE) /\
      aligned 2 (state.c_PC state.procID) /\
      (state.MEM8 (state.c_PC state.procID) = a) /\
      (state.MEM8 (state.c_PC state.procID + 1w) = b) /\
      (state.MEM8 (state.c_PC state.procID + 2w) = c) /\
      (state.MEM8 (state.c_PC state.procID + 3w) = d) /\
      state.c_PC state.procID + 3w IN s.mem_domain /\
      state.c_PC state.procID + 2w IN s.mem_domain /\
      state.c_PC state.procID + 1w IN s.mem_domain /\
      state.c_PC state.procID IN s.mem_domain`,
   rw [riscv_asm_state_def, riscv_ok_def, asmSemTheory.bytes_in_memory_def,
       alignmentTheory.aligned_extract, set_sepTheory.fun2set_eq]
   \\ rfs []
   )

val bytes_in_memory_thm2 = Q.prove(
   `!w s state a b c d.
      riscv_asm_state s state /\
      bytes_in_memory (s.pc + w) [a; b; c; d] s.mem s.mem_domain ==>
      (state.MEM8 (state.c_PC state.procID + w) = a) /\
      (state.MEM8 (state.c_PC state.procID + w + 1w) = b) /\
      (state.MEM8 (state.c_PC state.procID + w + 2w) = c) /\
      (state.MEM8 (state.c_PC state.procID + w + 3w) = d) /\
      state.c_PC state.procID + w + 3w IN s.mem_domain /\
      state.c_PC state.procID + w + 2w IN s.mem_domain /\
      state.c_PC state.procID + w + 1w IN s.mem_domain /\
      state.c_PC state.procID + w IN s.mem_domain`,
   rw [riscv_asm_state_def, riscv_ok_def, asmSemTheory.bytes_in_memory_def,
       set_sepTheory.fun2set_eq]
   \\ rfs []
   )

val lem1 = asmLib.v2w_BIT_n2w 5
val lem2 = asmLib.v2w_BIT_n2w 6

val lem3 = Q.prove(
   `!n s state.
     n <> 0 /\ n <> 1 /\ n < 32 /\ riscv_asm_state s state ==>
     (s.regs n = state.c_gpr state.procID (n2w n))`,
   lrw [riscv_asm_state]
   )

val lem4 = blastLib.BBLAST_PROVE
  ``0xFFFFFFFFFFFFF800w <= c /\ c <= 0x7FFw ==>
    (sw2sw
      (v2w [c ' 11; c ' 10; c ' 9; c ' 8; c ' 7; c ' 6; c ' 5;
            c ' 4; c ' 3; c ' 2; c ' 1; c ' 0] : word12) = c : word64)``


val lem5 = Q.prove(
  `aligned 2 (c: word64) ==>
   ~word_lsb (v2w [c ' 20; c ' 19; c ' 18; c ' 17; c ' 16; c ' 15; c ' 14;
                   c ' 13; c ' 12; c ' 11; c ' 10; c ' 9; c ' 8; c ' 7;
                   c ' 6; c ' 5; c ' 4; c ' 3; c ' 2; c ' 1] : 20 word)`,
  simp [alignmentTheory.aligned_extract]
  \\ blastLib.BBLAST_TAC
  )

val lem6 = blastLib.BBLAST_PROVE
  ``(((31 >< 0) (c: word64) : word32) ' 11 = c ' 11) /\
    (((63 >< 32) c : word32) ' 11 = c ' 43) /\
    (~(63 >< 32) c : word32 ' 11 = ~c ' 43) ``

val lem7 = CONJ (bitstringLib.v2w_n2w_CONV ``v2w [F] : word64``)
                (bitstringLib.v2w_n2w_CONV ``v2w [T] : word64``)

val lem8 = Q.prove(
  `((if b then 1w else 0w : word64) = v2w [x] || v2w [y]) = (b = x \/ y)`,
  rw [] \\ blastLib.BBLAST_TAC)

val lem9 = Q.prove(
  `!r2 : word64 r3 : word64.
    (18446744073709551616 <= w2n r2 + (w2n r3 + 1) =
     18446744073709551616w <=+ w2w r2 + w2w r3 + 1w : 65 word) /\
    (18446744073709551616 <= w2n r2 + w2n r3 =
     18446744073709551616w <=+ w2w r2 + w2w r3 : 65 word)`,
   Cases
   \\ Cases
   \\ imp_res_tac wordsTheory.BITS_ZEROL_DIMINDEX
   \\ fs [wordsTheory.w2w_n2w, wordsTheory.word_add_n2w,
          wordsTheory.word_ls_n2w])

(* some rewrites ---------------------------------------------------------- *)

val encode_rwts =
   let
      open riscvTheory
   in
      [riscv_enc_def, riscv_encode_def, riscv_const32_def, riscv_bop_r_def,
       riscv_bop_i_def, riscv_sh_def, riscv_memop_def, Encode_def, opc_def,
       Itype_def, Rtype_def, Stype_def, SBtype_def, Utype_def, UJtype_def]
   end

val enc_rwts =
  [riscv_config_def, lem6] @ encode_rwts @ asmLib.asm_ok_rwts @ asmLib.asm_rwts

val enc_ok_rwts =
  [asmPropsTheory.enc_ok_def, riscv_config_def] @
  encode_rwts @ asmLib.asm_ok_rwts

(* some custom tactics ---------------------------------------------------- *)

local
   val bool1 = utilsLib.rhsc o blastLib.BBLAST_CONV o fcpSyntax.mk_fcp_index
   fun boolify n tm =
      List.tabulate (n, fn i => bool1 (tm, numLib.term_of_int (n - 1 - i)))
   val bytes = List.concat o List.map (boolify 8)
   val is_riscv_next = #4 (HolKernel.syntax_fns1 "riscv_target" "riscv_next")
   val (_, _, dest_NextRISCV, is_NextRISCV) =
      HolKernel.syntax_fns1 "riscv_step" "NextRISCV"
   val find_NextRISCV =
      dest_NextRISCV o List.hd o HolKernel.find_terms is_NextRISCV
   val s = ``s: riscv_state``
   fun step the_state l =
      let
         val v = listSyntax.mk_list (bytes l, Type.bool)
         val thm = Thm.INST [s |-> the_state] (riscv_stepLib.riscv_step v)
      in
         (Drule.DISCH_ALL thm,
          optionSyntax.dest_some (boolSyntax.rand (Thm.concl thm)))
      end
   val ms = ``ms: riscv_state``
   fun new_state_var l =
     Lib.with_flag (Globals.priming, SOME "_")
       (Term.variant (List.concat (List.map Term.free_vars l))) ms
   fun env (t, tm) =
     let
       (*
       val (t, tm) = Option.valOf (find_env g)
       *)
       val etm = ``env ^t ^tm : riscv_state``
     in
       (fn (asl, g) =>
         let
           val pc = fst (pred_setSyntax.dest_in (hd asl))
         in
           `(!a. a IN s1.mem_domain ==> ((^etm).MEM8 a = ms.MEM8 a)) /\
            ((^etm).exception = ms.exception) /\
            ((^etm).c_NextFetch (^etm).procID = ms.c_NextFetch ms.procID) /\
            (((^etm).c_MCSR (^etm).procID).mstatus.VM =
             (ms.c_MCSR ms.procID).mstatus.VM) /\
            (((^etm).c_MCSR (^etm).procID).mcpuid.ArchBase =
             (ms.c_MCSR ms.procID).mcpuid.ArchBase) /\
            ((^etm).c_PC (^etm).procID = ^pc)`
            by asm_simp_tac (srw_ss())
                 [combinTheory.UPDATE_APPLY, combinTheory.UPDATE_EQ, Abbr `^tm`]
         end (asl, g)
       , etm
       )
     end
in
   fun next_state_tac (asl, g) =
     (let
         val x as (pc, l, _, _) =
            List.last
              (List.mapPartial (Lib.total asmLib.dest_bytes_in_memory) asl)
         val x_tm = asmLib.mk_bytes_in_memory x
         val l = List.rev (fst (listSyntax.dest_list l))
         val th = case Lib.total wordsSyntax.dest_word_add pc of
                     SOME (_, w) => Thm.SPEC w bytes_in_memory_thm2
                   | NONE => bytes_in_memory_thm
         val (tac, the_state) =
           case asmLib.find_env is_riscv_next g of
              SOME x => env x
            | NONE => (all_tac, ms)
         val (step_thm, next_state) = step the_state l
         val next_state_var = new_state_var (g::asl)
      in
         imp_res_tac th
         \\ tac
         \\ assume_tac step_thm
         \\ qabbrev_tac `^next_state_var = ^next_state`
         \\ NO_STRIP_REV_FULL_SIMP_TAC (srw_ss())
              [lem1, lem4, lem5, alignmentTheory.aligned_numeric]
         \\ Tactical.PAT_X_ASSUM x_tm kall_tac
         \\ SUBST1_TAC (Thm.SPEC the_state riscv_next_def)
         \\ byte_eq_tac
         \\ NO_STRIP_REV_FULL_SIMP_TAC (srw_ss()++boolSimps.LET_ss) [lem1]
      end
      handle List.Empty => FAIL_TAC "next_state_tac: empty") (asl, g)
end

local
  val thm = DECIDE ``~(n < 32n) ==> (n - 32 + 32 = n)``
in
  fun state_tac asm (gs as (asl, _)) =
    let
      val l = List.mapPartial (Lib.total (fst o markerSyntax.dest_abbrev)) asl
      val (l, x) = Lib.front_last l
    in
      (
       NO_STRIP_FULL_SIMP_TAC (srw_ss())
         [riscv_ok_def, riscv_asm_state, asmPropsTheory.all_pcs, lem2,
          alignmentTheory.aligned_numeric, set_sepTheory.fun2set_eq]
       \\ MAP_EVERY (fn s =>
            qunabbrev_tac [QUOTE s]
            \\ asm_simp_tac (srw_ss()) [combinTheory.APPLY_UPDATE_THM,
                  alignmentTheory.aligned_numeric]
            \\ NTAC 10 (POP_ASSUM kall_tac)
            ) l
       \\ qunabbrev_tac [QUOTE x]
       \\ asm_simp_tac (srw_ss())
            [combinTheory.APPLY_UPDATE_THM, alignmentTheory.aligned_numeric]
       \\ CONV_TAC (Conv.DEPTH_CONV bitstringLib.v2w_n2w_CONV)
       \\ simp []
       \\ (if asmLib.isAddCarry asm then
             qabbrev_tac `r2 = ms.c_gpr ms.procID (n2w n0)`
             \\ qabbrev_tac `r3 = ms.c_gpr ms.procID (n2w n1)`
             \\ REPEAT strip_tac
             \\ Cases_on `i = n2`
             \\ asm_simp_tac std_ss [wordsTheory.WORD_LO_word_0, lem8]
             >- (Cases_on `ms.c_gpr ms.procID (n2w n2) = 0w`
                 \\ simp [wordsTheory.WORD_LO_word_0, lem7, lem9]
                 \\ blastLib.BBLAST_TAC)
             \\ rw [GSYM wordsTheory.word_add_n2w, lem7]
           else
             rw [combinTheory.APPLY_UPDATE_THM, thm]
             \\ (if asmLib.isMem asm then
                   full_simp_tac
                      (srw_ss()++wordsLib.WORD_EXTRACT_ss++
                       wordsLib.WORD_CANCEL_ss) []
                 else
                   NO_STRIP_FULL_SIMP_TAC std_ss
                        [alignmentTheory.aligned_extract]
                   \\ blastLib.FULL_BBLAST_TAC))
      ) gs
    end
end

local
   fun number_of_instructions asl =
      case asmLib.strip_bytes_in_memory (hd asl) of
         SOME l => List.length l div 4
       | NONE => raise ERR "number_of_instructions" ""
   fun next_tac' asm gs =
      let
         val j = number_of_instructions (fst gs)
         val i = j - 1
         val n = numLib.term_of_int i
      in
         exists_tac n
         \\ simp [asmPropsTheory.asserts_eval, set_sepTheory.fun2set_eq,
                  asmPropsTheory.interference_ok_def, riscv_proj_def]
         \\ NTAC 2 strip_tac
         \\ NTAC i (split_bytes_in_memory_tac 4)
         \\ NTAC j next_state_tac
         \\ REPEAT (Q.PAT_X_ASSUM `ms.MEM8 qq = bn` kall_tac)
         \\ REPEAT (Q.PAT_X_ASSUM `NextRISCV qq = qqq` kall_tac)
         \\ state_tac asm
      end gs
   val (_, _, dest_riscv_enc, is_riscv_enc) =
     HolKernel.syntax_fns1 "riscv_target" "riscv_enc"
   fun get_asm tm = dest_riscv_enc (HolKernel.find_term is_riscv_enc tm)
in
   fun next_tac gs =
     (qpat_x_assum `bytes_in_memory (aa : word64) bb cc dd` mp_tac
      \\ simp enc_rwts
      \\ NO_STRIP_REV_FULL_SIMP_TAC (srw_ss()++boolSimps.LET_ss) enc_rwts
      \\ imp_res_tac lem3
      \\ NO_STRIP_FULL_SIMP_TAC std_ss []
      \\ strip_tac
      \\ next_tac' (get_asm (snd gs))) gs
end

val enc_ok_tac =
   full_simp_tac (srw_ss()++boolSimps.LET_ss)
      (asmPropsTheory.offset_monotonic_def :: enc_ok_rwts)

val enc_tac =
  simp (riscv_encode_fail_def :: enc_rwts)
  \\ REPEAT (TRY (Q.MATCH_GOALSUB_RENAME_TAC `if b then _ else _`)
             \\ CASE_TAC
             \\ simp [])

(* -------------------------------------------------------------------------
   riscv backend_correct
   ------------------------------------------------------------------------- *)

val print_tac = asmLib.print_tac "encode"

val riscv_encoding = Q.prove (
   `!i. let n = LENGTH (riscv_enc i) in (n MOD 4 = 0) /\ n <> 0`,
   Cases
   >- (
      (*--------------
          Inst
        --------------*)
      Cases_on `i'`
      >- (
         (*--------------
             Skip
           --------------*)
         print_tac "Skip"
         \\ enc_tac
         )
      >- (
         (*--------------
             Const
           --------------*)
         print_tac "Const"
         \\ Cases_on `c = sw2sw ((11 >< 0) c : word12)`
         >- enc_tac
         \\ Cases_on `((63 >< 32) c = 0w: word32) /\ ~c ' 31 \/
                      ((63 >< 32) c = -1w: word32) /\ c ' 31`
         >- (Cases_on `c ' 11` \\ enc_tac)
         \\ Cases_on `c ' 31`
         \\ Cases_on `c ' 43`
         \\ Cases_on `c ' 11`
         \\ enc_tac
         )
      >- (
         (*--------------
             Arith
           --------------*)
         Cases_on `a`
         >- (
            (*--------------
                Binop
              --------------*)
            print_tac "Binop"
            \\ Cases_on `r`
            \\ Cases_on `b`
            \\ enc_tac
            )
         >- (
            (*--------------
                Shift
              --------------*)
            print_tac "Shift"
            \\ Cases_on `s`
            \\ enc_tac
            )
         >- (
            (*--------------
                LongMul
              --------------*)
            print_tac "LongMul"
            \\ enc_tac
            )
         >- (
            (*--------------
                LongDiv
              --------------*)
            print_tac "LongDiv"
            \\ enc_tac
            )
            (*--------------
               AddCarry
              --------------*)
            \\ print_tac "AddCarry"
            \\ enc_tac
         )
         (*--------------
             Mem
           --------------*)
         \\ print_tac "Mem"
         \\ Cases_on `a`
         \\ Cases_on `m`
         \\ enc_tac
      )
      (*--------------
          Jump
        --------------*)
   >- (
      print_tac "Jump"
      \\ enc_tac
      )
   >- (
      (*--------------
          JumpCmp
        --------------*)
      print_tac "JumpCmp"
      \\ Cases_on `r`
      \\ Cases_on `c`
      \\ enc_tac
      )
      (*--------------
          Call
        --------------*)
   >- (
      print_tac "Call"
      \\ enc_tac
      )
   >- (
      (*--------------
          JumpReg
        --------------*)
      print_tac "JumpReg"
      \\ enc_tac
      )
      (*--------------
          Loc
        --------------*)
   \\ print_tac "Loc"
   \\ enc_tac
   )

val enc_ok_rwts =
   SIMP_RULE (bool_ss++boolSimps.LET_ss) [] riscv_encoding :: enc_ok_rwts

val print_tac = asmLib.print_tac "correct"

val riscv_backend_correct = Q.store_thm ("riscv_backend_correct",
   `backend_correct riscv_target`,
   simp [asmPropsTheory.backend_correct_def, asmPropsTheory.target_ok_def,
         riscv_target_def]
   \\ REVERSE (REPEAT conj_tac)
   >| [
      rw [asmSemTheory.asm_step_def]
      \\ simp [riscv_config_def]
      \\ Cases_on `i`,
      srw_tac []
        [riscv_asm_state_def, riscv_config_def, set_sepTheory.fun2set_eq]
      \\  `1 < i` by decide_tac
      \\ simp [],
      srw_tac [] [riscv_proj_def, riscv_asm_state_def, riscv_ok_def],
      srw_tac [boolSimps.LET_ss] enc_ok_rwts
   ]
   >- (
      (*--------------
          Inst
        --------------*)
      Cases_on `i'`
      >- (
         (*--------------
             Skip
           --------------*)
         print_tac "Skip"
         \\ next_tac
         )
      >- (
         (*--------------
             Const
           --------------*)
         print_tac "Const"
         \\ Cases_on `c = sw2sw ((11 >< 0) c : word12)`
         >- next_tac
         \\ Cases_on `((63 >< 32) c = 0w: word32) /\ ~c ' 31 \/
                      ((63 >< 32) c = -1w: word32) /\ c ' 31`
         >- (Cases_on `c ' 11` \\ next_tac)
         \\ Cases_on `c ' 31`
         \\ Cases_on `c ' 43`
         \\ Cases_on `c ' 11`
         \\ next_tac
         )
      >- (
         (*--------------
             Arith
           --------------*)
         Cases_on `a`
         >- (
            (*--------------
                Binop
              --------------*)
            print_tac "Binop"
            \\ Cases_on `r`
            \\ Cases_on `b`
            \\ next_tac
            )
         >- (
            (*--------------
                Shift
              --------------*)
            print_tac "Shift"
            \\ Cases_on `s`
            \\ next_tac
            )
         >- (
            (*--------------
                LongMul
              --------------*)
            print_tac "LongMul"
            \\ next_tac
            )
         >- (
            (*--------------
                LongDiv
              --------------*)
            print_tac "LongDiv"
            \\ next_tac
            )
            (*--------------
                AddCarry
              --------------*)
            \\ print_tac "AddCarry"
            \\ next_tac
         )
         (*--------------
             Mem
           --------------*)
         \\ print_tac "Mem"
         \\ Cases_on `a`
         \\ Cases_on `m`
         \\ next_tac
      ) (* close Inst *)
      (*--------------
          Jump
        --------------*)
   >- (
      print_tac "Jump"
      \\ next_tac
      )
   >- (
      (*--------------
          JumpCmp
        --------------*)
      print_tac "JumpCmp"
      \\ Cases_on `r`
      \\ Cases_on `c`
      >| [
         Cases_on `ms.c_gpr ms.procID (n2w n) = ms.c_gpr ms.procID (n2w n')`,
         Cases_on `ms.c_gpr ms.procID (n2w n) <+ ms.c_gpr ms.procID (n2w n')`,
         Cases_on `ms.c_gpr ms.procID (n2w n) < ms.c_gpr ms.procID (n2w n')`,
         Cases_on `ms.c_gpr ms.procID (n2w n) &&
                   ms.c_gpr ms.procID (n2w n') = 0w`,
         Cases_on `ms.c_gpr ms.procID (n2w n) <> ms.c_gpr ms.procID (n2w n')`,
         Cases_on `~(ms.c_gpr ms.procID (n2w n) <+
                     ms.c_gpr ms.procID (n2w n'))`,
         Cases_on `~(ms.c_gpr ms.procID (n2w n) < ms.c_gpr ms.procID (n2w n'))`,
         Cases_on `(ms.c_gpr ms.procID (n2w n) &&
                    ms.c_gpr ms.procID (n2w n')) <> 0w`,
         Cases_on `ms.c_gpr ms.procID (n2w n) = c'`,
         Cases_on `ms.c_gpr ms.procID (n2w n) <+ c'`,
         Cases_on `ms.c_gpr ms.procID (n2w n) < c'`,
         Cases_on `ms.c_gpr ms.procID (n2w n) && c' = 0w`,
         Cases_on `ms.c_gpr ms.procID (n2w n) <> c'`,
         Cases_on `~(ms.c_gpr ms.procID (n2w n) <+ c')`,
         Cases_on `~(ms.c_gpr ms.procID (n2w n) < c')`,
         Cases_on `(ms.c_gpr ms.procID (n2w n) && c') <> 0w`
      ]
      \\ next_tac
      )
      (*--------------
          Call
        --------------*)
   >- (
      print_tac "Call"
      \\ next_tac
      )
   >- (
      (*--------------
          JumpReg
        --------------*)
      print_tac "JumpReg"
      \\ next_tac
      )
   >- (
      (*--------------
          Loc
        --------------*)
      print_tac "Loc"
      \\ next_tac
      )
   >- (
      (*--------------
          Jump enc_ok
        --------------*)
      print_tac "enc_ok: Jump"
      \\ enc_ok_tac
      )
   >- (
      (*--------------
          JumpCmp enc_ok
        --------------*)
      print_tac "enc_ok: JumpCmp"
      \\ Cases_on `ri`
      \\ Cases_on `cmp`
      \\ enc_ok_tac
      )
   >- (
      (*--------------
          Call enc_ok
        --------------*)
      enc_ok_tac
      )
   \\ (*--------------
          Loc enc_ok
        --------------*)
      print_tac "enc_ok: Loc"
   \\ enc_ok_tac
   )

val () = export_theory ()
