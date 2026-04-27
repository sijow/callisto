#import "reading/cell.typ": cells, cell
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
    handle(c, mime: "cell", ctx: get-ctx(c, cfg: cfg))
  }
}

// Render a single cell.
#let Cell(..args, apply-theme: true) = {
  // Make sure the handlers are called with a context with result: "value"
  let (cell-spec, cfg) = parse-main-args(
    ..args,
    apply-theme: apply-theme,
    result: "value",
  )
  if read-enabled(cfg: cfg) == false { return none }
  let c = cell(..args)
  handle(c, mime: "cell", ctx: get-ctx(c, cfg: cfg))
}
