# Tutorial 3: Exporting and Executing Code Blocks

Now instead of writing code cells in a notebook file, we want to write code blocks directly in the Typst file. We want these code blocks to be executed, and the result included in the document.

This can be done with Callisto: we can use `typst eval` to export code blocks to a notebook file, and `jupyter-nbconvert` to execute the notebook.  Callisto will automatically read the results from the exported notebook. The notebook file works like a "cache" for the execution.

Let's see in details how this works.

## A First Document with Executed Blocks

We start with a blank file `document.typ`. We must configure Callisto functions with the notebook filename we want to use and the Jupyter kernel that will execute the code blocks. To find the available kernels we can use the following command in the terminal:

```txt
$ jupyter kernelspec list
Available kernels:
  ir            /home/user/.local/share/jupyter/kernels/ir
  julia-1.11    /home/user/.local/share/jupyter/kernels/julia-1.11
  python3       /usr/share/jupyter/kernels/python3
```

In this example we have the `ir` kernel for R, the `julia-1.11` kernel for Julia and the `python3` kernel for Python. Let's configure Callisto to use the Python kernel:

```typst
#import "@preview/callisto:0.3.0"

#let (execute, stage-notebook) = callisto.config(
  nb: path("export.ipynb"),
  kernel: "python3",
)

#stage-notebook()
```

The last line prepares the data for the exported notebook.

We now need to specify which code blocks should be executed. This can be done with a show rule that selects all raw elements with a specific language tag:

```typst
#show raw.where(lang: "py-x"): execute
#show raw: set text(11pt * 0.8)
```

Make sure to use a non-standard language tag like `py-x` here, to avoid selecting Python code blocks by mistake (for example code blocks generated in the rendering of the notebook cells!).

The `#show raw: set text` line is a workaround for an [issue](https://github.com/typst/typst/issues/1331) with show rules on raw elements, to avoid the default `0.8em` scaling of raw text to be applied twice.

Now let's add code blocks in our document:

``````typst
In Python we can use `len` to get the length of a list:

```python
len([1,2,3])
```

Let's try it:

```py-x
len([1,2,3])
```
``````

The first code block has tag `python` so it won't be touched by the show rule. The second block, with tag `py-x`, will be executed.

## Commands for Export and Execution

Our first document is complete. Let's export the `py-x` code blocks to a Jupyter notebook. We use a `typst eval` command to find the notebook data that was prepared by `#stage-notebook()`:

```bash
typst eval --input callisto-export=true --in document.typ \
    'query(<notebook>).first().value' > export.ipynb
```

This creates the notebook file `export.ipynb`. To execute the notebook, we use the nbconvert tool from our Jupyter installation:

```bash
jupyter-nbconvert --to notebook --execute --inplace export.ipynb
```

That's it! The Typst preview should now show the source and result of the executed code block.

### Automatic Export and Execution

We don't want to run `typst eval` and `jupyter-nbconvert` manually every time we change the code blocks... Let's write a Makefile for this:

```makefile
EVAL := typst eval --input callisto-export=true --in document.typ

default: export execute

export:
	$(EVAL) "query(<notebook>).first().value" > export.ipynb

execute:
	jupyter-nbconvert --to notebook --execute --inplace export.ipynb

watch:
	watchexec -w . -f '**/*.typ' make export execute

.PHONY: default export execute watch
```

Putting this in a file called `Makefile` next to our Typst document, we can then run the `typst eval` and `jupyter-nbconvert` commands by simply typing `make` in the terminal.

Note that we also defined a `watch` target in the Makefile: if you have the [`watchexec`](https://watchexec.github.io/) tool installed, you can type `make watch` to monitor the project directory for changes to any Typst file and run `typst eval` and `jupyter-nbconvert` automatically.

See the [reference manual](callisto-manual.pdf#nameddest=makefile) for an example Justfile if you prefer to use `just` instead of `make`.

## A Larger Example

The following example illustrates some more features:

- Code blocks can be selected using a Typst label instead of the language tag.

- A Typst label can also be used as cell specification, for example to render all cells that were exported from code blocks with the given label.

- The `export` function can be used to include in the exported notebook some "setup" code that should be executed silently, without the source or execution result appearing in the final document.

- The `evaluate` function can be used to export some code and get a single output from the result. One can think of `execute` as `export` + `Cell` while `evaluate` is like `export` + `output`.

- To include a cell header in the notebook cell produced by `export`/`execute`/`evaluate` we can pass it with the `cell-header` setting or write the header directly in the raw element.

Here are these features in action:


``````typ
#import "@preview/callisto:0.3.0"

#let (render, In, Out, execute, export, evaluate, stage-notebook) = callisto.config(
  nb: path("export.ipynb"),
  kernel: "python3",
)

#stage-notebook()

#show <exec>: execute
#show raw: set text(11pt * 0.8)

// Setup code, specifying cell header with a dict
#export(`a = 2`, cell-header: (label: "setup"))

Executed block, rendering only the output:
```python
#| echo: false
a + 3
```<exec>

Executed block, rendering only the source:
```python
#| label: calc
#| output: false
a + 3
```<exec>

Let's render the output here:
#Out("calc")

Let's get just a result, inline: #evaluate(`a + 4`).

Here is the setup code:
#In("setup")

And here are all the code blocks passed to `execute`:
#render(<exec>, input: true, output: false)

``````

## Next

See the [reference manual](callisto-manual.pdf#nameddest=export-and-execution) for more information on the export/execute functionality, including an example where several notebooks are exported from the same Typst document.
