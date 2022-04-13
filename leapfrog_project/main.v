Require Import VST.floyd.proofauto.
Require Import Reals.
Require Import real_lemmas.
Require Import lfharm.
Require Import verif_lfharm.
Require Import lf_harm_float lf_harm_theorems.
Require Import vcfloat.FPSolve.

Definition integrate_spec_highlevel := 
  DECLARE _integrate
  WITH xp: val, vp: val
  PRE [ tptr tfloat , tptr tfloat ]
    PROP()
    PARAMS (xp; vp)
    SEP(data_at_ Tsh tfloat xp; data_at_ Tsh tfloat vp )
  POST [ tvoid ]
   EX (xv: float32*float32),
    PROP(total_error_100 xv)
    RETURN()
    SEP(data_at Tsh tfloat (Vsingle (fst xv)) xp; 
          data_at Tsh tfloat (Vsingle (snd xv)) vp ).

Lemma subsume_integrate: funspec_sub (snd integrate_spec) (snd integrate_spec_highlevel).
Proof.
apply NDsubsume_subsume.
split; auto.
unfold snd.
hnf; intros.
split; auto. intros [x v] [? ?]. Exists (x,v) emp.
Intros. simpl in H.
inv H. inv H4. inv H5.
pose proof yes_iternF_is_finite.
destruct (H 100%nat ltac:(lia)).
pose proof yes_total_error_100.
change initial_x with q_init. change initial_v with p_init.
set (xv := iternF (q_init, p_init) 100) in *.
clearbody xv.
unfold_for_go_lower; normalize.
inv H5.
simpl; entailer!.
intros.
Exists xv.
entailer!.
Qed.

Theorem body_integrate_highlevel :
   semax_body Vprog Gprog f_integrate integrate_spec_highlevel.
Proof.
eapply semax_body_funspec_sub.
apply body_integrate.
apply subsume_integrate.
repeat constructor; intro H; simpl in H; decompose [or] H; try discriminate; auto.
Qed.


