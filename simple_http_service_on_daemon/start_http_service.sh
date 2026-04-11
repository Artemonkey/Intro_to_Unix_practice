#!/usr/bin/env bash
# Initial startup script for http service

function install_Systemd_Configs() {
    local target_dir="$HOME/.config/systemd/user"
    local project_dir="$PWD"

    if [ ! -e "$project_dir/http_service.py" ]; then
        echo "Не найден файл $project_dir/http_service.py"
        exit 1
    fi

    mkdir -p "$target_dir"

    cat > "$target_dir/friendly.service" <<EOF
[Unit]
Description=A simple http service
After=network.target friendly.socket
Requires=friendly.socket

[Service]
Type=simple
WorkingDirectory=$project_dir
ExecStart=/usr/bin/python3 ./http_service.py
Sockets=friendly.socket
Restart=on-failure

[Install]
WantedBy=default.target
EOF

    if [ -e "$project_dir/friendly.socket" ]; then
        cp "$project_dir/friendly.socket" "$target_dir/friendly.socket"
    else
        echo "Нет обязательной конфигурации в текущей папке $project_dir/friendly.socket"
        exit 1
    fi
}

install_Systemd_Configs

systemctl --user daemon-reload
systemctl --user start friendly.socket
