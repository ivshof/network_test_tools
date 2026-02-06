#!/bin/bash
# Network latency and packet drop test script
# Example
# sudo ./network_sim.sh --latency 500 --jitter 200 --loss 50 --interface enp0s3


# Check if required arguments are provided
if [ $# -lt 4 ]; then
  echo "Usage: $0 --latency <value> --jitter <value> --loss <value> --interface <name>"
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case $1 in
    --latency) LATENCY=$2; shift 2 ;;
    --jitter) JITTER=$2; shift 2 ;;
    --loss) LOSS=$2; shift 2 ;;
    --interface) INTERFACE=$2; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Validate inputs
if ! [[ $LATENCY =~ ^[0-9]+(\.[0-9]+)?$ ]] || ! [[ $JITTER =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
  echo "Invalid latency or jitter value"
  exit 1
fi
if ! [[ $LOSS =~ ^[0-9]+(\.[0-9]+)?$ ]] || (( $(echo "$LOSS < 0 || $LOSS > 100" | bc -l) )); then
  echo "Invalid packet loss value"
  exit 1
fi
if ! ip link show $INTERFACE &> /dev/null; then
  echo "Interface $INTERFACE does not exist"
  exit 1
fi

# Check qdisc action
if tc qdisc show dev $INTERFACE | grep -q "qdisc"; then
  ACTION="replace"
else
  ACTION="add"
fi

# Apply settings
tc qdisc $ACTION dev $INTERFACE root netem delay ${LATENCY}ms ${JITTER}ms loss $LOSS%

echo "Current qdisc settings for $INTERFACE:"
tc qdisc show dev $INTERFACE
