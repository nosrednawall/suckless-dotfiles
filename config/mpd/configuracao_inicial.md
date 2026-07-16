# Instalação
```bash
sudo apt install mpd ncmpcpp
```

# Configuração
```bash
sudo systemctl disable mpd
sudo systemctl stop mpd
mpd --kill
systremctl --user enable mpd
systemctl --user start mpd
```
