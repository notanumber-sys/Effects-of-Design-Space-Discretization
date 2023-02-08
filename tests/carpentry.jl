using JuMP
using HiGHS
using LinearAlgebra, Printf


# data
N = 2;  # number of shops
M = 4;  # number of products
T = [6000; 4000]  # available man hours
P = [12 20 18 40]  # profit
# C[i, j] production time required in shop i for desk j
C = [
    4 9 7 10
    1 1 3 40
]

# model
model = Model(HiGHS.Optimizer)
set_silent(model)

@variable(model, x[i=1:M], Int)  # number of desks to produce

# bounds
for i in 1:M
    @constraint(model, x[i] >= 0)  # positive number of desks
end

for i in 1:N
    @constraint(model, sum(x[j]*C[i, j] for j in 1:M) <= T[i])  # shop hours
end

# maximize profit
@objective(model, Max, sum(P'.*x))

optimize!(model)
x_val = value.(x)

@printf("RESULT: ----------\n")
for i in 1:M
    @printf("Produce %4d of desk %d\n", abs(x_val[i]), i)
end
@printf(" -> For a profit of %d\n", sum(P'.*x_val))
