#import "/callisto.typ"

#callisto.render(
  0,
  format: "text/html",
  nb: path("/tests/R/R.ipynb"),
)

#callisto.render(
  "plot1",
  format: "text/html",
  nb: path("/tests/julia/julia.ipynb"),
)

