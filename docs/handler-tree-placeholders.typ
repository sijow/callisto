#import "@preview/autograph:0.1.0": diagram, node, edge
#set page(width: auto, height: auto)
#diagram(
  bezier: true,
  node(<placeholder-cell>),

  node(<placeholder-function-call>),
  edge(<placeholder-cell>, <placeholder-function-call>),

  node(<placeholder-input-from-source>),
  edge(<placeholder-cell>, <placeholder-input-from-source>),

  node(<placeholder-code-cell-input>),
  edge(<placeholder-code-cell-input>, <placeholder-input-from-source>),
  edge(<placeholder-code-cell-input>, <placeholder-function-call>),

  node(<placeholder-code-cell-output>),
  edge(<placeholder-code-cell-output>, <placeholder-function-call>),

  node(<placeholder-output>),
  edge(<placeholder-output>, <placeholder-function-call>),

  node(<placeholder-inline-generic>),
  node(<placeholder-block-generic>),
  edge(<placeholder-function-call>, <placeholder-inline-generic>),
  edge(<placeholder-function-call>, <placeholder-block-generic>),
  edge(<placeholder-input-from-source>, <placeholder-block-generic>),

  node(<source-code-generic>),
  edge(<placeholder-input-from-source>, <source-code-generic>)
)
