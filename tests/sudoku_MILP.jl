# Sudoku solver using Mixed Integer Linear Programming,
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

@variable(model, x[i=1:9, j=1:9, k=1:9], Bin)

# one number per box
for i in 1:9
    for j in 1:9
        @constraint(model, sum(x[i, j, k] for k in 1:9) == 1)
    end
end

# each number should appear once in each row and column
for i in 1:9
    for k in 1:9
        @constraint(model, sum(x[i, j, k] for j in 1:9) == 1)
        @constraint(model, sum(x[j, i, k] for j in 1:9) == 1)
    end
end

# each number should appear once in each 3x3 sub-matrix
for i in 1:3:7
    for j in 1:3:7
        for k in 1:9
            @constraint(model,
                        sum(x[r, c, k] for r in i:(i+2), c in j:(j+2)) == 1)
        end
    end
end

# build representation from inital state
for i in 1:9
    for j in 1:9
        if init_sol[i, j] != 0
            fix(x[i, j, init_sol[i, j]], 1; force=true)
        end
    end
end

# solve
optimize!(model)
x_val = value.(x)

# create solution matrix
sol = zeros(Int, 9, 9)
for i in 1:9
    for j in 1:9
        for k in 1:9
            if round(Int, x_val[i, j, k]) == 1
                sol[i, j] = k
            end
        end
    end
end

@show sol
