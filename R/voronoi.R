#' @include shape.R
NULL

#' Voronoi tesselation and delaunay triangulation
#'
#' This set of geoms and stats allows you to display voronoi tesselation and
#' delaunay triangulation, both as polygons and as line segments. Furthermore
#' it lets you augment your point data with related summary statistics. The
#' computations are based on the [deldir::deldir()] package.
#'
#' @section Aesthetics:
#' geom_voronoi_tile and geom_delaunay_tile understand the following aesthetics
#' (required aesthetics are in bold):
#'
#' - **x**
#' - **y**
#' - alpha
#' - color
#' - fill
#' - linetype
#' - size
#'
#' geom_voronoi_segment, geom_delaunay_segment, and geom_delaunay_segment2
#' understand the following aesthetics (required aesthetics are in bold):
#'
#' - **x**
#' - **y**
#' - alpha
#' - color
#' - linetype
#' - size
#'
#' @section Computed variables:
#' stat_delvor_summary computes the following variables:
#' \describe{
#'  \item{x, y}{If `switch.centroid = TRUE` this will be the coordinates for
#'  the voronoi tile centroid, otherwise it is the original point}
#'  \item{xcent, ycent}{If `switch.centroid = FALSE` this will be the
#'  coordinates for the voronoi tile centroid, otherwise it will be `NULL`}
#'  \item{xorig, yorig}{If `switch.centroid = TRUE` this will be the
#'  coordinates for the original point, otherwise it will be `NULL`}
#'  \item{ntri}{Number of triangles emanating from the point}
#'  \item{triarea}{The total area of triangles emanating from the point divided
#'  by 3}
#'  \item{triprop}{`triarea` divided by the sum of the area of all
#'  triangles}
#'  \item{nsides}{Number of sides on the voronoi tile associated with the point}
#'  \item{nedges}{Number of sides of the associated voronoi tile that is part of
#'  the bounding box}
#'  \item{vorarea}{The area of the voronoi tile associated with the point}
#'  \item{vorprop}{`vorarea` divided by the sum of all voronoi tiles}
#' }
#'
#' @inheritParams ggplot2::geom_polygon
#' @inheritParams ggplot2::geom_segment
#' @inheritParams ggplot2::stat_identity
#' @inheritParams geom_link
#'
#' @param bound The bounding rectangle for the tesselation or a custom polygon
#' to clip the tesselation to. Defaults to `NULL` which creates a rectangle
#' expanded 10\% in all directions. If supplied as a bounding box it should be a
#' vector giving the bounds in the following order: xmin, xmax, ymin, ymax. If
#' supplied as a polygon it should either be a 2-column matrix or a data.frame
#' containing an `x` and `y` column.
#'
#' @param eps A value of epsilon used in testing whether a quantity is zero,
#' mainly in the context of whether points are collinear. If anomalous errors
#' arise, it is possible that these may averted by adjusting the value of eps
#' upward or downward.
#'
#' @param max.radius The maximum distance a tile can extend from the point of
#' origin. Will in effect clip each tile to a circle centered at the point with
#' the given radius. If `normalize = TRUE` the radius will be given relative to
#' the normalized values
#'
#' @param normalize Should coordinates be normalized prior to calculations. If
#' `x` and `y` are in wildly different ranges it can lead to
#' tesselation and triangulation that seems off when plotted without
#' [ggplot2::coord_fixed()]. Normalization of coordinates solves this.
#' The coordinates are transformed back after calculations.
#'
#' @param asp.ratio If `normalize = TRUE` the x values will be multiplied by this
#' amount after normalization.
#'
#' @name geom_voronoi
#' @aliases geom_delaunay
#' @rdname geom_delvor
#'
#' @examples
#' # Voronoi
#' # You usually wants all points to take part in the same tesselation so set
#' # the group aesthetic to a constant (-1L is just a convention)
#' ggplot(iris, aes(Sepal.Length, Sepal.Width, group = -1L)) +
#'   geom_voronoi_tile(aes(fill = Species)) +
#'   geom_voronoi_segment() +
#'   geom_text(aes(label = after_stat(nsides), size = after_stat(vorarea)),
#'     stat = 'delvor_summary', switch.centroid = TRUE
#'   )
#'
#' # Difference of normalize = TRUE (segment layer is calculated without
#' # normalisation)
#' ggplot(iris, aes(Sepal.Length, Sepal.Width, group = -1L)) +
#'   geom_voronoi_tile(aes(fill = Species), normalize = TRUE) +
#'   geom_voronoi_segment()
#'
#' # Set a max radius
#' ggplot(iris, aes(Sepal.Length, Sepal.Width, group = -1L)) +
#'   geom_voronoi_tile(aes(fill = Species), colour = 'black', max.radius = 0.25)
#'
#' # Set custom bounding polygon
#' triangle <- cbind(c(3, 9, 6), c(1, 1, 6))
#' ggplot(iris, aes(Sepal.Length, Sepal.Width, group = -1L)) +
#'   geom_voronoi_tile(aes(fill = Species), colour = 'black', bound = triangle)
#'
#' # Use geom_shape functionality to round corners etc
#' ggplot(iris, aes(Sepal.Length, Sepal.Width, group = -1L)) +
#'   geom_voronoi_tile(aes(fill = Species), colour = 'black',
#'                     expand = unit(-.5, 'mm'), radius = unit(2, 'mm'))
#'
#' # Delaunay triangles
#' ggplot(iris, aes(Sepal.Length, Sepal.Width)) +
#'   geom_delaunay_tile(alpha = 0.3, colour = 'black')
#'
#' # Use geom_delauney_segment2 to interpolate aestetics between end points
#' ggplot(iris, aes(Sepal.Length, Sepal.Width)) +
#'   geom_delaunay_segment2(aes(colour = Species, group = -1), size = 2,
#'                          lineend = 'round')
NULL

#' @rdname ggforce-extensions
#' @format NULL
#' @usage NULL
#' @importFrom scales rescale
#' @export
StatVoronoiTile <- ggproto('StatVoronoiTile', Stat,
  setup_params = function(self, data, params) {
    check_installed('deldir', 'to calculate voronoi tesselation')
    params
  },
  compute_group = function(self, data, scales, bound = NULL, eps = 1e-9,
                           max.radius = NULL, normalize = FALSE, asp.ratio = 1) {
    data$group <- paste0(seq_len(nrow(data)), ':', data$group)
    if (any(duplicated(data[, c('x', 'y')]))) {
      cli::cli_warn('{.fn {snake_class(self)}} is dropping duplicated points')
    }
    polybound <- NULL
    if (is.null(bound)) {
      if (!is.null(max.radius)) {
        bound <- c(range(data$x), range(data$y))
        bound[c(1, 3)] <- bound[c(1, 3)] - max.radius * 1.5
        bound[c(2, 4)] <- bound[c(2, 4)] + max.radius * 1.5
      }
    } else if (is.matrix(bound) || is.data.frame(bound)) {
      if (is.matrix(bound) && is.null(colnames(bound))) {
        colnames(bound) <- c('x', 'y')
      }
      polybound <- as.data.frame(bound)
      bound <- c(range(polybound$x), range(polybound$y))
    }
    if (normalize) {
      x_range <- range(data$x, na.rm = TRUE, finite = TRUE)
      y_range <- range(data$y, na.rm = TRUE, finite = TRUE)
      data$x <- rescale(data$x, from = x_range) * asp.ratio
      data$y <- rescale(data$y, from = y_range)
      if (!is.null(bound)) {
        bound[1:2] <- rescale(bound[1:2], from = x_range) * asp.ratio
        bound[3:4] <- rescale(bound[3:4], from = y_range)
      }
      if (!is.null(polybound)) {
        polybound$x <- rescale(polybound$x, from = x_range) * asp.ratio
        polybound$y <- rescale(polybound$y, from = y_range)
      }
    }
    vor <- deldir::deldir(data$x, data$y, rw = bound, eps = eps,
                          suppressMsge = TRUE)
    tiles <- to_tile(vor)
    tiles$orig_x <- data$x[vor$ind.orig[tiles$group]]
    tiles$orig_y <- data$y[vor$ind.orig[tiles$group]]
    tiles$group <- data$group[vor$ind.orig[tiles$group]]
    tiles <- clip_tiles(tiles, max.radius, polybound)
    data$x <- NULL
    data$y <- NULL
    data <- merge(tiles, data, sort = FALSE, all.x = TRUE)
    if (normalize) {
      data$x <- rescale(data$x / asp.ratio, to = x_range, from = c(0, 1))
      data$y <- rescale(data$y, to = y_range, from = c(0, 1))
    }
    data
  },
  required_aes = c('x', 'y')
)

#' @rdname geom_delvor
#' @inheritParams geom_shape
#' @export
geom_voronoi_tile <- function(mapping = NULL, data = NULL, stat = 'voronoi_tile',
                              position = 'identity', na.rm = FALSE, bound = NULL,
                              eps = 1e-9, max.radius = NULL, normalize = FALSE,
                              asp.ratio = 1, expand = 0, radius = 0,
                              show.legend = NA, inherit.aes = TRUE, ...) {
  layer(
    data = data, mapping = mapping, stat = stat, geom = GeomShape,
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(bound = bound, eps = eps, max.radius = max.radius,
                  normalize = normalize, asp.ratio = asp.ratio, na.rm = na.rm,
                  expand = expand, radius = radius, ...)
  )
}

#' @rdname ggforce-extensions
#' @format NULL
#' @usage NULL
#' @importFrom scales rescale
#' @export
StatVoronoiSegment <- ggproto('StatVoronoiSegment', Stat,
  setup_params = function(self, data, params) {
    check_installed('deldir', 'to calculate voronoi tesselation')
    params
  },
  compute_group = function(self, data, scales, bound = NULL, eps = 1e-9,
                           normalize = FALSE, asp.ratio = 1) {
    if (any(duplicated(data[, c('x', 'y')]))) {
      cli::cli_warn('{.fn {snake_class(self)}} is dropping duplicated points')
    }
    if (normalize) {
      x_range <- range(data$x, na.rm = TRUE, finite = TRUE)
      y_range <- range(data$y, na.rm = TRUE, finite = TRUE)
      data$x <- rescale(data$x, from = x_range) * asp.ratio
      data$y <- rescale(data$y, from = y_range)
      if (!is.null(bound)) {
        bound[1:2] <- rescale(bound[1:2], from = x_range) * asp.ratio
        bound[3:4] <- rescale(bound[3:4], from = x_range)
      }
    }
    vor <- deldir::deldir(data$x, data$y, rw = bound, eps = eps,
                          suppressMsge = TRUE)
    segments <- vor$dirsgs[, 1:5]
    names(segments) <- c('x', 'y', 'xend', 'yend', 'group')
    segments$group <- vor$ind.orig[segments$group]
    data <- cbind(
      segments[, 1:4],
      data[segments$group, !names(data) %in% c('x', 'y'), drop = FALSE]
    )
    if (normalize) {
      data$x <- rescale(data$x / asp.ratio, to = x_range, from = c(0, 1))
      data$xend <- rescale(data$xend / asp.ratio, to = x_range, from = c(0, 1))
      data$y <- rescale(data$y, to = y_range, from = c(0, 1))
      data$yend <- rescale(data$yend, to = y_range, from = c(0, 1))
    }
    data
  },
  required_aes = c('x', 'y')
)

#' @rdname geom_delvor
#' @export
geom_voronoi_segment <- function(mapping = NULL, data = NULL,
                                 stat = 'voronoi_segment', position = 'identity',
                                 na.rm = FALSE, bound = NULL, eps = 1e-9,
                                 normalize = FALSE, asp.ratio = 1,
                                 show.legend = NA, inherit.aes = TRUE, ...) {
  layer(
    data = data, mapping = mapping, stat = stat, geom = GeomSegment,
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(bound = bound, eps = eps, normalize = normalize,
                  asp.ratio = asp.ratio, na.rm = na.rm, ...)
  )
}

#' @rdname ggforce-extensions
#' @format NULL
#' @usage NULL
#' @importFrom scales rescale
#' @export
StatDelaunayTile <- ggproto('StatDelaunayTile', Stat,
  setup_params = function(self, data, params) {
    check_installed('deldir', 'to calculate delaunay triangulation')
    params
  },
  compute_group = function(self, data, scales, bound = NULL, eps = 1e-9,
                           normalize = FALSE, asp.ratio = 1) {
    if (normalize) {
      x_range <- range(data$x, na.rm = TRUE, finite = TRUE)
      y_range <- range(data$y, na.rm = TRUE, finite = TRUE)
      data$x <- rescale(data$x, from = x_range) * asp.ratio
      data$y <- rescale(data$y, from = y_range)
      if (!is.null(bound)) {
        bound[1:2] <- rescale(bound[1:2], from = x_range) * asp.ratio
        bound[3:4] <- rescale(bound[3:4], from = x_range)
      }
    }
    data <- lapply(split(data, data$group), function(d) {
      if (any(duplicated(d[, c('x', 'y')]))) {
        cli::cli_warn('{.fn {snake_class(self)}} is dropping duplicated points')
      }
      vor <- deldir::deldir(d$x, d$y, rw = bound, eps = eps,
                            suppressMsge = TRUE)
      d <- to_triangle(vor)
      d$group <- paste(data$group[1], '_', match(d$group, unique0(d$group)))
      d
    })
    for (i in seq_len(length(data) - 1) + 1) {
      max_group <- max(data[[i - 1]]$group)
      data[[i]]$group <- data[[i]]$group + max_group
    }
    data <- vec_rbind(!!!data)
    if (normalize) {
      data$x <- rescale(data$x / asp.ratio, to = x_range, from = c(0, 1))
      data$y <- rescale(data$y, to = y_range, from = c(0, 1))
    }
    data
  },
  required_aes = c('x', 'y')
)

#' @rdname geom_delvor
#' @inheritParams geom_shape
#' @export
geom_delaunay_tile <- function(mapping = NULL, data = NULL,
                               stat = 'delaunay_tile', position = 'identity',
                               na.rm = FALSE, bound = NULL, eps = 1e-9,
                               normalize = FALSE, asp.ratio = 1, expand = 0,
                               radius = 0, show.legend = NA, inherit.aes = TRUE,
                               ...) {
  layer(
    data = data, mapping = mapping, stat = stat, geom = GeomShape,
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(bound = bound, eps = eps, normalize = normalize,
                  asp.ratio = asp.ratio, expand = expand, radius = radius,
                  na.rm = na.rm, ...)
  )
}

#' @rdname ggforce-extensions
#' @format NULL
#' @usage NULL
#' @importFrom scales rescale
#' @export
StatDelaunaySegment <- ggproto('StatDelaunaySegment', Stat,
  setup_params = function(self, data, params) {
    check_installed('deldir', 'to calculate delaunay triangulation')
    params
  },
  compute_group = function(self, data, scales, bound = NULL, eps = 1e-9,
                           normalize = FALSE, asp.ratio = 1) {
    if (any(duplicated(data[, c('x', 'y')]))) {
      cli::cli_warn('{.fn {snake_class(self)}} is dropping duplicated points')
    }
    if (normalize) {
      x_range <- range(data$x, na.rm = TRUE, finite = TRUE)
      y_range <- range(data$y, na.rm = TRUE, finite = TRUE)
      data$x <- rescale(data$x, from = x_range) * asp.ratio
      data$y <- rescale(data$y, from = y_range)
      if (!is.null(bound)) {
        bound[1:2] <- rescale(bound[1:2], from = x_range) * asp.ratio
        bound[3:4] <- rescale(bound[3:4], from = x_range)
      }
    }
    vor <- deldir::deldir(data$x, data$y, rw = bound, eps = eps,
                          suppressMsge = TRUE)
    segments <- vor$delsgs[, 1:5]
    names(segments) <- c('x', 'y', 'xend', 'yend', 'group')
    segments$group <- vor$ind.orig[segments$group]
    data <- cbind(
      segments[, 1:4],
      data[segments$group, !names(data) %in% c('x', 'y'), drop = FALSE]
    )
    if (normalize) {
      data$x <- rescale(data$x / asp.ratio, to = x_range, from = c(0, 1))
      data$xend <- rescale(data$xend / asp.ratio, to = x_range, from = c(0, 1))
      data$y <- rescale(data$y, to = y_range, from = c(0, 1))
      data$yend <- rescale(data$yend, to = y_range, from = c(0, 1))
    }
    data
  },
  required_aes = c('x', 'y')
)

#' @rdname geom_delvor
#' @export
geom_delaunay_segment <- function(mapping = NULL, data = NULL,
                                  stat = 'delaunay_segment',
                                  position = 'identity', na.rm = FALSE,
                                  bound = NULL, eps = 1e-9, normalize = FALSE,
                                  asp.ratio = 1, show.legend = NA,
                                  inherit.aes = TRUE, ...) {
  layer(
    data = data, mapping = mapping, stat = stat, geom = GeomSegment,
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(bound = bound, eps = eps, normalize = normalize, na.rm = na.rm,
                  asp.ratio = asp.ratio, ...)
  )
}

#' @rdname ggforce-extensions
#' @format NULL
#' @usage NULL
#' @importFrom scales rescale
#' @export
StatDelaunaySegment2 <- ggproto('StatDelaunaySegment2', Stat,
  setup_params = function(self, data, params) {
    check_installed('deldir', 'to calculate delaunay triangulation')
    params
  },
  compute_group = function(self, data, scales, bound = NULL, eps = 1e-9, n = 100,
                           normalize = FALSE, asp.ratio = 1) {
    if (any(duplicated(data[, c('x', 'y')]))) {
      cli::cli_warn('{.fn {snake_class(self)}} is dropping duplicated points')
    }
    if (normalize) {
      x_range <- range(data$x, na.rm = TRUE, finite = TRUE)
      y_range <- range(data$y, na.rm = TRUE, finite = TRUE)
      data$x <- rescale(data$x, from = x_range) * asp.ratio
      data$y <- rescale(data$y, from = y_range)
      if (!is.null(bound)) {
        bound[1:2] <- rescale(bound[1:2], from = x_range) * asp.ratio
        bound[3:4] <- rescale(bound[3:4], from = x_range)
      }
    }
    vor <- deldir::deldir(data$x, data$y, rw = bound, eps = eps,
                          suppressMsge = TRUE)
    segments <- vec_rbind(
      structure(vor$delsgs[, c(1:2, 5)], names = c('x', 'y', 'group')),
      structure(vor$delsgs[, c(3:4, 6)], names = c('x', 'y', 'group'))
    )
    segments$group <- vor$ind.orig[segments$group]
    segments <- cbind(
      segments[, 1:2],
      data[segments$group, !names(data) %in% c('x', 'y'), drop = FALSE]
    )
    segments$group <- rep(seq_len(nrow(vor$delsgs)), 2)
    segments <- segments[order(segments$group), ]
    if (normalize) {
      segments$x <- rescale(segments$x / asp.ratio, to = x_range, from = c(0, 1))
      segments$y <- rescale(segments$y, to = y_range, from = c(0, 1))
    }
    StatLink2$compute_panel(segments, scales, n)
  },
  required_aes = c('x', 'y')
)

#' @rdname geom_delvor
#' @export
geom_delaunay_segment2 <- function(mapping = NULL, data = NULL,
                                   stat = 'delaunay_segment2',
                                   position = 'identity', na.rm = FALSE,
                                   bound = NULL, eps = 1e-9, normalize = FALSE,
                                   asp.ratio = 1, n = 100, show.legend = NA,
                                   inherit.aes = TRUE, ...) {
  layer(
    data = data, mapping = mapping, stat = stat, geom = GeomPathInterpolate,
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(bound = bound, eps = eps, normalize = normalize,
                  asp.ratio = asp.ratio, n = n, na.rm = na.rm, ...)
  )
}

#' @rdname ggforce-extensions
#' @format NULL
#' @usage NULL
#' @importFrom scales rescale
#' @export
StatDelvorSummary <- ggproto('StatDelvorSummary', Stat,
  setup_params = function(self, data, params) {
    check_installed('deldir', 'to calculate delaunay triangulation')
    params
  },
  compute_group = function(self, data, scales, bound = NULL, eps = 1e-9,
                           switch.centroid = FALSE, normalize = FALSE,
                           asp.ratio = 1) {
    if (any(duplicated(data[, c('x', 'y')]))) {
      cli::cli_warn('{.fn {snake_class(self)}} is dropping duplicated points')
    }
    if (normalize) {
      x_range <- range(data$x, na.rm = TRUE, finite = TRUE)
      y_range <- range(data$y, na.rm = TRUE, finite = TRUE)
      data$x <- rescale(data$x, from = x_range) * asp.ratio
      data$y <- rescale(data$y, from = y_range)
      if (!is.null(bound)) {
        bound[1:2] <- rescale(bound[1:2], from = x_range) * asp.ratio
        bound[3:4] <- rescale(bound[3:4], from = x_range)
      }
    }
    vor <- deldir::deldir(data$x, data$y, rw = bound, eps = eps,
                          suppressMsge = TRUE)
    names(vor$summary) <- c('x', 'y', 'ntri', 'triarea', 'triprop', 'nsides',
                            'nedges', 'vorarea', 'vorprop')
    tiles <- to_tile(vor)
    vor$summary$xcent <- sapply(split(tiles$x, tiles$group), mean)
    vor$summary$ycent <- sapply(split(tiles$y, tiles$group), mean)
    data <- cbind(
      data[vor$ind.orig, , drop = FALSE],
      vor$summary[, !names(vor$summary) %in% c('x', 'y'), drop = FALSE]
    )
    if (normalize) {
      data$x <- rescale(data$x / asp.ratio, to = x_range, from = c(0, 1))
      data$xcent <- rescale(data$xcent / asp.ratio, to = x_range, from = c(0, 1))
      data$y <- rescale(data$y, to = y_range, from = c(0, 1))
      data$ycent <- rescale(data$ycent, to = y_range, from = c(0, 1))
    }
    if (switch.centroid) {
      name_ind <- match(c('xcent', 'ycent', 'x', 'y'), names(data))
      names(data)[name_ind] <- c('x', 'y', 'xorig', 'yorig')
    }
    data
  },
  required_aes = c('x', 'y')
)

#' @rdname geom_delvor
#' @export
stat_delvor_summary <- function(mapping = NULL, data = NULL, geom = 'point',
                                position = 'identity', na.rm = FALSE,
                                bound = NULL, eps = 1e-9, normalize = FALSE,
                                asp.ratio = 1, show.legend = NA,
                                inherit.aes = TRUE, ...) {
  layer(
    data = data, mapping = mapping, stat = StatDelvorSummary, geom = geom,
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(bound = bound, eps = eps, normalize = normalize, na.rm = na.rm,
                  asp.ratio = asp.ratio, ...)
  )
}


# HELPERS -----------------------------------------------------------------
to_tile <- function(object) {
  check_installed('deldir', 'to calculate voronoi tesselation')
  tiles <- vec_rbind(
    structure(object$dirsgs[, c(1:2, 5)], names = c('x', 'y', 'group')),
    structure(object$dirsgs[, c(1:2, 6)], names = c('x', 'y', 'group')),
    structure(object$dirsgs[, c(3:5)], names = c('x', 'y', 'group')),
    structure(object$dirsgs[, c(3:4, 6)], names = c('x', 'y', 'group'))
  )
  tiles <- unique0(tiles)
  tiles <- vec_rbind(
    tiles,
    data_frame0(
      x = object$rw[c(1, 2, 2, 1)],
      y = object$rw[c(3, 3, 4, 4)],
      group = deldir::get.cnrind(
        object$summary$x,
        object$summary$y,
        object$rw
      )
    )
  )
  tiles$theta <- atan2(
    tiles$y - object$summary$y[tiles$group],
    tiles$x - object$summary$x[tiles$group]
  )
  tiles$theta <- ifelse(tiles$theta > 0, tiles$theta, tiles$theta + 2 * pi)
  tiles[order(tiles$group, tiles$theta), ]
}
to_triangle <- function(object) {
  tiles <- vec_rbind(
    structure(object$dirsgs[, c(1:2, 5)], names = c('x', 'y', 'point')),
    structure(object$dirsgs[, c(3:4, 6)], names = c('x', 'y', 'point'))
  )
  tiles$group <- as.integer(
    factor(paste0(signif(tiles$x, 5), '_', signif(tiles$y, 5)))
  )
  # tiles <- tiles[tiles$tri %in% unique(tiles$tri[duplicated(tiles$tri)]),]
  unconform <- table(tiles$group)
  unconform <- as.integer(names(unconform[unconform != 3]))
  unconform_point <- tiles$point[tiles$group %in% unconform]
  tiles <- tiles[!tiles$group %in% unconform, , drop = FALSE]
  unconform_seg <- object$delsgs$ind1 %in% unconform_point &
    object$delsgs$ind2 %in% unconform_point
  object$delsgs <- object$delsgs[unconform_seg, , drop = FALSE]
  last_points <- tri_mat(object)
  last_points <- data_frame0(
    point = as.vector(last_points),
    group = rep(seq(max(tiles$group) + 1, length.out = ncol(last_points)),
                each = 3)
  )
  triangles <- vec_rbind(tiles[, c('point', 'group'), drop = FALSE], last_points)
  triangles$x <- object$summary$x[triangles$point]
  triangles$y <- object$summary$y[triangles$point]
  triangles <- triangles[order(triangles$group, triangles$point), ]
  triangles$group <- match(triangles$group, unique0(triangles$group))
  dup_tri <- which(duplicated(matrix(triangles$point, ncol = 3, byrow = TRUE)))
  triangles <- triangles[!triangles$group %in% dup_tri, , drop = FALSE]
  triangles
}
tri_mat <- function(object) {
  a <- object$delsgs[, 5]
  b <- object$delsgs[, 6]
  tlist <- matrix(integer(0), 3, 0)
  for (i in union(a, b)) {
    jj <- c(b[a == i], a[b == i])
    jj <- sort(unique0(jj))
    jj <- jj[jj > i]
    if (length(jj) > 0) {
      for (j in jj) {
        kk <- c(b[a == j], a[b == j])
        kk <- kk[(kk %in% jj) & (kk > j)]
        if (length(kk) > 0) {
          for (k in kk) tlist <- cbind(tlist, c(
              i, j,
              k
            ))
        }
      }
    }
  }
  tlist
}
#' @importFrom polyclip polyclip
clip_tiles <- function(tiles, radius, bound) {
  if (is.null(radius) && is.null(bound)) return(tiles)
  p <- seq(0, 2 * pi, length.out = 361)[-361]
  circ <- list(
    x = cos(p) * radius,
    y = sin(p) * radius
  )
  dapply(tiles, 'group', function(tile) {
    final_tile <- list(x = tile$x, y = tile$y)
    if (!is.null(radius)) {
      circ_temp <- list(x = circ$x + tile$orig_x[1],
                        y = circ$y + tile$orig_y[1])
      final_tile <- polyclip(final_tile, circ_temp, 'intersection')
    }
    if (!is.null(bound)) {
      final_tile <- polyclip(final_tile, bound, 'intersection')
    }
    if (length(final_tile) == 0) return(NULL)
    data_frame0(
      x = final_tile[[1]]$x,
      y = final_tile[[1]]$y,
      group = tile$group[1]
    )
  })
}
