#include "Math/gfp.h"
#include "Math/gf2n.h"
#include "Networking/sockets.h"
#include "Networking/ssl_sockets.h"
#include "Tools/int.h"
#include "Math/Setup.h"
#include "Protocols/fake-stuff.h"

#include "Math/gfp.hpp"
#include "ExternalIO/Client.hpp"

#include <sodium.h>
#include <iostream>
#include <sstream>
#include <fstream>
#include <random>
#include <chrono>
#include <vector>

const int N_PARTIES = 2;
const int PORT_BASE = 14000;

template<class T>
void run(int num_inputs, Client& client)
{
    cout << "Client generating " << num_inputs << " random weights" << endl;
    auto start = std::chrono::high_resolution_clock::now();

    std::vector<T> model(num_inputs, 0);
    // TODO: generate model?
    for (int i = 0; i < num_inputs; i++)
        model[i] = T(i + 1);

    client.send_private_inputs<T>(model);
    
    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed = end - start;    
    cout << "Time = " << elapsed.count() << " seconds" << endl;
    cout << endl;
}

int main(int argc, char** argv)
{
    int my_client_id;
    int num_clients;
    int num_inputs;

    if (argc < 4) {
        cout << "Usage is flame-client <client_id> <num_clients> <num_inputs> " << endl;
        exit(0);
    }

    my_client_id = atoi(argv[1]);
    num_clients = atoi(argv[2]);
    num_inputs = atoi(argv[3]);
    size_t finish = (my_client_id == num_clients - 1);
    vector<string> hostnames(N_PARTIES, "localhost");

    bigint::init_thread();

    Client client(hostnames, PORT_BASE, my_client_id);
    auto& specification = client.specification;
    auto& sockets = client.sockets;
    for (int i = 0; i < N_PARTIES; i++)
    {
        octetStream os;
        os.store(finish);
        os.Send(sockets[i]);
    }
    cout << "Finish setup socket connections to SPDZ engines." << endl;

    int type = specification.get<int>();
    switch (type)
    {
    case 'p':
    {
        gfp::init_field(specification.get<bigint>());
        cerr << "using prime " << gfp::pr() << endl;
        run<gfp>(num_inputs, client);
        break;
    }
    case 'R':
    {
        int R = specification.get<int>();
        int R2 = specification.get<int>();
        if (R2 != 64)
        {
            cerr << R2 << "-bit ring not implemented" << endl;
        }

        switch (R)
        {
        case 64:
            run<Z2<64>>(num_inputs, client);
            break;
        case 104:
            run<Z2<104>>(num_inputs, client);
            break;
        case 128:
            run<Z2<128>>(num_inputs, client);
            break;
        default:
            cerr << R << "-bit ring not implemented";
            exit(1);
        }
        break;
    }
    default:
        cerr << "Type " << type << " not implemented";
        exit(1);
    }

    return 0;
}