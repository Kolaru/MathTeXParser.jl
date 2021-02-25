# MathTeXParser

This package tries to provide parsing for LaTeX math expression, with the end goal to allow plotting package (espcially `Makie.jl`) to render mathematical formulas.

The package is currently work in process and is riddle with bugs and missing features. We have pretty tree printing of parsed expressions though, so I guess it's overall going pretty well.

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