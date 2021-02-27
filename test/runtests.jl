using Test
using MathTeXParser

@testset "Decoration" begin
    @test parse(TeXExpr, "a^2_3") == parse(TeXExpr, "a_3^2")
end