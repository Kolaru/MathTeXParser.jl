# MathTeXParser

This package tries to provide parsing for LaTeX math expression, with the end goal to allow plotting package (espcially `Makie.jl`) to render mathematical formulas.

Note that this package does not do any render or layouting, it only extract the meaning of LaTeX math expression into an abstract syntax tree.

The package is currently work in process and is riddle with bugs and missing features. We have pretty tree printing of parsed expressions though, so I guess it's overall going pretty well.

This works is based on `mathtext`, matplotlib LaTeX engine.

# Currently supported

- `(:decorated, core, subscript, superscript)` Elements "decorated" with subscript and superscript
- `(:spaced_symbol, symbol)` Spaced symbols (binary symbols, relational symbols and arrows)
- `(:punctuation, symbol)` Punctuation (I don't think they are treated differently from other symbols in math mode though)
- `(:underover, symbol, under, over)` Symbols or function with decoration over and/or under them (sum, limits and the like, except integral)
- `(:integral, symbol, under, over)` Integrals (no idea why it is parsed separately by matplotlib)
- `(:function, name)` Named functions (like `sin`)
- `(:space, width)` Fixed space commands (the `\quad` family)
- `(:group, elements...)` Groups defined with braces, possibly nested
- `(:delimited, left_delimiter, content, right_delimiter)` Groups with automatically sized delimiters
- `(:accent, symbol, core)` and `(:wide_accent, symbol, core)` Narrow and wide accents
- `(:mathfont, fontstyle, content)` Mathematical font commands (`\mathbb` and the like). `fontstyle` omits the starting `\math` (e.g. it is `bb` for a `\mathbb` command).
- `(:frac, numerator, denumerator)` Fraction
- `(:symbol, symbol_command)` Generic symbol (currently any command not recognized as one of the above fallback to this)

# Example

```julia
julia> parse(TeXExpr, raw"\sum^{a_2}_{b + 2} \left[ x + y \right] \Rightarrow \sin^2 x_k")
group
├─ overunder
│  ├─ symbol
│  │  └─ "\\sum"
│  ├─ group
│  │  ├─ 'b'
│  │  ├─ spaced_symbol
│  │  │  └─ "+"
│  │  └─ 2
│  └─ decorated
│     ├─ 'a'
│     ├─ 2
│     └─ ""
├─ delimited
│  ├─ "["
│  ├─ group
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
│  ├─ ""
│  └─ 2
└─ decorated
   ├─ 'x'
   ├─ 'k'
   └─ ""
```