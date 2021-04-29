module MathTeXParser
# Adapted from Matplotlib mathtext grammar definition
# https://github.com/matplotlib/matplotlib/blob/master/lib/matplotlib/_mathtext.py

using AbstractTrees
using Automa

import Automa.RegExp: @re_str
import DataStructures: Stack
import REPL.REPLCompletions: latex_symbols

const re = Automa.RegExp

export TeXExpr, texparse

include("texexpr.jl")
include("command_data.jl")
include("parser.jl")

end