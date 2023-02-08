using JuMP
using HiGHS
using LinearAlgebra, Printf


# data
N = 3  # number of elements
M = 9  # number of starting alloys
T = [0.3; 0.3; 0.4]  # desired composition
C = [4.1 4.3 5.8 6.0 7.6 7.5 7.3 6.9 7.3]  # costs
# available starting alloys, O[i, j] is percentage of element i in alloy j
O = [
    0.1 0.1 0.4 0.6 0.3 0.3 0.3 0.5 0.2
    0.1 0.3 0.5 0.3 0.3 0.4 0.2 0.4 0.3
    0.8 0.6 0.1 0.1 0.4 0.3 0.5 0.1 0.5
]

# model
model = Model(HiGHS.Optimizer)
set_silent(model)

@variable(model, x[i=1:M])  # amount of each alloy to buy

# bounds
for i in 1:M
    @constraint(model, x[i] >= 0)  # positive amount of alloy
end

# target composition
@constraint(model, O*x .== T)

# minimize cost
@objective(model, Min, sum(C'.*x))

optimize!(model)
x_val = value.(x)
@printf("RESULT: ------------------\n")
for i in 1:M
    @printf("Buy %4.2f of alloy %d\n", abs(x_val[i]), i)
end

@printf(" = total price of %4.2f\n", sum(C'.*x_val))
