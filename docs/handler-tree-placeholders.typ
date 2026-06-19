#import "@preview/autograph:0.1.0": diagram, node, edge
#set page(width: auto, height: auto)
#diagram(
  bezier: true,
  node(<placeholder-Cell>),

  node(<placeholder-function-call>),
  edge(<placeholder-Cell>, <placeholder-function-call>),

  node(<placeholder-input-from-source>),
  edge(<placeholder-Cell>, <placeholder-input-from-source>),

  node(<placeholder-In>),
  edge(<placeholder-In>, <placeholder-input-from-source>),
  edge(<placeholder-In>, <placeholder-function-call>),

  node(<placeholder-Out>),
  edge(<placeholder-Out>, <placeholder-function-call>),

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
