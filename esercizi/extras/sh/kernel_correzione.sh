#!/bin/env bash
# Questo script verifica se, il kernel attualmente in uso, è il più recente tra quelli installati.

if [ "$(uname -r)" == "$(rpm -q kernel | sort -V | tail -n 1 | cut -d'-' -f 2-)" ]; then
    echo "TRUE"
else
    echo "FALSE"
fi

