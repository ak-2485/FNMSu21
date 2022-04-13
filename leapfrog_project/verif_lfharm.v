Require Import VST.floyd.proofauto.
Require Import lfharm.
#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.
Definition Vprog : varspecs. mk_varspecs prog. Defined.

Open Scope logic.

From vcfloat Require Import FPSolve Float_notations.
Require Import lf_harm_float (*lf_harm_lemmas lf_harm_theorems*).

Set Bullet Behavior "Strict Subproofs". 

Definition force_spec :=
 DECLARE _force
 WITH  x : ftype Tsingle
 PRE [ tfloat ] PROP() PARAMS(Vsingle x) SEP()
 POST [ tfloat ] PROP() RETURN (Vsingle (F x)) SEP().

Definition lfstep_spec := 
  DECLARE _lfstep
  WITH xp: val, x: ftype Tsingle, vp: val, v: ftype Tsingle
  PRE [ tptr tfloat , tptr tfloat , tfloat ]
    PROP(Binary.is_finite 24 128 x = true)
    PARAMS (xp; vp; Vsingle h)
    SEP(data_at Tsh tfloat (Vsingle x) xp; data_at Tsh tfloat (Vsingle v) vp )
  POST [ tvoid ]
    PROP()
    RETURN()
    SEP(data_at Tsh tfloat (Vsingle (fst(leapfrog_stepF (x,v)))) xp; 
          data_at Tsh tfloat (Vsingle (snd(leapfrog_stepF (x,v)))) vp ).

Definition integrate_spec_lowlevel := 
  DECLARE _integrate
  WITH xp: val, vp: val
  PRE [ tptr tfloat , tptr tfloat ]
    PROP(iternF_is_finite)
    PARAMS (xp; vp)
    SEP(data_at_ Tsh tfloat xp; data_at_ Tsh tfloat vp )
  POST [ tvoid ]
    PROP()
    RETURN()
    SEP(data_at Tsh tfloat (Vsingle (fst(iternF (q_init,p_init) 100))) xp; 
          data_at Tsh tfloat (Vsingle (snd(iternF (q_init,p_init) 100))) vp ).

Definition main_spec :=
 DECLARE _main
  WITH gv: globals
  PRE  [] main_pre prog tt gv
  POST [ tint ]
       PROP() RETURN (Vint (Int.repr 0)) SEP(TT).

Definition Gprog : funspecs := [force_spec; lfstep_spec; integrate_spec_lowlevel; main_spec].

Lemma body_force: semax_body Vprog Gprog f_force force_spec.
Proof.
start_function.
forward.
Qed.

Lemma body_lfstep: semax_body Vprog Gprog f_lfstep lfstep_spec.
Proof.
start_function. 
subst MORE_COMMANDS; unfold abbreviate; canonicalize_float_constants.
forward.
forward_call.
forward.
forward.
forward.
forward.
forward.
forward_call.
forward.
forward.
entailer!. 
autorewrite with float_elim in *.
unfold leapfrog_stepF, fst, snd.
replace (1/2)%F32 with (0.5)%F32
  by (compute_binary_floats; auto).
auto.
Qed.

Lemma body_integrate: semax_body Vprog Gprog f_integrate integrate_spec_lowlevel.
Proof.
start_function.
subst MORE_COMMANDS; unfold abbreviate; canonicalize_float_constants.
forward.
forward.
forward.
forward.
forward.
autorewrite with float_elim in *. 
pose (step n := iternF (q_init, p_init) (Z.to_nat n)).
 forward_for_simple_bound 100%Z (EX n:Z,
       PROP() 
       LOCAL (temp _h (Vsingle h);
                   temp _max_step (Vint (Int.repr 100));
                   temp _t (Vsingle (Z.iter n (BPLUS Tsingle h) (0%F32))); 
                   temp lfharm._x xp; temp lfharm._v vp)
   SEP (data_at Tsh tfloat (Vsingle (fst (step n))) xp;
          data_at Tsh tfloat (Vsingle (snd (step n))) vp))%assert.
- entailer!.
- forward_call.
  apply H; lia.
  forward.
  autorewrite with float_elim in *.
  entailer!.
  fold (Z.succ i); rewrite Zbits.Ziter_succ by lia.
  rewrite BPLUS_commut by reflexivity; auto.
  replace (fst (step i), snd (step i)) with
  (iternF (q_init, p_init) (Z.to_nat i)).
  rewrite <- step_iternF.
  replace (iternF (q_init, p_init) (S (Z.to_nat i))) with 
  ((step (i + 1)%Z)).
  cancel.
 + unfold step. f_equal. lia.
 + unfold step. destruct (iternF (q_init, p_init) (Z.to_nat i)).
     auto.
- change (iternF(q_init, p_init) 100) with (step 100%Z).
   forward.
Qed.









