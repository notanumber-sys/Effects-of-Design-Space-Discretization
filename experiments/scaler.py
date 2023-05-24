import csv
import sys
from pathlib import Path


HEADER = ["time_res", "mem_res", "num_th", "exa_th", "time", "batch_size"]

# tool that scales all throughput values by a factor 6
def scale(identifier):
    data_path = Path(f"out_case_{identifier}.csv")
    if not data_path.is_file():
        print(f"Failed! {identifier} is not a valid identifier!")
        exit()

    entries = []
    with open(data_path, newline='') as handle:
        reader = csv.DictReader(handle)  # automatically reads header
        for entry in reader:
            entries.append(entry)
    
    with open(data_path, "w", newline='') as handle:
        writer = csv.DictWriter(handle, fieldnames=HEADER)
        for entry in entries:
            #print(entry)
            writer.writerow({
                "time_res": int(entry["time_res"]),
                "mem_res": int(entry["mem_res"]),
                "num_th": float(entry["num_th"])*6,
                "exa_th": float(entry["exa_th"])*6,
                "time": float(entry["time"]),
                "batch_size": int(entry["batch_size"])
            })

    print("Done")


if __name__=="__main__":
    if len(sys.argv) == 1:
        print("Please specify target identifier!")
        exit()

    identifier = sys.argv[1]
    scale(identifier)
