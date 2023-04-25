for i in 2 3 4
do
    echo "S${i}..."
    ./plotter.jl sobel${i}
    ./plotter.jl sobel${i}ddense
    ./plotter.jl sobel${i} sobel${i}ddense
done

for i in 2 3
do
    echo "J${i}..."
    ./plotter.jl jpegsdf${i}
    ./plotter.jl jpegsdf${i}dense
    ./plotter.jl jpegsdf${i} jpegsdf${i}dense
done

for i in 2 4
do
    echo "SR${i}..."
    ./plotter.jl sobelrasta${i}
    ./plotter.jl sobelrasta${i}dense
    ./plotter.jl sobelrasta${i} sobelrasta${i}dense
done

for i in 2 3 #4
do
    echo "RJ${i}..."
    ./plotter.jl rastajpegsdf${i}
    ./plotter.jl rastajpegsdf${i}dense
    ./plotter.jl rastajpegsdf${i} rastajpegsdf${i}dense
done

#for i in 2
#do
#    echo "SRJ${i}..."
#    ./plotter.jl sobelrastajpegsdf${i}
#    ./plotter.jl sobelrastajpegsdf${i}dense
#    ./plotter.jl sobelrastajpegsdf${i} sobelrastajpegsdf${i}dense
#done

echo "DONE!"
