
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ggforce

[![Travis-CI Build
Status](https://travis-ci.org/thomasp85/ggforce.svg?branch=master)](https://travis-ci.org/thomasp85/ggforce)
[![AppVeyor Build
Status](https://ci.appveyor.com/api/projects/status/github/thomasp85/ggforce?branch=master&svg=true)](https://ci.appveyor.com/project/thomasp85/ggforce)
[![CRAN\_Release\_Badge](http://www.r-pkg.org/badges/version-ago/ggforce)](https://CRAN.R-project.org/package=ggforce)
[![CRAN\_Download\_Badge](http://cranlogs.r-pkg.org/badges/ggforce)](https://CRAN.R-project.org/package=ggforce)

*Accelerating ggplot2*

`ggforce` is a package aimed at providing missing functionality to
`ggplot2` through the extension system introduced with `ggplot2` v2.0.0.
Broadly speaking `ggplot2` has been aimed primarily at explorative data
visualization in order to investigate the data at hand, and less at
providing utilities for composing custom plots a la
[D3.js](https://d3js.org). `ggforce` is mainly an attempt to address
these “shortcoming” (design choices might be a better description). The
goal is to provide a repository of geoms, stats, etc. that are as well
documented and implemented as the official ones found in `ggplot2`.

## Installation

You can install the released version of ggforce from
[CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("ggforce")
```

And the development version from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("thomasp85/ggforce")
```

## Features

`ggforce` is by design a collection of features with the only
commonality being their tie to the `ggplot2` API. Because of this an
overview of all features would get too long for a README. The package
does contain a
[vignette](https://CRAN.R-project.org/package=ggforce/vignettes/Visual_Guide.html)
where every feature is described and justified with examples and plots.
There should be a plot in the README of a visualization package though,
so without further ado:

``` r
library(ggforce)
#> Loading required package: ggplot2
ggplot(iris, aes(Petal.Length, Petal.Width, colour = Species)) +
  geom_point() +
  facet_zoom(x = Species == "versicolor")
```

<img src="man/figures/README-example-1.png" width="100%" />
