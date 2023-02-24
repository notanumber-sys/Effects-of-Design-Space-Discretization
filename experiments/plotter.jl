#!/bin/bash
#=
exec julia --color=yes --startup-file=no "${BASH_SOURCE[0]}" "$@"
=#

#@show ARGS

using Printf, Plots, CSV
using LinearAlgebra

# mode if program is run as script
mode = abspath(PROGRAM_FILE) == @__FILE__

function read_data(path::String)
    data = CSV.File(path)
    M = 1
    p = data[1][1]
    while data[M][1] == p && M < length(data)
        M += 1
    end
    M -= 1
    N = Int(length(data)/M)
    return data, N, M
end

function plot_th_by_time_mult()
    p = plot(
        data["time_mult"][1:M:end],
        data["n_through"][1:M:end],
        xaxis=("time multiplier", :log10),
        yaxis=("throughput"),
        label=@sprintf("Disc Th., md=%d", data["mem_div"][1]),
        mark=:circle,
        legend=:bottomright
    )
    for n in 2:M
        plot!(p,
            data["time_mult"][n:M:end],
            data["n_through"][n:M:end],
            label=@sprintf("Disc Th., md=%d", data["mem_div"][n]),
            mark=:circle
        )
    end
    savefig(p, @sprintf("%s/th_vs_tm.png", plotsdir))
end

function plot_errest_by_time_mult()
    correct = data["n_through"][end]  # TODO: Update this to more exact e_through
    vals = correct.-data["n_through"][1:M:end]
    p = plot(
        data["time_mult"][1:M:end][vals.>0],
        vals[vals.>0],
        xaxis=("time multiplier", :log10),
        yaxis=("error estimate", :log10),
        label=@sprintf("Disc Th., md=%d", data["mem_div"][1]),
        mark=:circle,
        legend=:topright
    )
    for n in 2:M
        vals = correct.-data["n_through"][n:M:end]
        plot!(p,
            data["time_mult"][n:M:end][vals.>0],
            vals[vals.>0],
            label=@sprintf("Disc Th., md=%d", data["mem_div"][n]),
            mark=:circle
        )
    end
    savefig(p, @sprintf("%s/err_vs_tm.png", plotsdir))
end

function plot_time_by_time_mult()
    p = plot(
        data["time_mult"][1:M:end],
        data["time"][1:M:end],
        xaxis=("time multiplier", :log10),
        yaxis=("run time"),
        label=@sprintf("Disc Th., md=%d", data["mem_div"][1]),
        mark=:circle,
        legend=:bottomright
    )
    for n in 2:M
        plot!(p,
            data["time_mult"][n:M:end],
            data["time"][n:M:end],
            label=@sprintf("Disc Th., md=%d", data["mem_div"][n]),
            mark=:circle
        )
    end
    savefig(p, @sprintf("%s/t_vs_tm.png", plotsdir))
end

function plot_errest_by_time()
    correct = data["n_through"][end]  # TODO: Update this to more exact e_through
    vals = correct.-data["n_through"][1:M:end]
    p = plot(
        data["time"][1:M:end][vals.>0],
        vals[vals.>0],
        xaxis=("time [s]"),
        yaxis=("error estimate", :log10),
        label=@sprintf("Disc Th., md=%d", data["mem_div"][1]),
        seriestype=:scatter,
        mark=:circle,
        legend=:topright
    )
    for n in 2:M
        vals = correct.-data["n_through"][n:M:end]
        plot!(p,
            data["time"][n:M:end][vals.>0],
            vals[vals.>0],
            label=@sprintf("Disc Th., md=%d", data["mem_div"][n]),
            seriestype=:scatter,
            mark=:circle
        )
    end
    savefig(p, @sprintf("%s/err_vs_t.png", plotsdir))
end

# determine target
identifier = "test"
if mode
    global identifier = strip(ARGS[1])
end
target = @sprintf("out_case_%s.csv", identifier)
plotsdir = @sprintf("plt_case_%s", identifier)

data, N, M = read_data(target)
rm(plotsdir, force=true, recursive=true)
mkdir(plotsdir)
plot_th_by_time_mult()
plot_errest_by_time_mult()
plot_time_by_time_mult()
plot_errest_by_time()
