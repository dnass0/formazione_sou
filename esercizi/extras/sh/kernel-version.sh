#!/usr/bin/env bash
# Questo script verifica se la versione del kernel installata corrisponde con l'ultima disponibile, stampando TRUE o FALSE.

if [ "$(dnf repoquery --latest-limit=1 kernel 2>/dev/null | cut -d ":" -f 2 -s)" == "$(uname -r)" ]; then
	echo "TRUE"
else
	echo "FALSE"
fi
 
