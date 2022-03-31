(* This file contains proofs of the floating point properties:
local and global error, finiteness *)

From vcfloat Require Import FPLang FPLangOpt RAux Rounding Reify Float_notations Automate.
Require Import Interval.Tactic.
Import Binary.
Import List ListNotations.
Set Bullet Behavior "Strict Subproofs".

Require Import lf_harm_float lf_harm_real real_lemmas lf_harm_real_theorems lf_harm_lemmas.


Open Scope R_scope.

Section WITHNANS.


Context {NANS: Nans}.

Import Interval.Tactic.


Lemma prove_roundoff_bound_q:
  forall p q : ftype Tsingle,
  prove_roundoff_bound leapfrog_bmap (leapfrog_vmap p q) q' 
    (/ 4068166).
Proof.
intros.
prove_roundoff_bound.
- abstract (prove_rndval; interval).
-
  prove_roundoff_bound2.
 match goal with |- Rabs ?a <= _ => field_simplify a end.
 interval.
Qed.

Lemma prove_roundoff_bound_p:
  forall p q : ftype Tsingle,
  prove_roundoff_bound leapfrog_bmap (leapfrog_vmap p q) p' 
   (/4065000).
Proof.
intros.
prove_roundoff_bound.
- abstract (prove_rndval; interval).
-
  prove_roundoff_bound2.

 match goal with |- Rabs ?a <= _ => field_simplify a end.
interval.
Qed.


Lemma prove_roundoff_bound_q_implies:
  forall p q : ftype Tsingle,
boundsmap_denote leapfrog_bmap (leapfrog_vmap p q)-> 
Rabs (FT2R (fval (env_ (leapfrog_vmap p q)) q') - rval (env_ (leapfrog_vmap p q)) q') <= (/ 4068166)
.
Proof.
intros.
pose proof prove_roundoff_bound_q p q.
unfold prove_roundoff_bound in H0. 
specialize (H0 H).
unfold roundoff_error_bound in H0; auto. 
Qed.


Lemma prove_roundoff_bound_p_implies:
  forall p q : ftype Tsingle,
boundsmap_denote leapfrog_bmap (leapfrog_vmap p q)-> 
Rabs (FT2R (fval (env_ (leapfrog_vmap p q)) p') - rval (env_ (leapfrog_vmap p q)) p') <= (/4065000)
.
Proof.
intros.
pose proof prove_roundoff_bound_p p q.
unfold prove_roundoff_bound in H0. 
specialize (H0 H).
unfold roundoff_error_bound in H0; auto. 
Qed.


Lemma init_norm_eq :
∥  (FT2R p_init, FT2R q_init) ∥ = 1 . 
Proof.
intros.
replace 1 with (sqrt 1).
replace (FT2R q_init) with 1.
simpl. unfold Rprod_norm, fst, snd.
f_equal; nra.
unfold FT2R, q_init. 
unfold Rprod_norm, fst, snd.
 cbv [B2R]. simpl. cbv [Defs.F2R IZR IPR]. simpl;
field_simplify; nra.
apply sqrt_1.
Qed.


Hypothesis iternR_bnd:
  forall p q n,
  ∥iternR (p,q) h n∥ <= (sqrt 2 * ∥(p,q)∥).



Lemma init_norm_bound :
forall n,
∥ iternR (FT2R p_init, FT2R q_init) h n ∥ <= 1.5. 
Proof.
intros.
specialize (iternR_bnd (FT2R p_init) (FT2R q_init) n).
pose proof init_norm_eq.
rewrite H in iternR_bnd; clear H.
rewrite Rmult_1_r in iternR_bnd.
interval.
Qed.



Lemma roundoff_norm_bound:
 forall p q : ftype Tsingle,
boundsmap_denote leapfrog_bmap (leapfrog_vmap p q)-> 
let (pnf, qnf) := FT2R_prod (fval (env_ (leapfrog_vmap p q)) p', fval (env_ (leapfrog_vmap p q)) q') in 
let (pnr, qnr) := (rval (env_ (leapfrog_vmap p q)) p', rval (env_ (leapfrog_vmap p q)) q') in
∥ (pnf, qnf) .- (pnr, qnr)∥ <= ∥(/4065000, / 4068166)∥.
Proof.
intros.
unfold Rprod_minus, FT2R_prod, Rprod_norm, fst, snd.
rewrite <- pow2_abs.
rewrite Rplus_comm.
rewrite <- pow2_abs.
pose proof prove_roundoff_bound_p_implies p q H.
pose proof prove_roundoff_bound_q_implies p q H.
apply sqrt_le_1_alt.
eapply Rle_trans.
apply Rplus_le_compat_r.
apply pow_incr.
split; try (apply Rabs_pos).
apply H1.
eapply Rle_trans. 
apply Rplus_le_compat_l.
apply pow_incr.
split; try (apply Rabs_pos).
apply H0.
nra.
Qed.




Lemma global_error : 
  boundsmap_denote leapfrog_bmap 
    (leapfrog_vmap p_init q_init) ->
  forall n : nat, 
  (n <= 200)%nat -> 
  boundsmap_denote leapfrog_bmap 
    (leapfrog_vmap (fst(iternF (p_init,q_init) n)) (snd(iternF (p_init,q_init) n))) /\
  ∥(iternR (FT2R p_init, FT2R q_init) h n) .- FT2R_prod (iternF (p_init,q_init) n) ∥ <= (∥ (/ 4065000, / 4068166) ∥) * error_sum (1 + h) n.
  Proof.
intros.
induction n.
- unfold Rprod_minus. simpl. repeat rewrite Rminus_eq_0.
unfold Rprod_norm, fst, snd. repeat rewrite pow_ne_zero; try lia.
rewrite Rplus_0_r. rewrite sqrt_0.
split.  try nra.
  + apply H.
  + nra. 
- 
match goal with |- context [?A /\ ?B] =>
  assert B; try split; auto
end.
+ 
destruct IHn as (IHbmd & IHnorm); try lia.
rewrite step_iternF; rewrite step_iternR.
pose proof init_norm_bound n.
destruct (iternR (FT2R p_init, FT2R q_init) h n) as (pnr, qnr). 
destruct (iternF (p_init,q_init) n) as (pnf, qnf).
match goal with |- context[∥?a .- ?b∥ <=  _] =>
  let c := (constr:(leapfrog_stepR (FT2R_prod (pnf, qnf)) h)) in
  replace (∥a .- b∥) with (∥ Rprod_plus (a .- c) (c .- b) ∥)
end.
eapply Rle_trans.
apply Rprod_triang_ineq.
rewrite leapfrog_minus_args.
eapply Rle_trans.
apply Rplus_le_compat_l.
assert (BNDn: (n<= 200)%nat) by lia.
assert (∥ Rprod_minus (pnr, qnr) (FT2R_prod (pnf, qnf)) ∥ <=
      (∥ (/ 4065000, / 4068166) ∥) * error_sum (1 + h) n /\ ∥ (pnr, qnr) ∥ <= 1.5).
split; auto.
pose proof (roundoff_norm_bound pnf qnf IHbmd) as BND.
rewrite reflect_reify_p in BND.
rewrite reflect_reify_q in BND.
change (leapfrog_step_p pnf qnf, leapfrog_step_q pnf qnf) with 
  (leapfrog_stepF (pnf, qnf)) in BND.
rewrite rval_correct_q in BND. 
rewrite rval_correct_p in BND.
change ((fst (leapfrog_stepR (FT2R_prod (pnf, qnf)) h),
         snd (leapfrog_stepR (FT2R_prod (pnf, qnf)) h))) with 
(leapfrog_stepR (FT2R_prod (pnf, qnf)) h) in BND.
destruct (FT2R_prod (leapfrog_stepF (pnf, qnf))). 
rewrite Rprod_minus_comm in BND. 
apply BND.  
destruct (Rprod_minus (pnr, qnr) (FT2R_prod (pnf, qnf))).
assert (0 < h < 2) as Hh by (unfold h; nra).
pose proof (method_norm_bounded r r0 h Hh) as BND.
eapply Rle_trans.
apply Rplus_le_compat_r.
apply BND. 
eapply Rle_trans.
apply Rplus_le_compat_r.
apply Rmult_le_compat_l; try (unfold h; nra).
assert (BNDn: (n<= 200)%nat) by lia.
apply IHnorm. 
set (aa:= (∥ (/ 4065000, / 4068166) ∥)). 
replace ((1 + h) * (aa * error_sum (1 + h) n) + aa)
with
(aa * ((1 + h) * (error_sum (1 + h) n) + 1)) by nra.
rewrite <- error_sum_aux2. nra.
symmetry. apply Rprod_norm_plus_minus_eq.
+ destruct IHn as (IHbmd & IHnorm); try lia.
apply itern_implies_bmd; try lia; auto; split; auto.
pose proof init_norm_bound (S n); auto.
Qed. 



Theorem total_error: 
  forall pt qt: R -> R,
  forall n : nat, 
  (n <= 200)%nat ->
  let t0 := 0 in
  let tn := t0 + INR n * h in
  let w  := 1 in
  Harmonic_osc_system pt qt w t0 (FT2R p_init) (FT2R q_init) ->
  (forall t1 t2: R,
  k_differentiable pt 4 t1 t2 /\
  k_differentiable qt 3 t1 t2)  ->
  ∥ (pt tn, qt tn) .- (FT2R_prod (iternF (p_init,q_init) n)) ∥ <= 
  (h^2  + (∥ (/ 4065000, / 4068166) ∥) / h) * ((1 + h)^ n - 1) .
Proof.
assert (BMD: boundsmap_denote leapfrog_bmap (leapfrog_vmap p_init q_init)) by
apply bmd_init.
intros ? ? ? ? ? ? ? Hsys Kdiff.
match goal with |- context[?A <= ?B] =>
replace A with
  (∥ ((pt (t0 + INR n * h), qt (t0 + INR n * h)) .- (iternR (FT2R p_init, FT2R q_init) h n)) .+
((iternR (FT2R p_init, FT2R q_init) h n) .- (FT2R_prod (iternF (p_init,q_init) n))) ∥)
end.
assert (HSY: Harmonic_osc_system pt qt 1 t0 (FT2R p_init) (FT2R q_init)) by auto.
unfold Harmonic_osc_system in Hsys.
destruct Hsys as (A & B & C).
eapply Rle_trans.
apply Rprod_triang_ineq.
eapply Rle_trans.
apply Rplus_le_compat_l.
apply global_error; auto.
eapply Rle_trans.
apply Rplus_le_compat_r.
apply symmetry in A. apply symmetry in B.
rewrite A in *. rewrite B in *.
apply global_truncation_error_aux; try unfold h; try nra; auto.
assert (hlow: 0 < h) by (unfold h; nra).
 pose proof error_sum_GS n h hlow as GS.
rewrite GS.
apply Req_le.
replace ((∥ (/ 4065000, / 4068166) ∥) * (((1 + h) ^ n - 1) / h))
with 
((∥ (/ 4065000, / 4068166) ∥) / h  * ((1 + h) ^ n - 1) ).
replace (∥ (pt t0, qt t0) ∥) with 1.
field_simplify; nra.
rewrite A. rewrite B.
symmetry.
apply init_norm_eq.
field_simplify; repeat nra.
field_simplify.
symmetry; apply Rprod_norm_plus_minus_eq.
Qed. 




Lemma leapfrog_step_is_finite:
 forall n,  ( n <= 200)%nat->
  (is_finite _ _  (fst(iternF (p_init,q_init)  n)) = true) /\
  (is_finite _ _  (snd(iternF (p_init,q_init)  n)) = true).
Proof.
intros.
pose proof global_error bmd_init n H.
destruct H0 as (A & _).
 lazymatch goal with
 | H: boundsmap_denote _ _ |- _ =>
  apply boundsmap_denote_e in H;
  simpl Maps.PTree.elements in H;
  unfold list_forall in H
end.
destruct A as (A & B).
simpl in A. destruct A as (V1 & V2 & V3 & V4 & _).  
  inversion V3; subst. simpl in V4; auto.
simpl in B. destruct B as (U1 & U2 & U3 & U4 & _).  
  inversion U3; subst. simpl in U4; auto.
Qed.



End WITHNANS.