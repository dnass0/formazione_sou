#!/usr/bin/env bash
# Questo script cancella, nella directory corrente, tutti i file creati o modificati negli ultimi 30 giorni

find . -type f -mtime +30 -exec rm {} +
