#import "/callisto.typ"

#let (output,) = callisto.config(nb: path("../../docs/example.ipynb"))
#let my-table(n) = table(columns: n, ..range(n).map(str))
#my-table(int(output("calc")))

#let (evaluate, stage-notebook) = callisto.config(
  nb: path("export.ipynb"),
  kernel: "python3",
)
#stage-notebook()

Here's a table with 5 columns:
#evaluate(`2+3`, transform: x => my-table(int(x)))
