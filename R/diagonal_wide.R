#' Draw an area defined by an upper and lower diagonal
#'
#' The `geom_diagonal_wide()` function draws a *thick* diagonal, that is, a
#' polygon confined between a lower and upper [diagonal][geom_diagonal]. This
#' geom is bidirectional and the direction can be controlled with the
#' `orientation` argument.
#'
#' @section Aesthetics:
#' geom_diagonal_wide understand the following aesthetics
#' (required aesthetics are in bold):
#'
#' - **x**
#' - **y**
#' - **group**
#' - color
#' - linewidth
#' - linetype
#' - alpha
#' - lineend
#'
#' @inheritParams geom_shape
#' @inheritParams ggplot2::stat_identity
#' @inheritParams ggplot2::geom_line
#'
#' @param n The number of points to create for each of the bounding diagonals
#'
#' @param strength The proportion to move the control point along the x-axis
#' towards the other end of the bezier curve
#'
#' @inheritSection ggplot2::geom_line Orientation
#'
#' @name geom_diagonal_wide
#' @rdname geom_diagonal_wide
#'
#' @examples
#' data <- data.frame(
#'   x = c(1, 2, 2, 1, 2, 3, 3, 2),
#'   y = c(1, 2, 3, 2, 3, 1, 2, 5),
#'   group = c(1, 1, 1, 1, 2, 2, 2, 2)
#' )
#'
#' ggplot(data) +
#'   geom_diagonal_wide(aes(x, y, group = group))
#'
#' # The strength control the steepness
#' ggplot(data, aes(x, y, group = group)) +
#'   geom_diagonal_wide(strength = 0.75, alpha = 0.5, fill = 'red') +
#'   geom_diagonal_wide(strength = 0.25, alpha = 0.5, fill = 'blue')
#'
#' # The diagonal_wide geom uses geom_shape under the hood, so corner rounding
#' # etc are all there
#' ggplot(data) +
#'   geom_diagonal_wide(aes(x, y, group = group), radius = unit(5, 'mm'))
#'
NULL

#' @rdname ggforce-extensions
#' @format NULL
#' @usage NULL
#' @export
StatDiagonalWide <- ggproto('StatDiagonalWide', Stat,
  setup_params = function(data, params) {
    params$flipped_aes <- has_flipped_aes(data, params, ambiguous = TRUE)
    params
  },
  setup_data = function(data, params) {
    data$flipped_aes <- params$flipped_aes
    if (any(table(data$group) != 4)) {
      cli::cli_abort('Each group must consist of 4 points')
    }
    data
  },
  compute_panel = function(data, scales, strength = 0.5, n = 100, flipped_aes = FALSE) {
    data <- flip_data(data, flipped_aes)
    data <- data[order(data$group, data$x, data$y), ]
    lower <- data[rep_len(c(TRUE, FALSE, TRUE, FALSE), nrow(data)), ]
    upper <- data[rep_len(c(FALSE, TRUE, FALSE, TRUE), nrow(data)), ]
    lower <- add_controls(lower, strength)
    upper <- add_controls(upper[rev(seq_len(nrow(upper))), ], strength)
    lower <- StatBezier$compute_panel(lower, scales, n)
    upper <- StatBezier$compute_panel(upper, scales, n)
    diagonals <- vec_rbind(lower, upper)
    diagonals$index <- NULL
    diagonals <- diagonals[order(diagonals$group), ]
    flip_data(diagonals, flipped_aes)
  },
  required_aes = c('x', 'y', 'group'),
  extra_params = c('na.rm', 'n', 'strength', 'orientation')
)
#' @rdname geom_diagonal_wide
#' @export
stat_diagonal_wide <- function(mapping = NULL, data = NULL, geom = 'shape',
                               position = 'identity', n = 100, strength = 0.5,
                               na.rm = FALSE, orientation = NA, show.legend = NA,
                               inherit.aes = TRUE, ...) {
  layer(
    stat = StatDiagonalWide, data = data, mapping = mapping, geom = geom,
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(na.rm = na.rm, orientation = orientation, n = n,
                  strength = strength, ...)
  )
}
#' @rdname geom_diagonal_wide
#' @export
geom_diagonal_wide <- function(mapping = NULL, data = NULL, stat = 'diagonal_wide',
                               position = 'identity', n = 100, na.rm = FALSE,
                               orientation = NA, strength = 0.5,
                               show.legend = NA, inherit.aes = TRUE, ...) {
  layer(
    data = data, mapping = mapping, stat = stat, geom = GeomShape,
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(na.rm = na.rm, orientation = orientation, n = n,
                  strength = strength, ...)
  )
}
