#!/usr/bin/python3

import sys
import random

sys.path.append(".")

from client import *
from domains import *

import time

PRECISION = 16
N_PARTIES = 2

client_id = int(sys.argv[1])
num_clients = int(sys.argv[2])
num_inputs = int(sys.argv[3])
finish = client_id == num_clients - 1

client = Client(["localhost"] * N_PARTIES, 14000, client_id)

for socket in client.sockets:
    os = octetStream()
    os.store(finish)
    os.Send(socket)


def run(n, p):
    """
    Generate and send random model update with n weights and precision p to all parties.
    Args:
        n (int): Number of weights in the model.
        p (int): Precision for the weights.
    """
    start = time.perf_counter()
    model = [random.uniform(0, 1) for _ in range(n)]
    # print(f"Client {client_id} generated model: {model}")

    # Convert to fixed-point integer representation
    model = [int(x * (1 << p)) for x in model]

    print(f"Sending model update to {N_PARTIES} parties")
    # print(f"Client {client_id} sending model: {model}")
    client.send_private_inputs(model)
    end = time.perf_counter()
    print(f"Time: {end - start:.6f} seconds")


run(num_inputs, PRECISION)
print("")
