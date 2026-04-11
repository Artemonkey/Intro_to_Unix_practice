# Simple HTTP Service on systemd socket activation

Этот сервис принимает HTTP-запросы по локальному сокету и отвечает простым текстом.

## Что делает

- запускает Python-скрипт `http_service.py`
- при активации через systemd получает слушающий сокет
- принимает входящие TCP-соединения на `127.0.0.1:8888`
- читает первую строку HTTP-запроса и заголовки
- проверяет синтаксис первой строки
- возвращает ответ `HTTP/1.0 200 OK` с телом `Hello World!` или `400 Bad Request`

## Установка

1. Перейдите в каталог:
   ```bash
   cd ~/Intro_to_Unix_practice/simple_http_service_on_daemon
   ```
2. Запустите скрипт установки:
   ```bash
   ./start_http_service.sh
   ```

Скрипт создаст `friendly.service` в `~/.config/systemd/user` и загрузит сокет в systemd.

## Проверка работы

Запрос через netcat:

```bash
printf 'GET / HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n' | ncat 127.0.0.1 8888
```

Или откройте в браузере:

```text
http://127.0.0.1:8888/
```

Если все настроено, сервис ответит `Hello World!`.

## Диагностика

Если что-то пошло не так, проверьте статус и журнал:

```bash
systemctl --user status friendly.socket friendly.service
journalctl --user -u friendly.service -n 50
```
