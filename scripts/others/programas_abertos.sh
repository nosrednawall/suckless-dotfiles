#!/usr/bin/env bash

# Obtém a lista de processos e agrupa os percentuais de memória para processos com o mesmo nome
processes=$(ps -eo comm,pmem --sort=-pmem | awk '
NR>1 {
    mem[$1] += $2;
}
END {
    for (proc in mem) {
        printf "%s %.1f\n", proc, mem[proc];
    }
}' | sort -k2,2nr | head -n 10)

# Cabeçalho da notificação
notification="Principais consumidores de RAM:\n"

# Itera sobre os processos agrupados
while IFS= read -r line; do
    comm=$(echo "$line" | awk '{print $1}')
    pmem=$(echo "$line" | awk '{print $2}')

    # Adiciona as informações ao texto da notificação
    notification+="  $comm ${pmem}%\n"
done <<< "$processes"

# Envia a notificação
notify-send "Monitor de Memória RAM" "$notification"
#echo -e $notification
