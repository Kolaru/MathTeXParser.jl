module MathTeXParser
# Adapted from Matplotlib mathtext grammar definition
# https://github.com/matplotlib/matplotlib/blob/master/lib/matplotlib/_mathtext.py

using AbstractTrees
using CombinedParsers

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
        else
            # Ignore all spaces, this could probably be done elsewhere
            if arg != ' '
                push!(args, arg)
            end
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
Base.parse(::Type{TeXExpr}, s) = TeXExpr(parse(mathexpr, s))

# Definition is forwarded to allow recursive search
atom = Either{Any}(Numeric(Int), CharNotIn(raw"\%_^{}"))  # Called `placeable` in matplotlib

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

# Super and subscript
superscript = Sequence(2, '^', atom)
subscript = Sequence(2, '_', atom)

# Always return the decoration in order (super, sub)
decoration = Either(
    Sequence(superscript, subscript) do (x, y)
        (:supersub, x, y)
    end,
    Sequence(subscript, Optional(superscript, default="")) do (x, y)
        (:supersub, y, x)
    end,
    Sequence(1, superscript) do x
        (:supersub, x, "")
    end
)

decorated = Sequence(atom, decoration) do (core, dec)
    (:decorated, core, (:super, dec[2]), (:sub, dec[3]))
end

bslash = '\\'

binary_operator = Either(split_tokens(raw"""
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
    \uplus          \lhd                     \amalg""")...)

relation = Either(split_tokens(raw"""
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
    \dashv      \dots       \dotplus \doteqdot""")...)

arrow = Either(split_tokens(raw"""
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
    \rightleftharpoons      \leadsto""")...)

spaced_symbol = sEither(binary_operator, relation, arrow) do x
    (:spaced_symbol, x)
end

punctuation = Either(split_tokens(raw", ; . ! \ldotp \cdotp")...) do x
    (:punctuation, x)
end

overunder_symbol = Either(split_tokens(raw"""
    \sum \prod \coprod \bigcap \bigcup \bigsqcup \bigvee
    \bigwedge \bigodot \bigotimes \bigoplus \biguplus""")...)

overunder_function = Sequence(
    2, bslash, Either(split_tokens(raw"lim liminf limsup sup max min")...)) do name
    (:function, name)
end

overunder = Sequence(
    sEither(overunder_symbol, overunder_function),
    Optional(decoration)) do (core, dec)
        dec === missing ? core : (:overunder, core, (:super, dec[2]), (:sub, dec[3]))
    end

integral_symbol = Either(split_tokens(raw"\int \oint")...)

integral = Sequence(integral_symbol, Optional(decoration)) do (core, dec)
    dec === missing ? core : (:integral, core, (:super, dec[2]), (:sub, dec[3]))
end

generic_function = Sequence(
    2, bslash, Either(split_tokens(raw"""
    arccos csc ker min arcsin deg lg Pr arctan det lim sec arg dim
    liminf sin cos exp limsup sinh cosh gcd ln sup cot hom log tan
    coth inf max tanh""")...)) do name
        (:function, name)
    end

ambi_delimiter = Either(split(raw"""
    | \| / \backslash \uparrow \downarrow \updownarrow \Uparrow
    \Downarrow \Updownarrow . \vert \Vert \\|""")...)

left_delimiter = Either(split(raw"( [ \{ < \lfloor \langle \lceil")...)

right_delimiter = Either(split(raw") ] \} > \rfloor \rangle \rceil")...)

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


# TODO add accent and fonts
narrow_accent = Either(keys(narrow_accent_map)...)
wide_accent = Either(split(raw"widehat widetilde widebar")...)

fontnames = split(raw"rm cal it tt sf bf default bb frak scr regular")
font = Either(fontnames...)
latexfont = Either(("math" .* fontnames)...)


# Main parser
# TODO Fractions
# TODO Error if the string is not match entirely
# TODO Add generic command for symbols
# TODO Command that require a following groupe in brace
mathexpr = Repeat(Either(
    decorated, spaced_symbol, punctuation, overunder, integral, space, atom)) do res
    (:expr, res...)
end

# Recursive bracket
group = Sequence(2, '{', mathexpr, '}') do expr
    (:group, expr[2:end]...)  # Get rid of the :expr header
end

delimiter = sEither(ambi_delimiter, left_delimiter, right_delimiter)
delimited = Sequence(raw"\left", delimiter, mathexpr, raw"\right", delimiter) do res
    (:delimited, res[2], res[3], res[5])
end

# Add everything needed to atom
push!(atom, generic_function)
pushfirst!(atom, group)
pushfirst!(atom, delimited)

end # module
