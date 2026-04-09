responce_message = 'Hello World!'
http_prococols = [ 'HTTP/1.1', 'HTTP/1.0']
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

def saveHTTPRequestContent() -> None:
    header_lines = []
    while True: 
        request_line = input()
        # Проверяем на окончание запроса – пришла пустая строка
        if request_line:
            # Сохраняем строки заголовков
            header_lines.append(request_line)
        else:
            # Выход из цикла
            break

def checkHTTPRequestFirstLineSemantic(query: str) -> bool:
    # Разделение первой строки на слова
    words = query.partition('\n')[0].split(' ')
    # Проверка на количество слов
    if not len(words) == 3:
        return False
    # Проверка метода, пути и http протокола в словах 
    if words[0] in http_methods and words[1].startswith('/') and words[2] in http_prococols:
        return True
    return False


def main():
    # Читаем первую строку из STDIN
    first_line = input()
    # Проверяем на минимальные требования HTTP запроса
    if checkHTTPRequestFirstLineSemantic(first_line):
        # Читаем строки заголовков до пустой строки
        saveHTTPRequestContent()
        # Отправляем HTTP ответ в STDOUT
        print("HTTP/1.0 200 OK")
        print("Content-type: text/plain")
        print()  # Пустая строка
        print(responce_message)
    else:
        # В случае ошибки, отправить 400 Bad Request
        print("HTTP/1.0 400 Bad Request")
        print("Content-type: text/plain")
        print()

if __name__ == "__main__":
    main()
