From Flocq Require Import Binary Bits Core.
From compcert.lib Require Import IEEE754_extra Coqlib Floats Zbits Integers.
Require Import vcfloat float_lib lf_harm_float lf_harm_real optimize real_lemmas lf_harm_lemmas.
Set Bullet Behavior "Strict Subproofs". 

Import FPLangOpt. 
Import FPLang.
Import FPSolve.
Import Test.

Import Interval.Tactic.


Definition one_step_sum_bnd_x := (4646536420130942 / 2251799813685248)%R.
Definition one_step_sum_bnd_v := (4646570650113373 / 2251799813685248)%R.

Definition lf_bmap_init := (lf_bmap_n 0 0 0).

Lemma lf_bmap_init_eq :
forall x v : float32, 
forall e1 e2 : R, 
  boundsmap_denote (lf_bmap_init ) (leapfrog_vmap x v)=
boundsmap_denote (lf_bmap_n e1 e2 0) (leapfrog_vmap x v).
Proof.
intros.
f_equal; unfold lf_bmap_init, lf_bmap_n, lf_bmap_list_n.
rewrite Rmult_0_r. 
replace (INR 0 * e1) with 0 by (simpl; nra).
replace (INR 0 * e2) with 0 by (simpl; nra).
repeat f_equal.
Qed.


(* single step position error *)
Theorem one_step_error_x:
  forall x v : float32,
    boundsmap_denote lf_bmap_init (leapfrog_vmap x v)->
    (Rabs (Rminus (rval (leapfrog_env  x v) (optimize_div x')) 
   (B2R _ _ (fval (leapfrog_env  x v) (optimize_div x'))))) <=
         (1.25/(10^7)).
Proof.
intros.
(destruct (rndval_with_cond O (mempty  (Tsingle, Normal)) (optimize_div x')) 
  as [[r [si2 s]] p] eqn:rndval).
(assert (BND: 0 <= 0 <= 1) by nra).
pose proof 
  (rndval_with_cond_correct_optx_n x v 0%nat (Nat.le_0_l (1000)) 0 0 BND BND H r si2 s p rndval)
as rndval_result.
intro_absolute_error_bound Tsingle Normal H x v rndval_result.
Qed.

(* single step position error *)
Theorem one_step_error_v:
  forall x v : float32,
    boundsmap_denote lf_bmap_init (leapfrog_vmap x v)->
    (Rabs (Rminus (rval (leapfrog_env  x v) (optimize_div v')) 
   (B2R _ _ (fval (leapfrog_env  x v) (optimize_div v'))))) <=
       6.75/(10^8) .
Proof.
intros.
(destruct (rndval_with_cond O (mempty  (Tsingle, Normal)) (optimize_div v')) 
  as [[r [si2 s]] p] eqn:rndval).
(assert (BND: 0 <= 0 <= 1) by nra).
pose proof 
  (rndval_with_cond_correct_optv_n x v 0%nat (Nat.le_0_l (1000)) 0 0 BND BND H r si2 s p rndval)
as rndval_result.
intro_absolute_error_bound Tsingle Normal H x v rndval_result.
Qed.


Lemma local_error_x :
  forall x v : float32,
  forall x1 v1 : R,
    boundsmap_denote lf_bmap_init (leapfrog_vmap x v)->
  x1 = B2R _ _ x ->
  v1 = B2R _ _ v -> 
    (Rabs (Rminus (fst(leapfrog_stepR' (x1,v1))) 
    (B2R _ _ (leapfrog_stepx x v)))) <=  (1.25/(10^7)).
Proof.
intros.
replace (fst (leapfrog_stepR' (x1,v1))) with 
  (rval (leapfrog_env x v) (optimize_div x')).
 replace (B2R 24 128 (leapfrog_stepx x v)) with
  (B2R _ _(fval (leapfrog_env x v) (optimize_div x'))).
  - pose proof one_step_error_x x v H. apply H2.
  - rewrite <- env_fval_reify_correct_leapfrog_step_x; 
  (assert (BND: 0 <= 0 <= 1) by nra).
  pose proof optimize_div_correct' (leapfrog_env x v) x' 
  (leapfrog_stepx_not_nan_n x v 0%nat (Nat.le_0_l (1000)) 0 0 BND BND H);
revert H2;
generalize (fval (leapfrog_env x v) (optimize_div x'));
rewrite optimize_div_type; intros;
apply binary_float_eqb_eq in H2; subst; reflexivity.
- rewrite (@env_rval_reify_correct_leapfrog_stepx x v x1 v1); auto.
Qed.


Lemma local_error_v:
  forall x v : float32,
  forall x1 v1 : R,
    boundsmap_denote lf_bmap_init (leapfrog_vmap x v)->
  x1 = B2R _ _ x ->
  v1 = B2R _ _ v -> 
    (Rabs (Rminus (snd(leapfrog_stepR' (x1,v1))) 
    (B2R _ _ (leapfrog_stepv x v)))) <= 6.75/(10^8).
Proof.
intros. 
replace (snd (leapfrog_stepR' (x1,v1))) with 
  (rval (leapfrog_env x v) (optimize_div v')).
 replace (B2R 24 128 (leapfrog_stepv x v)) with
  (B2R _ _(fval (leapfrog_env x v) (optimize_div v'))).
  - pose proof one_step_error_v x v H. apply H2.
  - rewrite <- env_fval_reify_correct_leapfrog_step_v; 
  (assert (BND: 0 <= 0 <= 1) by nra).
  pose proof optimize_div_correct' (leapfrog_env x v) v' 
  (leapfrog_stepv_not_nan_n x v 0%nat (Nat.le_0_l (1000)) 0 0 BND BND H);
revert H2;
generalize (fval (leapfrog_env x v) (optimize_div v'));
rewrite optimize_div_type; intros;
apply binary_float_eqb_eq in H2; subst; reflexivity.
- rewrite (@env_rval_reify_correct_leapfrog_stepv x v x1 v1); auto.
Qed.



Lemma leapfrog_step_is_finite:
forall n: nat,
forall x  v : float32,
forall e1 e2: R,
boundsmap_denote (lf_bmap_n e1 e2 n) 
  (leapfrog_vmap (fst ( iternF ( n) x v)) (snd ( iternF ( n) x v))) ->
(n <= 1000)%nat ->
is_finite _ _ (fst ( iternF (S n) x v)) = true/\
is_finite _ _ (snd ( iternF (S n) x v)) = true.  
Proof.
Admitted.


(*
Theorem global_error:
  forall x v : float32, 
  forall n: nat, 
  (n <= 1000)%nat ->
    (forall m: nat,
    (m <= n)%nat ->
    boundsmap_denote (lf_bmap_n e_x e_v m) 
      (leapfrog_vmap (snd(iternF m x v)) (snd(iternF m x v)))) 

(* incorrect assumption *)
->
  forall x1 v1 : R,
  x1 = B2R _ _ x ->
  v1 = B2R _ _ v -> 
  Rle (Rabs (Rminus (fst(leapfrogR' x1 v1 (S n))) (B2R _ _ (fst(iternF (S n) x v))))) 
   (delta_x e_x e_v n) /\
  Rle (Rabs (Rminus (snd(leapfrogR' x1 v1 (S n))) (B2R _ _ (snd(iternF (S n) x v))))) 
   (delta_v e_x e_v n) .
Proof.
Admitted.
*)
