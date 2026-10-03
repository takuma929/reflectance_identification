# Identification of surface colours across environmental illuminations

MATLAB code and data to reproduce the figures of the manuscript *Identification
of surface colours across environmental illuminations* (T. Morimoto and
H. E. Smithson). Observers located the odd-one-out among four rendered objects
shown under two environmental illuminations. Experiment 1 asked how surface
specularity and a surrounding context affect this selection-based colour
constancy; Experiment 2 asked what is lost when the surround no longer predicts
the light falling on the objects. Computational observers that estimate one
illuminant from the image and apply a diagonal correction are scored on the
same trials.

Each script in the repository root regenerates one figure from the data in
[`data/`](data/) and writes its panels (PDF, PNG or TIFF) into `figs/`.

---

## 1. System requirements

* **Operating system:** Windows, macOS or Linux (tested on macOS 15).
* **MATLAB:** R2020a or newer (the scripts use `exportgraphics`; tested on
  R2025b).
* **Required toolbox:** Statistics and Machine Learning Toolbox, for
  `fitrm` / `ranova` (repeated-measures ANOVAs), `ttest` and `corr`.

No other toolbox is needed and nothing has to be downloaded: every helper
function is bundled in [`utils/`](utils/), including Stephen Cobeldick's
`brewermap` (BSD licence, see the file header).

## 2. Installation

```
git clone https://github.com/takuma929/reflectance_identification.git
```

No build step. Every script resolves its paths relative to its own location
and adds `utils/` to the path, so it can be run from any working folder.

## 3. Regenerate all figures

In MATLAB, make the repository the current folder and run:

```matlab
run_all
```

This runs every figure script in turn and writes the panels into `figs/`. The
Command Window reports, for each figure, the statistics quoted in the paper
(means and standard errors, ANOVA F and p values, t tests, correlations).
The full set takes a few minutes.

To regenerate a single figure, run its script by name, e.g.

```matlab
fig7_human_performance_exp1
```

## 4. Figure scripts

| Script | Figure | Content |
| --- | --- | --- |
| `fig1_environment.m` | 1 | Chromatic distributions of the four environmental illuminations |
| `fig2_reflectance.m` | 2 | Chromaticities and spectra of the test reflectances |
| `fig4_procedure.m` | 4 | Stimulus presentation on one trial (Experiment 1) |
| `fig5_gaussian_noise.m` | 5 | Internal-noise inset of the model schematic |
| `fig7_human_performance_exp1.m` | 7 | Experiment 1 human performance: overall, across sessions, per reflectance pair, by hue separation |
| `fig8_model_accuracy_exp1.m` | 8 | Experiment 1 model accuracy and the pair matrices of the best models |
| `fig9_exp2_stimuli.m` | 9 | Example presentations of Experiment 2 |
| `fig10_human_performance_exp2.m` | 10 | Experiment 2 human performance, congruent vs incongruent |
| `fig11_model_accuracy_exp2.m` | 11 | Experiment 2: cost of an uninformative surround for observers and models |

**Figure 3** (overview of all stimuli) and **Figure 6** and the viewing-angle
panels of **Figure 9** (scene geometry) are made from the full set of rendered
stimuli, which is not distributed because of its size (several GB); the
remaining panels of Figure 5 are a hand-drawn schematic. These have no script
here.

## 5. Data

[`data/`](data/) holds everything the figure scripts read. The rendered
stimuli and the trial-by-trial model simulations are not included; the model
results enter through the performance matrices in `data/scores/`.

### 5.1 Human responses (`data/human/`)

Seven observers (`akh`, `jh`, `ly`, `ms`, `sr`, `td`, `tm`), four sessions per
condition. One file per observer, condition and session:

* Experiment 1: `data/human/exp1/bumpy_<specularity>_<context>_session<1-4>_<observer>.mat`
* Experiment 2: `data/human/exp2/potato_<specularity>_<context>_<difmin|difmax>_session<1-4>_<observer>.mat`

with `<specularity>` = `matte` or `shiny`, `<context>` = `nocontext` or
`context` (without / with the surrounding context), and for Experiment 2
`difmin` = congruent and `difmax` = incongruent viewing angle. Each file holds
one struct `result`, one row per trial (144 trials in Experiment 1, 40 in
Experiment 2):

| Field | Size | Description |
| --- | --- | --- |
| `HueCombination` | N × 3 | Reflectance index of the target, of the distractor, and the environment (1 or 2) under which the target was shown. In Experiment 1 indices 1–8 are the hue directions 0°:45°:315° and 9 is the neutral reflectance. |
| `ansIndex` | N × 1 | Position of the target: 1 and 2 are the upper and lower object of the pair under environment 1, 3 and 4 those of the pair under environment 2 |
| `response` | N × 1 | The observer's choice, same coding as `ansIndex` |
| `correct` | N × 1 | 1 if `response` equals `ansIndex`, else 0 |
| `pattern` | N × 1 | Experiment 2 only: 1 if the target was the upper object of its pair, 2 if the lower |

### 5.2 Performance matrices (`data/scores/`)

The scored performance of every observer and every computational observer
model, as read by Figures 7, 8, 10 and 11. File names:

* Experiment 1: `data/scores/exp1/m_<specularity>_<context>_<who>_chromaticity.mat`
* Experiment 2: `data/scores/exp2/m_<specularity>_<context>_<who>_chromaticity_<min|max>.mat`
  (`min` = congruent, `max` = incongruent)

`<who>` is an observer code or a model name. Models are named
`<estimator>_tau<τ>_noise25`, where the estimator of the illuminant is one of

| Estimator | Statistic | Taken from |
| --- | --- | --- |
| `mean_history` | mean chromaticity | surround |
| `brightest_history` | chromaticity of the brightest pixels | surround |
| `wmean_history_w<1,3,5>` | luminance-weighted mean chromaticity, weight exponent 1, 3 or 5 | surround |
| `meanacrssobj_history`, `brightestacrssobj_history`, `wmeanacrssobj_history_w<1,3,5>` | the same three statistics | the objects themselves |
| `null` | no correction | – |
| `congruent100`, `congruent0` | Experiment 2 only: a fixed estimate taken from the congruent (`100`) or incongruent (`0`) surround and applied on every trial | surround |

`tau` is the time constant (in trials) over which the statistic is integrated
across preceding trials (`tau0` = current trial only, `tauinf` = all trials),
and `noise25` is the internal-noise level used in the paper. Each file holds
`OverallPercentageCorrect` and a struct `M`:

| Field | Size | Description |
| --- | --- | --- |
| `CorrectN`, `TrialN` | 9 × 9 × 4 | Correct and scored trials per target reflectance (row) × distractor reflectance (column) × session. A trial is scored only if the chosen object lay in the correct pair |
| `CorrectN_SessionSum`, `TrialN_SessionSum` | 9 × 9 | The same summed over sessions |
| `InCorrectN`, `InCorrectN_SessionSum` | 9 × 9 (× 4) | Trials in which the wrong pair was chosen |
| `PercentageCorrect` | 9 × 9 | `CorrectN_SessionSum ./ TrialN_SessionSum` |
| `PercentageInCorrect` | 9 × 9 | Proportion of wrong-pair trials |

### 5.3 Other inputs

| File | Used by | Content |
| --- | --- | --- |
| `data/environments_mb.mat` | Fig. 1 | `MB_En1` … `MB_En4`: 512 × 1024 × 3 MacLeod–Boynton images (L/(L+M), S/(L+M), luminance) of the four light probes |
| `data/blackbody_locus.mat` | Fig. 1 | `bbl`: MacLeod–Boynton chromaticities of blackbody radiators, 100 K to 10⁶ K |
| `data/allsurfaces.mat` | Fig. 2 | `ALLSURFACES`: 4,824 natural-object reflectance spectra, 400:10:700 nm |
| `data/thresholds_morimoto2018.mat` | Fig. 2 | `threshold`: discrimination thresholds of Morimoto et al. (2018), observer × specularity × environment × session × hue (3 × 2 × 2 × 5 × 8), in mixture-level units; the labels of each dimension are stored alongside |
| `data/procedure/*.mat` | Fig. 4 | Four renders (`MB` images) used to draw the trial procedure |
| `data/stimuli_exp2/*.mat` | Fig. 9 | Eight example renders (`MB` images) of Experiment 2 |
| `utils/lms_400to700.mat` | Fig. 2 | Cone fundamentals used by `spectrum_to_mb_rgb` |

## 6. Citation

If you use this code or data, please cite the paper (details will be added on
publication) and this repository.

## 7. License

Released under the [MIT License](LICENSE).
