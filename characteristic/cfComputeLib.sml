structure cfComputeLib =
struct

open HolKernel boolLib bossLib

(* Auxiliary definitions used in cfs *)
val add_cf_aux_compset = computeLib.extend_compset
  [computeLib.Defs
    [cfTheory.dest_opapp_def,
     cfTheory.is_bound_Fun_def,
     cfTheory.Fun_body_def,
     cfTheory.Fun_params_def,
     cfTheory.naryFun_def,
     cfTheory.letrec_pull_params_def,
     cfTheory.naryClosure_def,
     cfTheory.naryRecclosure_def,
     cfTheory.extend_env_v_def,
     cfTheory.extend_env_def,
     cfTheory.build_rec_env_aux_def,
     cfTheory.extend_env_v_rec_def,
     cfTheory.extend_env_rec_def,
     cfTheory.v_of_pat_def,
     cfTheory.v_of_pat_norest_def,
     cfTheory.pat_typechecks_def,
     cfTheory.pat_without_Pref_def,
     cfTheory.validate_pat_def,
     cfTheory.build_cases_def
    ]
  ]

val add_cf_normalize_compset = computeLib.extend_compset
  [computeLib.Defs
    [cfNormalizeTheory.exp2v_def,
     cfNormalizeTheory.exp2v_list_def
    ]
  ]


end
