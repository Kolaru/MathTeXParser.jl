# MathTeXParser

This package tries to provide parsing for LaTeX math expression, with the end goal to allow plotting package (espcially `Makie.jl`) to render mathematical formulas.

Note that this package does not do any render or layouting, it only extract the meaning of LaTeX math expression into an abstract syntax tree.

The package is currently work in process and is riddle with bugs and missing features. We have pretty tree printing of parsed expressions though, so I guess it's overall going pretty well.

This works is based on `mathtext`, matplotlib LaTeX engine.

# Currently supported

- Subscript and superscript (wrapped in `:decorated` expression)
- Spaced symbols (binary symbols, relational symbols and arrows)
- Punctuation (I don't think they are treated differently from other symbols in math mode though)
- Symbols and function with decoration over and/or under them (sum, integral, limits and the like)
- Named functions (like sin)
- Fixed space commands (the `\quad` family)
- Nested groups with braces
- Nested groups with automatically sized delimiters
- Narrow and wide accents
- Mathematical font commands
- Fraction
- Generic symbol (currently any command not recognized as one of the above fallback to this)

# Example

```julia
julia> parse(TeXExpr, raw"\sum^{a_2}_{b + 2} \left[ x + y \right] \Rightarrow \sin^2 x_k")
expr
├─ overunder
│  ├─ "\\sum"
│  ├─ super
│  │  └─ group
│  │     └─ decorated
│  │        ├─ 'a'
│  │        ├─ super
│  │        │  └─ ""
│  │        └─ sub
│  │           └─ 2
│  └─ sub
│     └─ group
│        ├─ 'b'
│        ├─ spaced_symbol
│        │  └─ "+"
│        └─ 2
├─ delimited
│  ├─ "["
│  ├─ expr
│  │  ├─ 'x'
│  │  ├─ spaced_symbol
│  │  │  └─ "+"
│  │  └─ 'y'
│  └─ "]"
├─ spaced_symbol
│  └─ "\\Rightarrow"
├─ decorated
│  ├─ function
│  │  └─ "sin"
│  ├─ super
│  │  └─ 2
│  └─ sub
│     └─ ""
└─ decorated
   ├─ 'x'
   ├─ super
   │  └─ ""
   └─ sub
      └─ 'k'
```