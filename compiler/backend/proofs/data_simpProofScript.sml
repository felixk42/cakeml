open preamble data_simpTheory dataSemTheory;

val _ = new_theory"data_simpProof";

val _ = temp_bring_to_front_overload"evaluate"{Name="evaluate",Thy="dataSem"};

val evaluate_Seq_Skip = prove(
  ``!c s. evaluate (Seq c Skip,s) = evaluate (c,s)``,
  fs [evaluate_def,LET_DEF] \\ REPEAT STRIP_TAC
  \\ Cases_on `evaluate (c,s)` \\ fs [] \\ SRW_TAC [] []);

val evaluate_pSeq = prove(
  ``evaluate (pSeq c1 c2, s) = evaluate (Seq c1 c2, s)``,
  SRW_TAC [] [pSeq_def] \\ fs [evaluate_Seq_Skip]);

val evaluate_simp = prove(
  ``!c1 s c2. evaluate (simp c1 c2,s) = evaluate (Seq c1 c2,s)``,
  recInduct evaluate_ind \\ reverse (REPEAT STRIP_TAC) THEN1
   (Cases_on `handler` \\ fs [simp_def,evaluate_pSeq]
    \\ Cases_on `x` \\ fs [simp_def,evaluate_pSeq]
    \\ fs [evaluate_def]
    \\ every_case_tac >> fs[evaluate_def,LET_THM]
    \\ Cases_on `evaluate (r,set_var q a r''')` \\ fs []
    \\ Cases_on `q'` \\ fs [])
  \\ fs [simp_def,evaluate_def,LET_DEF,evaluate_pSeq,evaluate_pSeq]
  \\ Cases_on `evaluate (c1,s)` \\ fs []
  \\ Cases_on `evaluate (c2,r)` \\ fs []
  \\ Cases_on `evaluate (c2,set_var n a r)` \\ fs []
  \\ rw[] >> every_case_tac \\ fs [evaluate_def] \\ fs []
  \\ CONV_TAC (DEPTH_CONV (PairRules.PBETA_CONV))
  \\ every_case_tac >> fs[evaluate_def]);

val simp_correct = store_thm("simp_correct",
  ``!c s. evaluate (simp c Skip,s) = evaluate (c,s)``,
  SIMP_TAC std_ss [evaluate_simp,evaluate_Seq_Skip]);

val _ = export_theory();
