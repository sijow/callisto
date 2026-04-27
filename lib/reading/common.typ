#import "/lib/configuration.typ": parse-main-args, read-enabled

// Returns a single value from the given list as specified by the `choice`
// argument, raising an error if the list is empty or if 'choice' is "unique"
// and the list contains more than one. The value-kind string is used for
// error messages.
#let single-value(values, kind: none, setting: none, cfg: none) = {
  if values.len() == 0 {
    panic("no matching " + kind + " found")
  }
  let choice = cfg.at(setting)
  if choice == "unique" {
    if values.len() != 1 {
      panic("expected 1 " + kind + ", found " + str(values.len()))
    }
    return values.first()
  }
  if type(choice) != int {
    panic("unexpected value for '" + setting +
      "': expected \"unique\" or int, got " + type(choice))
  }
  return values.at(choice)
}

// A dictionary of cell-related data, to be used as one field in the result
// dict.
#let _cell-output-dict(cell) = (
  index: cell.index,
  id: cell.id,
  metadata: cell.metadata,
  type: cell.cell_type,
) + if cell.cell_type == "code" {
  (execution-count: cell.execution_count)
}

// Final result for an output item.
// Depending on ctx.result, this returns either 'value', or the
// 'preprocessed' dict with 'output_type' renamed to 'type' and with additional
// fields:
// - value: the rendered item
// - cell (dict): the cell index, id, metadata and type.
#let final-result(preprocessed, value, ctx: none) = {
  if ctx.result not in ("value", "dict") {
    panic("invalid result specification: " + repr(ctx.result))
  }
  if ctx.result == "value" {
    return value
  }
  // Remove "output_type" field if present (will be replaced by type field from
  // ctx.item-desc)
  _ = preprocessed.remove("output_type", default: none)
  return preprocessed + ctx.item-desc + (
    cell: _cell-output-dict(ctx.cell),
    value: value,
  )
}

// Gets a boolean value from the cell header
#let get-header-bool(cell, key, default) = {
  let value = cell.metadata.callisto.header.at(key, default: default)
  if value not in ("true", "false") {
    panic("value for " + key + " in cell header must be \"true\" or \"false\"")
  }
  return value == "true"
}
