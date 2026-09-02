#' Allocate a budget to minimize expected gpl loss
#'
#' Solves
#' \deqn{\min_x \sum_i E_{Y_i \sim F_i} L_i(x_i, Y_i)
#'       \quad\text{subject to}\quad \sum_i w_i x_i \le K,\ x_i \ge 0,}
#' where each \eqn{L_i} is a generalized piecewise linear loss (see
#' [gpl_loss_fun()]). The problem is separable and convex, so at the optimum the
#' marginal expected benefit \eqn{\Lambda_i} (see [meb_gpl_df()]) is equal
#' across all targets receiving a positive allocation. `allocate()` bisects on
#' that common value \eqn{\lambda}, inverting \eqn{\Lambda_i} for each target at
#' each step. All values of `K` are solved simultaneously, sharing root-finding
#' work wherever they currently agree on \eqn{\lambda}.
#'
#' @param df data frame with one row per target. Columns of `df` supply the
#'   other arguments: an argument left empty is filled from a like-named column,
#'   and an argument whose value is a length-1 string naming a column of `df` is
#'   replaced by that column, so `w = "c"` uses the `c` column as weights.
#' @param K vector of budgets. Cannot be supplied via `df`.
#' @param target_names names for the allocation targets, or the name of a column
#'   of `df` holding them. Defaults to the row indices.
#' @param F list of predictive cdfs, one per target.
#' @param Q list of predictive quantile functions, one per target.
#' @param w numeric vector of costs per unit of resource allocated to each
#'   target.
#' @inheritParams gpl_loss_fun
#' @param dg derivative of the increment function `g`. If `NA`, `g` is
#'   differentiated symbolically with [stats::D()].
#' @param eps_lam relative tolerance for terminating the bisection on lambda.
#' @param eps_K relative tolerance on the budget, below which no post-processing
#'   is attempted.
#' @param point_mass_window distance by which search intervals are widened in
#'   order to catch point masses in the `F`s, intended or otherwise.
#'
#' @return A tibble of class `allocated`, with one row per value of `K` and
#'   columns
#'   \describe{
#'     \item{K}{the budget.}
#'     \item{x}{list of named allocation vectors.}
#'     \item{xs}{list of data frames holding the allocation at each iteration.}
#'     \item{qs_OK}{whether the unconstrained (quantile) solution already
#'       satisfied the budget.}
#'     \item{lam, lamL, lamU}{final Lagrange multiplier and its bracketing
#'       interval, with `*_seq` columns holding the full iteration history.}
#'     \item{post_processed}{whether plateau post-processing was applied.}
#'     \item{xdf}{list of per-target tibbles holding the allocation and a
#'       scoring function.}
#'   }
#'   The `gpl_df`, `w` and `target_col_name` attributes carry the loss
#'   functions, weights and target column name.
#'
#' @examples
#' fc <- add_pdqr_funs(
#'   tibble::tibble(
#'     target_names = c("a", "b", "c"),
#'     dist = "norm",
#'     mean = c(5, 8, 12),
#'     sd = c(1, 2, 3)
#'   ),
#'   types = c("p", "q")
#' )
#' a <- allocate(fc, K = c(10, 20), alpha = 0.9)
#' a$xdf[[1]]
#'
#' @export
allocate <- function(
  df = NULL,
  K,
  target_names = NA,
  F = NULL,
  Q = NULL,
  w = 1,
  kappa = 1,
  alpha = 1,
  g = "x",
  dg = NA,
  eps_lam = 1e-4,
  eps_K = .01,
  point_mass_window = .001
) {
  # a length-1 string target_names identifies a column of df to name targets by
  target_col_name <- if (
    is.character(target_names) && length(target_names) == 1L
  ) {
    target_names
  } else {
    NULL
  }

  if (!is.null(df)) {
    resolved <- resolve_df_args(
      df,
      vals = list(
        target_names = target_names,
        F = F,
        Q = Q,
        w = w,
        kappa = kappa,
        alpha = alpha,
        g = g,
        dg = dg
      ),
      has_default = c("target_names", "w", "kappa", "alpha", "g", "dg")
    )
    target_names <- resolved$target_names
    F <- resolved$F
    Q <- resolved$Q
    w <- resolved$w
    kappa <- resolved$kappa
    alpha <- resolved$alpha
    g <- resolved$g
    dg <- resolved$dg
    N <- nrow(df)
  } else {
    N <- length(F)
  }

  if (is.null(F)) {
    cli::cli_abort(
      "Predictive cdfs {.arg F} must be supplied, directly or as a column of {.arg df}."
    )
  }
  if (length(target_names) == 1L && all(is.na(target_names))) {
    target_names <- as.character(seq_len(N))
  }
  if (length(w) == 1L) {
    w <- rlang::set_names(rep(w, N), target_names)
  } else if (length(w) == N) {
    w <- rlang::set_names(w, target_names)
  } else {
    cli::cli_abort("{.arg w} must have length 1 or {N}, not {length(w)}.")
  }

  gpl_df <- new_gpl_df(
    N = N,
    target_names = target_names,
    g = g,
    dg = dg,
    kappa = kappa,
    alpha = alpha
  )
  if (!is.null(target_col_name)) {
    gpl_df <- dplyr::rename(gpl_df, !!target_col_name := "target_names")
  } else {
    target_col_name <- "target_names"
  }

  # Initialize the allocation at the alpha-quantile of each forecast when that
  # is finite; otherwise at a finite value large enough to violate the budget.
  qs <- max(K) * (1 + 2 * point_mass_window)
  if (any(alpha < 1)) {
    qs <- purrr::map2_dbl(Q, alpha, rlang::exec)
  }

  # marginal expected benefits, and their values at the origin
  Lambda <- meb_gpl_df(df = gpl_df, F = F, w = w)
  Lambda0 <- purrr::map2_dbl(Lambda, 0, rlang::exec)
  lamU0 <- max(Lambda0)
  if (!is.finite(lamU0)) {
    # g'(0) is unbounded for increment functions such as log(x), which makes
    # Lambda_i(0) infinite (or NaN when alpha < 1) and leaves the bisection with
    # no usable upper bracket. The original package messaged and carried on,
    # returning the initial iterate unchanged.
    cli::cli_abort(c(
      "The marginal expected benefit at zero is not finite, so lambda cannot be bracketed.",
      "i" = "This happens when {.arg g} has an unbounded derivative at zero, as \
             {.code g = \"log(x)\"} does.",
      "i" = "Use a shifted increment function such as {.code g = \"log(1 + x)\"} instead."
    ))
  }

  # the iteration history starts as a single column of initial allocations,
  # shared by every budget
  xs0 <- dplyr::mutate(
    dplyr::select(gpl_df, tidyselect::all_of(target_col_name)),
    `0` = qs
  )
  x0 <- tibble::deframe(xs0)

  Kdf <- tibble::tibble(
    K = K,
    xs = list(xs0),
    x = list(x0),
    qs_OK = sum(w * x0) < K,
    converged = FALSE,
    lamL = 0,
    lamL_seq = list(0),
    lamU = lamU0,
    lamU_seq = list(lamU0),
    lam = 0,
    lam_seq = list(0),
    lam_prev = 0
  )
  Kdf <- dplyr::arrange(Kdf, .data$K)

  # budgets already satisfied by the unconstrained solution need no search
  out <- dplyr::mutate(dplyr::filter(Kdf, .data$qs_OK), converged = TRUE)
  Kdf <- dplyr::filter(Kdf, !.data$qs_OK)

  if (nrow(Kdf) > 0 && Kdf$lamU[1] <= 0) {
    # No target has any marginal benefit from a positive allocation, so zero is
    # optimal. Flagging these rows as qs_OK keeps them out of post-processing:
    # the budget is deliberately left unspent, which is not a plateau failure.
    Kdf$x <- list(rlang::set_names(rep(0, N), target_names))
    Kdf$qs_OK <- TRUE
    Kdf$converged <- TRUE
    out <- rbind(out, Kdf)
    cli::cli_inform("All targets receiving zero allocation.")
  } else {
    tau <- 1
    while (nrow(Kdf) > 0) {
      Kdf <- dplyr::mutate(
        Kdf,
        lam = (.data$lamL + .data$lamU) / 2,
        lam_seq = purrr::map2(.data$lam_seq, .data$lam, c)
      )
      for (lam_tau in unique(Kdf$lam)) {
        # index once and reuse, rather than comparing doubles twice
        idx <- which(Kdf$lam == lam_tau)
        Kdf_lam <- Kdf[idx, ]
        K_lam <- max(Kdf_lam$K)
        x_tau <- Kdf_lam$x[[1]]
        lam_prev <- unique(Kdf_lam$lam_prev)
        stopifnot(length(lam_prev) == 1L)
        for (i in seq_len(N)) {
          x_tau[i] <- solve_target_allocation(
            Lambda_i = Lambda[[i]],
            Lambda0_i = Lambda0[i],
            x_i = x_tau[i],
            lam_tau = lam_tau,
            lam_prev = lam_prev,
            K_lam = K_lam,
            point_mass_window = point_mass_window,
            target_name = target_names[i],
            index = i,
            tau = tau
          )
        }
        Kdf_lam <- dplyr::mutate(
          Kdf_lam,
          x = list(x_tau),
          xs = purrr::map(.data$xs, function(xs) {
            dplyr::mutate(xs, !!as.character(tau) := x_tau)
          }),
          lam_prev = lam_tau,
          # narrow the bracket according to whether we over- or under-shot K
          lamL = ifelse(sum(w * x_tau) > .data$K, lam_tau, .data$lamL),
          lamL_seq = purrr::map2(.data$lamL_seq, .data$lamL, c),
          lamU = ifelse(sum(w * x_tau) <= .data$K, lam_tau, .data$lamU),
          lamU_seq = purrr::map2(.data$lamU_seq, .data$lamU, c),
          converged = ((.data$lamU - .data$lamL) / .data$lamU < eps_lam) |
            (.data$lamU <= eps_lam)
        )
        Kdf[idx, ] <- Kdf_lam
      }
      out <- rbind(out, dplyr::filter(Kdf, .data$converged))
      Kdf <- dplyr::filter(Kdf, !.data$converged)
      tau <- tau + 1
    }
  }

  # post-process allocations left infeasible by plateaus in the objective
  out <- dplyr::mutate(
    out,
    post_processed = purrr::pmap_lgl(
      list(.data$x, .data$K, .data$qs_OK),
      function(x, K, qs_OK) abs((sum(w * x) - K) / K) > eps_K && !qs_OK
    ),
    x = purrr::pmap(
      list(.data$post_processed, .data$x, .data$K, .data$lam),
      function(post_processed, x, K, lam) {
        if (post_processed) {
          x <- post_process(x, K, lam, w, Lambda, eps_lam, point_mass_window)
        }
        x
      }
    )
  )

  out <- dplyr::arrange(
    dplyr::select(out, -c("converged", "lam_prev")),
    .data$K
  )

  # build a scorable data frame for each K
  out <- dplyr::mutate(
    out,
    xdf = purrr::map(.data$x, function(x) {
      xdf <- tibble::enframe(x, name = target_col_name, value = "x")
      xdf <- dplyr::left_join(
        xdf,
        gpl_df[, c(target_col_name, "gpl_loss_fun")],
        by = target_col_name
      )
      xdf[["score_fun"]] <- purrr::map2(
        xdf[["x"]],
        xdf[["gpl_loss_fun"]],
        function(x, gpl_loss_fun) function(y) gpl_loss_fun(x, y)
      )
      dplyr::select(xdf, -"gpl_loss_fun")
    })
  )

  structure(
    out,
    class = c("allocated", class(out)),
    gpl_df = gpl_df,
    w = w,
    target_col_name = target_col_name
  )
}

#' Invert the marginal expected benefit for a single target
#'
#' Finds the allocation `x_i` at which target `i`'s marginal expected benefit
#' equals `lam_tau`, using the current iterate to bracket the search.
#'
#' @return A single allocation value.
#'
#' @noRd
solve_target_allocation <- function(
  Lambda_i,
  Lambda0_i,
  x_i,
  lam_tau,
  lam_prev,
  K_lam,
  point_mass_window,
  target_name,
  index,
  tau
) {
  # lam exceeds the benefit at zero, so this target gets nothing
  if (lam_tau > Lambda0_i) {
    return(0)
  }
  lam_grad <- function(xi) Lambda_i(xi) - lam_tau

  tryCatch(
    {
      if (is.finite(x_i)) {
        if (lam_grad(K_lam) > 0) {
          # the quantile sought lies beyond the search window, so clamp
          K_lam
        } else if (lam_tau < lam_prev) {
          # lambda decreased, so the root moved toward the quantile
          unirootL(
            f = lam_grad,
            lower = x_i,
            upper = K_lam,
            point_mass_window = point_mass_window
          )
        } else {
          # lambda increased, so the root moved toward zero
          unirootL(
            f = lam_grad,
            lower = 0,
            upper = x_i + point_mass_window,
            point_mass_window = point_mass_window
          )
        }
      } else {
        if (lam_tau < lam_prev) {
          cli::cli_abort(
            "Lambda should not decrease while there are infinite allocations."
          )
        }
        uniroot(
          f = lam_grad,
          lower = 0,
          upper = K_lam * (1 + point_mass_window),
          extendInt = "downX"
        )$root
      }
    },
    error = function(e) {
      # The original package messaged and carried on here, silently leaving the
      # previous iterate in place; failing loudly is the point of this rewrite.
      cli::cli_abort(
        c(
          "Root finding failed for target {.val {target_name}} (index {index}) at iteration {tau}.",
          "x" = conditionMessage(e)
        ),
        parent = e
      )
    }
  )
}

#' Repair allocations left infeasible by plateaus in the objective
#'
#' The objective has flat stretches wherever a predictive distribution has a
#' point mass -- always, for the degenerate distributions used by
#' [oracle_allocate()] -- so bisection on lambda can stall at an allocation
#' that does not exhaust the budget. This finds bracketing vectors `x_L` and
#' `x_U` and interpolates between them to hit the budget exactly.
#'
#' @param x final allocation from the lambda search.
#' @param K budget.
#' @param lam final lambda iterate.
#' @param w weights.
#' @param Lambda list of marginal expected benefit functions.
#' @inheritParams allocate
#'
#' @return An allocation vector exhausting the budget.
#'
#' @examples
#' # a pair of targets whose marginal benefit declines linearly
#' Lambda <- list(function(x) 1 - x / 10, function(x) 1 - x / 10)
#' # the allocation c(8, 8) costs 16, over a budget of 12
#' post_process(
#'   x = c(8, 8), K = 12, lam = 0.5, w = c(1, 1),
#'   Lambda = Lambda, eps_lam = 1e-4, point_mass_window = 1e-3
#' )
#'
#' @export
post_process <- function(x, K, lam, w, Lambda, eps_lam, point_mass_window) {
  x_L <- x_U <- x
  if (sum(w * x) > K) {
    lam_grad_eps <- purrr::map(
      Lambda,
      function(Lam) function(x) Lam(x) - lam - eps_lam
    )
    for (i in seq_along(x)) {
      if (lam_grad_eps[[i]](0) <= 0 || x[i] < point_mass_window) {
        x_L[i] <- 0
      } else {
        # No root in [0, x[i]] means this target's marginal benefit exceeds the
        # shadow price across the whole bracket, so it cannot be reduced and
        # x[i] is its own lower end.
        x_L[i] <- tryCatch(
          unirootL(
            f = lam_grad_eps[[i]],
            lower = 0,
            upper = x[i],
            point_mass_window = point_mass_window
          ),
          error = function(e) x[i]
        )
      }
    }
  } else {
    # Approximate right-hand plateau endpoints. When lam is near zero -- which
    # happens for large K, out on the upper tails of the forecasts -- an exact
    # endpoint is not available, so we settle for any x_U above x_L and let
    # uniroot extend the interval when solving for t below.
    lam_grad_eps <- purrr::map(
      Lambda,
      function(Lam) function(x) Lam(x) - max(lam - eps_lam, lam / 2)
    )
    for (i in seq_along(x)) {
      if (lam_grad_eps[[i]](0) <= 0) {
        x_U[i] <- x[i]
      } else {
        # As above: with no root to find, x[i] is its own upper end.
        x_U[i] <- tryCatch(
          uniroot(
            f = lam_grad_eps[[i]],
            lower = x[i],
            upper = x[i] + 1,
            extendInt = "downX"
          )$root,
          error = function(e) x[i]
        )
      }
    }
  }
  delta <- function(t) sum(w * ((1 - t) * x_L + t * x_U)) - K
  if (delta(0) < 0 && delta(1) > 0) {
    t_star <- uniroot(f = delta, interval = c(0, 1))$root
  } else if (lam <= 2 * eps_lam) {
    t_star <- uniroot(f = delta, interval = c(0, 1), extendInt = "upX")$root
  } else {
    cli::cli_abort("Post-processing failed for K = {K}.")
  }
  (1 - t_star) * x_L + t_star * x_U
}
