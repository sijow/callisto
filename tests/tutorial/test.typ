#import "/callisto.typ"

#let (output, export, execute, evaluate, stage-notebook, Out) = callisto.config(
  nb: path("export.ipynb"),
  kernel: "python3",
)
#stage-notebook()

#export(
  ```
  #| label: pandas-setup
  import pandas as pd
  pd.options.display.float_format = '{:.2f}'.format
  ```
)

The square of 3 is #evaluate(`3+3`).

The square of 3 is #evaluate(`3+3`, cell-header: (label: "square")).

Recall that the square of 3 is #output("square").

#show raw.where(lang: "py-x"): execute
#show raw: set text(11pt * 0.8)

```py-x
import random
random.randint(0, 6)
```

Executed block, rendering only the output:
```py-x
#| echo: false
2 + 3
```

Executed block, rendering only the source:
```py-x
#| label: calc
#| output: false
2 + 3
```

Showing the output here:
#Out("calc")

#show <exec>: execute

```python
2 + 3
```<exec>

```python
2 + 4
```<exec>


#show <x>: evaluate

The square of 3 is `3*3`<x>.

// Make table with n columns holding numbers 0 to n-1
#let my-table(n) = table(columns: n, ..range(n).map(str))

// Configure output function for example.ipynb, and name it output-ex
#let (output: output-ex,) = callisto.config(nb: path("/docs/example.ipynb"))

// Use output of "calc" cell for the number of columns
#my-table(int(output-ex("calc")))


#evaluate(`2+3`, transform: x => my-table(int(x)))
