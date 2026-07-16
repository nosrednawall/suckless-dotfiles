#!/usr/bin/env bash
# ~/.doom.d/bin/org-to-ipynb.sh

if [ $# -eq 0 ]; then
    echo "Uso: $0 arquivo.org"
    exit 1
fi

org_file="$1"
base_name="${org_file%.*}"
ipynb_file="${base_name}.ipynb"

# Converter usando pandoc com opções específicas
pandoc -s "$org_file" -o "$ipynb_file" \
       --to ipynb \
       --from org \
       --metadata title="$(basename "$base_name")" \
       --metadata kernelspec:"{\"display_name\": \"Python 3\", \"language\": \"python\", \"name\": \"python3\"}" \
       --metadata language_info:"{\"name\": \"python\", \"version\": \"3.8.0\", \"mimetype\": \"text/x-python\", \"codemirror_mode\": {\"name\": \"ipython\", \"version\": 3}, \"pygments_lexer\": \"ipython3\", \"nbconvert_exporter\": \"python\", \"file_extension\": \".py\"}"

echo "Convertido: $org_file -> $ipynb_file"
