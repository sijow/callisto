#import "reading/cell.typ": cells, cell
#import "reading/common.typ": placeholder-enabled, get-placeholder
#import "util.typ": handle
#import "configuration.typ": parse-main-args, read-enabled
#import "ctx/ctx.typ": get-ctx

// Render the specified cells according to the settings (see common.typ).
#let render(..args) = {
  // Make sure the handlers are called with a context with result: "value"
  let (cell-spec, cfg) = parse-main-args(
    ..args,
    apply-theme: true,
    result: "value",
  )
  if read-enabled(cfg: cfg) == false { return none }
  for c in cells(..args) {
    handle(c, mime: "cell", ctx: get-ctx(c, cell-spec: cell-spec, cfg: cfg))
  }
}

// Helper for rendering from a single cell
#let _render-cell(..args, placeholder-mime: none) = {
  // Make sure the handlers are called with a context with result: "value"
  let (cell-spec, cfg) = parse-main-args(
    ..args,
    apply-theme: true,
    result: "value",
  )

  let cs = cells(..args)

  if cs.len() == 0 and placeholder-enabled(cfg: cfg) {
    let ctx = get-ctx(none, cell-spec: cell-spec, cfg: cfg)
    return get-placeholder(mime: placeholder-mime, ctx: ctx)
  }
  
  if cs.len() != 1 {
    panic("expected 1 cell, found " + str(cs.len()) +
      ". Cell spec was " + repr(cell-spec))
  }

  let c = cs.first()
  handle(c, mime: "cell", ctx: get-ctx(c, cell-spec: cell-spec, cfg: cfg))
}

// Render a single cell
#let Cell(..args) = _render-cell(
  ..args,
  placeholder-mime: "placeholder-cell",
)
// Render a single code cell's input
#let In(..args) = _render-cell(
  ..args,
  cell-type: "code",
  input: true,
  output: false,
  placeholder-mime: "placeholder-code-cell-input",
)
// Render a single code cell's output
#let Out(..args) = _render-cell(
  ..args,
  cell-type: "code",
  input: false,
  output: true,
  placeholder-mime: "placeholder-code-cell-output",
)
