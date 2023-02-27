#!/bin/bash
#=
exec julia --color=yes --startup-file=no "${BASH_SOURCE[0]}" "$@"
=#

#@show ARGS

using Printf, Plots, CSV
using LinearAlgebra

# mode if program is run as script
mode = abspath(PROGRAM_FILE) == @__FILE__
formats = ["png", "svg"]

function read_data(path::String)
    data = CSV.File(path)
    M = 1
    p = data[1][1]
    while M <= length(data) && data[M][1] == p
        M += 1
    end
    M -= 1
    N = Int(length(data)/M)
    return data, N, M
end

function savefigs(p, plotname)
    for format in formats
        savefig(p, @sprintf("%s/%s/%s.%s", plotsdir, format, plotname, format))
    end
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
    for m in 2:M
        plot!(p,
            data["time_mult"][m:M:end],
            data["n_through"][m:M:end],
            label=@sprintf("Disc Th., md=%d", data["mem_div"][m]),
            mark=:circle
        )
    end
    savefigs(p, "th_vs_tm")
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
    for m in 2:M
        vals = correct.-data["n_through"][m:M:end]
        plot!(p,
            data["time_mult"][m:M:end][vals.>0],
            vals[vals.>0],
            label=@sprintf("Disc Th., md=%d", data["mem_div"][m]),
            mark=:circle
        )
    end
    savefigs(p, "err_vs_tm")
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
    for m in 2:M
        plot!(p,
            data["time_mult"][m:M:end],
            data["time"][m:M:end],
            label=@sprintf("Disc Th., md=%d", data["mem_div"][m]),
            mark=:circle
        )
    end
    savefigs(p, "t_vs_tm")
end

function plot_th_by_mem_div()
    p = plot(
        data["mem_div"][1:M],
        data["n_through"][1:M],
        xaxis=("memory divider", :log10),
        yaxis=("throughput"),
        label=@sprintf("Disc Th., tm=%d", data["time_mult"][1]),
        mark=:circle,
        legend=:bottomright
    )
    for n in 2:N
        plot!(p,
            data["mem_div"][M*(n-1)+1:M*n],
            data["n_through"][M*(n-1)+1:M*n],
            label=@sprintf("Disc Th., tm=%d", data["time_mult"][n*M]),
            mark=:circle
        )
    end
    savefigs(p, "th_vs_md")
end

function plot_errest_by_mem_div()
    correct = data["n_through"][end]  # TODO: Update this to more exact e_through
    vals = correct.-data["n_through"][1:M]
    p = plot(
        data["mem_div"][1:M][vals.>0],
        vals[vals.>0],
        xaxis=("memory divider", :log10),
        yaxis=("error estimate", :log10),
        label=@sprintf("Disc Th., tm=%d", data["time_mult"][1]),
        mark=:circle,
        legend=:topright
    )
    for n in 2:N
        vals = correct.-data["n_through"][M*(n-1)+1:M*n]
        plot!(p,
            data["time_mult"][M*(n-1)+1:M*n][vals.>0],
            vals[vals.>0],
            label=@sprintf("Disc Th., tm=%d", data["time_mult"][n*M]),
            mark=:circle
        )
    end
    savefigs(p, "err_vs_md")
end

function plot_time_by_mem_div()
    p = plot(
        data["mem_div"][1:M],
        data["time"][1:M],
        xaxis=("memory divider", :log10),
        yaxis=("run time"),
        label=@sprintf("Disc Th., tm=%d", data["time_mult"][1]),
        mark=:circle,
        legend=:bottomright
    )
    for n in 2:N
        plot!(p,
            data["mem_div"][M*(n-1)+1:M*n],
            data["time"][M*(n-1)+1:M*n],
            label=@sprintf("Disc Th., tm=%d", data["time_mult"][n*M]),
            mark=:circle
        )
    end
    savefigs(p, "t_vs_md")
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
    for m in 2:M
        vals = correct.-data["n_through"][m:M:end]
        plot!(p,
            data["time"][m:M:end][vals.>0],
            vals[vals.>0],
            label=@sprintf("Disc Th., md=%d", data["mem_div"][m]),
            seriestype=:scatter,
            mark=:circle
        )
    end
    savefigs(p, "err_vs_t.png")
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
for format in formats
    mkdir(@sprintf("%s/%s", plotsdir, format))
end

# make plots
plot_th_by_time_mult()
plot_errest_by_time_mult()
plot_time_by_time_mult()
plot_th_by_mem_div()
plot_errest_by_mem_div()
plot_time_by_mem_div()
plot_errest_by_time()
