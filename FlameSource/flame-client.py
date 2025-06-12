#!/usr/bin/python3

import sys

sys.path.append('.')

from client import *
from domains import *
from random import random

client_id = int(sys.argv[1])
n_parties = int(sys.argv[2])
model_size = sys.argv[3]
finish = int(sys.argv[4])

client = Client(['localhost'] * n_parties, 14000, client_id)

# Handshake
for socket in client.sockets:
    os = octetStream()
    os.store(finish)
    os.Send(socket)

def run(x):
    client.send_private_inputs([x])

    print('Winning client id is :', client.receive_outputs(1)[0])

def send_model_update(n):
    """
    Generate and send random model update with n weights to all clients.
    """
    #generate random integer model update
    model = [int(random() * 100) for _ in range(int(n))]
    #make every client print id and update
    print(f'Client {client_id} sending model update: {model}')

    client.send_private_inputs(model)
    

# running two rounds
# first for sint, then for sfix
send_model_update(model_size)
