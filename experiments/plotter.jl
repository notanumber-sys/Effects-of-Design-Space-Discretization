#!/bin/bash
#=
exec julia --color=yes --startup-file=no "${BASH_SOURCE[0]}" "$@"
=#

#@show ARGS

using Printf, Plots, CSV
using LinearAlgebra, Interpolations

# mode if program is run as script
mode = abspath(PROGRAM_FILE) == @__FILE__
formats = ["png", "svg", "pdf"]

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

function short_id(identifier)
    return replace(
        identifier,
        "sobel" => "S",
        "rasta" => "R",
        "jpegsdf" => "J",
        "ddense" => "dd",
        "dense" => "d"
    )
end

function plot_th_by_time_res(data, N, M)
    p = plot(
        data["time_res"][1:M:end],
        data["num_th"][1:M:end],
        xaxis=("time resolution", :log10),
        yaxis=("throughput [ops/s]"),
        title=@sprintf("Throughput vs. time resolution; %s", short_id(identifier)),
        label=@sprintf("num Th., mr=%d", data["mem_res"][1]),
        mark=(N>100 ? :x : :x),
        markersize=(N>100 ? 3 : 4),
        color=1,
        legend=:bottomright
    )
    for m in 2:M
        plot!(p,
            data["time_res"][m:M:end],
            data["num_th"][m:M:end],
            label=@sprintf("num Th., mr=%d", data["mem_res"][m]),
            mark=(N>100 ? :x : :x),
            markersize=(N>100 ? 3 : 4),
            color=m
        )
    end
    for m in 1:M
        plot!(p,
            data["time_res"][m:M:end],
            data["exa_th"][m:M:end],
            label=@sprintf("Th, mr=%d", data["mem_res"][m]),
            mark=(N>100 ? :circle : :circle),
            markersize=(N>100 ? 2 : 4),
            color=(M + m)
        )
    end
    savefigs(p, "th_vs_tr")
end

function plot_errest_by_time_res(data, N, M)
    correct = maximum(data["exa_th"])
    vals = correct.-data["num_th"][1:M:end]
    p = plot(
        data["time_res"][1:M:end][vals.>0],
        vals[vals.>0],
        xaxis=("time resolution", :log10),
        yaxis=("error estimate (in Th) [ops/s]", :log10),
        title=@sprintf("Error vs. time resolution; %s", short_id(identifier)),
        label=@sprintf("total error, mr=%d", data["mem_res"][1]),
        mark=(N>100 ? :x : :x),
        markersize=(N>100 ? 3 : 4),
        color=1,
        legend=:topright
    )
    for m in 2:M
        vals = correct.-data["num_th"][m:M:end]
        plot!(p,
            data["time_res"][m:M:end][vals.>0],
            vals[vals.>0],
            label=@sprintf("total error, mr=%d", data["mem_res"][m]),
            mark=(N>100 ? :x : :x),
            markersize=(N>100 ? 3 : 4),
            color=m
        )
    end
    for m in 1:M
        vals_exa = correct.-data["exa_th"][m:M:end]
        plot!(p,
            data["time_res"][m:M:end][vals_exa.>0],
            vals_exa[vals_exa.>0],
            label=@sprintf("solution error, mr=%d", data["mem_res"][m]),
            mark=(N>100 ? :circle : :circle),
            markersize=(N>100 ? 2 : 4),
            color=(M + m)
        )
    end
    savefigs(p, "err_vs_tr")
end

function plot_time_by_time_res(data, N, M)
    picklog = maximum(data["time"])/minimum(data["time"])>50
    p = plot(
        data["time_res"][1:M:end],
        data["time"][1:M:end],
        xaxis=("time resolution", :log10),
        yaxis=("run time [s]", picklog ? :log10 : :identity),
        title=@sprintf("Median time vs. tr; B=%d; %s", data["batch_size"][1], short_id(identifier)),
        label=@sprintf("run time, mr=%d", data["mem_res"][1]),
        mark=(N>100 ? (picklog ? :circle : :none) : :circle),  # nested ternaries are good practice
        markersize=(N>100 ? 2 : 4),
        legend=:topleft
    )
    for m in 2:M
        plot!(p,
            data["time_res"][m:M:end],
            data["time"][m:M:end],
            label=@sprintf("run time, mr=%d", data["mem_res"][m]),
            mark=(N>100 ? :none : :circle)
        )
    end
    savefigs(p, "t_vs_tr")
end

function plot_errest_by_time(data, N, M)
    correct = maximum(data["exa_th"])
    vals = correct.-data["num_th"][1:M:end]
    p = plot(
        data["time"][1:M:end][vals.>0],
        vals[vals.>0],
        xaxis=("time [s]"),
        yaxis=("error estimate (in Th) [ops/s]", :log10),
        title=@sprintf("Error est. vs. median time; B=%d; %s", data["batch_size"][1], short_id(identifier)),
        label=@sprintf("total error, mr=%d", data["mem_res"][1]),
        seriestype=:scatter,
        mark=:x,
        color=1,
        legend=:topright
    )
    for m in 2:M
        vals = correct.-data["num_th"][m:M:end]
        plot!(p,
            data["time"][m:M:end][vals.>0],
            vals[vals.>0],
            label=@sprintf("total error, mr=%d", data["mem_res"][m]),
            seriestype=:scatter,
            mark=:x,
            color=m
        )
    end
    for m in 1:M
        vals_exa = correct.-data["exa_th"][m:M:end]
        plot!(p,
            data["time"][m:M:end][vals_exa.>0],
            vals_exa[vals_exa.>0],
            label=@sprintf("solution error, mr=%d", data["mem_res"][m]),
            seriestype=:scatter,
            mark=:circle,
            color=(M + m)
        )
    end
    savefigs(p, "err_vs_t.png")
end

function plot_th_by_time_res_comp(data1, N1, M1, data2, N2, M2)
    p = plot(
        data2["time_res"][1:M2:end],
        data2["num_th"][1:M2:end],
        xaxis=("time resolution", :log10),
        yaxis=("throughput [ops/s]"),
        title=@sprintf("Throughput vs. time resolution; %s, %s", short_id(identifier), short_id(identifier2)),
        label=@sprintf("num Th., %s, mr=%d", short_id(identifier2), data2["mem_res"][1]),
        mark=:x,
        markersize=3,
        linestyle=:dash,
        color=1,
        legend=:bottomright
    )
    for m in 2:M2
        plot!(p,
            data2["time_res"][m:M2:end],
            data2["num_th"][m:M2:end],
            label=@sprintf("num Th., %s, mr=%d", short_id(identifier2), data2["mem_res"][m]),
            mark=:x,
            markersize=3,
            linestyle=:dash,
            color=m
        )
    end
    for m in 1:M1
        plot!(p,
            data1["time_res"][m:M1:end],
            data1["num_th"][m:M1:end],
            label=@sprintf("num Th., %s, mr=%d", short_id(identifier), data1["mem_res"][m]),
            mark=:circle,
            seriestype=:scatter,
            color=m
        )
    end
    for m in 1:M2
        plot!(p,
            data2["time_res"][m:M2:end],
            data2["exa_th"][m:M2:end],
            label=@sprintf("Th., %s, mr=%d", short_id(identifier2), data2["mem_res"][m]),
            mark=:x,
            markersize=3,
            linestyle=:dash,
            color=(M1 + m)
        )
    end
    for m in 1:M1
        plot!(p,
            data1["time_res"][m:M1:end],
            data1["exa_th"][m:M1:end],
            label=@sprintf("Th., %s, mr=%d", short_id(identifier), data1["mem_res"][m]),
	        seriestype=:scatter, 
            mark=:circle,
            color=(M1 + m)
        )
    end
    savefigs(p, "th_vs_tr")
    return p
end

function plot_errest_by_time_res_comp(data1, N1, M1, data2, N2, M2)
    correct = max(maximum(data1["exa_th"]), maximum(data2["exa_th"]))
    vals2 = correct.-data2["num_th"][1:M2:end]
    p = plot(
        data2["time_res"][1:M2:end][vals2.>0],
        vals2[vals2.>0],
        label=@sprintf("total error, %s, mr=%d", short_id(identifier2), data2["mem_res"][1]),
        mark=:x,
        markersize=3,
        linestyle=:dash,
        color=1,
        xaxis=("time resolution", :log10),
        yaxis=("error estimate (in Th) [ops/s]", :log10),
        title=@sprintf("Error estimate vs. time resolution; %s, %s", short_id(identifier), short_id(identifier2)),
        legend=:bottomleft
    )
    for m in 2:M2
        vals2 = correct.-data2["num_th"][m:M2:end]
        plot!(p,
            data2["time_res"][m:M2:end][vals2.>0],
            vals2[vals2.>0],
            label=@sprintf("total error, %s, mr=%d", short_id(identifier2), data2["mem_res"][m]),
            mark=:x,
            markersize=3,
            linestyle=:dash,
            color=m
        )
    end
    for m in 1:M1
        vals1 = correct.-data1["num_th"][m:M1:end]
        plot!(p,
            data1["time_res"][m:M1:end][vals1.>0],
            vals1[vals1.>0],
            label=@sprintf("total error, %s, mr=%d", short_id(identifier), data1["mem_res"][m]),
            mark=:circle,
            seriestype=:scatter,
            color=m
        )
    end
    for m in 1:M2
        vals_exa = correct.-data2["exa_th"][m:M2:end]
        plot!(p,
            data2["time_res"][m:M2:end][vals_exa.>0],
            vals_exa[vals_exa.>0],
            label=@sprintf("solution error, %s, mr=%d", short_id(identifier2), data2["mem_res"][m]),
    	    mark=:x,
            markersize=3,
            linestyle=:dash,
            color=(M1 + m)
        )
    end
    for m in 1:M1
        vals_exa = correct.-data1["exa_th"][m:M1:end]
        plot!(p,
            data1["time_res"][m:M1:end][vals_exa.>0],
            vals_exa[vals_exa.>0],
            label=@sprintf("solution error, %s, mr=%d", short_id(identifier), data1["mem_res"][m]),
    	    seriestype=:scatter,
            mark=:circle,
            color=(M1 + m)
        )
    end
    savefigs(p, "err_vs_tr")
    return p
end

function insert_bound_estimates(p1, data1, N1, M1, p2, data2, N2, M2, identifier)
    sid = short_id(identifier)
    firing_card = 0.0
    actors_time = 0.0
    t_max = 0.0
    # values computed in report, see section 5.4.3.1
    firing_cards = [4, 7, 16]
    actors_times = [776.1, 1315.6, 10062.0].*(1e-6)
    comm_times = [0.56, 0.6, 0.8].*(1e-6)    
    # compute estimate throughput bound from lookup
    for (i, id) in enumerate(["S", "R", "J"])
        if occursin(id, sid)
            firing_card += firing_cards[i]
            actors_time += actors_times[i]
            t_max += actors_times[i]+ comm_times[i]
        end
    end
    # obtain tiles
    tiles = 0.0
    for i in 1:9
        if occursin(string(i), sid)
            tiles += i
        end
    end
    gamma = 2 # single communication element
    # optimal throughput bound
    throughput_bound = tiles/actors_time
    bound_type = "bound"
    throughput = max(maximum(data1["exa_th"]), maximum(data2["exa_th"]))

    if maximum(data2["exa_th"]) != data2["exa_th"][end]
        throughput = throughput_bound
        bound_type = "approximate bound"
    end

    # total bounding coefficient
    C = throughput^2 * firing_card * t_max * (gamma + 1)
    ebound = p -> 2*C/p
    tbound = p -> throughput - ebound(p)

    # add bound to throughput plot
    plot!(p1,
        data2["time_res"][1:M2:end],
        tbound.(data2["time_res"][1:M2:end]),
        label=@sprintf("%s, C=%.2f", bound_type, C),
        ylims=(0, 1.05*throughput),
        color=:red,
        linestyle=:dash
    )

    # add bound to error plot
    plot!(p2,
        data2["time_res"][1:M2:end],
        ebound.(data2["time_res"][1:M2:end]),
        label=@sprintf("%s, C=%.2f", bound_type, C),
        color=:red,
        linestyle=:dash
    )
end

#TODO: Update
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
        title=@sprintf("Throughput deviation; case: %s, %s", short_id(identifier), short_id(identifier2)),
        label=@sprintf("Error deviation, mr=%d", data1["mem_res"][1]),
        seriestype=:scatter,
        mark=:x,
        legend=:topright
    )
    plot!(p,
        data2["time_res"][1:M2:end][index_set],
        ref.(data2["time_res"][1:M2:end][index_set]),
        label=@sprintf("Reference %.3f/x", error_series[max_index]),
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
    plot_errest_by_time_res(data, N, M)
    plot_time_by_time_res(data, N, M)
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
    p1 = plot_th_by_time_res_comp(data1, N1, M1, data2, N2, M2)
    p2 = plot_errest_by_time_res_comp(data1, N1, M1, data2, N2, M2)
    throughput_deviation_comp(data1, N1, M1, data2, N2, M2)

    cp = plot(p1, p2, layout=(2, 1), size=(600, 800))
    savefigs(cp, "combo")

    insert_bound_estimates(p1, data1, N1, M1, p2, data2, N2, M2, identifier)
    savefigs(p1, "th_vs_tr_bounds")
    cpb = plot(p1, p2, layout=(2, 1), size=(600, 800))
    #cpb = plot(p1, p2, layout=(1, 2), size=(1000, 400))
    savefigs(cpb, "combo_bounds")
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
