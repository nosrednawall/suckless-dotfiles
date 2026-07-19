# Corrige todos os arquivos .sh e executáveis
find . -type f -executable -o -name "*.sh" | while read file; do
  if head -n1 "$file" | grep -q "^#!/bin/bash"; then
    echo "Corrigindo: $file"
    sed -i '1s|#!/bin/bash|#!/usr/bin/env bash|' "$file"
  fi
done
