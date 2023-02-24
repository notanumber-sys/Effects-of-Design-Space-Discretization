#!/bin/bash
#=
exec julia --color=yes --startup-file=no "${BASH_SOURCE[0]}" "$@"
=#

@show ARGS

using Printf, Plots, CSV
using LinearAlgebra

# mode if program is run as script
mode = abspath(PROGRAM_FILE) == @__FILE__

function read_data(path::String)
    data = CSV.File(path)
    M = 1
    p = data[1][1]
    while data[M][1] != p && M < length(data)
        M += 1
    end
    N = Int(length(data)/M)
    return data, N, M
end

function plot_by_time_mult()
    p = plot(
        data["time_mult"][1:M:end],
        data["n_through"][1:M:end],
        xaxis=("time multiplier", :log10),
        yaxis=("throughput"),
        label=@sprintf("Disc th, md=%d", data["mem_div"][1]),
        mark=:circle,
        legend=:topleft
    )
    for n in 2:M
        plot!(p,
            data["time_mult"][n:M:end],
            data["n_through"][n:M:end],
            label=@sprintf("Disc th, md=%d", data["mem_div"][n]),
            mark=:circle
        )
    end
    savefig(p, @sprintf("%s/time.png", plotsdir))
end

# determine target
identifier = "test"
if mode
    global target = ARGS[1]
end
target = @sprintf("out_case_%s.csv", identifier)
@printf("Attempting to plot from: %s\n", target)
plotsdir = @sprintf("plt_case_%s", identifier)

data, N, M = read_data(target)
mkdir(plotsdir)
plot_by_time_mult()
