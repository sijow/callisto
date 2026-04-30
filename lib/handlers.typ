#import "@preview/based:0.2.0": base64
#import "@preview/cmarker:0.1.8"
#import "@preview/mitex:0.2.7"

#import "util.typ": handle
#import "reading/rich-object.typ"
#import "reading/stream.typ"
#import "reading/error.typ"
#import "reading/notebook.typ"
#import "reading/output.typ": outputs, all-output-types
#import "header-pattern.typ"
#import "ansi.typ"
#import "latex.typ"

// A handler is a function called to process a value such as a cell's source,
// a cell output such as a PNG image, or even a whole cell.
// Each handler is associated with a "MIME type", which is really an arbitrary
// string used to identify the kind of value being processed: Rich items,
// which can be available in multiple formats, are rendered by calling the
// handler on the selected format. In this case the type is a real MIME type,
// for example "image/png". Other handlers use dummy MIME types such as
// "code-cell" (without slash character).
//
// Handlers are always called with a positional argument for the data to
// render, and a 'ctx' keyword argument for contextual data. Some handlers also
// take additional arguments:
// 
// - Image handlers must accept an 'alt' argument.
// 
// - Math handlers must accept a 'block' argument (true for block equations).
//
// - The "source-code-generic" handler (used by the default raw cell and
//   code input handlers) takes a 'lang' argument.
//
// - The "attachment" handler gets 'metadata', 'type' and
//   'subhandler-args' arguments.
//
// - The "placeholder-function" and "placeholder-cell-source" handlers (used
//   by some default placeholder handlers) take a 'func' argument.
//
// When defining a handler, the user can choose to add an '..args' sink if
// they don't care about extra arguments, or omit this sink if they prefer to
// see an error when an unknown argument is passed.
//
// To call a handler, use the 'handle' function from common.typ.

// Generic image handler that supports image path and image bytes, used by
// several others to actually render the image.
#let image-generic(data, ctx: none, ..args) = {
  if type(data) == str {
    data = handle(data, mime: "path", ctx: ctx, ..args)
  }
  std.image(data, ..args)
}

// Handler for images in Markdown. Such images can be specified by a
// path of the form "attachment:name" where 'name' refers to a cell attachment.
// As all image handlers, this handler can receive extra arguments such as
// 'alt' that must be forwarded to the subhandler.
#let image-markdown(path, ctx: none, ..args) = {
  let (handlers, cell) = ctx
  if path.starts-with("attachment:") {
    let name = path.trim("attachment:", at: start)
    let attachments = cell.at("attachments", default: (:))
    if name in attachments {
      // Get data dict (keyed by MIME type) for this attachment
      let data = attachments.at(name)
      handle(
        data,
        mime: "attachment",
        ctx: ctx,
        metadata: (path: path),
        subhandler-args: args,
      )
    } else {
      panic("cell attachment " + name + " not found")
    }
  } else {
    handle(path, mime: "image-generic", ctx: ctx, ..args)
  }
}

// Handler for base64-encoded images
#let image-base64(data, ctx: none, ..args) = {
  let data-bytes = base64.decode(data.replace("\n", ""))
  handle(data-bytes, mime: "image-generic", ctx: ctx, ..args)
}

// Handler for text-encoded images, for example svg+xml
#let image-text(data, ctx: none, ..args) = {
  handle(bytes(data), mime: "image-generic", ctx: ctx, ..args)
}

// Helper function to guess the SVG data encoding based on the first characters
// in the given data string.
#let _encoded-svg-mime(data) = {
  // base64 encoded version of:     "<?xml "                        "<sv"
  if data.starts-with("PD94bWwg") or data.starts-with("PHN2") {
    return "image-base64"
  } else if data.starts-with("<?xml ") or data.starts-with("<svg") {
    return "image-text"
  }
  panic("unrecognized svg+xml data")
}

// Smart svg+xml handler that handles both text and base64 data
#let image-svg-xml(data, ctx: none, ..args) = {
  let mime = _encoded-svg-mime(data)
  handle(data, mime: mime, ctx: ctx, ..args)
}

// Handler for Markdown markup to be rendered inline, without block wrapper.
// (This is useful for Markdown that must be included seamlessly in the flow
// of the document, so that e.g. spacing around headings can be configured
// without interference from a container block, see
// https://github.com/knuesel/callisto/issues/13 )
#let markdown-generic(data, ctx: none, ..args) = cmarker.render(
  data,
  math: handle.with(mime: "math-markdown", ctx: ctx),
  scope: (
    // Note that for images specified by disk path, the default image-generic
    // handler uses the path handler to resolve the path. Users must define
    // that handler to have working path resolution (unfortunately this
    // probably won't change when Typst gets a 'path' type as that won't give
    // access to other files in the notebook directory, but the path type will
    // make it easier to define the path handler).
    image: handle.with(mime: "image-markdown", ctx: ctx),
  ),
  heading-labels: "jupyter",
  h1-level: ctx.h1-level,
  ..args,
)

// Handler for Markdown outputs
#let text-markdown(data, ctx: none, ..args) = {
  block(handle(data, mime: "markdown-generic", ctx: ctx, ..args))
}

// Handler for LaTeX markup
#let text-latex(data, ctx: none, ..args) = block(mitex.mitext(data, ..args))

// Handler for rendering text that includes ANSI escape sequences.
#let text-ansi-generic(data, ctx: none, ..args) = {
  let (process, ..render-args) = ctx.ansi
  ansi.render(data, ..render-args)
}

// Handler for text to render as console output, in particular text that can
// include ANSI escape sequences for colors, etc.
#let text-console-block(data, ctx: none, ..args) = {
  let process = ctx.ansi.process

  if process == auto {
    process = data.contains(ansi.escape-regex)
  }

  if process in (false, "strip") {
    if process == "strip" {
      data = ansi.strip(data)
    }
    return raw(block: true, lang: "txt", data)
  }

  if process != true {
    panic("invalid ansi.process value: " + repr(process))
  }

  let renderer = handle.with(mime: "text-ansi-generic", ctx: ctx)

  // Pass args here (could be used e.g. to change the template)
  ansi.console-block(data, renderer: renderer, ..args)
}

// Handler for simple text
#let text-plain(data, ctx: none, ..args) = data

// Handler for LaTeX equations
#let math-generic(data, ctx: none, ..args) = mitex.mitex(data, ..args)

// Handler for LaTeX equations in Markdown cells.
#let math-markdown(data, ctx: none, ..args) = {
  let txt = data
  // If the preamble is set, we must use it and remove definitions from the
  // math item itself to avoid duplicates.
  if ctx.latex-preamble != none {
    // Remove definitions from this item's body and prepend all defs
    txt = ctx.latex-preamble + txt.replace(latex.definition-regex(), "")
  }
  // Render equation with the latex math handler
  return handle(txt, mime: "math-generic", ctx: ctx, ..args)
}

// Handler for attachments, where data is a dict keyed by MIME types, and
// metadata can be a simple metadata dict or a dict with metadata dicts keyed
// by MIME types. If given, the subhandler args will be forwarded to
// the subhandler called by this handler to handle a particular format.
#let attachment(
  data,
  ctx: none,
  metadata: none,
  subhandler-args: none,
  ..args,
) = {
  // Make item
  let item = (data: data, metadata: metadata)
  // Update context item desc
  ctx.item-desc = (index: none, type: "attachment")
  // Get dict with normalized data for this item
  let preprocessed = rich-object.preprocess(item, ctx: ctx)
  if preprocessed == none { return none }
  return rich-object.process(
    preprocessed,
    ctx: ctx,
    handler-args: subhandler-args,
  )
}

// Default handler for path: raise an error
#let path-handler(cell, ctx: none, ..args) = {
  panic("\"path\" handler undefined. You can define it with callisto.config(..., handlers: (path: (x, ..args) => read(x, encoding: none)))")
}

// Generic stream handler
#let stream-generic(data, ctx: none, ..args) = data

// Handler for stream output items
#let stream(item, ctx: none, ..args) = {
  let mime = (
    "stdout": "stream-stdout",
    "stderr": "stream-stderr",
    "all": "stream-merged",
  ).at(item.name)
  handle(item.text, mime: mime, ctx: ctx, ..args)
}

// Handler for error output items
#let error(item, ctx: none, ..args) = item.evalue

// Handler for rich output items (display and result)
#let rich-output-generic(data, ctx: none, ..args) = {
  rich-object.process(data, ctx: ctx, ..args)
}

// Handler for any type of code cell output
#let output(data, ctx: none, ..args) = {
  handle(data, mime: ctx.item-desc.type, ctx: ctx, ..args)
}

// Handler for source code
#let source-code-generic(txt, ctx: none, lang: none, ..args) = {
  // Ensure the source has at least one (possibly empty) line
  // (without this the raw block looks weird for empty cells)
  if txt == "" {
    txt = "\n"
  }
  raw(txt, lang: lang, block: true)
}

// Handler for raw cell
#let raw-cell(cell, ctx: none, ..args) = {
  handle(
    cell.source,
    mime: "source-code-generic",
    ctx: ctx,
    lang: ctx.raw-lang,
    ..args,
  )
}

// Handler for Markdown cell
#let markdown-cell(cell, ctx: none, ..args) = {
  parbreak()
  handle(cell.source, mime: "markdown-generic", ctx: ctx, ..args)
  parbreak()
}

// Handler for code cell input
#let code-cell-input(cell, ctx: none, ..args) = {
  handle(
    cell.source,
    mime: "source-code-generic",
    ctx: ctx,
    lang: ctx.lang,
    ..args,
  )
}

// Handler for code cell output
#let code-cell-output(cell, ctx: none, ..args) = {
  // Get outputs with user config, but override 'result' to get just the values
  outputs(cell, ..ctx.cfg, result: "value").join()
}

// Handler for code cell
#let code-cell(cell, ctx: none, ..args) = {
  if ctx.input {
    handle(cell, mime: "code-cell-input", ctx: ctx, ..args)
  }
  if ctx.output {
    handle(cell, mime: "code-cell-output", ctx: ctx, ..args)
  }
}

// Handler for cells
#let cell(cell, ctx: none, ..args) = {
  // Delegate to cell-type-specific handler
  handle(cell, mime: cell.cell_type + "-cell", ctx: ctx, ..args)
}

// Check if the cell spec is a raw element
#let _is-raw-spec(spec) = type(spec) == content and spec.func() == raw

// Return a string that summarizes the given cell spec
#let _cell-spec-summary(spec) = {
  if _is-raw-spec(spec) {
    let txt = spec.text.trim()
    let truncated = false
    let lines = txt.split("\n")
    if lines.len() > 1 {
      txt = lines.first()
      truncated = true
    }
    let clusters = txt.clusters()
    if clusters.len() >= 50 {
      txt = clusters.slice(0, count: 49).join()
      truncated = true
    }
    if truncated {
      txt += "…"
    }
    return "`" + txt + "`"
  }
  return repr(spec)
}

// Return true if the placeholder is likely for block content
#let _is-placeholder-likely-block(ctx: none) = {
  if _is-raw-spec(ctx.cell-spec) {
    return ctx.cell-spec.block
  }
  return true
}

// Return placeholder for rendered code cell input using the raw spec
#let _placeholder-input-from-raw-spec(ctx: none, ..args) = {
  let source = ctx.cell-spec.text
  if not ctx.keep-cell-header {
    // Remove cell header
    let pattern = ctx.cell-header-pattern
    source = header-pattern.parse-text(source, pattern: pattern).code
  }
  return handle(
    source,
    mime: "placeholder-input-from-source",
    ctx: ctx,
    ..args,
  )
}

// Handler that shows the given block in generic placeholder style
#let placeholder-generic-block(data, ctx: none, ..args) = block(
  stroke: (dash: "dashed"),
  inset: 1em,
  data,
)

// Handler that shows the given inline content in generic placeholder style
#let placeholder-generic-inline(data, ctx: none, ..args) = box(
  stroke: (dash: "dashed"),
  inset: (x: 0.5em),
  outset: (y: 0.5em),
  data,
)

// Placeholder that renders the data in a generic placeholder style.
// This implementation tries to guess if the content should be rendered
// inline or as block.
#let placeholder-generic(data, ctx: none, ..args) = {
  if _is-placeholder-likely-block(ctx: ctx) {
    handle(data, mime: "placeholder-generic-block", ctx: ctx, ..args)
  } else {
    handle(data, mime: "placeholder-generic-inline", ctx: ctx, ..args)
  }
}

// Placeholder that shows `func(spec)` where func is given as argument and
// spec is a summary of a the cell specification.
#let placeholder-function-call(func, ctx: none, ..args) = {
  let txt = func + "(" + _cell-spec-summary(ctx.cell-spec) + ")"
  let elem = raw(txt, block: _is-placeholder-likely-block(ctx: ctx))
  handle(elem, mime: "placeholder-generic", ctx: ctx, ..args)
}

// Placeholder for code cell input rendering using source (from raw spec)
#let placeholder-input-from-source(source, ctx: none, ..args) = {
  // Make new raw element with canonical lang (the lang on the raw-spec
  // element might be a "fake" value like "python-x" for selection in a show
  // rule, and in any case reusing in the output the value used for show rule
  // the selector would lead to infinite recursion).
  // For code cell input rendering we render as block even if the raw spec
  // was inline (e.g. from #execute(`...`)).
  let new-elem = raw(
    block: true,
    lang: ctx.lang,
    source,
  )
  return handle(new-elem, mime: "placeholder-generic-block", ctx: ctx, ..args)
}

// Placeholder for an output item
#let placeholder-output(data, ctx: none, ..args) = {
  let func = if ctx.output-type in all-output-types {
    ctx.output-type
  } else {
    "output"
  }
  handle(func, mime: "placeholder-function-call", ctx: ctx, ..args)
}

// Placeholder for rendered code cell input (e.g. for In() calls)
#let placeholder-code-cell-input(data, ctx: none, ..args) = {
  if _is-raw-spec(ctx.cell-spec) {
    // Source is available!
    return _placeholder-input-from-raw-spec(ctx: ctx, ..args)
  }
  return handle("In", mime: "placeholder-function-call", ctx: ctx, ..args)
}

// Placeholder for rendered code cell output (e.g. for Out() calls)
#let placeholder-code-cell-output(data, ctx: none, ..args) = {
  handle("Out", mime: "placeholder-function-call", ctx: ctx, ..args)
}

// Placeholder for a rendered code cell (e.g. Cell() call).
// This implementation shows the cell source if available from raw spec, or
// a representation of the function call otherwise.
#let placeholder-code-cell(data, ctx: none, ..args) = {
  if _is-raw-spec(ctx.cell-spec) {
    // Source is available!
    return _placeholder-input-from-raw-spec(ctx: ctx, ..args)
  }
  return handle("Cell", mime: "placeholder-function-call", ctx: ctx, ..args)
}

// Placeholder for a rendered cell.
#let placeholder-cell(data, ctx: none, ..args) = {
  if _is-raw-spec(ctx.cell-spec) {
    // Raw spec implies that this is a code cell
    return handle(data, mime: "placeholder-code-cell", ctx: ctx, ..args)
  }
  return handle("Cell", mime: "placeholder-function-call", ctx: ctx, ..args)
}

// Default handlers
#let default = (
  // Handlers for specific formats of rich items (outputs and cell attachments)
  "image/svg+xml": image-svg-xml,
  "image/png"    : handle.with(mime: "image-base64"),
  "image/jpeg"   : handle.with(mime: "image-base64"),
  "image/gif"    : handle.with(mime: "image-base64"),
  "text/markdown": text-markdown,
  "text/latex"   : text-latex,
  "text/plain"   : text-plain,
  // Generic image handlers
  "image-generic": image-generic, // base handler used by others
  "image-base64" : image-base64,  // base64 encoded image
  "image-text"   : image-text,    // text encoded image
  "image-markdown": image-markdown, // image in Markdown
  // Handlers for output items
  "rich-output-generic": rich-output-generic,
  "display": handle.with(mime: "rich-output-generic"),
  "result": handle.with(mime: "rich-output-generic"),
  "error": error,
  "stream-generic": stream-generic,
  "stream-stdout": handle.with(mime: "stream-generic"),
  "stream-stderr": handle.with(mime: "stream-generic"),
  "stream-merged": handle.with(mime: "stream-generic"), // used when both streams are merged
  "stream": stream, // called before stream-type-specific handler
  "output": output, // called before output-type-specific handler
  // Handlers for Markdown as part of the document flow
  "markdown-generic": markdown-generic, // returns inline content
  // Handlers for LaTeX math
  "math-generic": math-generic, // base handler for math
  "math-markdown": math-markdown, // Markdown math
  // Handlers for cell rendering
  "raw-cell": raw-cell,
  "markdown-cell": markdown-cell,
  "code-cell-input": code-cell-input,
  "code-cell-output": code-cell-output,
  "code-cell": code-cell,
  "cell": cell, // called before the cell-type-specific handler
  // Placeholders
  "placeholder-generic-inline": placeholder-generic-inline,
  "placeholder-generic-block": placeholder-generic-block,
  "placeholder-generic": placeholder-generic,
  "placeholder-function-call": placeholder-function-call,
  "placeholder-input-from-source": placeholder-input-from-source,
  "placeholder-output": placeholder-output,
  "placeholder-code-cell-input": placeholder-code-cell-input,
  "placeholder-code-cell-output": placeholder-code-cell-output,
  "placeholder-code-cell": placeholder-code-cell,
  "placeholder-cell": placeholder-cell,
  "placeholder-cell-func": none,
  "placeholder-source-func": none,
  // Other handlers
  "text-ansi-generic": text-ansi-generic,
  "text-console-block": text-console-block,
  "source-code-generic": source-code-generic,
  "attachment": attachment,
  "path": path-handler,
)
