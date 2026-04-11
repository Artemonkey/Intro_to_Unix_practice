import os
import socket
from typing import Optional

response_message = 'Hello World!'
http_protocols = ['HTTP/1.1', 'HTTP/1.0']
http_methods = [
    'GET',
    'POST',
    'PUT',
    'DELETE',
    'PATCH',
    'HEAD',
    'CONNECT',
    'OPTIONS',
    'TRACE',
]


def check_http_request_first_line_semantic(query: str) -> bool:
    words = query.partition('\n')[0].split(' ')
    if len(words) != 3:
        return False
    if words[0] in http_methods and words[1].startswith('/') and words[2] in http_protocols:
        return True
    return False


def send_response(conn_file, status_code: int, body: str = '') -> None:
    reason = 'OK' if status_code == 200 else 'Bad Request'
    body_bytes = body.encode('utf-8')
    conn_file.write(f'HTTP/1.0 {status_code} {reason}\r\n'.encode('latin-1'))
    conn_file.write(b'Content-Type: text/plain\r\n')
    conn_file.write(f'Content-Length: {len(body_bytes)}\r\n'.encode('latin-1'))
    conn_file.write(b'Connection: close\r\n')
    conn_file.write(b'\r\n')
    if body_bytes:
        conn_file.write(body_bytes)
    conn_file.flush()


def handle_connection(conn: socket.socket) -> None:
    with conn, conn.makefile('rwb') as conn_file:
        first_line_bytes = conn_file.readline()
        if not first_line_bytes:
            send_response(conn_file, 400)
            return

        first_line = first_line_bytes.decode('latin-1').rstrip('\r\n')
        if not check_http_request_first_line_semantic(first_line):
            send_response(conn_file, 400)
            return

        while True:
            header_line = conn_file.readline()
            if not header_line or header_line in (b'\r\n', b'\n'):
                break

        send_response(conn_file, 200, response_message)


def get_activated_socket() -> Optional[socket.socket]:
    listen_pid = os.environ.get('LISTEN_PID')
    listen_fds = os.environ.get('LISTEN_FDS')
    if not listen_pid or not listen_fds:
        return None
    try:
        if int(listen_pid) != os.getpid() or int(listen_fds) < 1:
            return None
    except ValueError:
        return None

    return socket.socket(fileno=3)


def main() -> None:
    conn = get_activated_socket()
    if conn is not None:
        with conn:
            while True:
                client_socket, _ = conn.accept()
                handle_connection(client_socket)
        return

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as listening_socket:
        listening_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        listening_socket.bind(('127.0.0.1', 8888))
        listening_socket.listen(1)
        while True:
            client_socket, _ = listening_socket.accept()
            handle_connection(client_socket)


if __name__ == '__main__':
    main()
