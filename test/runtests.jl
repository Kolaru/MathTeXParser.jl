using Test
using MathTeXParser

@testset "Decoration" begin
    @test parse(TeXExpr, "a^2_3") == parse(TeXExpr, "a_3^2")
end

@testset "Command match full words" begin
    # Check it doesn't stop parsing at \in
    @test parse(TeXExpr, raw"\int") == TeXExpr((:expr, raw"\int"))

    # Check braces are not added to the function name
    @test parse(TeXExpr, raw"\sin{x}") == TeXExpr((:expr, (:function, "sin"), (:group, 'x')))
end