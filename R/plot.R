#' Plot the per-target components of an allocation score
#'
#' Shows how a score decomposes across targets: as stacked or dodged bars when
#' a single budget is plotted, and as stacked areas over the budget otherwise.
#'
#' @param ... objects to plot. For the default method, a data frame with a list
#'   column of scored allocations; for the `allocated` method, one or more
#'   scored `allocated` objects.
#'
#' @return A [ggplot2::ggplot()] object.
#'
#' @examples
#' fc <- add_pdqr_funs(
#'   tibble::tibble(
#'     target_names = c("a", "b", "c"), dist = "norm",
#'     mean = c(5, 8, 12), sd = c(1, 2, 3)
#'   ),
#'   types = c("p", "q")
#' )
#' scored <- alloscore(fc, y = c(4, 9, 11), K = c(10, 20, 30))
#' plot_components(scored)
#'
#' @export
plot_components <- function(...) {
  UseMethod("plot_components")
}

#' @describeIn plot_components Plots a data frame holding a list column of
#'   scored allocations, such as one row per model and origin time.
#'
#' @param df a data frame with a list column of scored allocations.
#' @param Ks budgets to plot. Defaults to `NULL`, which keeps all of them; note
#'   that the bar layout requires a single budget.
#' @param scored_col_name name of the list column holding the scored
#'   allocations.
#' @param origin_time_col_name name of the column holding an origin time, used
#'   to facet.
#' @param model_col_name name of the column holding a model name. For hubverse
#'   model output this is `"model_id"`.
#' @param target_col_name name of the column holding target names.
#' @param show_oracle whether to add the oracle's components as an extra model.
#'
#' @export
plot_components.default <- function(
  df,
  Ks = NULL,
  scored_col_name = "scored",
  origin_time_col_name = NULL,
  model_col_name = NULL,
  target_col_name = NULL,
  show_oracle = TRUE,
  ...
) {
  scored_list <- df[[scored_col_name]]
  if (is.null(scored_list)) {
    cli::cli_abort(c(
      "No scored allocations found in column {.val {scored_col_name}}.",
      "i" = "Pass the name of the list column to {.arg scored_col_name}."
    ))
  }
  # carry the origin time and model down into each scored data frame
  if (!is.null(origin_time_col_name)) {
    scored_list <- purrr::map2(
      df[[origin_time_col_name]],
      scored_list,
      function(origin_time, scored) {
        scored[[origin_time_col_name]] <- origin_time
        scored
      }
    )
  }
  if (!is.null(model_col_name)) {
    scored_list <- purrr::map2(
      df[[model_col_name]],
      scored_list,
      function(model, scored) {
        scored[[model_col_name]] <- model
        scored
      }
    )
  }
  do.call(
    plot_components,
    c(
      scored_list,
      list(
        Ks = Ks,
        origin_time_col_name = origin_time_col_name,
        model_col_name = model_col_name,
        target_col_name = target_col_name,
        show_oracle = show_oracle
      )
    )
  )
}

#' @describeIn plot_components Plots one or more scored `allocated` objects.
#'
#' @export
plot_components.allocated <- function(
  ...,
  Ks = NULL,
  origin_time_col_name = NULL,
  model_col_name = NULL,
  target_col_name = NULL,
  show_oracle = TRUE
) {
  adfs <- list(...)
  is_allocated <- purrr::map_lgl(adfs, function(x) inherits(x, "allocated"))
  is_scored <- purrr::map_lgl(adfs, function(x) inherits(x, "scored"))
  has_origin_time <- purrr::map_lgl(adfs, function(x) {
    !is.null(origin_time_col_name) && origin_time_col_name %in% names(x)
  })
  has_model <- purrr::map_lgl(adfs, function(x) {
    !is.null(model_col_name) && model_col_name %in% names(x)
  })

  if (!all(is_allocated)) {
    cli::cli_abort("All inputs must be {.cls allocated} objects.")
  }
  if (!all(is_scored)) {
    cli::cli_abort("All inputs must be scored; see {.fun alloscore}.")
  }
  if (any(has_origin_time) && !all(has_origin_time)) {
    cli::cli_abort(
      "All inputs must have a column named {.val {origin_time_col_name}}."
    )
  }
  if (any(has_model) && !all(has_model)) {
    cli::cli_abort(
      "All inputs must have a column named {.val {model_col_name}}."
    )
  }
  if (!any(has_model) && !any(has_origin_time) && length(adfs) > 1) {
    cli::cli_abort(c(
      "Several allocations were given but there is nothing to tell them apart.",
      "i" = "Add a model or origin time column and name it with {.arg model_col_name} \\
             or {.arg origin_time_col_name}."
    ))
  }

  adf <- dplyr::bind_rows(adfs)
  id_cols <- c(origin_time_col_name, model_col_name)
  key <- dplyr::select(adf, tidyselect::any_of(c(id_cols, "K")))
  if (any(duplicated(key))) {
    cli::cli_abort(
      "Allocations are not uniquely identified by {.val {c(id_cols, 'K')}}."
    )
  }
  plot_components_slim(
    slim(adf, id_cols = id_cols),
    Ks = Ks,
    origin_time_col_name = origin_time_col_name,
    model_col_name = model_col_name,
    target_col_name = target_col_name,
    show_oracle = show_oracle
  )
}

#' Rename the plotting columns to their canonical names
#'
#' @param slim_df a slim scored allocation.
#' @inheritParams plot_components.default
#'
#' @return `slim_df` with `origin_time`, `model` and `target_names` columns.
#'
#' @noRd
normalize_col_names <- function(
  slim_df,
  origin_time_col_name = NULL,
  model_col_name = NULL,
  target_col_name = NULL
) {
  if (
    !is.null(origin_time_col_name) && origin_time_col_name %in% names(slim_df)
  ) {
    slim_df <- dplyr::rename(
      slim_df,
      origin_time = tidyselect::all_of(origin_time_col_name)
    )
  }
  if (!is.null(model_col_name) && model_col_name %in% names(slim_df)) {
    slim_df <- dplyr::rename(
      slim_df,
      model = tidyselect::all_of(model_col_name)
    )
  }
  if (!"model" %in% names(slim_df)) {
    slim_df[["model"]] <- "model"
  }
  if (!is.null(target_col_name) && target_col_name %in% names(slim_df)) {
    slim_df <- dplyr::rename(
      slim_df,
      target_names = tidyselect::all_of(target_col_name)
    )
  }
  slim_df
}

#' Prepare a slim scored allocation for plotting
#'
#' Filters to the requested budgets, unnests, normalizes column names and
#' optionally appends the oracle as an extra model.
#'
#' @noRd
prepare_plot_data <- function(
  slim_df,
  Ks,
  origin_time_col_name,
  model_col_name,
  target_col_name,
  show_oracle
) {
  if (!is.null(Ks)) {
    slim_df <- dplyr::filter(slim_df, .data$K %in% Ks)
  }
  if ("xdf" %in% names(slim_df)) {
    slim_df <- tidyr::unnest(slim_df, "xdf")
  }
  slim_df <- normalize_col_names(
    slim_df,
    origin_time_col_name,
    model_col_name,
    target_col_name
  )
  if (show_oracle) {
    if (!"components_oracle" %in% names(slim_df)) {
      cli::cli_abort(c(
        "{.arg show_oracle} is {.code TRUE} but there are no oracle components.",
        "i" = "Score with {.code against_oracle = TRUE}, or pass {.code show_oracle = FALSE}."
      ))
    }
    oracle_rows <- dplyr::mutate(
      dplyr::filter(slim_df, .data$model == .data$model[1]),
      model = "oracle",
      components_raw = .data$components_oracle
    )
    slim_df <- dplyr::bind_rows(slim_df, oracle_rows)
  }
  slim_df
}

#' Order target or model levels at a chosen slice of the data
#'
#' @noRd
levels_at <- function(
  df,
  col,
  by,
  order_at_K,
  order_at_model,
  order_at_origin_time
) {
  if (!is.null(order_at_K)) {
    df <- dplyr::filter(df, .data$K == order_at_K)
  }
  if (!is.null(order_at_model)) {
    df <- dplyr::filter(df, .data$model == order_at_model)
  }
  if (!is.null(order_at_origin_time)) {
    df <- dplyr::filter(df, .data$origin_time == order_at_origin_time)
  }
  ordered <- forcats::fct_reorder(df[[col]], dplyr::desc(df[[by]]))
  levels(ordered)
}

#' Plot the components of a slim scored allocation
#'
#' @param slim_df a slim scored allocation; see [slim()].
#' @inheritParams plot_components.default
#' @param show_raw plot the forecaster's own losses rather than its losses
#'   relative to the oracle.
#' @param order_at_K,order_at_model,order_at_origin_time order the targets by
#'   their contribution at this budget, model or origin time. By default the
#'   targets are ordered over the whole data set.
#' @param pal_top colours for the largest contributors when an ordering slice
#'   is given; the remaining targets are shown in grey.
#' @param bar_positioning `"stack"` or `"dodge"`, for the single-budget layout.
#'
#' @return A [ggplot2::ggplot()] object.
#'
#' @examples
#' fc <- add_pdqr_funs(
#'   tibble::tibble(
#'     target_names = c("a", "b", "c"), dist = "norm",
#'     mean = c(5, 8, 12), sd = c(1, 2, 3)
#'   ),
#'   types = c("p", "q")
#' )
#' scored <- alloscore(fc, y = c(4, 9, 11), K = c(10, 20, 30))
#' plot_components_slim(slim(scored))
#'
#' @export
plot_components_slim <- function(
  slim_df,
  Ks = NULL,
  origin_time_col_name = NULL,
  model_col_name = NULL,
  target_col_name = NULL,
  show_oracle = TRUE,
  show_raw = TRUE,
  order_at_K = NULL,
  order_at_model = NULL,
  order_at_origin_time = NULL,
  pal_top = c("#CD3333", "#009ACD", "#FFB90F", "#8B3E2F", "#8B8B00"),
  bar_positioning = c("stack", "dodge")
) {
  bar_positioning <- match.arg(bar_positioning)
  slim_df <- prepare_plot_data(
    slim_df,
    Ks,
    origin_time_col_name,
    model_col_name,
    target_col_name,
    show_oracle
  )
  if (show_raw) {
    slim_df <- dplyr::mutate(slim_df, components = .data$components_raw)
  }

  levs <- levels_at(
    slim_df,
    "target_names",
    "components",
    order_at_K,
    order_at_model,
    order_at_origin_time
  )
  ordered_slice <- !is.null(order_at_K) ||
    !is.null(order_at_model) ||
    !is.null(order_at_origin_time)
  if (ordered_slice) {
    colors <- stats::setNames(
      c(pal_top, rep(c("lightgrey", "darkgrey"), length.out = 60)),
      levs
    )
  } else {
    colors <- stats::setNames(
      grDevices::palette.colors(n = 60, palette = "Paired", recycle = TRUE),
      levs
    )
  }
  slim_df <- dplyr::mutate(
    slim_df,
    target_names = factor(.data$target_names, levels = levs)
  )

  has_origin_time <- "origin_time" %in% names(slim_df)
  if (length(unique(slim_df$K)) == 1) {
    # a single budget: bars, one group per model
    p <- if (bar_positioning == "stack") {
      ggplot2::ggplot(
        slim_df,
        ggplot2::aes(
          x = .data$model,
          y = .data$components,
          fill = .data$target_names
        )
      ) +
        ggplot2::geom_bar(position = "stack", stat = "identity")
    } else {
      ggplot2::ggplot(
        slim_df,
        ggplot2::aes(
          x = .data$target_names,
          y = .data$components,
          fill = .data$model
        )
      ) +
        ggplot2::geom_bar(position = "dodge", stat = "identity")
    }
    if (has_origin_time) {
      p <- p + ggplot2::facet_wrap(ggplot2::vars(.data$origin_time))
    }
  } else {
    # several budgets: stacked areas over K
    p <- ggplot2::ggplot(
      slim_df,
      ggplot2::aes(x = .data$K, y = .data$components, fill = .data$target_names)
    ) +
      ggplot2::geom_area()
    if (has_origin_time) {
      p <- p +
        ggplot2::facet_grid(
          rows = ggplot2::vars(.data$model),
          cols = ggplot2::vars(.data$origin_time)
        )
    } else {
      p <- p + ggplot2::facet_grid(rows = ggplot2::vars(.data$model))
    }
  }
  if (bar_positioning == "stack") {
    p <- p + ggplot2::scale_fill_manual(values = colors)
  }
  p
}

#' Plot allocation scores against the budget or over time
#'
#' @inheritParams plot_components_slim
#' @param ts plot the score as a time series over `origin_time` rather than
#'   against the budget. Requires one budget per origin time, given in `Ks`.
#' @param ts_dates restrict a time series plot to these origin times.
#' @param palette colours for the models, passed to
#'   [ggplot2::scale_color_manual()].
#' @param linetypes line types for the models, passed to
#'   [ggplot2::scale_linetype_manual()].
#' @param ytot add a dashed vertical line at the total weighted outcome, the
#'   budget beyond which the oracle incurs no loss.
#'
#' @return A [ggplot2::ggplot()] object.
#'
#' @examples
#' fc <- add_pdqr_funs(
#'   tibble::tibble(
#'     target_names = c("a", "b", "c"), dist = "norm",
#'     mean = c(5, 8, 12), sd = c(1, 2, 3)
#'   ),
#'   types = c("p", "q")
#' )
#' scored <- alloscore(fc, y = c(4, 9, 11), K = seq(5, 40, by = 5))
#' plot_scores_slim(slim(scored))
#'
#' @export
plot_scores_slim <- function(
  slim_df,
  Ks = NULL,
  ts = FALSE,
  ts_dates = NULL,
  origin_time_col_name = NULL,
  model_col_name = NULL,
  target_col_name = NULL,
  show_oracle = FALSE,
  show_raw = FALSE,
  order_at_K = NULL,
  order_at_model = NULL,
  order_at_origin_time = NULL,
  palette = NULL,
  linetypes = NULL,
  ytot = TRUE
) {
  slim_df <- prepare_plot_data(
    slim_df,
    Ks,
    origin_time_col_name,
    model_col_name,
    target_col_name,
    show_oracle
  )
  if (show_raw) {
    slim_df <- dplyr::mutate(slim_df, score = .data$score_raw)
  }
  has_origin_time <- "origin_time" %in% names(slim_df)

  levs <- levels_at(
    slim_df,
    "model",
    "score",
    order_at_K,
    order_at_model,
    order_at_origin_time
  )
  slim_df <- dplyr::mutate(slim_df, model = factor(.data$model, levels = levs))

  time_series <- ts && has_origin_time
  if (time_series) {
    if (is.null(Ks) || length(Ks) != length(unique(slim_df$origin_time))) {
      cli::cli_abort(c(
        "A time series plot needs one budget per origin time.",
        "i" = "Pass {length(unique(slim_df$origin_time))} value{?s} in {.arg Ks}."
      ))
    }
    # one (origin_time, K) pair per model, in the model order established above
    ts_base <- tidyr::expand_grid(
      model = factor(levs, levels = levs),
      tibble::tibble(origin_time = sort(unique(slim_df$origin_time)), K = Ks)
    )
    ts_df <- dplyr::left_join(
      ts_base,
      slim_df,
      by = c("model", "origin_time", "K")
    )
    ts_df <- dplyr::ungroup(dplyr::slice(
      dplyr::group_by(ts_df, .data$origin_time, .data$model),
      1
    ))
    if (!is.null(ts_dates)) {
      ts_df <- dplyr::filter(ts_df, .data$origin_time %in% ts_dates)
    }
    p <- ggplot2::ggplot(
      ts_df,
      ggplot2::aes(
        x = .data$origin_time,
        y = .data$score,
        group = .data$model,
        color = .data$model,
        linetype = .data$model
      )
    ) +
      ggplot2::geom_line() +
      ggplot2::geom_point()
  } else {
    p <- ggplot2::ggplot(
      slim_df,
      ggplot2::aes(
        x = .data$K,
        y = .data$score,
        color = .data$model,
        linetype = .data$model
      )
    ) +
      ggplot2::geom_line()
    if (has_origin_time && length(unique(slim_df$origin_time)) > 1) {
      p <- p + ggplot2::facet_grid(cols = ggplot2::vars(.data$origin_time))
    }
  }
  if (!is.null(palette)) {
    p <- p + ggplot2::scale_color_manual(values = palette)
  }
  if (!is.null(linetypes)) {
    p <- p + ggplot2::scale_linetype_manual(values = linetypes)
  }
  if (ytot && !time_series) {
    group_cols <- intersect(c("origin_time", "model"), names(slim_df))
    ytot_df <- if ("ytot" %in% names(slim_df)) {
      dplyr::distinct(dplyr::select(
        slim_df,
        tidyselect::all_of(c(group_cols, "ytot"))
      ))
    } else if ("y" %in% names(slim_df)) {
      # slim() drops the ytot column, so recover the total from the outcomes
      dplyr::summarise(
        dplyr::group_by(
          slim_df,
          dplyr::pick(tidyselect::all_of(c(group_cols, "K")))
        ),
        ytot = sum(.data$y),
        .groups = "drop"
      )
    } else {
      NULL
    }
    if (!is.null(ytot_df)) {
      p <- p +
        ggplot2::geom_vline(
          data = ytot_df,
          ggplot2::aes(xintercept = .data$ytot),
          linetype = 2
        )
    }
  }
  p
}

#' Plot the allocation search for one budget
#'
#' Shows how the allocation evolved over the bisection on lambda, as a stacked
#' area of allocations above a panel tracking lambda and its bracketing
#' interval.
#'
#' @param adf an `allocated` object; see [allocate()].
#' @param K_to_plot the budget whose search to show. Required unless `adf` has
#'   a single row.
#' @param itnum how many iterations to show. Defaults to all of them.
#' @param num_targets_to_color how many of the largest targets to colour
#'   individually; the rest are pooled into "other".
#' @param target_palette colours for the individually coloured targets.
#'
#' @return A [patchwork::patchwork] object stacking the two panels.
#'
#' @examples
#' fc <- add_pdqr_funs(
#'   tibble::tibble(
#'     target_names = c("a", "b", "c"), dist = "norm",
#'     mean = c(5, 8, 12), sd = c(1, 2, 3)
#'   ),
#'   types = c("p", "q")
#' )
#' plot_iterations(allocate(fc, K = 20, alpha = 0.9))
#'
#' @export
plot_iterations <- function(
  adf,
  K_to_plot = NULL,
  itnum = NULL,
  num_targets_to_color = 6,
  target_palette = scales::viridis_pal()(num_targets_to_color + 1)
) {
  req_cols <- c("K", "xs", "lamL_seq", "lamU_seq", "lam_seq")
  missing_cols <- setdiff(req_cols, names(adf))
  if (length(missing_cols) > 0) {
    cli::cli_abort(c(
      "{.arg adf} does not hold an allocation search to plot.",
      "x" = "Missing column{?s} {.val {missing_cols}}.",
      "i" = "Pass the output of {.fun allocate} or {.fun allocate_model_out}."
    ))
  }
  # allocate_model_out() returns a flat tibble with no target_col_name
  # attribute, so fall back to whichever column of the history is not an
  # iteration index
  target_col_name <- attr(adf, "target_col_name")
  if (is.null(target_col_name)) {
    xs_cols <- names(adf[["xs"]][[1]])
    target_col_name <- xs_cols[is.na(suppressWarnings(as.numeric(xs_cols)))][1]
  }
  if (is.null(K_to_plot)) {
    if (nrow(adf) != 1) {
      cli::cli_abort(c(
        "{.arg K_to_plot} must be given when {.arg adf} has more than one budget.",
        "i" = "Available budgets: {.val {adf$K}}."
      ))
    }
    K_to_plot <- adf$K
  } else if (!K_to_plot %in% adf$K) {
    cli::cli_abort(
      "{.arg K_to_plot} value {.val {K_to_plot}} is not among the budgets {.val {adf$K}}."
    )
  }
  adf <- dplyr::filter(adf, .data$K == K_to_plot)
  if (nrow(adf) != 1) {
    cli::cli_abort(c(
      "{nrow(adf)} allocations share the budget {.val {K_to_plot}}.",
      "i" = "Subset {.arg adf} to the single allocation whose search you want to see."
    ))
  }
  iters <- tidyr::unnest(dplyr::select(adf, "K", "xs"), "xs")
  iter_cols <- setdiff(names(iters), c("K", target_col_name))
  if (is.null(itnum)) {
    itnum <- iter_cols[length(iter_cols)]
  }
  itnum <- as.character(itnum)
  if (!itnum %in% iter_cols) {
    cli::cli_abort(
      "{.arg itnum} value {.val {itnum}} is not among the iterations recorded."
    )
  }
  keep_cols <- iter_cols[seq_len(match(itnum, iter_cols))]

  lambdas <- tidyr::unnest(
    dplyr::select(adf, "lamL_seq", "lamU_seq", "lam_seq"),
    cols = c("lamL_seq", "lamU_seq", "lam_seq")
  )
  lambdas <- dplyr::mutate(
    lambdas,
    lamL_seq = dplyr::lag(.data$lamL_seq, 1),
    lamU_seq = dplyr::lag(.data$lamU_seq, 1)
  )
  lambdas <- dplyr::slice(
    lambdas,
    seq_len(min(nrow(lambdas), length(keep_cols) + 1L))
  )
  lambdas <- dplyr::mutate(lambdas, iteration = dplyr::row_number() - 1)

  final <- iters[[itnum]]
  plot_dat <- dplyr::mutate(
    iters,
    allo_rank = dplyr::row_number(dplyr::desc(final)),
    Targets = forcats::fct_inorder(ifelse(
      dplyr::row_number(dplyr::desc(final)) <= num_targets_to_color,
      as.character(.data[[target_col_name]]),
      "other"
    ))
  )
  plot_dat <- dplyr::arrange(plot_dat, .data$allo_rank)
  plot_dat[[target_col_name]] <- forcats::fct_inorder(
    as.character(plot_dat[[target_col_name]])
  )
  plot_dat <- tidyr::pivot_longer(
    dplyr::select(
      plot_dat,
      tidyselect::all_of(c(target_col_name, "Targets", "K", keep_cols))
    ),
    cols = tidyselect::all_of(keep_cols),
    names_to = "iteration",
    values_to = "allocation"
  )
  plot_dat <- dplyr::mutate(plot_dat, iteration = as.numeric(.data$iteration))

  # colours: interleave the palette so adjacent bands contrast, and grey "other"
  target_names <- unique(plot_dat$Targets)
  n_even <- num_targets_to_color - num_targets_to_color %% 2
  color_shuffle <- num_targets_to_color:1
  if (n_even > 0) {
    color_shuffle[seq_len(n_even)] <-
      rep(seq_len(n_even / 2), each = 2) + c(0, n_even / 2)
  }
  target_palette <- target_palette[color_shuffle]
  target_palette[num_targets_to_color + 1] <- "lightgrey"
  color_palette <- stats::setNames(
    target_palette[seq_along(target_names)],
    target_names
  )

  max_iter <- max(plot_dat$iteration)
  p_iter <- ggplot2::ggplot(plot_dat) +
    ggplot2::geom_area(
      ggplot2::aes(
        group = .data[[target_col_name]],
        x = .data$iteration,
        y = .data$allocation
      ),
      position = "stack",
      color = "black",
      linewidth = .3,
      fill = NA
    ) +
    ggplot2::geom_area(
      ggplot2::aes(
        group = .data[[target_col_name]],
        x = .data$iteration,
        y = .data$allocation,
        fill = .data$Targets,
        alpha = 1 - .5 * (.data$Targets == "other")
      ),
      position = "stack"
    ) +
    ggplot2::geom_hline(ggplot2::aes(yintercept = .data$K), alpha = .5) +
    ggplot2::scale_x_continuous(
      breaks = seq_len(max_iter),
      expand = c(0, 0),
      name = NULL
    ) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, 0.1))) +
    ggplot2::scale_fill_manual(values = color_palette) +
    ggplot2::scale_alpha_continuous(guide = "none") +
    ggplot2::labs(y = "Allocations") +
    ggplot2::theme_bw() +
    ggplot2::theme(panel.grid.minor.x = ggplot2::element_blank())

  p_lambda <- ggplot2::ggplot(lambdas) +
    ggplot2::geom_line(ggplot2::aes(x = .data$iteration, y = .data$lam_seq)) +
    ggplot2::geom_ribbon(
      ggplot2::aes(
        x = .data$iteration,
        ymin = .data$lamL_seq,
        ymax = .data$lamU_seq
      ),
      alpha = .3
    ) +
    ggplot2::scale_x_continuous(breaks = seq_len(max_iter), expand = c(0, 0)) +
    ggplot2::scale_y_continuous(
      expand = ggplot2::expansion(mult = c(0, 0.1)),
      name = expression(lambda)
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(panel.grid.minor.x = ggplot2::element_blank())

  patchwork::wrap_plots(p_iter, p_lambda, ncol = 1)
}
