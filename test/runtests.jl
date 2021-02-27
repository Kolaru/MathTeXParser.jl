using Test
using MathTeXParser

@testset "Accent" begin
    @test parse(TeXExpr, raw"\vec{a}") == TeXExpr((:expr, (:accent, "vec", (:group, 'a'))))
    @test parse(TeXExpr, raw"\dot{\vec{x}}") == TeXExpr(
        (:expr, (:accent, "dot", (:group, (:accent, "vec", (:group, 'x'))))))
end

@testset "Decoration" begin
    @test parse(TeXExpr, raw"a^2_3") == parse(TeXExpr, "a_3^2")
end

@testset "Command match full words" begin
    # Check it doesn't stop parsing at \in
    @test parse(TeXExpr, raw"\int") == TeXExpr((:expr, raw"\int"))

    # Check braces are not added to the function name
    @test parse(TeXExpr, raw"\sin{x}") == TeXExpr((:expr, (:function, "sin"), (:group, 'x')))
end