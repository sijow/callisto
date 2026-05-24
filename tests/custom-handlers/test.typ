#import "/callisto.typ"
#import "@preview/maquette:0.1.0": render-obj

#let cfg = callisto.configuration.settings
#let c0 = json("test-cell.json")
#let c = callisto.reading.notebook.preprocess-cell(c0, index: 0, cfg: cfg)

#let obj-handler(data, ..args) = render-obj(
  camera: (2, 3, 3),
  stroke: (color: "#000000", width: 1),
  data,
)

#callisto.render(
  c,
  new-handlers: ("model/obj": obj-handler), 
  format: ("model/obj", auto),
)
