using Test
using MathTeXParser

"""
Utils for easier manual building of TeXExpr.

Allow to skip the first :expr header and one level of nestedness.
"""
expr(args...) = TeXExpr((:expr, args...))

@testset "Accent" begin
    @test parse(TeXExpr, raw"\vec{a}") == expr((:accent, "vec", 'a'),)
    @test parse(TeXExpr, raw"\dot{\vec{x}}") == expr((:accent, "dot", (:accent, "vec", 'x')),)
end

@testset "Decoration" begin
    @test parse(TeXExpr, raw"a^2_3") == parse(TeXExpr, "a_3^2")
end

@testset "Command match full words" begin
    # Check it doesn't stop parsing at \in
    @test parse(TeXExpr, raw"\int") == expr(raw"\int")

    # Check braces are not added to the function name
    @test parse(TeXExpr, raw"\sin{x}") == expr((:function, "sin"), 'x')
end

@testset "Fraction" begin
    @test parse(TeXExpr, raw"\frac{1}{2}") == expr((:frac, 1, 2),)
end

@testset "Symbol" begin
    for sym in ("phi", "varphi", "Phi")
        @test parse(TeXExpr, "\\$sym") == expr((:symbol, sym),)
    end
end