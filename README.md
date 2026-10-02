# Identification of surface colours across environmental illuminations

MATLAB code for the analyses, computational-observer models and figures of:

> T. Morimoto and H. E. Smithson, *Identification of surface colours across
> environmental illuminations* (in preparation; target journal: **JOSA A**).

This repository holds all of the analysis code. The stimuli and human data are
archived separately because of their size — see **[Getting the data](#getting-the-data)**
below. With `data/` in place, one command in MATLAB regenerates every figure in
the paper and prints every reported statistic to the console.

---

## Overview

Colour is useful for recognising objects, but the light reaching the eye
confounds surface reflectance with the illumination. This project measures
**selection-based colour constancy** under realistic, directionally structured
lighting simulated with *environmental illumination* maps.

On each trial four computer-graphics objects are shown — a left pair and a right
pair rendered under two different lighting environments. Three objects share a
diffuse reflectance; the fourth (the target) differs. Observers find the target
in an "odd-one-out" task.

- **Experiment 1** — how do *specularity* (matte vs glossy) and the presence of a
  *surrounding context* affect constancy under complex illumination?
- **Experiment 2** — does constancy survive when the surround is deliberately made
  *uninformative* about the light falling on the objects?

Seven observers completed both experiments. Alongside the human data we run
**computational observer models** that estimate a single, global illuminant from
the image (mean chromaticity, brightest pixel, luminance-weighted mean
chromaticity), apply a diagonal (von Kries) correction, and are corrupted by
Gaussian internal noise — optionally integrating chromatic statistics over trials
with a time constant τ. Two of them, the no-correction baseline and the
object-based estimators, never look at the surround, so the conditions with and
without one are the same condition for them; `run_simulation_exp1.m` runs each
once and writes the responses to both, rather than redrawing the internal noise
and inventing a difference.

The headline result: constancy was good and orderly. Difficulty was set by the
chromatic separation of the two reflectances, and the surrounding context was
worth 9.4 percentage points at every level of it. Computational observers that
estimate one illuminant statistic from the surround and apply a diagonal
correction reached the observers' accuracy — a single-illuminant correction does
transfer to directionally structured light. It is not, however, what observers
used: when the surround was made uninformative about the light on the objects,
observers lost 5.1 percentage points and the best of those models lost 44.2,
falling to chance.

## Getting the data

`data/` and `results/` are **not** tracked in git: together they run to about
4 GB, most of it rendered multispectral stimuli. The archive is available at

> *(DOI to be added on publication — the dataset will be deposited on Zenodo.)*

Unpack it so that the repository root contains `data/`, i.e.

```
reflectance_identification/
├── data/human/exp1, data/human/exp2      raw observer responses
├── data/stimuli/exp1, data/stimuli/exp2  rendered multispectral stimuli
├── data/environments/                    environmental illumination maps
└── src/, main.m, ...                     (this repository)
```

`results/` is created by `main.m`; you do not need to download it.

## Quick start

With `data/` in place, from the repository root in MATLAB:

```matlab
main            % compute scores, run the control analysis, redraw every figure
```

Other entry points:

```matlab
main(true)          % also rerun the model simulations (slow; uses parfor)
main(false, false)  % reuse an existing results/, only redraw the figures
```

Starting from `data/` alone, `main` takes roughly an hour, most of it in the
model simulations and the permutation test; afterwards `main(false, false)`
redraws everything in seconds.

Each figure script also **prints the statistics reported for that figure**
(means ± SE, repeated-measures ANOVA F/p, Spearman ρ between model and observer
pair matrices) to the MATLAB console, so the numbers in the manuscript can be
checked directly against the output.

## Requirements

- **MATLAB** — originally developed with R2016b; verified on R2025b.
- **Statistics and Machine Learning Toolbox** — `fitrm` / `ranova` for the
  repeated-measures ANOVAs.
- [**brewermap**](https://github.com/DrosteEffect/BrewerMap) — bundled in
  `src/functions/vendor/`, so no separate install is needed; `main` puts `src/`
  (and its `vendor/`) on the path automatically.
- *Re-rendering the stimuli* (not needed for any analysis) additionally requires
  Blender, Mitsuba 0.5 and RenderToolbox4 — see
  `src/plotting/plot_fig3_all_stimuli.m`.

## Reproducing the analysis

The pipeline has three stages, wrapped by `main.m`:

```
 data/stimuli + data/human
        │
        ▼   run_simulation_exp{1,2}          (optional; hours, parfor)
 results/model/            per-trial responses of every model observer
        │
        ▼   compute_scores_exp{1,2}
 results/scores/           performance matrices + human-vs-model trial scores
 results/matrix_images/    per-condition performance-matrix images
        │
        ▼   plot_fig<N>_* scripts
 figs/                     vector PDF + 600-dpi PNG per figure
```

Neither `data/` nor `results/` is tracked in git (see
[Getting the data](#getting-the-data)). `results/` is produced entirely by
`main.m`, so once it exists locally, `main(false, false)` redraws every figure in
seconds; use `main(true)` only to regenerate `results/model/` from scratch.

## Manuscript figure map

`src/plotting/` holds exactly one script per manuscript figure, named
`plot_fig<N>_*.m` (minimal "mean + individual observers" style; light-grey axes;
two-column 17.8 cm / one-column 8.9 cm sizing defined centrally in
`src/functions/fig_parameters.m`).

| Fig. | Content | Script |
|-----|---------|--------|
| 1  | Environmental illuminations & chromatic distributions | `plot_fig1_environment.m` |
| 2  | Surface reflectances | `plot_fig2_reflectance.m` |
| 3  | Overview of all rendered stimuli | `plot_fig3_all_stimuli.m` *(needs Mitsuba)* |
| 4  | Trial procedure | `plot_fig4_procedure.m` |
| 5  | Model flow schematic | *(illustration; `plot_fig5_gaussian_noise.m` draws the internal-noise inset)* |
| 6  | Exp 1 viewing angles | `plot_fig6_viewing_angles.m` *(needs external data)* |
| 7a-d | Exp 1 human performance: overall (a, with the no-correction model), learning across sessions (b), per reflectance pair (c), hue separation (d) | `plot_fig7_human_performance_exp1.m` |
| 8  | Exp 1 model accuracy; what gloss is worth to a model; pair matrices of the accuracy-matching models | `plot_fig8_model_accuracy_exp1.m` |
| 9  | Exp 2 viewing angles and example presentations | `plot_fig6_viewing_angles.m` *(needs external data)* + `plot_fig9_exp2_stimuli.m` |
| 10 | Exp 2 human performance + ANOVA, with pair matrices | `plot_fig10_human_performance_exp2.m` |
| 11 | Exp 2 cost of an uninformative surround, with the congruent-estimate model's pair matrices | `plot_fig11_model_accuracy_exp2.m` |

`main` runs all of these except Figure 3 (which re-renders the stimuli and needs
Mitsuba) and Figure 6/9's viewing-angle panels, which are drawn only when
`data/external/` is present.

## Repository layout

```
main.m                       one-click wrapper (recompute + redraw everything)
data/
  human/{exp1,exp2}          raw human responses (7 observers; irreplaceable)
  stimuli/{exp1,exp2}        rendered stimuli as MacLeod–Boynton images (.mat)
  stimuli/all_hues           per-hue renders for the stimulus-overview figure
  config/                    thresholds, environment variance, seeds, misc inputs
  environments/              MB/RGB images of the four illumination maps
  procedure/                 renders used for the procedure figure
  rendering/                 blend scenes + reflectance spectra (.spd)
  thresholds_morimoto2018/   discrimination thresholds from Morimoto et al. (2018)
  figure_assets/             object icons composited into figures
  external/                  large renders not bundled — see "Large external data"
src/
  functions/                 color conversions, model observers, figure styling
  functions/vendor/          third-party helpers (brewermap, ticklengthcm, …)
  analysis/                  run_simulation_exp{1,2}, compute_scores_exp{1,2}
  plotting/                  plot_fig<N>_*.m, one script per paper figure
results/
  model/{exp1,exp2}          simulated model responses per trial (regenerable)
  scores/{exp1,exp2}         performance matrices + human-vs-model scores
  matrix_images/{exp1,exp2}  per-condition performance-matrix images
figs/                        generated figures (vector PDF + 600-dpi PNG)
```

All data and result **file names are lowercase**; the code and directories use
`snake_case`.

## Large external data

The camera-angle renders used by `plot_viewing_angles.m`
(`E3E4_AllAnglewithMirrorMB`, ~1.2 GB) are too large to bundle. Copy the folder
from the archive repository `Paper_RefIdentification` into `data/external/` so the
files resolve at
`data/external/E3E4_AllAnglewithMirrorMB/En3_cameraYRot0_…mat`. When the folder
is absent, `main` skips `plot_viewing_angles` and reports that it did so; all
other figures still build.

## A note on naming

The two experiments were called "Exp3_1" and "Exp3_2" during data collection.
Data **file** names (e.g. `potato_…_exp3_2.mat`) keep that historical suffix,
while all code and directories use `exp1` / `exp2`.

## Data availability

The stimuli, individual observer responses, and analysis and figure-generation
code are openly available in this repository:
<https://github.com/takuma929/ReflectanceIdentificationAcrossEnvironmentalIlluminations>

## License

Code is released under the [MIT License](LICENSE) © 2021 Takuma Morimoto.

## Citation

If you use this code or data, please cite the paper (details will be updated on
publication) and this repository.
