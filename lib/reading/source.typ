#import "/lib/configuration.typ": parse-main-args, read-enabled
#import "/lib/ctx/ctx.typ"
#import "common.typ": final-result
#import "cell.typ": cells, cell

// Return the lang of the cell's source
#let _cell-lang(cell, ctx: none) = (
  markdown: "markdown",
  raw: ctx.raw-lang,
  code: ctx.lang,
).at(cell.cell_type)

#let _cell-source(cell, cfg: none) = {
  let ctx = ctx.get-ctx(cell, cfg: cfg)
  let cell-lang = _cell-lang(cell, ctx: ctx)
  let value = raw(cell.source, lang: cell-lang, block: true)
  return final-result((text: cell.source), value, ctx: ctx)
}

// Extract the 'source' field from cells as raw blocks.
#let sources(..args) = {
  let (cell-spec, cfg) = parse-main-args(..args)
  if read-enabled(cfg: cfg) == false { return none }
  return cells(..args).map(_cell-source.with(cfg: cfg))
}

// Get a single cell's source
#let source(..args) = {
  let (cfg,) = parse-main-args(..args)
  if read-enabled(cfg: cfg) == false { return none }
  return _cell-source(cell(..args), cfg: cfg)
}
