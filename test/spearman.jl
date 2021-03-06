using HypothesisTests, Base.Test

# Test Exact P value: n <= 10
let x = [44.4, 45.9, 41.9, 53.3, 44.7, 44.1],
    y = [2.6, 3.1, 2.5, 5.0, 3.6, 4.0]

    corr = HypothesisTests.SpearmanCorrelationTest(x, y)

    # R values
    @test_approx_eq corr.ρ 0.6
    @test_approx_eq_eps HypothesisTests.pvalue(corr) 0.2417 0.0001
    @test_approx_eq_eps HypothesisTests.pvalue(corr, tail=:right) 0.1208 0.0001
    @test_approx_eq_eps HypothesisTests.pvalue(corr, tail=:left) 0.9125 0.0001

    # Test throws
    @test_throws AssertionError HypothesisTests.SpearmanCorrelationTest(x,y[1:5])

    @test_throws ArgumentError HypothesisTests.pvalue(corr, tail=:greater, method=:exact)
    @test_throws ArgumentError HypothesisTests.pvalue(corr, tail=:greater, method=:sampling)
    @test_throws ArgumentError HypothesisTests.pvalue(corr, tail=:greater, method=:exact)
    @test_throws ArgumentError HypothesisTests.pvalue(corr, tail=:greater, method=:ttest)

    @test_throws ArgumentError HypothesisTests.pvalue(corr, tail=:right, method=:R)
end

show(IOBuffer(),
     HypothesisTests.SpearmanCorrelationTest([44.4, 45.9, 41.9, 53.3, 44., 44.1],
                                             [2.6, 3.1, 2.5, 5.0, 3.6, 4.0])
     )

let x = collect(1:11),
    y = [6, 5, 4, 3, 2, 1, 7, 11, 10, 9, 8]
    # https://stat.ethz.ch/pipermail/r-devel/2009-February/052112.html
    # The correct P value is 0.03044548, R 3.2.5 gives 0.03036

    srand(12345) # Seed for method=:sampling

    corr = HypothesisTests.SpearmanCorrelationTest(x, y)

    @test_approx_eq_eps HypothesisTests.pvalue(corr, tail=:right, method=:exact)     0.03044548 1e-8
    @test_approx_eq_eps HypothesisTests.pvalue(corr, tail=:right, method=:sampling)  0.030      1e-3
    @test_approx_eq_eps HypothesisTests.pvalue(corr, tail=:right, method=:estimated) 0.030      1e-3
    @test_approx_eq_eps HypothesisTests.pvalue(corr, tail=:right, method=:ttest)     0.03       1e-2

    corr = HypothesisTests.SpearmanCorrelationTest(x, -y)

    @test_approx_eq_eps HypothesisTests.pvalue(corr, tail=:left, method=:exact)      0.03044548 1e-8
    @test_approx_eq_eps HypothesisTests.pvalue(corr, tail=:left, method=:sampling)   0.030      1e-3
    @test_approx_eq_eps HypothesisTests.pvalue(corr, tail=:left, method=:estimated)  0.030      1e-3
    @test_approx_eq_eps HypothesisTests.pvalue(corr, tail=:left, method=:ttest)      0.03       1e-2
end

let x = collect(1:10),
    y = [5, 4, 3, 2, 1, 6, 10, 9, 8, 7]

    # R's pspearman: 0.05443067 is the exact value
    corr = HypothesisTests.SpearmanCorrelationTest(x, y)
    @test_approx_eq_eps HypothesisTests.pvalue(corr) 0.05443067 1e-8
end

# Using (N-1)N²(N+1)² overflows with N = 10153 and sqrt((N-1)N²(N+1)²) throws an error
# pvalue avoids the Int overflow using float(N) and sqrt(N-1)N(N+1) since N > 0
srand(12345) # Seed for rand
let x = rand(10153)

    corr = SpearmanCorrelationTest(x, x)

    @test_approx_eq corr.ρ 1.0
    @test_approx_eq pvalue(corr) 0.0

end

# Test S value with ties

function rho_with_ties(S, N, tx, ty) # S == D
    # Equation (14.6.5) from Numerical Recipes for rho with ties
    a=(N^3)-N
    (1-((6/a)*(S+(tx/12)+(ty/12)))) / (sqrt(1-(tx/a))*sqrt(1-(ty/a)))
end

function diff_rho(x, y)
    corr = SpearmanCorrelationTest(x, y)
    corr.ρ - rho_with_ties(corr.S, corr.n, corr.xtiesadj, corr.ytiesadj)
end

srand(12345) # Seed for rand
for i in 20:100
    @test_approx_eq_eps diff_rho(rand(1:10, i), rand(1:10, i)) 0.0 1e-10
end
