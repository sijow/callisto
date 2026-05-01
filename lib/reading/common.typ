#import "/lib/configuration.typ": parse-main-args, read-enabled
#import "/lib/util.typ"
#import "notebook.typ"

// Knowing that reading is enabled, is it from an exported notebook?
#let _from-export(cfg: none) = {
  let nb-json = notebook.get-json(cfg: cfg)
  return "callisto" in nb-json.metadata
}

// Return true if the configuration allows using placeholders
#let placeholder-enabled(cfg: none) = {
  if read-enabled(cfg: cfg) and not _from-export(cfg: cfg) {
    // Enabled if anything but false or auto (can be true/content/function)
    return cfg.placeholder not in (false, auto)
  }
  // If read disabled or from export, we use it unless explicitly disabled
  return cfg.placeholder != false
}

// Return the placeholder value to use for the given kind (cell, source,
// output).
#let get-placeholder(mime: none, ctx: none) = {
  if ctx.placeholder in (auto, true) {
    return util.handle(none, mime: mime, ctx: ctx)
  }
  if type(ctx.placeholder) == function {
    return (ctx.placeholder)(ctx.cell-spec)
  }
  return ctx.placeholder
}

// Returns a single value from the given list as specified by the 'item'
// setting (in args), using a placeholder or raising an error if the list is
// empty or none or if 'item' is "unique" and the list contains more than one.
#let single-output(values, ctx: none) = {
  let (cell-spec, cfg) = ctx

  if values == none or values.len() == 0 {
    if placeholder-enabled(cfg: cfg) {
      return get-placeholder(mime: "placeholder-output", ctx: ctx)
    }
    panic("no matching item found. Cell spec was " + repr(cell-spec))
  }
  if cfg.item == "unique" {
    if values.len() != 1 {
      panic("expected 1 item, found " + str(values.len()) +
        ". Cell spec was " + repr(cell-spec))
    }
    return values.first()
  }
  if type(cfg.item) != int {
    panic("unexpected value for 'item'': expected \"unique\" or int, got " +
      type(cfg.item))
  }
  return values.at(cfg.item)
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

// Final result for an output item, with transform applied if any.
// Depending on ctx.result, this returns either 'value', or the
// 'preprocessed' dict with 'output_type' renamed to 'type' and with additional
// fields:
// - value: the rendered item
// - cell (dict): the cell index, id, metadata and type.
#let final-result(preprocessed, value, ctx: none) = {
  if ctx.result not in ("value", "dict") {
    panic("invalid result specification: " + repr(ctx.result))
  }
  if ctx.transform != none {
    value = (ctx.transform)(value)
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
