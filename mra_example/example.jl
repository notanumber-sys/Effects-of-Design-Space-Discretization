using LinearAlgebra, Plots, Printf
using QuadGK

phi   = x -> (0 <= x < 1)
phimn = (x, m, n) -> 2^(m/2)*phi(x*2^m - n)
bas   = x -> (-1 <= x < 0) - (0 <= x < 1)
psi   = x -> bas(2*x - 1)#*sqrt(2)
psimn = (x, m, n) -> 2^(m/2)*psi(x*2^m - n)

# configuration
f = x -> sin(3*pi*x)
N_LEVELS = 6
showlevels = [0, 2, 4, 6]
series = 0:2^(-12):1

function projection(f, b)
    # this is probably very inefficient since the basis functions are not smooth
    integral, err = quadgk(x -> f(x)*b(x), 0, 1, rtol=1e-10)
    return integral
end

function evaluate(base, coeff, x)
    result = 0.0
    for (i, b) in enumerate(base)
        result += coeff[i]*b(x)
    end
    return result
end

functions    = [x -> 0, x -> phimn(x, 0, 0)]
coefficients = [0.0,    projection(f, functions[2])]
plots = []
errors = zeros(Float64, N_LEVELS + 1)
if 0 in showlevels
    plots = [
        plot(
            series,
            c00*phi.(series),
            label="approximation",
            title="m=0",
            xlabel="x",
            ylabel="f(x)"
        )
    ]
end
errors[1], _ = quadgk(x -> (f(x) - evaluate(functions, coefficients, x))^2, 0, 1, rtol=10e-10)

for m in 1:N_LEVELS
    @show(coefficients)
    @printf("m=%d\n", m)

    for n in 0:(2^m - 1)
        @printf("i=%d, m=%d, n=%d\n", length(functions) + 1, m, n)
        push!(functions,    x -> psimn(x, m, n))
        push!(coefficients, projection(f, functions[end]))
    end

    if m in showlevels
        approx = x -> evaluate(functions, coefficients, x)
        push!(plots,
            plot(
                series,
                approx.(series),
                label="approximation",
                title=@sprintf("m=%d", m),
                xlabel="x",
                ylabel="f(x)"
            )
        )
    end
    errors[m + 1], _ = quadgk(x -> (f(x) - evaluate(functions, coefficients, x))^2, 0, 1, rtol=10e-10)
end
@show(coefficients)

for p in plots
    plot!(p,
        series,
        f.(series),
        label="exact",
        linestyle=:dash
    )
end

#A = zeros(Float64, length(functions) - 1, length(functions) - 1)
#for i in 2:length(functions)
#    for j in 2:length(functions)
#        A[i - 1, j - 1] = projection(functions[i], functions[j])
#    end
#    @show(A[i - 1, :])
#end

p1 = plot(
    0:N_LEVELS,
    errors.^(1/2),
    yaxis=("L2-error", :log10),
    xaxis=("m"),
    title="Error",
    marker=:circle,
    label="Error"
)
@show(errors)
savefig(p1, "error.png")

p2 = plot(plots[1], plots[2], plots[3], plots[4], layout=(length(plots), 1), size=(800, 300*length(plots)))
savefig(p2, "approximations.png")