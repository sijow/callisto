#import "@local/callisto:0.3.0"

#show heading: set block(above: 2em, below : 1em)

// Configure the `output` and `outputs` function to work with our notebook.
// These functions will look for any kind of cell output: results, streams,
// display items and errors.
#let (output, outputs) = callisto.config(
  // Set notebook
  nb: json("data-import-examples.ipynb"),
  // Prefer JSON output when available
  format: ("application/json", auto),
)

= Some results

For plain Python types, the Python kernel stores the "repr":

- A numeric result is stored as string: #output("some-number")

  We can convert it to an actual number in Typst: #int(output("some-number"))

- A string result is stored as quoted string: #output("some-text")

The Python `print` command produces stream outputs, which are stored as unquoted strings: #output("some-stream")


= Some formula

The notebook stores each SymPy formula in two versions: a LaTeX version and a plain text version. By default Callisto will use the LaTeX version and convert it to Typst math using mitex:

#output("some-math")

= Multiple outputs

The Callisto `output` function expects a single output, and will raise an error if several are found. The `outputs` function accepts several outputs and returns a Typst array:

#outputs("several-outputs")

= JSON outputs

Python cells can use `IPython.display.JSON` to produce an output of type JSON. With the setting `format: ("application/json", auto)` used here, Callisto will import such outputs as Typst dictionaries:

Single output: #output("json-result")

Multiple outputs: #outputs("several-json-outputs")
