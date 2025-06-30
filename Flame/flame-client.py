#!/usr/bin/python3

import sys
import random

sys.path.append('.')

from client import *
from domains import *

import numpy as np

PRECISION = 32

client_id = int(sys.argv[1])
n_parties = int(sys.argv[2])
model_size = int (sys.argv[3])
finish = int(sys.argv[4])

client = Client(['localhost'] * n_parties, 14000, client_id)

for socket in client.sockets:
    os = octetStream()
    os.store(finish)
    os.Send(socket)

def run(n, p):
    """
    Generate and send random model update with n weights and precision p to all clients.
    """
    model = [random.uniform(-1, 1) for _ in range(model_size)]

    # norm = np.linalg.norm(model)
    # print(f"Client {client_id} sending model: {model} with norm {norm}")

    model = [int(x * (1 << p)) for x in model]  # Convert to int representation
    client.send_private_inputs(model)

run(model_size, PRECISION)
