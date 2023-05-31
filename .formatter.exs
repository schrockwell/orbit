# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  export: [
    locals_without_parens: [
      route: 2,
      route: 3,
      group: 1,
      middleware: 1,
      middleware: 2
    ]
  ]
]
