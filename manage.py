connection = sqlite3.connect('identifier.sqlite')
cursor = connection.cursor()


def clear_console():
    """

    Очищение консоли

    """
    os.system('cls')


def insert_teacher() -> None:
    """

    Создание учителя.

    :return: Создаёт запись в таблицу Teachers
    :rtype: None

    """
    state_input = ""
    full_name = ""
    """Полное имя. 200 символов"""
    gender = ""
    """Пол. m, f, o"""
    has_degree = False
    """Наличие учёной степени"""
    date_birth = ""
    """Дата рождения. '2000-01-01'"""

    while state_input != "y":
        clear_console()
        full_name = input("Введите полное ФИО:\n    ")
        gender = input("Введите пол ([m]ale, [f]emale, [o]ther:\n    ")
        has_degree = True if input("Имеется ли научная степень? [y]es, [n]o:\n    ") == "y" else False
        date_birth = input("Введите дату рождения в формате: '2000-01-01':\n    ")

        print(f"Проверьте правильность введённых данных:\n"
              f"    {full_name}\n    {gender}\n    {has_degree}\n    {date_birth}")
        state_input = input("\nВсё верно? [y]es, [n]o:\n    ")
        "Специально не проверяю в самом коде правильность ввода, чтобы было видно, что всё правильно обрабатывается в SQL"

    "Try-Except не работает..."
    cursor.execute("INSERT INTO Teachers ('Full Name', gender, has_degree, 'Date of birth') VALUES (?, ?, ?, ?)",
                   (full_name, gender, has_degree, date_birth))


def insert_student() -> None:
    """

    Создание студента.

    :return: Создаёт запись в таблицу Students
    :rtype: None

    """

    state_input = ""
    full_name = ""
    """Полное имя. 200 символов"""
    gender = ""
    """Пол. m, f, o"""
    id_certificate = 0
    """Номер аттестата."""
    date_birth = ""
    """Дата рождения. '2000-01-01'"""

    while state_input != "y":
        clear_console()
        full_name = input("Введите полное ФИО:\n    ")
        gender = input("Введите пол ([m]ale, [f]emale, [o]ther:\n    ")
        id_certificate = int(input("Введите номер аттестата:\n    "))
        date_birth = input("Введите дату рождения в формате: '2000-01-01':\n    ")

        print(f"\n\nПроверьте правильность введённых данных:\n"
              f"    {full_name}\n    {gender}\n    {id_certificate}\n    {date_birth}")
        state_input = input("\nВсё верно? [y]es, [n]o:\n    ")

    cursor.execute("INSERT INTO Students (ID_certificate, 'Full Name', Gender, 'Date of birth') VALUES (?, ?, ?, ?)",
                   (id_certificate, full_name, gender, date_birth))


def insert_discipline() -> None:
    """

    Создание дисциплины.

    :return: Создаёт запись в таблицу Disciplines
    :rtype: None

    """
    state_input = ""
    name = ""
    description = ""
    while state_input != "y":
        clear_console()
        name = input("Введите название дисциплины:\n    ")
        description = input("Введите описание дисциплины:\n    ")
        print(f"\n\nПроверьте правильность введённых данных:\n"
              f"    {name}\n    {description}")
        state_input = input("\nВсё верно? [y]es, [n]o:\n    ")

    cursor.execute("INSERT INTO Disciplines (Name, Description) VALUES (?, ?)", (name, description))


def insert_subject() -> None:
    """

    Создание предмета.

    :return: Создаёт запись в таблицу Subjects
    :rtype: None

    """


if __name__ == "__main__":
    clear_console()

    input_text = input(DEFAULT_TEXT)
    while input_text != "break":
        is_success = True
        match input_text:
            case "help":
                pass
            case "create teacher":
                insert_teacher()
            case "create student":
                insert_student()
            case "create discipline":
                insert_discipline()
            case "create subject":
                insert_subject()

            case _:
                is_success = False
        connection.commit()
        clear_console()
        if is_success:
            input_text = input(DEFAULT_TEXT)
        else:
            input_text = input(ERROR_TEXT)

    connection.close()
