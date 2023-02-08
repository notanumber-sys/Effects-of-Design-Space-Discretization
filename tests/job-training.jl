using JuMP
using HiGHS
using LinearAlgebra, Printf

# parameters
R = [0; 100; 200; 300; 400; 200]  # required delivery schedule
# allowed actions: hiring, firing, production, storing
p = 30  # delayed delivery penalty / week
s = 10  # storage penalty / week
g = 20  # initial workers
h = 10  # initial units
k = 8   # units per worker per week
m = 100 # weekly wage
n = 600 # training cost, occupies one worker and produces 5 additional trained workers
f = 100 # cost to fire a worker
w = length(R)  # number of weeks


# model
model = Model(HiGHS.Optimizer)
set_silent(model)

# weeks 0, 1, ..., 5  ->  1, 2, ..., 6
@variable(model, trai[i=1:w], Int)
@variable(model, prod[i=1:w], Int)
@variable(model, idle[i=1:w], Int)
@variable(model, fire[i=1:w], Int)
@variable(model, stor[i=1:w], Int)
@variable(model, pena[i=1:w], Int)

# help variables
@variable(model, cost, Int)
@variable(model, work[i=1:w], Int)
#@variable(model, quan[i=1:w], Int)

# constraints
# positivity
for i in 1:w
    @constraint(model, trai[i] >= 0)
    @constraint(model, prod[i] >= 0)
    @constraint(model, idle[i] >= 0)
    @constraint(model, fire[i] >= 0)
    @constraint(model, stor[i] >= 0)
    @constraint(model, pena[i] >= 0)

#    @constraint(model, quan[i] >= 0)
end

# define cost from other variables
@constraint(model, cost == sum([
    sum(trai.*n),
    sum(prod.*m),
    sum(idle.*m),
    sum(fire.*f),
    sum(stor.*s),
    sum(pena.*p)
]))

# define work from other variables
for i in 1:w
    @constraint(model, work[i] == trai[i] + prod[i] + idle[i] + fire[i])
end

# define time progression of workers
@constraint(model, work[1] == g)
for i in 2:w
    @constraint(model, work[i] == work[i - 1] + 5*trai[i - 1] - fire[i - 1])
end
@constraint(model, fire[w] == work[w])  # fire all workers to terminate program

# define time progression of quantity
@constraint(model, stor[1] == h)
for i in 2:w
    @constraint(model, stor[i] == stor[i - 1] + k*prod[i - 1] - R[i - 1])
end

for i in 1:w
    #@constraint(model, stor[i])
end


@objective(model, Min, cost)

# solve
optimize!(model)
trai_val = value.(trai)
prod_val = value.(prod)
idle_val = value.(idle)
fire_val = value.(fire)
stor_val = value.(stor)
pena_val = value.(pena)
cost_val = value.(cost)
work_val = value.(work)

@printf("RESULT: -------------------\n")
    @printf("         train produce idle fire store penalty workers\n")
for i in 1:w
    @printf("Week %d: %5d %7d %4d %4d %5d %7d %7d\n", i,
            abs(trai_val[i]), abs(prod_val[i]), abs(idle_val[i]),
            abs(fire_val[i]), abs(stor_val[i]), abs(pena_val[i]),
            abs(work_val[i]))
end
@printf("    for a total cost of %d\n", cost_val)