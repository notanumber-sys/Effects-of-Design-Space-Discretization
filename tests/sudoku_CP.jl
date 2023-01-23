# Sudoku solver using Constraint Programming,
# from JuMP documentation
#
# 2023-01-23

using JuMP
using HiGHS
using LinearAlgebra, Printf

# initial solution
include("sudoku.jl")

model = Model(HiGHS.Optimizer)
set_silent(model)

@variable(model, 1 <= x[1:9, 1:9] <= 9, Int)  # 9x9 integer model

# values in each row must be different
@constraint(model, [i = 1:9], x[i, :] in MOI.AllDifferent(9))

# values in each column must be different
@constraint(model, [i = 1:9], x[:, i] in MOI.AllDifferent(9))

# values in each 3x3 submatrix must be different
for i in (0, 3, 6), j in (0, 3, 6)
    @constraint(model, vec(x[i.+(1:3), j.+(1:3)]) in MOI.AllDifferent(9))
end

for i in 1:9, j in 1:9
    if init_sol[i, j] != 0
        fix(x[i, j], init_sol[i, j]; force=true)
    end
end

# solve
optimize!(model)
sol = round.(Int, value.(x))
@show sol
