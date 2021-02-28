using Test
using MathTeXParser

"""
Utils for easier manual building of TeXExpr.

Allow to skip the first :expr header and one level of nestedness.
"""
expr(args...) = TeXExpr((:expr, args...))

@testset "Accent" begin
    @test parse(TeXExpr, raw"\vec{a}") == expr((:accent, raw"\vec", 'a'),)
    @test parse(TeXExpr, raw"\dot{\vec{x}}") == expr((:accent, raw"\dot", (:accent, raw"\vec", 'x')),)
end

@testset "Decoration" begin
    @test parse(TeXExpr, raw"a^2_3") == parse(TeXExpr, "a_3^2")
end

@testset "Command match full words" begin
    # Check braces are not added to the function name
    @test parse(TeXExpr, raw"\sin{x}") == expr((:function, "sin"), 'x')
end

@testset "Fraction" begin
    @test parse(TeXExpr, raw"\frac{1}{2}") == expr((:frac, 1, 2),)
end

@testset "Integral" begin
    @test parse(TeXExpr, raw"\int") == expr((:symbol, raw"\int"),)
    @test parse(TeXExpr, raw"\int_a^b") == expr(
        (:overunder, (:symbol, raw"\int"),
            (:sub, 'a'),
            (:super, 'b')),)
end

@testset "Overunder" begin
    @test parse(TeXExpr, raw"\sum") == expr((:symbol, raw"\sum"),)
    @test parse(TeXExpr, raw"\sum_{k=0}^n") == expr(
        (:overunder, (:symbol, raw"\sum"),
            (:sub, (:group, 'k', (:spaced_symbol, "="), 0)),
            (:super, 'n')),)
end

@testset "Symbol" begin
    for sym in split(raw"\phi \varphi \Phi")
        @test parse(TeXExpr, sym) == expr((:symbol, sym),)
    end
end