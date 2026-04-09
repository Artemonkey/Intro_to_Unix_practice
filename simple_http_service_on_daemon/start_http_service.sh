#!/usr/bin/env bash
# Initial startup script for http service

# Installation function for systemd configuration files of http service
function install_Systemd_Configs() {
    # Create folders for configs
    if [ ! -d ~/.config/systemd/user ]; then
        mkdir -p ~/.config/systemd/user
    fi

    if [ -e "$PWD"/friendly.service ]; then
        cp "$PWD"/friendly.service "$HOME"/.config/systemd/user/friendly.service
    else
        echo -e "Нет обязательной конфигурации в текущей папке $PWD/friendly.service"
        exit 1
    fi

    if [ -e "$PWD"/friendly.socket ]; then
        cp "$PWD"/friendly.socket "$HOME"/.config/systemd/user/friendly.socket
    else
        echo -e "Нет обязательной конфигурации в текущей папке $PWD/friendly.socket"
        exit 1
    fi
}

install_Systemd_Configs

systemctl --user daemon-reload
systemctl --user start friendly.socket
