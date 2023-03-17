import random


def generate():
    start_exp = int(input("Specify starting exponent: "))
    stop_exp  = int(input("Specify ending   exponent: "))
    substeps  = int(input("Specify substeps         : "))

    result = ""
    for i in range(start_exp, stop_exp):
        major = 2**i
        newvalues = random.sample(range(major, major*2), substeps - 1)
        newvalues.sort()
        result += str(major) + " " + " ".join(str(v) for v in newvalues) + " "        
    return result + str(2**stop_exp)

if __name__=="__main__":
    print(generate())
