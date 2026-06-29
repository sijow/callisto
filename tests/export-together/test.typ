#import "/callisto.typ"

#let (execute: execute-a,) = callisto.config(
  nb: path("export-python-a.ipynb"),
  kernel: "python3",
  export-name: "python-a",
)
#let (execute: execute-b,) = callisto.config(
  nb: path("export-python-b.ipynb"),
  kernel: "python3",
  export-name: "python-b",
)

// Stage all exported notebooks under <notebook> label
#context for name in callisto.export-names() {
  callisto.stage-notebook(export-name: name, export-label: <notebook>)
}

#execute-a(`a = 1`)
#execute-b(`a = 10`)
#execute-a(`a += 3; print(a)`)
#execute-b(`print(a)`)

