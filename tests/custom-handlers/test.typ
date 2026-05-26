#import "/callisto.typ"
#import "@preview/maquette:0.1.0": render-obj

#let cfg = callisto.configuration.settings
#let c = json("test-cell.json")
#let nb = (cells: (c,), metadata: (:), nbformat: 4, nbformat_minor: 5)

#let obj-handler(data, ..args) = render-obj(
  camera: (2, 3, 3),
  stroke: (color: "#000000", width: 1),
  data,
)

#callisto.render(
  nb: nb,
  new-handlers: ("model/obj": obj-handler), 
  format: ("model/obj", auto),
)
