#!/usr/bin/env bash

# Configurações
if [ "$1" = "adicionar" ]; then
    SERVER=$2
    USUARIO=$3
    SENHA=$4
    MOUNT_POINT="/mnt/samba_share/$SERVER"
else
    SERVER=$2
    SHARE=$3
    MOUNT_POINT="/mnt/samba_share/$SERVER/$SHARE"
fi

# Porta padrão, lembre-se que no Umbrel a porta padrão é 446, altere no Umbrel ou no seu sistema o que lhe for mais conveniente
# 445
OPTIONS="workgroup=workgroup,iocharset=utf8,uid=1000,gid=1000"

# Função para montar o compartilhamento
montar() {
    # Criar o diretório de montagem, se não existir
    if [ ! -d "$MOUNT_POINT" ]; then
        echo "Criando diretório de montagem: $MOUNT_POINT"

        sudo mkdir -p "$MOUNT_POINT"
    fi

    # Verificar se já está montado
    if mount | grep -q "$MOUNT_POINT"; then
        echo "O compartilhamento já está montado em $MOUNT_POINT."
    else
        echo "Montando o compartilhamento..."
        #sudo mount -t cifs "//$SERVER/$SHARE" "$MOUNT_POINT" -o username=$USERNAME,password=$PASSWORD,$OPTIONS
        sudo mount -t cifs "//$SERVER/$SHARE" "$MOUNT_POINT" -o credentials="/etc/samba/credentials/$SERVER",$OPTIONS

        # Verificar se a montagem foi bem-sucedida
        if mount | grep -q "$MOUNT_POINT"; then
            echo "Montagem concluída com sucesso!"
            # Defina o nome do usuário
            USUARIO="anderson"

            # Abre a pasta para o usuario, pois o script esta executando como root
            sudo -u $USUARIO thunar "$MOUNT_POINT" &
        else
            echo "Erro ao montar o compartilhamento."
        fi
    fi
}

# Função para desmontar o compartilhamento
desmontar() {
    if mount | grep -q "$MOUNT_POINT"; then
        echo "Desmontando $MOUNT_POINT..."
        sudo umount "$MOUNT_POINT"

        if mount | grep -q "$MOUNT_POINT"; then
            echo "Erro ao desmontar o compartilhamento."
        else
            echo "Desmontagem concluída com sucesso!"
        fi
    else
        echo "O compartilhamento não está montado."
    fi
}

adicionar() {
    echo "username=$USUARIO\npassword=$SENHA"
    echo -e "username=$USUARIO\npassword=$SENHA" | sudo tee /etc/samba/credentials/$SERVER > /dev/null

    # Cria a pasta do servidor
    if [ ! -d "$MOUNT_POINT" ]; then
        echo "Criando diretório de montagem: $MOUNT_POINT"

        sudo mkdir -p "$MOUNT_POINT"
    fi
    echo "As credenciais do servidor $SERVER foram adicionadas com sucesso"
}

# Verificar argumento passado
if [ $# -lt 1 ]; then
    echo "Uso: $0 {montar|desmontar} [IP do servidor] [Pasta do servidor]"
    exit 1
fi

case "$1" in
    montar)
        montar
        ;;
    desmontar)
        desmontar
        ;;
    adicionar)
        adicionar
        ;;
    *)
        echo "Uso: $0 {montar|desmontar} [IP do servidor][Pasta do servidor]  e  para adicionar [IP do servidor][nome do usuario][senha do usuario]"
        exit 1
        ;;
esac
