# multi-agyw

Code for the project *A multinomial spatio-temporal model for sexual risk behaviour*.
This repository is an [`orderly`](https://github.com/vimc/orderly) project, with directories: 

* `src`: containing all reports
* `archive`: containing versioned results of running your report
* `global`: containing global data
* `data`: copies of data used in the reports
* `tutorials`: miscellaneous code used to study models etc.

## How to run and commit reports

After installing [`orderly`](https://github.com/vimc/orderly) (from either CRAN or Github) a report, let's say called `example`, may be run by:

`orderly::orderly_run(name = "src/example")`

The results of this run will appear in the `draft/` folder.
To commit the draft (with associated `id`) to the `archive/` folder use:

`orderly::orderly_commit(id)`

Any outputs of this report will then be available to use as dependencies within other reports.

## To-do

Numbers, when present, indicate priority.

- [ ] Create individual data that links the `cluster_id` to area by modifying `mwi_data_survey_behav` (currently it's only the aggregate data that is output)
- Fit model to Malawi data from `mwi_data_survey_behav`
  - Aggregate format
    - [ ] Ignoring weights, BYM2 on space (which structure?), age, space category interaction (?), age category interaction (?)
    - [ ] Kish weights (following Jeff), BYM2 on space, age, space category interaction, age category interaction
      - `xPoisson` may be useful for this, see `INLA::inla.doc("xPoisson")`
  - Individual format
    - [ ] Ignoring weights, BYM2 on space (which structure?), age, space category interaction (?), age category interaction (?)
    - Individual weighted log-likelihood in `R-INLA` might not be possible, see Google group [discussion](https://groups.google.com/g/r-inla-discussion-group/c/Q-STkrFXR0g/m/6PWxRV4tBQ. Could try `TMB`
- [ ] Create simulated data in `sim_sexbehav` and try to recover truth with `fit_sim-multisexbehav-sae`
- [ ] Add other different types of simulated data e.g. spatial structure to `sim_sexbehav` and try to recover
- [ ] Decide structure for multinomial model (baseline category, nested, etc.)
  - How does this interplay with the Poisson trick?
- [ ] Generalise modifications of individual data higher in the analysis pipeline. May be quite hard to have a generalised task for `parameters: iso3` and have to be country by country
- [ ] More detailed comparison of differences in the outcomes using `sex12m` versus `eversex` to derive `nosex`
- [ ] Add age at first sex question to help deal with `NA` entries in `eversex`
- [ ] Possibility to include covariates
- Extend Malawi model by considering effect of survey years
  - [ ] DHS, requires adding time and temporal smoothing, could use survey specific intercepts
  - [ ] Adding PHIA and MICS
- Extend model to more countries
  - [ ] Fit a model for all DHS countries – separately (depend on previous steps)
  - [ ] Fit a model for all DHS countries – jointly
    - Biases and variation in methodology for key population data which vary by country. Survey estimates have more comparable methodology but depending on KP features (for example proportion in households included in survey sampling frame) may have varying bias. See working paper "Laga - Mapping the population size of female sex worker in countries across sub-Saharan Africa"
    - Survey question "did you have sex in exchange for money or goods" has been critisied 

## Resources

* [Which logit to use](https://stats.stackexchange.com/questions/307249/guidance-on-when-to-use-cumulative-vs-stopping-ratio-vs-continuation-ratio-vs) SE question
* [The Poisson transform for unnormalised statistical models](https://warwick.ac.uk/fac/sci/statistics/crism/workshops/estimatingconstants/chopin.pdf) slides by Chopin
* [Nested logit model](https://www.youtube.com/watch?v=5MuJ95nHISM) from EPFL MOOC
* [DHS Recode manual](https://dhsprogram.com/publications/publication-dhsg4-dhs-questionnaires-and-manuals.cfm)
* [Multinomial Response Models](https://data.princeton.edu/wws509/notes/c6.pdf) by Rodriguez
* [Ordinal Regression](https://betanalpha.github.io/assets/case_studies/ordinal_regression.html) case study by Betancourt
* [Poisson GLMs and the Multinomial model](http://www.statslab.cam.ac.uk/~qz280/teaching/modelling-2020/L14.pdf) lecture notes from Cambridge
* [Online lecture material](https://online.stat.psu.edu/stat504/lesson/8/8.4) from PennState
* [`orderly`](https://www.vaccineimpact.org/orderly/index.html) documentation
* [Example using survey weight in multinomial model](https://core.ac.uk/download/pdf/95690175.pdf), where they put the weights in the log-likelihood
