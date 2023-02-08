using JuMP
using HiGHS
using LinearAlgebra, Printf


# data
N = 3  # number of cannaries
M = 5  # number of distribution terminals
Q = 300  # delivery from each terminal
P = [250; 500; 750]  # production at each cannary
# costs, C[i, j] is the cost of shipping a case from cannary i to terminal j
C = [
    2.70 1.80 1.50 1.00 0.90
    0.90 2.00 1.80 1.70 2.50
    0.60 1.60 1.40 1.80 2.50
]
# variable is no. of cases from each cannary to each terminal

# model
model = Model(HiGHS.Optimizer)
set_silent(model)

@variable(model, x[i=1:N, j=1:M], Int)

# bounds on cases
for i in 1:N
    for j in 1:M
        @constraint(model, x[i, j] >= 0)  # all transports non-negative
    end
    # this could be changed for a more general formulation, since demand might not
    # necessarily match available production. (... <= P)
    @constraint(model, sum(x[i, j] for j in 1:M) == P[i])  # sum of deliveries matches production
end

# sum of delivieries to terminals equal deliveries from terminals
for j in 1:M
    # similarly, a terminal might (although this will never be preferable in a
    # one-situation case) receive more product than it is able to sell. (... >= Q)
    @constraint(model, sum(x[i, j] for i in 1:N) == Q)
end

# minimize cost
@objective(model, Min, sum(C.*x))

optimize!(model)
x_val = value.(x)
@show x_val
