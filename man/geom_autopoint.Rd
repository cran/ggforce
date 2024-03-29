% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/autopoint.R
\name{geom_autopoint}
\alias{geom_autopoint}
\title{A point geom specialised for scatterplot matrices}
\usage{
geom_autopoint(
  mapping = NULL,
  data = NULL,
  stat = "identity",
  position = "auto",
  ...,
  na.rm = FALSE,
  show.legend = NA,
  inherit.aes = TRUE
)
}
\arguments{
\item{mapping}{Set of aesthetic mappings created by \code{\link[ggplot2:aes]{aes()}}. If specified and
\code{inherit.aes = TRUE} (the default), it is combined with the default mapping
at the top level of the plot. You must supply \code{mapping} if there is no plot
mapping.}

\item{data}{The data to be displayed in this layer. There are three
options:

If \code{NULL}, the default, the data is inherited from the plot
data as specified in the call to \code{\link[ggplot2:ggplot]{ggplot()}}.

A \code{data.frame}, or other object, will override the plot
data. All objects will be fortified to produce a data frame. See
\code{\link[ggplot2:fortify]{fortify()}} for which variables will be created.

A \code{function} will be called with a single argument,
the plot data. The return value must be a \code{data.frame}, and
will be used as the layer data. A \code{function} can be created
from a \code{formula} (e.g. \code{~ head(.x, 10)}).}

\item{stat}{The statistical transformation to use on the data for this
layer, either as a \code{ggproto} \code{Geom} subclass or as a string naming the
stat stripped of the \code{stat_} prefix (e.g. \code{"count"} rather than
\code{"stat_count"})}

\item{position}{Position adjustment, either as a string naming the adjustment
(e.g. \code{"jitter"} to use \code{position_jitter}), or the result of a call to a
position adjustment function. Use the latter if you need to change the
settings of the adjustment.}

\item{...}{Other arguments passed on to \code{\link[ggplot2:layer]{layer()}}. These are
often aesthetics, used to set an aesthetic to a fixed value, like
\code{colour = "red"} or \code{size = 3}. They may also be parameters
to the paired geom/stat.}

\item{na.rm}{If \code{FALSE}, the default, missing values are removed with
a warning. If \code{TRUE}, missing values are silently removed.}

\item{show.legend}{logical. Should this layer be included in the legends?
\code{NA}, the default, includes if any aesthetics are mapped.
\code{FALSE} never includes, and \code{TRUE} always includes.
It can also be a named logical vector to finely select the aesthetics to
display.}

\item{inherit.aes}{If \code{FALSE}, overrides the default aesthetics,
rather than combining with them. This is most useful for helper functions
that define both data and aesthetics and shouldn't inherit behaviour from
the default plot specification, e.g. \code{\link[ggplot2:borders]{borders()}}.}
}
\description{
This geom is a specialisation of \code{\link[ggplot2:geom_point]{ggplot2::geom_point()}} with two changes. It
defaults to mapping \code{x} and \code{y} to \code{.panel_x} and \code{.panel_y} respectively,
and it defaults to using \code{\link[=position_auto]{position_auto()}} to jitter the points based on the
combination of position scale types.
}
\examples{
# Continuous vs continuous: No jitter
ggplot(mpg) + geom_autopoint(aes(cty, hwy))

# Continuous vs discrete: sina jitter
ggplot(mpg) + geom_autopoint(aes(cty, drv))

# Discrete vs discrete: disc-jitter
ggplot(mpg) + geom_autopoint(aes(fl, drv))

# Used with facet_matrix (x and y are automatically mapped)
ggplot(mpg) +
  geom_autopoint() +
  facet_matrix(vars(drv:fl))

}
\seealso{
\link{facet_matrix} for how to lay out scatterplot matrices and
\link{position_auto} for information about the position adjustments
}
