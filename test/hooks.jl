const JL = JuliaLowering

@testset "hooks" begin
    test_mod = Module()

    @testset "`core_lowering_hook`" begin
        # Non-AST types are often sent through lowering
        stuff = Any[LineNumberNode(1), 123, 123.123, true, "foo", test_mod]
        for s in stuff
            @test JL.core_lowering_hook(s, test_mod) == Core.svec(s)
        end

        st = parseall(JL.SyntaxTree, "function f_st end")
        out = core_lowering_hook(st, test_mod)
        @test out isa Core.Svec && out[1] isa Expr
        Core.eval(test_mod, out)
        @test isdefined(test_mod, :f_st)

        ex = parseall(Expr, "function f_ex end")
        @test core_lowering_hook(ex, test_mod)
        @test out isa Core.Svec && out[1] isa Expr
        Core.eval(test_mod, out)
        @test isdefined(test_mod, :f_ex)
    end

    @testset "integration: `JuliaLowering.activate!`" begin
        prog = parseall(Expr, "global asdf = 1")
        JuliaLowering.activate!()
        out = Core.eval(test_mod, prog)
        JuliaLowering.activate!(false)
        @test out === 1
        @test isdefined(test_mod, :asdf)

        prog = parseall(Expr, "module M; x = 1; end")
        JuliaLowering.activate!()
        out = Core.eval(test_mod, prog)
        JuliaLowering.activate!(false)
        @test out isa Module
        @test isdefined(test_mod, :M)
        @test isdefined(test_mod.M, :x)
    end
end
