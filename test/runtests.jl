using Test
using MathTeXParser

test_parse(input, args...) = @test parse(TeXExpr, input) == TeXExpr((:group, args...))

@testset "Accent" begin
    test_parse(raw"\vec{a}", (:accent, raw"\vec", 'a'))
    test_parse(raw"\dot{\vec{x}}", (:accent, raw"\dot", (:accent, raw"\vec", 'x')))
end

@testset "Decoration" begin
    @test parse(TeXExpr, raw"a^2_3") == parse(TeXExpr, "a_3^2")
end

@testset "Command match full words" begin
    # Check braces are not added to the function name
    test_parse(raw"\sin{x}", (:function, "sin"), 'x')
end

@testset "Fraction" begin
    test_parse(raw"\frac{1}{2}", (:frac, 1, 2))
end

@testset "Integral" begin
    test_parse(raw"\int", (:symbol, raw"\int"))
    test_parse(raw"\int_a^b", (:overunder,
        (:symbol, raw"\int"), 'a', 'b'))
end

@testset "Overunder" begin
    test_parse(raw"\sum", (:symbol, raw"\sum"))
    test_parse(raw"\sum_{k=0}^n", (:overunder,
        (:symbol, raw"\sum"),
        (:group, 'k', (:spaced_symbol, "="), 0),
        'n'))
end

@testset "Symbol" begin
    for sym in split(raw"\phi \varphi \Phi")
        test_parse(sym, (:symbol, sym))
    end
end