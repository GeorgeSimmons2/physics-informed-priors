# Rerun finished Fri Oct  2 10:51:27 PM BST 2026

## Job outcomes
     6324775            repro_w_core_qp          COMPLETED   00:05:17 
     6324776       repro_al12_committee          COMPLETED   00:08:55 
     6324777        repro_al12_cutplane          COMPLETED   00:08:20 
     6324778       repro_al12_hypercube          COMPLETED   00:04:15 
     6324779           repro_al12_naive          COMPLETED   00:11:08 
     6324780             repro_al16_ens          COMPLETED   00:02:26 
     6324781           repro_al16_bands          COMPLETED   00:18:05 
     6324782         repro_npt_con_Al12          COMPLETED   04:45:03 
     6324783       repro_npt_naive_Al12          COMPLETED   03:41:42 
     6324784         repro_committee_mv          COMPLETED   00:17:33 
     6324785        repro_committee_aeq          COMPLETED   00:07:46 
     6324786         repro_npt_con_Al12          COMPLETED   04:46:29 
     6324787       repro_npt_naive_Al12          COMPLETED   03:51:20 

## Verify
| quantity | tier | verdict | detail |
|---|---|---|---|
| W positive-core θ | `converged` | **FAIL** | max|Δ| = 1.688e+00  median|Δ| = 3.734e-05  ‖Δ‖/‖θ‖ = 1.434e-01  (tol 1.0e-02) |
| Al_12 θ_mean (ncell4 densek) | `converged` | **PASS** | max|Δ| = 5.454e-06  median|Δ| = 4.740e-08  ‖Δ‖/‖θ‖ = 5.021e-06  (tol 1.0e-02) |
| Al_12 committee_repaired (30) | `statistical` | **PASS** | n=30  worst z(mean) = 0.88, worst z(std) = 1.10  (threshold 4.5 σ of sampling noise) |
| Al_12 committee_rejection (30) | `statistical` | **FAIL** | n=30  worst z(mean) = 3.43, worst z(std) = 4.56  (threshold 4.5 σ of sampling noise) |
| Al_12 cutting-plane cloud, min ω | `statistical` | **PASS** | n=73479  min +0.1495→+0.1482  median +0.1669→+0.1666  max +0.4088→+0.4099 THz  (rel 0.0034, tol 0.010) |
| Al_12 rejection committee (full cloud) | `statistical` | **PASS** | n=30  worst z(mean) = 2.09, worst z(std) = 2.98  (threshold 4.5 σ of sampling noise) |
| Al_12 naive ensemble (30 × 91) | `converged` | **FAIL** | max|Δ| = 9.638e-02  median|Δ| = 1.443e-03  ‖Δ‖/‖θ‖ = 5.681e-03  (tol 1.0e-02) |
| Al_12 naive relaxed a | `converged` | **PASS** | n=30  min +3.9793→+3.9538  median +4.0873→+4.0795  max +4.2970→+4.3005 Å  (rel 0.0059, tol 0.010) |
| Al_16 unconstrained, native min ω (grid-matched) | `converged` | **  — ** | not produced yet: /storage/astro2/phupfb/PhD/acestuff/physics-informed-priors-repro/models/Al_16_4_6A_3_/results/repro_pinned_ensembles_nps20/bands_unconstrained.csv |
| Al_16 constrained, native min ω (grid-matched) | `converged` | **  — ** | not produced yet: /storage/astro2/phupfb/PhD/acestuff/physics-informed-priors-repro/models/Al_16_4_6A_3_/results/repro_pinned_ensembles_nps20/bands_constrained.csv |
| NPT multi-volume committee θ_mean | `converged` | **FAIL** | max|Δ| = 3.495e-02  median|Δ| = 4.452e-05  ‖Δ‖/‖θ‖ = 1.324e-02  (tol 1.0e-02) |
| NPT multi-volume committee_rejection (30) | `statistical` | **PASS** | n=30  worst z(mean) = 3.57, worst z(std) = 2.92  (threshold 4.5 σ of sampling noise) |
| NPT a_eq committee θ_mean | `converged` | **FAIL** | max|Δ| = 1.048e-01  median|Δ| = 6.973e-05  ‖Δ‖/‖θ‖ = 5.355e-02  (tol 1.0e-02) |
| NPT a_eq committee_rejection (30) | `statistical` | **PASS** | n=30  worst z(mean) = 4.01, worst z(std) = 2.89  (threshold 4.5 σ of sampling noise) |
7 passed, 5 failed, 2 not yet produced.

## NPT summaries
### repro_npt_multivolume_softest
T_K,a_Ang,a_std_Ang,delta_a_over_a0_pct,min_omega_THz,mean_coord,median_nn_Ang,still_fcc
0,4.044936,0,0,0.2882,12.00,2.8602,true
300,4.077861,0.004956,0.8140,0.3021,11.9900,2.7257,true
500,4.099550,0.006255,1.3502,0.2896,11.8471,2.6885,true
700,4.120435,0.008445,1.8665,0.2801,11.5121,2.6590,true
900,4.312109,0.010641,6.6051,0.2078,9.1187,2.4980,false
### repro_npt_thermal_expansion_naive_worst_member
T_K,a_Ang,a_std_Ang,delta_a_over_a0_pct,min_omega_THz
0,4.035234,0,0,-5.8740
300,4.130819,0.003269,2.3688,-9.5208
500,4.173372,0.004740,3.4233,-10.1210
700,4.225918,0.045052,4.7255,-10.4368
900,4.271154,0.008223,5.8465,-10.0181
### repro_e2e_npt_multivolume_softest
T_K,a_Ang,a_std_Ang,delta_a_over_a0_pct,min_omega_THz,mean_coord,median_nn_Ang,still_fcc
0,4.044936,0,0,0.2666,12.00,2.8602,true
300,4.090912,0.004965,1.1366,0.2310,11.9781,2.7323,true
500,4.120604,0.006450,1.8707,0.2106,11.7172,2.6955,true
700,4.146674,0.008685,2.5152,0.2025,11.2137,2.6653,true
900,4.291883,0.009169,6.1051,0.1882,9.1175,2.4882,false
### repro_e2e_npt_thermal_expansion_naive_worst_member
T_K,a_Ang,a_std_Ang,delta_a_over_a0_pct,min_omega_THz
0,4.035234,0,0,-5.8740
300,4.130819,0.003269,2.3688,-9.5208
500,4.173372,0.004740,3.4233,-10.1210
700,4.225918,0.045052,4.7255,-10.4368
900,4.271154,0.008223,5.8465,-10.0181
