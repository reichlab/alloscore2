# alloscore2: Allocation Scoring Rules for Hubverse Model Output

Implements allocation scoring rules for evaluating probabilistic
forecasts. Given forecasts for several targets and a shared resource
budget, an allocation is computed by minimizing expected generalized
piecewise linear loss subject to the budget constraint, and forecasts
are scored by the realized loss of that allocation relative to the loss
of an allocation made by an oracle that knew the observed outcomes.
Model output and observed data are read in the formats used by the
hubverse.

## See also

Useful links:

- <https://reichlab.github.io/alloscore2/>

- <https://github.com/reichlab/alloscore2>

- Report bugs at <https://github.com/reichlab/alloscore2/issues>

## Author

**Maintainer**: Nicholas Reich <nick@umass.edu>
([ORCID](https://orcid.org/0000-0003-3503-9899))

Authors:

- Nicholas Reich <nick@umass.edu>
  ([ORCID](https://orcid.org/0000-0003-3503-9899))

- Aaron Gerding <agerding@umass.edu> (Author of the original alloscore
  package) \[copyright holder\]
