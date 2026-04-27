#import "reading/cell.typ": cells, cell
#import "reading/common.typ": placeholder-enabled, get-placeholder
#import "util.typ": handle
#import "configuration.typ": parse-main-args, read-enabled
#import "ctx/ctx.typ": get-ctx

// Render the specified cells according to the settings (see common.typ).
// By default this function does apply the theme.
#let render(..args, apply-theme: true) = {
  // Make sure the handlers are called with a context with result: "value"
  let (cell-spec, cfg) = parse-main-args(
    ..args,
    apply-theme: apply-theme,
    result: "value",
  )
  if read-enabled(cfg: cfg) == false { return none }
  for c in cells(..args) {
    handle(c, mime: "cell", ctx: get-ctx(c, cell-spec: cell-spec, cfg: cfg))
  }
}

// Helper for rendering from a single cell
#let _render-cell(..args, apply-theme: true, kind: none) = {
  // Make sure the handlers are called with a context with result: "value"
  let (cell-spec, cfg) = parse-main-args(
    ..args,
    apply-theme: apply-theme,
    result: "value",
  )

  let c = if placeholder-enabled(cfg: cfg) {
    cell(..args, placeholder: "placeholder")
  } else {
    cell(..args, placeholder: false)
  }

  if c == "placeholder" {
    let ctx = get-ctx(none, cell-spec: cell-spec, cfg: cfg)
    return get-placeholder(kind: kind, ctx: ctx)
  }
  
  handle(c, mime: "cell", ctx: get-ctx(c, cell-spec: cell-spec, cfg: cfg))
}

// Render a single cell
#let Cell(..args) = _render-cell(..args, kind: "Cell")
// Render a single code cell's input
#let In(..args) = _render-cell(..args, cell-type: "code", input: true, output: false, kind: "In")
// Render a single code cell's output
#let Out(..args) = _render-cell(..args, cell-type: "code", input: false, output: true, kind: "Out")
