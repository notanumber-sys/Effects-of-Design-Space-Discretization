import csv
import json
import sys
from pathlib import Path


HEADER = ["time_res", "mem_res", "num_th", "exa_th", "time", "batch_size"]

def median(values):
    if values is None or len(values) == 0:
        return None
    values.sort()
    if len(values) % 2 == 1:
        return values[len(values)//2]
    return (values[len(values)//2 - 1] + values[len(values)//2])/2

def get_throughput(data):
    return min(data)

def convert(identifier):
    data_src = Path(f"so_case_{identifier}")
    cfg_src = Path(f"in_case_{identifier}/config")
    time_src = Path(f"so_case_{identifier}/times")
    res_file = Path(f"out_case_{identifier}.csv")
    
    if (not data_src.is_dir()) or (not cfg_src.is_file()) or (not time_src.is_file()):
        print(f"Failed! {identifier} is not a valid identifier!")
        exit()

    # read configuration
    time_discs = None
    mem_discs = None
    with open(cfg_src, "r") as handle:
        time_discs = [int(val) for val in handle.readline().strip().split()]
        mem_discs = [int(val) for val in handle.readline().strip().split()]

    times = []
    batch_size = 1
    with open(time_src, "r") as handle:
        for line in handle:
            line = line.strip()
            if line == "":
                continue
            entries = line.split()
            batch_size = len(entries)
            times.append(median([float(val) for val in entries]))

    if len(times) != len(time_discs)*len(mem_discs):
        print("Incorrect times format!")
        exit()

    with open(res_file, "w", newline="") as handle:
        csv_writer = csv.DictWriter(handle, fieldnames=HEADER)
        csv_writer.writeheader()
        counter = 0
        for tr in time_discs:
            for mr in mem_discs:
                json_src = Path(f"so_case_{identifier}/{tr}_{mr}.json")
                json_handle = open(json_src, "r")
                json_data = json.load(json_handle)
                json_handle.close()
                entry = {
                    "time_res": tr,
                    "mem_res": mr,
                    "num_th": get_throughput(json_data["sdfApplications"]["minimumActorThroughputs"]),
                    "exa_th": get_throughput(json_data["actorThroughputs"]),
                    "time": times[counter],
                    "batch_size": batch_size
                }
                csv_writer.writerow(entry)
                counter += 1


if __name__=="__main__":
    if len(sys.argv) == 1:
        print("Please specify target identifier!")
        exit()

    identifier = sys.argv[1]
    convert(identifier)