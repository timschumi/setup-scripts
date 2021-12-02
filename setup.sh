#!/bin/bash -e

if grep -q "Arch Linux" /etc/os-release; then
    curl "https://raw.githubusercontent.com/timschumi/setup-scripts/master/setup-arch.sh" | bash -
fi
