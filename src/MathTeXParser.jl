module MathTeXParser
# Adapted from Matplotlib mathtext grammar definition
# https://github.com/matplotlib/matplotlib/blob/master/lib/matplotlib/_mathtext.py

using AbstractTrees
using CombinedParsers
import REPL.REPLCompletions: latex_symbols
import REPL: symbol_latex

export TeXExpr, parse

struct TeXExpr{T <: Tuple}
    head::Symbol
    args::T
end

TeXExpr(head, args...) = TeXExpr(head, args)

function TeXExpr(tuple::Tuple)
    head = tuple[1]
    args = []

    for arg in tuple[2:end]
        if isa(arg, Tuple)
            push!(args, TeXExpr(arg))
        # Ignore all spaces
        elseif arg != ' '
            push!(args, arg)
        end
    end

    return TeXExpr(head, Tuple(args))
end


AbstractTrees.children(texexpr::TeXExpr) = texexpr.args
AbstractTrees.printnode(io::IO, texexpr::TeXExpr) = print(io, "$(texexpr.head)")

Base.show(io::IO, texexpr::TeXExpr) = print_tree(io, texexpr, 10)

function Base.:(==)(tex1::TeXExpr, tex2::TeXExpr)
    childs1 = children(tex1)
    childs2 = children(tex2)
    
    length(childs1) != length(childs2) && return false

    return all(childs1 .== childs2)
end

# Everything is wrapped into TeXExpr after the initial parsing to tuple
# to avoid inference errors from CombinedParsers.jl
# TODO better error
Base.parse(::Type{TeXExpr}, s) = TeXExpr(parse(Sequence(1, mathexpr, AtEnd()), s))

bslash = '\\'

# Definition is forwarded to allow recursive search
atom = Either{Any}()  # Called `placeable` in matplotlib

command_char = CharIn(union('a':'z'), ('A':'Z'))

"""
    to_token(s)

Transform a string into a parser that match it as a token. For single char
string this does nothing, but for longer string it look forward to make sure
it only matches full words.
"""
function to_token(s)
    length(s) == 1 && return s
    return Sequence(2, NegativeLookahead(Sequence(s, command_char)), s)
end

split_tokens(s) = to_token.(split(s))

function to_symbol(com)
    com = convert(String, com)
    if haskey(latex_symbols, com)
        # In tis case the second argument should be a Char
        return (:symbol, first(latex_symbols[com]), com)
    else
        if length(com) == 1
            return (:symbol, first(com), symbol_latex(com))
        else
            return (:symbol, '?', com)
        end
    end
end

"""
    any_symbol(s::String)

Construct an `Either` of any of the symbol or command in the string. In addition
add the unicode char corresponding to the command if known to the `Either`.

Symbol coming from a known command have the form
    (:symbol, unicode_char, original_command)
while others have the first field.
"""
function any_symbol(s)
    commands = split(s)
    chars = [latex_symbols[com] for com in commands if haskey(latex_symbols, com)]
    
    append!(commands, chars)

    return Either(to_symbol, to_token.(commands)...)
end

# Super and subscript
superscript = Sequence(2, '^', atom)
subscript = Sequence(2, '_', atom)

# Always return the decoration in order (sub, super)
decoration = Either(
    Sequence(subscript, superscript) do (x, y)
        (:subsuper, x, y)
    end,
    Sequence(superscript, Optional(subscript, default=nothing)) do (x, y)
        (:subsuper, y, x)
    end,
    Sequence(1, subscript) do x
        (:subsuper, x, nothing)
    end
)

decorated = Sequence(atom, decoration) do (core, dec)
    (:decorated, core, dec[2], dec[3])
end

binary_operator = any_symbol(raw"""
    + * -
    \pm             \sqcap                   \rhd
    \mp             \sqcup                   \unlhd
    \times          \vee                     \unrhd
    \div            \wedge                   \oplus
    \ast            \setminus                \ominus
    \star           \wr                      \otimes
    \circ           \diamond                 \oslash
    \bullet         \bigtriangleup           \odot
    \cdot           \bigtriangledown         \bigcirc
    \cap            \triangleleft            \dagger
    \cup            \triangleright           \ddagger
    \uplus          \lhd                     \amalg""")

relation = any_symbol(raw"""
    = < > :
    \leq        \geq        \equiv   \models
    \prec       \succ       \sim     \perp
    \preceq     \succeq     \simeq   \mid
    \ll         \gg         \asymp   \parallel
    \subset     \supset     \approx  \bowtie
    \subseteq   \supseteq   \cong    \Join
    \sqsubset   \sqsupset   \neq     \smile
    \sqsubseteq \sqsupseteq \doteq   \frown
    \in         \ni         \propto  \vdash
    \dashv      \dots       \dotplus \doteqdot""")

arrow = any_symbol(raw"""
    \leftarrow              \longleftarrow           \uparrow
    \Leftarrow              \Longleftarrow           \Uparrow
    \rightarrow             \longrightarrow          \downarrow
    \Rightarrow             \Longrightarrow          \Downarrow
    \leftrightarrow         \longleftrightarrow      \updownarrow
    \Leftrightarrow         \Longleftrightarrow      \Updownarrow
    \mapsto                 \longmapsto              \nearrow
    \hookleftarrow          \hookrightarrow          \searrow
    \leftharpoonup          \rightharpoonup          \swarrow
    \leftharpoondown        \rightharpoondown        \nwarrow
    \rightleftharpoons      \leadsto""")

spaced_symbol = sEither(binary_operator, relation, arrow) do x
    (:spaced_symbol, x)
end

# Currently unused
punctuation = any_symbol(raw", ; . ! \ldotp \cdotp")

underover_symbol = any_symbol(raw"""
    \sum \prod \coprod \bigcap \bigcup \bigsqcup \bigvee
    \bigwedge \bigodot \bigotimes \bigoplus \biguplus""")

underover_function = Sequence(
    2, bslash, Either(split_tokens(raw"lim liminf limsup inf sup min max")...)) do name
        (:function, name)
    end

underover = Sequence(
    sEither(underover_symbol, underover_function),
    Optional(decoration)) do (core, dec)
        dec === missing ? core : (:underover, core, dec[2], dec[3])
    end

integral_symbol = any_symbol(raw"\int \oint")

integral = Sequence(integral_symbol, Optional(decoration)) do (core, dec)
    dec === missing ? core : (:integral, core, dec[2], dec[3])
end

func = Sequence(
    2, bslash, Either(split_tokens(raw"""
    arccos csc ker arcsin deg lg Pr arctan det sec arg dim
    sin cos exp sinh cosh gcd ln sup cot hom log tan
    coth tanh""")...)) do name
        (:function, name)
    end

space_widths = Dict(
    raw"\,"         => 0.16667,   # 3/18 em = 3 mu
    raw"\thinspace" => 0.16667,   # 3/18 em = 3 mu
    raw"\/"         => 0.16667,   # 3/18 em = 3 mu
    raw"\>"         => 0.22222,   # 4/18 em = 4 mu
    raw"\:"         => 0.22222,   # 4/18 em = 4 mu
    raw"\;"         => 0.27778,   # 5/18 em = 5 mu
    raw"\ "         => 0.33333,   # 6/18 em = 6 mu
    raw"~"          => 0.33333,   # 6/18 em = 6 mu, nonbreakable
    raw"\enspace"   => 0.5,       # 9/18 em = 9 mu
    raw"\quad"      => 1,         # 1 em = 18 mu
    raw"\qquad"     => 2,         # 2 em = 36 mu
    raw"\!"         => -0.16667,  # -3/18 em = -3 mu
)

space = Either(to_token.(keys(space_widths))...) do s
    (:space, space_widths[s])
end


## Main parser
mathexpr = Repeat(Either(
    integral, underover, decorated, spaced_symbol, space, atom)) do res
        (:group, res...)
end


## Recursive definition that uses mathexpr parser as one of their elements
# Expression grouped by braces
group = Sequence(2, '{', mathexpr, '}') do expr
    args = expr[2:end]  # Get rid of the :group header

    if length(args) == 1
        return args[1]  # Skip the group level if it contains a single element
    else
        (:group, args...)
    end
end

# Autodelim
# TODO find why delimiters take so long to be parsed
# Mayeb because delimiter appears twice in the sequence ?
ambi_delimiter = Either(split(raw"""
    | \| / \backslash \uparrow \downarrow \updownarrow \Uparrow
    \Downarrow \Updownarrow . \vert \Vert \\|""")...)

left_delimiter = Either(split(raw"( [ \{ < \lfloor \langle \lceil")...)

right_delimiter = Either(split(raw") ] \} > \rfloor \rangle \rceil")...)

delimiter = sEither(ambi_delimiter, left_delimiter, right_delimiter)
delimited = Sequence(raw"\left", delimiter, mathexpr, raw"\right", delimiter) do res
    left = to_symbol(res[2])
    right = to_symbol(res[5])
    content = res[3]

    (:delimited, left, content, right)
end

## Commands using a braced group as an argument
narrow_accent_map = Dict(
    raw"hat"            => raw"\circumflexaccent",
    raw"breve"          => raw"\combiningbreve",
    raw"bar"            => raw"\combiningoverline",
    raw"grave"          => raw"\combininggraveaccent",
    raw"acute"          => raw"\combiningacuteaccent",
    raw"tilde"          => raw"\combiningtilde",
    raw"dot"            => raw"\combiningdotabove",
    raw"ddot"           => raw"\combiningdiaeresis",
    raw"vec"            => raw"\combiningrightarrowabove",
       "\""             => raw"\combiningdiaeresis",
    raw"`"              => raw"\combininggraveaccent",
    raw"'"              => raw"\combiningacuteaccent",
    raw"~"              => raw"\combiningtilde",
    raw"."              => raw"\combiningdotabove",
    raw"^"              => raw"\circumflexaccent",
    raw"overrightarrow" => raw"\rightarrow",
    raw"overleftarrow"  => raw"\leftarrow",
    raw"mathring"       => raw"\circ",
)

narrow_accent = Sequence(bslash, Either(keys(narrow_accent_map)...), group) do (_, acc, content)
    (:accent, bslash * acc, content)
end
wide_accent = Sequence(bslash, Either(split(raw"widehat widetilde widebar")...), group) do (_, acc, content)
    (:wide_accent, bslash * acc, content)
end

fontnames = split(raw"rm cal it tt sf bf default bb frak scr regular")
mathfont = Sequence(bslash, "math", Either(fontnames...), group) do (_, _, name, content)
    (:mathfont, name, content)
end

frac = Sequence(to_token(raw"\frac"), group, group) do (_, num, denum)
    (:frac, num, denum)
end

# Add everything needed to atom
push!(atom, delimited)
push!(atom, group)
push!(atom, frac)
push!(atom, mathfont)
push!(atom, wide_accent)
push!(atom, narrow_accent)
push!(atom, func)
push!(atom, Numeric(Int))

# Intercept generic latex symbol inserted as unicode
unicode_math = Either(values(latex_symbols)...) do sym
    sym = convert(String, sym)
    (:symbol, first(sym), symbol_latex(sym))
end

push!(atom, unicode_math)

# Finally anything not matched yet is a single char
char = CharNotIn(raw"\%_^{}")

push!(atom, char)

## Default for generic latex commands
# We assume anything that starts with \ and has not been catch is a symbol
symbol = Sequence(2, bslash, Repeat(command_char)) do chars
    com = bslash * join(chars)
    if haskey(latex_symbols, com)
        return (:symbol, first(latex_symbols[com]), com)
    else
        return (:symbol, '?', com)
    end
end

# Make sure to add it at the very end to avoid matching known commands as a
# generic symbol
push!(atom, symbol)

end # module
