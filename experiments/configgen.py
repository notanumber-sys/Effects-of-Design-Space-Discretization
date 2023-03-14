
def generate():
    start_exp = int(input("Specify starting exponent: "))
    stop_exp  = int(input("Specify ending   exponent: "))
    steps_exp = int(input("Specify steping  exponent: "))

    if steps_exp > start_exp:
        print("Stepping exponent is greater than starting exponent!")
        exit()

    result = ""
    major = 2**start_exp
    for i in range(start_exp, stop_exp):
        major = 2**i
        step = 2**(i-steps_exp)
        for j in range(0, 2**steps_exp):
            result += str(int(major + step*j)) + " "
    return result + str(2**stop_exp)

if __name__=="__main__":
    print(generate())
