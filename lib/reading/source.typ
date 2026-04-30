#import "/lib/configuration.typ": parse-main-args, read-enabled
#import "/lib/ctx/ctx.typ": get-ctx
#import "/lib/util.typ"
#import "common.typ": final-result, placeholder-enabled, get-placeholder
#import "cell.typ": cells, cell

// Return the lang of the cell's source
#let _cell-lang(cell, ctx: none) = (
  markdown: "markdown",
  raw: ctx.raw-lang,
  code: ctx.lang,
).at(cell.cell_type)

#let _cell-source(cell, cell-spec: none, cfg: none) = {
  let ctx = get-ctx(cell, cell-spec: cell-spec, cfg: cfg)
  let cell-lang = _cell-lang(cell, ctx: ctx)
  let value = raw(cell.source, lang: cell-lang, block: true)
  return final-result((text: cell.source), value, ctx: ctx)
}

// Extract the 'source' field from cells as raw blocks.
#let sources(..args) = {
  let (cell-spec, cfg) = parse-main-args(..args)
  if read-enabled(cfg: cfg) == false { return none }
  return cells(..args).map(_cell-source.with(cell-spec: cell-spec, cfg: cfg))
}

// Get a single cell's source
#let source(..args) = {
  let (cell-spec, cfg) = parse-main-args(..args)

  // Get single cell, taking 'keep' into account
  let c = if placeholder-enabled(cfg: cfg) {
    cell(..args, placeholder: "placeholder")
  } else {
    cell(..args, placeholder: false)
  }

  if c == "placeholder" {
    let ctx = get-ctx(none, cell-spec: cell-spec, cfg: cfg)
    return get-placeholder(mime: "placeholder-source-func", ctx: ctx)
  }

  return _cell-source(c, cell-spec: cell-spec, cfg: cfg)
}
