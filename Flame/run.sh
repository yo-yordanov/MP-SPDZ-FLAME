#!/usr/bin/env bash

# Benchmark private FLAME
for CLI in 10 20 30; do
    for INP in 100000 300000 500000; do
        bash Flame/benchmark.sh -b private -c "$CLI" -i "$INP" -r 1
        echo ""
    done
done

# Benchmark leaky FLAME
for CLI in 10 20 30; do
    for INP in 100000 300000 500000; do
        bash Flame/benchmark.sh -b leaky -c "$CLI" -i "$INP" -r 1
        echo ""
    done
done