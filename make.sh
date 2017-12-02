#!/bin/sh

set -e

yosys -p "synth_ice40 -blif main.blif" main.sv
arachne-pnr -d 1k -P tq144 -p main.pcf main.blif -o main.asc
icepack main.asc main.bin
iceprog main.bin
