#!/bin/bash
#=
exec julia --color=yes --startup-file=no "${BASH_SOURCE[0]}" "$@"
=#

#@show ARGS

using Printf, Plots, CSV
using LinearAlgebra, Interpolations

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

function bound_estimator(x, a, f)
    inum = x ÷ a + 1
    return f(x/(inum*a))
end

function bound_estimator_factory(data, N)
    #k = data["num_th"][1]/data["time_res"][1]   # slope
    k = 1
    a = Int(round(data["num_th"][end]/k))        # range of linearity
    f = x -> a*x                                    # identity
    #          throughput estimate            monotonous bound
    return (x -> bound_estimator(x, a, f)), (x -> f(x/(x + a)))
end

function plot_th_by_time_res(data, N, M)
    p = plot(
        data["time_res"][1:M:end],
        data["num_th"][1:M:end],
        xaxis=("time resolution", :log10),
        yaxis=("throughput"),
        title=@sprintf("Th vs. tr; case: %s", identifier),
        label=@sprintf("Disc Th., mr=%d", data["mem_res"][1]),
        mark=(N>100 ? :none : :x),
        legend=:bottomright,
        linestyle=:dash
    )
    for m in 2:M
        plot!(p,
            data["time_res"][m:M:end],
            data["num_th"][m:M:end],
            label=@sprintf("Disc Th., mr=%d", data["mem_res"][m]),
            mark=(N>100 ? :none : :x),
            linestyle=:dash
        )
    end
    for m in 1:M
        plot!(p,
            data["time_res"][m:M:end],
            data["exa_th"][m:M:end],
            label=@sprintf("Throughput, mr=%d", data["mem_res"][m]),
            mark=(N>100 ? :none : :circle)
        )
    end
    savefigs(p, "th_vs_tr")
end

#TODO: Update
function plot_th_by_time_res_analysis(data, N, M)
    be, le = bound_estimator_factory(data, N)
    p = plot(
        data["time_res"][1:M:end],
        be.(data["time_res"][1:M:end]),
        xaxis=("time resolution", :log10),
        yaxis=("throughput"),
        title=@sprintf("Th analysis; case: %s", identifier),
        label="predicted throughput",
        legend=:bottomright
    )
    plot!(p,
        data["time_res"][1:M:end],
        data["num_th"][1:M:end],
        label=@sprintf("Disc Th., mr=%d", data["mem_res"][1]),
        seriestype=:scatter,
        mark=:x
    )
    plot!(p,
        data["time_res"][1:M:end],
        le.(data["time_res"][1:M:end]),
        label=@sprintf("lower bound"),
        linestyle=:dash
    )
    plot!(p,
        data["time_res"][1:M:end],
        ones(N).*data["num_th"][end],
        label=@sprintf("upper bound"),
        linestyle=:dash
    )
    savefigs(p, "th_vs_tr_analysis")
end

function plot_errest_by_time_res(data, N, M)
    correct = data["exa_th"][end]
    vals = correct.-data["num_th"][1:M:end]
    p = plot(
        data["time_res"][1:M:end][vals.>0],
        vals[vals.>0],
        xaxis=("time resolution", :log10),
        yaxis=("error estimate", :log10),
        title=@sprintf("Error numerical vs. tr; case: %s", identifier),
        label=@sprintf("Disc Th., mr=%d", data["mem_res"][1]),
        mark=(N>100 ? :none : :x),
        legend=:topright,
        linestyle=:dash
    )
    for m in 2:M
        vals = correct.-data["num_th"][m:M:end]
        plot!(p,
            data["time_res"][m:M:end][vals.>0],
            vals[vals.>0],
            label=@sprintf("Disc Th., mr=%d", data["mem_res"][m]),
            mark=(N>100 ? :none : :x),
            linestyle=:dash
        )
    end
    for m in 1:M
        vals_exa = correct.-data["exa_th"][m:M:end]
        plot!(p,
            data["time_res"][m:M:end][vals_exa.>0],
            vals_exa[vals_exa.>0],
            label=@sprintf("Error exact, mr=%d", data["mem_res"][m]),
            mark=(N>100 ? :none : :circle)
        )
    end
    savefigs(p, "err_vs_tr")
end

#TODO: Update
function plot_errest_by_time_res_analysis(data, N, M)
    be, le = bound_estimator_factory(data, N)
    correct = data["num_th"][end]
    vals = correct.-data["num_th"][1:M:end]
    bvals = correct.-be.(data["time_res"][1:M:end])
    lvals = correct.-le.(data["time_res"][1:M:end])
    p = plot(
        data["time_res"][1:M:end][bvals.>0],
        bvals[bvals.>0],
        xaxis=("time resolution", :log10),
        yaxis=("throughput", :log10),
        title=@sprintf("Error analysis; case: %s", identifier),
        label="predicted throughput error"
    )
    plot!(p,
        data["time_res"][1:M:end][vals.>0],
        vals[vals.>0],
        label=@sprintf("Disc Th., mr=%d", data["mem_res"][1]),
        seriestype=:scatter,
        mark=:x
    )
    plot!(p,
        data["time_res"][1:M:end][lvals.>0],
        lvals[lvals.>0],
        label=@sprintf("bound"),
        linestyle=:dash
    )
    savefigs(p, "err_vs_tr_analysis")
end

function plot_time_by_time_res(data, N, M)
    p = plot(
        data["time_res"][1:M:end],
        data["time"][1:M:end],
        xaxis=("time resolution", :log10),
        yaxis=("run time", :log10),
        title=@sprintf("Median time vs. tr; batches: %d; case: %s", data["batch_size"][1], identifier),
        label=@sprintf("Disc Th., mr=%d", data["mem_res"][1]),
        mark=(N>100 ? :none : :circle),
        legend=:bottomright
    )
    for m in 2:M
        plot!(p,
            data["time_res"][m:M:end],
            data["time"][m:M:end],
            label=@sprintf("Disc Th., mr=%d", data["mem_res"][m]),
            mark=(N>100 ? :none : :circle)
        )
    end
    savefigs(p, "t_vs_tr")
end

#TODO: Update
function plot_th_by_mem_res(data, N, M)
    p = plot(
        data["mem_res"][1:M],
        data["num_th"][1:M],
        xaxis=("memory resolution", :log10),
        yaxis=("throughput"),
        title=@sprintf("Th vs. mr; case: %s", identifier),
        label=@sprintf("Disc Th., tr=%d", data["time_res"][1]),
        mark=:circle,
        legend=:bottomright
    )
    for n in 2:N
        plot!(p,
            data["mem_res"][M*(n-1)+1:M*n],
            data["num_th"][M*(n-1)+1:M*n],
            label=@sprintf("Disc Th., tr=%d", data["time_res"][n*M]),
            mark=:circle
        )
    end
    savefigs(p, "th_vs_mr")
end

#TODO: Update
function plot_errest_by_mem_res(data, N, M)
    correct = data["exa_th"][end]
    vals = correct.-data["num_th"][1:M]
    p = plot(
        data["mem_res"][1:M][vals.>0],
        vals[vals.>0],
        xaxis=("memory resolution", :log10),
        yaxis=("error estimate", :log10),
        title=@sprintf("Error estimate vs. mr; case: %s", identifier),
        label=@sprintf("Disc Th., tr=%d", data["time_res"][1]),
        mark=:circle,
        legend=:topright
    )

    for n in 2:N
        vals = correct.-data["num_th"][M*(n-1)+1:M*n]
        plot!(p,
            data["time_res"][M*(n-1)+1:M*n][vals.>0],
            vals[vals.>0],
            label=@sprintf("Disc Th., tr=%d", data["time_res"][n*M]),
            mark=:circle
        )
    end
    savefigs(p, "err_vs_mr")
end

#TODO: Update
function plot_time_by_mem_res(data, N, M)
    p = plot(
        data["mem_res"][1:M],
        data["time"][1:M],
        xaxis=("memory resolution", :log10),
        yaxis=("run time"),
        title=@sprintf("Median time vs. mr; batches: %d; case: %s", data["batch_size"][1], identifier),
        label=@sprintf("Disc Th., tr=%d", data["time_res"][1]),
        mark=:circle,
        legend=:bottomright
    )
    for n in 2:N
        plot!(p,
            data["mem_res"][M*(n-1)+1:M*n],
            data["time"][M*(n-1)+1:M*n],
            label=@sprintf("Disc Th., tr=%d", data["time_res"][n*M]),
            mark=:circle
        )
    end
    savefigs(p, "t_vs_mr")
end

function plot_errest_by_time(data, N, M)
    correct = data["exa_th"][end]
    vals = correct.-data["num_th"][1:M:end]
    p = plot(
        data["time"][1:M:end][vals.>0],
        vals[vals.>0],
        xaxis=("time [s]"),
        yaxis=("error estimate", :log10),
        title=@sprintf("Error est. vs. median time; batches: %d; case: %s", data["batch_size"][1], identifier),
        label=@sprintf("Disc Th., mr=%d", data["mem_res"][1]),
        seriestype=:scatter,
        mark=:x,
        legend=:topright
    )
    for m in 2:M
        vals = correct.-data["num_th"][m:M:end]
        plot!(p,
            data["time"][m:M:end][vals.>0],
            vals[vals.>0],
            label=@sprintf("Disc Th., mr=%d", data["mem_res"][m]),
            seriestype=:scatter,
            mark=:x
        )
    end
    for m in 1:M
        vals_exa = correct.-data["exa_th"][m:M:end]
        plot!(p,
            data["time"][m:M:end][vals_exa.>0],
            vals_exa[vals_exa.>0],
            label=@sprintf("Error exact, mr=%d", data["mem_res"][m]),
            seriestype=:scatter,
            mark=:circle
        )
    end
    savefigs(p, "err_vs_t.png")
end

function plot_th_by_time_res_comp(data1, N1, M1, data2, N2, M2)
    p = plot(
        data1["time_res"][1:M1:end],
        data1["num_th"][1:M1:end],
        xaxis=("time resolution", :log10),
        yaxis=("throughput"),
        title=@sprintf("Th vs. tr comp; case: %s, %s", identifier, identifier2),
        label=@sprintf("Disc Th., %s, mr=%d", identifier, data1["mem_res"][1]),
        mark=:x,
        legend=:bottomright
    )
    for m in 2:M1
        plot!(p,
            data1["time_res"][m:M1:end],
            data1["num_th"][m:M1:end],
            label=@sprintf("Disc Th., %s, mr=%d", identifier, data1["mem_res"][m]),
            mark=:x
        )
    end
    for m in 1:M2
        plot!(p,
            data2["time_res"][m:M2:end],
            data2["num_th"][m:M2:end],
            label=@sprintf("Disc Th., %s, mr=%d", identifier2, data2["mem_res"][m]),
            mark=:none
        )
    end
    for m in 1:M2
        plot!(p,
            data2["time_res"][m:M2:end],
            data2["exa_th"][m:M2:end],
            label=@sprintf("Throughput, mr=%d", data1["mem_res"][m]),
            mark=(N2>100 ? :none : :circle)
        )
    end
    savefigs(p, "th_vs_tr")
end

function plot_errest_by_time_res_comp(data1, N1, M1, data2, N2, M2)
    correct = max(data1["exa_th"][end], data2["exa_th"][end])
    vals1 = correct.-data1["num_th"][1:M1:end]
    p = plot(
        data1["time_res"][1:M1:end][vals1.>0],
        vals1[vals1.>0],
        xaxis=("time resolution", :log10),
        yaxis=("error estimate", :log10),
        title=@sprintf("Error estimate vs. tr comp; case: %s, %s", identifier, identifier2),
        label=@sprintf("Disc Th., %s, mr=%d", identifier, data1["mem_res"][1]),
        mark=:x,
        legend=:topright
    )
    for m in 2:M1
        vals1 = correct.-data1["num_th"][m:M1:end]
        plot!(p,
            data1["time_res"][m:M1:end][vals1.>0],
            vals1[vals1.>0],
            label=@sprintf("Disc Th., %s, mr=%d", identifier, data1["mem_res"][m]),
            mark=:x
        )
    end
    for m in 1:M2
        vals2 = correct.-data2["num_th"][m:M2:end]
        plot!(p,
            data2["time_res"][m:M2:end][vals2.>0],
            vals2[vals2.>0],
            label=@sprintf("Disc Th., %s, mr=%d", identifier2, data2["mem_res"][m]),
            mark=:none
        )
    end
    for m in 1:M1
        vals_exa = correct.-data1["exa_th"][m:M1:end]
        plot!(p,
            data1["time_res"][m:M1:end][vals_exa.>0],
            vals_exa[vals_exa.>0],
            label=@sprintf("Error exact, mr=%d", data1["mem_res"][m]),
            mark=:circle
        )
    end
    savefigs(p, "err_vs_tr")
end

function throughput_deviation_comp(data1, N1, M1, data2, N2, M2)
    TOL = 1e-8
    interpolator = LinearInterpolation(data1["time_res"][1:M1:end], data1["num_th"][1:M1:end])
    index_set = (data2["time_res"][1:M2:end].>=data1["time_res"][1]).&(data2["time_res"][1:M2:end].<=data1["time_res"][end])
    error_series = abs.(data2["num_th"][1:M2:end][index_set] - interpolator.(data2["time_res"][1:M2:end][index_set]))
    max_index = argmax(error_series.*data2["time_res"][1:M2:end][index_set])
    ref = x -> (error_series[max_index]*data2["time_res"][1:M2:end][index_set][max_index])/x
    p = plot(
        data2["time_res"][1:M2:end][index_set][error_series.>TOL],
        error_series[error_series.>TOL],
        xaxis=("time resolution", :log10),
        yaxis=("throughput deviation", :log10),
        title=@sprintf("Th deviation; case: %s, %s", identifier, identifier2),
        label=@sprintf("Error deviation, mr=%d", data1["mem_res"][1]),
        seriestype=:scatter,
        mark=:x,
        legend=:topright
    )
    plot!(p,
        data2["time_res"][1:M2:end][index_set],
        ref.(data2["time_res"][1:M2:end][index_set]),
        label=@sprintf("Reference %.2f/x", error_series[max_index]),
        linestyle=:dash
    )
    savefigs(p, "th_dev_vs_tr")
end

function plot_errdiv_by_time_res_comp(data1, N1, M1, data2, N2, M2)
    @printf("TBD\n")
end

function load_data(identifier)
    target = @sprintf("out_case_%s.csv", identifier)
    data, N, M = read_data(target)
    return data, N, M
end

function single_analysis(identifier)
    global plotsdir = @sprintf("plt_case_%s", identifier)
    data, N, M = load_data(identifier)
    rm(plotsdir, force=true, recursive=true)
    mkdir(plotsdir)
    for format in formats
        mkdir(@sprintf("%s/%s", plotsdir, format))
    end
    
    # make plots
    plot_th_by_time_res(data, N, M)
    #plot_th_by_time_res_analysis(data, N, M)
    plot_errest_by_time_res(data, N, M)
    #plot_errest_by_time_res_analysis(data, N, M)
    plot_time_by_time_res(data, N, M)
    #plot_th_by_mem_res(data, N, M)
    #plot_errest_by_mem_res(data, N, M)
    #plot_time_by_mem_res(data, N, M)
    plot_errest_by_time(data, N, M)
end

function double_analysis(identifier_sparse, identifier_dense)
    global plotsdir = @sprintf("plt_dcase_%s_%s", identifier_sparse, identifier_dense)
    data1, N1, M1 = load_data(identifier_sparse)
    data2, N2, M2 = load_data(identifier_dense)
    rm(plotsdir, force=true, recursive=true)
    mkdir(plotsdir)
    for format in formats
        mkdir(@sprintf("%s/%s", plotsdir, format))
    end

    # make plots
    plot_th_by_time_res_comp(data1, N1, M1, data2, N2, M2)
    plot_errest_by_time_res_comp(data1, N1, M1, data2, N2, M2)
    throughput_deviation_comp(data1, N1, M1, data2, N2, M2)
end

# determine target
identifier = "test"
identifier2 = nothing
if mode
    if length(ARGS) == 1
        global identifier = strip(ARGS[1])
    elseif length(ARGS) == 2
        global identifier = strip(ARGS[1])
        global identifier2 = strip(ARGS[2])
    else
        @printf("Invalid arguments!\n")
        @printf("    Please specify one or two target identifiers.\n")
        exit(0)
    end
end

if isnothing(identifier2)
    single_analysis(identifier)
else
    double_analysis(identifier, identifier2)
end
