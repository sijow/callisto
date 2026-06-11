#import "/callisto.typ"

#show heading: set block(below: 1em)
#show heading.where(level: 1): set text(14pt)
#show heading.where(level: 2): set text(12pt)
#set heading(numbering: "1.")

// Work around https://github.com/typst/typst/issues/1331
#show raw: set text(8.8pt)

#let (
  Cell,
  In,
  Out,
  display,
  stage-notebook,
  execute,
  evaluate,
) = callisto.config(
  nb: path("export.ipynb"),
  kernel: "python3",
)

// Expose the exported notebook as labelled metadata for `typst query`
#stage-notebook()

#show raw.where(lang: "py-x"): execute

```py-x
a = 1
```<a>

#Out(<a>)

#context display(query(<a>).first())

#Cell(
  ```py-x
  b = 2
  ```
)

```py-x
a = 1
```<b>

1+1: #evaluate(`1+1`)

1+1: #evaluate(`1+1`, placeholder: [(computation)])

1+1: #evaluate(`1+1`, placeholder: text.with(red))
