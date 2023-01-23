# N-Queens, from JuMP documentation
#
# 2023-01-23

using JuMP
using HiGHS
using LinearAlgebra, Printf

N = 20

model = Model(HiGHS.Optimizer)
set_silent(model)

@variable(model, x[1:N, 1:N], Bin)

for i in 1:N
    @constraint(model, sum(x[i, :]) == 1)
    @constraint(model, sum(x[:, i]) == 1)
end

for i in -(N - 1):(N - 1)
    @constraint(model, sum(diag(x, i)) <= 1)
    @constraint(model, sum(diag(reverse(x; dims=1), i)) <= 1)
end

optimize!(model)
solution = round.(Int, value.(x))

@show(solution)
