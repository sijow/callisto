// This file exports the main functions and defines all the aliases of `cells`,
// `sources`, `outputs`, `render` and `streams`.
//
// It also pre-configures the `default-handlers` and `named-themes` parameters
// of all exposed functions (doing this here avoids circular import issues).
//
// It also exports modules and utility functions that should be available
// to users or theme developers.

#import "themes/themes.typ": themes
#import "lib/configuration.typ"
#import "lib/util.typ"
#import "lib/reading/reading.typ"
#import "lib/theming.typ"
#import "lib/rendering.typ"
#import "lib/handlers.typ": default as default-handlers
#import "lib/ansi.typ"
#import "lib/exporting.typ"
#import "lib/header-pattern.typ"

#import util: handle

#let cells = reading.cell.cells.with(
  default-handlers: default-handlers,
  named-themes: themes,
)
#let cell = reading.cell.cell.with(
  default-handlers: default-handlers,
  named-themes: themes,
)

#let sources = reading.source.sources.with(
  default-handlers: default-handlers,
  named-themes: themes,
)
#let source = reading.source.source.with(
  default-handlers: default-handlers,
  named-themes: themes,
)

#let outputs = reading.output.outputs.with(
  default-handlers: default-handlers,
  named-themes: themes,
)
#let output = reading.output.output.with(
  default-handlers: default-handlers,
  named-themes: themes,
)

#let displays(..args)     = outputs(..args, output-type: "display")
#let results(..args)      = outputs(..args, output-type: "result")
#let errors(..args)       = outputs(..args, output-type: "error")
#let stream-items(..args) = outputs(..args, output-type: "stream")

#let display(..args)     = output(..args, output-type: "display")
#let result(..args)      = output(..args, output-type: "result")
#let error(..args)       = output(..args, output-type: "error")
#let stream-item(..args) = output(..args, output-type: "stream")

#let streams = reading.stream.streams.with(
  default-handlers: default-handlers,
  named-themes: themes,
)
#let stream = reading.stream.stream.with(
  default-handlers: default-handlers,
  named-themes: themes,
)

#let render = rendering.render.with(
  default-handlers: default-handlers,
  named-themes: themes,
)
#let Cell = rendering.Cell.with(
  default-handlers: default-handlers,
  named-themes: themes,
)
#let In = rendering.In.with(
  default-handlers: default-handlers,
  named-themes: themes,
)
#let Out = rendering.Out.with(
  default-handlers: default-handlers,
  named-themes: themes,
)

#let export = exporting.export.with(
  default-handlers: default-handlers,
  named-themes: themes,
)
#let make-notebook = exporting.make-notebook.with(
  default-handlers: default-handlers,
  named-themes: themes,
)
#let stage-notebook = exporting.stage-notebook.with(
  default-handlers: default-handlers,
  named-themes: themes,
)
#let execute = exporting.execute.with(
  default-handlers: default-handlers,
  named-themes: themes,
)
#let evaluate = exporting.evaluate.with(
  default-handlers: default-handlers,
  named-themes: themes,
)

#let config(..args) = {
  if args.pos().len() > 0 {
    panic("unexpected positional argument(s): " + repr(args.pos()))
  }
  // Validate named arguments
  let (cfg,) = configuration.parse-main-args(..args)
  // Preconfigure functions with user args, not with cfg as cfg includes all
  // settings (using defaults for values not specified by the user) while we
  // might want functions to be able to have defaults different from the global
  // common.settings defaults.
  return (
    template: theming.resolve(cfg.theme, cfg.named-themes).template,
    cells:            cells           .with(..args),
    cell:             cell            .with(..args),
    outputs:          outputs         .with(..args),
    output:           output          .with(..args),
    displays:         displays        .with(..args),
    display:          display         .with(..args),
    results:          results         .with(..args),
    result:           result          .with(..args),
    stream-items:     stream-items    .with(..args),
    stream-item:      stream-item     .with(..args),
    errors:           errors          .with(..args),
    error:            error           .with(..args),
    streams:          streams         .with(..args),
    stream:           stream          .with(..args),
    sources:          sources         .with(..args),
    source:           source          .with(..args),
    render:           render          .with(..args),
    Cell:             Cell            .with(..args),
    In:               In              .with(..args),
    Out:              Out             .with(..args),
    export:           export          .with(..args),
    make-notebook:    make-notebook   .with(..args),
    stage-notebook:   stage-notebook  .with(..args),
    execute:          execute         .with(..args),
    evaluate:         evaluate        .with(..args),
  )
}
// Preconfigure named-themes in a way that they are included in
// the 'args' of the above config definition, and without introducing another
// exported binding in this module.
#let config = config.with(named-themes: themes)
