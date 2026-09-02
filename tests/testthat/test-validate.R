test_that("get_task_id_cols excludes the model output representation columns", {
  mot <- mini_model_out()
  expect_setequal(
    get_task_id_cols(mot),
    c("reference_date", "target", "horizon", "location", "target_end_date")
  )
})

test_that("validate_output_type accepts a single quantile output type", {
  expect_equal(validate_output_type(mini_model_out()), "quantile")
})

test_that("validate_output_type rejects several output types", {
  mot <- mini_model_out()
  mixed <- dplyr::bind_rows(mot, dplyr::mutate(mot, output_type = "mean"))
  expect_error(
    validate_output_type(mixed),
    regexp = "must contain a single .*output_type"
  )
})

test_that("validate_output_type rejects unsupported output types", {
  mot <- dplyr::mutate(mini_model_out(), output_type = "sample")
  expect_error(
    validate_output_type(mot),
    regexp = "only the .*quantile.* output type"
  )
})

test_that("validate_model_oracle_out requires the model output columns", {
  mot <- dplyr::select(mini_model_out(), -"value")
  expect_error(
    validate_model_oracle_out(mot, mini_oracle_out()),
    regexp = "missing required column"
  )
})

test_that("validate_model_oracle_out requires oracle_value", {
  oo <- dplyr::rename(mini_oracle_out(), observation = "oracle_value")
  expect_error(
    validate_model_oracle_out(mini_model_out(), oo),
    regexp = "must have an .*oracle_value.* column"
  )
})

test_that("validate_model_oracle_out rejects unexpected oracle columns", {
  oo <- dplyr::mutate(mini_oracle_out(), surprise = 1)
  expect_error(
    validate_model_oracle_out(mini_model_out(), oo),
    regexp = "unexpected column"
  )
})

test_that("validate_model_oracle_out requires a shared task ID column", {
  oo <- tibble::tibble(oracle_value = 1)
  expect_error(
    validate_model_oracle_out(mini_model_out(), oo),
    regexp = "no task ID columns in common"
  )
})

test_that("validate_model_oracle_out returns a model_out_tbl", {
  res <- validate_model_oracle_out(mini_model_out(), mini_oracle_out())
  expect_s3_class(res, "model_out_tbl")
})

test_that("resolve_allocation_unit derives the unit from target_cols", {
  res <- resolve_allocation_unit(mini_model_out(), "location")
  expect_equal(res$target_cols, "location")
  expect_setequal(
    res$allocation_unit,
    c("model_id", "reference_date", "target", "horizon", "target_end_date")
  )
})

test_that("resolve_allocation_unit accepts several target columns", {
  res <- resolve_allocation_unit(mini_model_out(), c("location", "target"))
  expect_setequal(
    res$allocation_unit,
    c("model_id", "reference_date", "horizon", "target_end_date")
  )
})

test_that("resolve_allocation_unit requires target_cols", {
  expect_error(
    resolve_allocation_unit(mini_model_out()),
    regexp = "must be supplied"
  )
  expect_error(
    resolve_allocation_unit(mini_model_out(), NULL),
    regexp = "must be supplied"
  )
})

test_that("resolve_allocation_unit rejects columns that are not task IDs", {
  expect_error(
    resolve_allocation_unit(mini_model_out(), "not_a_column"),
    regexp = "must name task ID columns"
  )
  # model_id is not a task ID either
  expect_error(
    resolve_allocation_unit(mini_model_out(), "model_id"),
    regexp = "must name task ID columns"
  )
})

test_that("resolve_weights accepts a scalar", {
  fc <- tibble::tibble(target_names = c("a", "b"))
  expect_equal(resolve_weights(1, fc, c("a", "b")), c(1, 1))
  expect_equal(resolve_weights(2.5, fc, c("a", "b")), c(2.5, 2.5))
})

test_that("resolve_weights matches a named vector by target", {
  fc <- tibble::tibble(target_names = c("a", "b"))
  # order follows the targets, not the vector
  expect_equal(resolve_weights(c(b = 3, a = 2), fc, c("a", "b")), c(2, 3))
  expect_error(
    resolve_weights(c(a = 2), fc, c("a", "b")),
    regexp = "no entry for target"
  )
})

test_that("resolve_weights accepts a positional vector of the right length", {
  fc <- tibble::tibble(target_names = c("a", "b"))
  expect_equal(resolve_weights(c(2, 3), fc, c("a", "b")), c(2, 3))
  expect_error(
    resolve_weights(c(2, 3, 4), fc, c("a", "b")),
    regexp = "has length 3 but there are 2 targets"
  )
})

test_that("resolve_weights takes a column name", {
  fc <- tibble::tibble(target_names = c("a", "b"), cost = c(5, 7))
  expect_equal(resolve_weights("cost", fc, c("a", "b")), c(5, 7))
  expect_error(
    resolve_weights("nope", fc, c("a", "b")),
    regexp = "names column .*nope.*which is not present"
  )
})

test_that("resolve_weights rejects other types", {
  fc <- tibble::tibble(target_names = c("a", "b"))
  expect_error(
    resolve_weights(TRUE, fc, c("a", "b")),
    regexp = "must be numeric"
  )
})
