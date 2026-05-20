
# МИНИСТЕРСТВО ОБРАЗОВАНИЯ КУЗБАССА

**ГПОУ «ЮРГИНСКИЙ ТЕХНОЛОГИЧЕСКИЙ КОЛЛЕДЖ»**  
**ИМ. ПАВЛЮЧКОВА Г.А.**

Отделение АиТ

## **Проектирование и создание схемы реляционной базы данных**

**ОТЧЕТ ПО ПРАКТИЧЕСКОЙ РАБОТЕ**  
уП.01.01 Практика

Специальность 09.02.09 Веб-разработка

Выполнил студент гр. 454  
**Молоков А.А.**

Проверил преподаватель  
Поликарпочкин М.В.

2026 г.

---

## Цель

Проектирование и создание схемы реляционной базы данных.

---

## Ход работы

### 1. Анализ предметной области

Система онлайн-записи предназначена для автоматизации работы агентства недвижимости по организации показов объектов (квартир, домов, апартаментов) потенциальным покупателям. Клиент выбирает интересующий его объект из базы агентства и записывается на удобное время для его осмотра. За каждым объектом закреплён ответственный риелтор, который сопровождает сделку и присутствует на показе, поэтому при создании записи автоматически определяется специалист.

Помимо основной функции подбора времени, система позволяет клиентам сохранять понравившиеся варианты в список избранных объявлений для последующего сравнения и быстрого доступа.

База данных должна поддерживать следующие бизнес-правила:
- Один и тот же объект недвижимости не может быть назначен к показу двум разным клиентам в одно и то же время, что исключает накладки в расписании риелторов.
- При попытке удаления клиента, у которого есть активные или архивные просмотры, операция должна быть заблокирована для сохранения истории взаимодействий.
- Цена и площадь объекта не могут быть отрицательными или нулевыми, а количество комнат должно быть целым положительным числом.
- Все контактные данные клиентов и риелторов должны быть уникальными во избежание дублирования записей.
- Каждая запись на просмотр должна быть обязательно связана с существующим клиентом, объектом и риелтором, что обеспечивает ссылочная целостность внешних ключей.
- Статус просмотра может принимать строго определённые значения, отражающие жизненный цикл сделки: от планирования до успешного закрытия или отмены.

---

### 2. Концептуальная модель

Концептуальная модель базы данных агентства недвижимости включает пять сущностей: **Клиент**, **Риелтор**, **Объект недвижимости**, **Просмотр** и **Избранное**.

#### Сущности и атрибуты

- **Клиент** (физическое лицо, желающее приобрести недвижимость):
  - идентификатор клиента (первичный ключ)
  - фамилия, имя, телефон, email

- **Риелтор** (сотрудник агентства):
  - идентификатор риелтора (первичный ключ)
  - фамилия, имя, телефон, дата найма

- **Объект недвижимости** (жилое помещение на продажу):
  - идентификатор объекта (первичный ключ)
  - адрес, тип объекта (квартира/дом/апартаменты)
  - количество комнат, общая площадь, цена

- **Просмотр** (запись клиента на осмотр):
  - идентификатор просмотра (первичный ключ)
  - дата и время проведения, статус, дата создания записи

- **Избранное** (связь клиента с понравившимися объектами):
  - составной первичный ключ (client_id + property_id)
  - дата добавления в избранное

#### Связи между сущностями

| Связь | Тип | Пояснение |
|-------|-----|-----------|
| Клиент – Просмотр | 1 : M | Один клиент может иметь много просмотров |
| Риелтор – Просмотр | 1 : M | Один риелтор проводит много показов |
| Объект – Просмотр | 1 : M | Один объект может показываться многократно |
| Риелтор – Объект | 1 : M | Один риелтор ведёт несколько объектов |
| Клиент – Объект (через Избранное) | M : M | Многие ко многим (избранное) |

> **Рисунок 1 – ER-Диаграмма** `images/image1.png`

---

### 3. Логическая модель и нормализация

Реляционная схема БД включает пять таблиц, соответствующих сущностям концептуальной модели.

#### Таблица `clients`

- `client_id` INT AUTO_INCREMENT PRIMARY KEY
- `last_name` VARCHAR(50) NOT NULL
- `first_name` VARCHAR(50) NOT NULL
- `phone` VARCHAR(20) NOT NULL UNIQUE, CHECK (формат +7XXXXXXXXXX)
- `email` VARCHAR(100) NOT NULL UNIQUE

#### Таблица `realtors`

- `realtor_id` INT AUTO_INCREMENT PRIMARY KEY
- `last_name` VARCHAR(50) NOT NULL
- `first_name` VARCHAR(50) NOT NULL
- `phone` VARCHAR(20) NOT NULL UNIQUE
- `hire_date` DATE NOT NULL DEFAULT CURRENT_DATE

#### Таблица `properties`

- `property_id` INT AUTO_INCREMENT PRIMARY KEY
- `address` VARCHAR(255) NOT NULL
- `property_type` ENUM('квартира','дом','апартаменты') NOT NULL
- `rooms` TINYINT UNSIGNED NOT NULL CHECK (rooms > 0)
- `area` DECIMAL(7,2) NOT NULL CHECK (area > 0)
- `price` DECIMAL(12,2) NOT NULL CHECK (price > 0)
- `realtor_id` INT NOT NULL, FOREIGN KEY → `realtors(realtor_id)` ON DELETE RESTRICT

#### Таблица `viewings`

- `viewing_id` INT AUTO_INCREMENT PRIMARY KEY
- `client_id` INT NOT NULL FOREIGN KEY → `clients`
- `property_id` INT NOT NULL FOREIGN KEY → `properties`
- `realtor_id` INT NOT NULL FOREIGN KEY → `realtors`
- `viewing_datetime` DATETIME NOT NULL
- `status` ENUM('запланирован','проведён','сделка','отменён') DEFAULT 'запланирован'
- `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
- **UNIQUE(property_id, viewing_datetime)** – бизнес-правило
- Индексы по `client_id`, `viewing_datetime`, `status`

#### Таблица `favorites`

- `client_id` INT NOT NULL (часть PK)
- `property_id` INT NOT NULL (часть PK)
- `added_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
- PRIMARY KEY (client_id, property_id)
- FOREIGN KEY (client_id) REFERENCES `clients` ON DELETE CASCADE
- FOREIGN KEY (property_id) REFERENCES `properties` ON DELETE CASCADE

#### Нормализация

- **1НФ**: все значения атомарны, повторяющиеся группы вынесены.
- **2НФ**: в таблице `favorites` столбец `added_at` зависит от полного составного ключа.
- **3НФ**: транзитивные зависимости отсутствуют (например, `rooms` и `area` зависят только от `property_id`).

Денормализация отсутствует. Схема полностью соответствует 3НФ.

---

### 4. SQL-скрипт создания базы данных

```sql
-- 1. Таблица клиентов
CREATE TABLE clients (
    client_id INT AUTO_INCREMENT PRIMARY KEY,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    CONSTRAINT chk_client_phone CHECK (phone REGEXP '^\\+7[0-9]{10}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Таблица риелторов
CREATE TABLE realtors (
    realtor_id INT AUTO_INCREMENT PRIMARY KEY,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    hire_date DATE NOT NULL DEFAULT (CURRENT_DATE)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Таблица объектов недвижимости
CREATE TABLE properties (
    property_id INT AUTO_INCREMENT PRIMARY KEY,
    address VARCHAR(255) NOT NULL,
    property_type ENUM('квартира', 'дом', 'апартаменты') NOT NULL,
    rooms TINYINT UNSIGNED NOT NULL CHECK (rooms > 0),
    area DECIMAL(7,2) NOT NULL CHECK (area > 0),
    price DECIMAL(12,2) NOT NULL CHECK (price > 0),
    realtor_id INT NOT NULL,
    FOREIGN KEY (realtor_id) REFERENCES realtors(realtor_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_property_realtor (realtor_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Таблица записей на просмотр
CREATE TABLE viewings (
    viewing_id INT AUTO_INCREMENT PRIMARY KEY,
    client_id INT NOT NULL,
    property_id INT NOT NULL,
    realtor_id INT NOT NULL,
    viewing_datetime DATETIME NOT NULL,
    status ENUM('запланирован', 'проведён', 'сделка', 'отменён') NOT NULL DEFAULT 'запланирован',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES clients(client_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (property_id) REFERENCES properties(property_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (realtor_id) REFERENCES realtors(realtor_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    UNIQUE KEY unique_viewing_slot (property_id, viewing_datetime),
    INDEX idx_viewing_datetime (viewing_datetime),
    INDEX idx_viewing_client (client_id),
    INDEX idx_viewing_realtor (realtor_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Таблица избранных объявлений
CREATE TABLE favorites (
    client_id INT NOT NULL,
    property_id INT NOT NULL,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (client_id, property_id),
    FOREIGN KEY (client_id) REFERENCES clients(client_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (property_id) REFERENCES properties(property_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Дополнительные индексы
CREATE INDEX idx_property_type ON properties(property_type);
CREATE INDEX idx_property_price ON properties(price);
CREATE INDEX idx_viewing_status ON viewings(status);
```

---

### 5. Тестовые данные и примеры запросов

> **Рисунок 1** – Заполнение таблицы клиентов (`images/image2.png`)  
> **Рисунок 2** – Заполнение таблицы риелторов (`images/image3.png`)  
> **Рисунок 3** – Заполнение таблицы объектов недвижимости (`images/image4.png`)  
> **Рисунок 4** – Заполнение таблицы просмотров (`images/image5.png`)  
> **Рисунок 5** – Заполнение таблицы избранных объявлений (`images/image6.png`)

#### Бизнес-задача

Получение полного списка записей на просмотр с указанием имён клиентов, имён риелторов и адресов объектов.

**Код запроса** (Рисунок 6 – `images/image7.png`):  
*(в документе вставлено изображение с SQL-запросом)*

**Результат выполнения** (Рисунок 7 – `images/image8.png`):  
*(таблица с результатами)*

---

### 6. Проверка ограничений целостности

#### 1) Уникальность временного слота для объекта

Попытка вставить запись на уже занятое время и объект вызывает ошибку:

> `Duplicate entry '1-2026-05-25 10:00:00' for key 'unique_viewing_slot'`

**Рисунок 8** – (`images/image9.png`)

#### 2) Удаление клиента с существующими просмотрами (ON DELETE RESTRICT)

```sql
DELETE FROM clients WHERE client_id = 1;
-- Error: Cannot delete or update a parent row: a foreign key constraint fails
```

**Рисунок 9** – (`images/image10.png`)

#### 3) Проверка CHECK (цена > 0)

```sql
INSERT INTO properties (address, property_type, rooms, area, price, realtor_id)
VALUES ('ул. Тестовая, 1', 'квартира', 1, 30.00, -5000.00, 1);
-- Error: Check constraint 'price' is violated
```

**Рисунок 10** – (`images/image11.png`)

---

## Заключение

В ходе выполнения практической работы спроектирована и реализована реляционная БД для системы онлайн-записи в агентство недвижимости.

**Ключевые результаты:**
- Выполнен анализ предметной области, формализованы бизнес-правила.
- Построена концептуальная (ER) и логическая модель, выполнена нормализация до 3НФ.
- Реализован SQL-скрипт создания БД с полным набором ограничений:
  - первичные и внешние ключи
  - уникальные и проверочные ограничения
  - индексы для оптимизации
- Вставлены тестовые данные, написан аналитический запрос (JOIN).
- Проверена работа ограничений целостности на ошибочных операциях.

**Сложности и решения:**
- Моделирование бизнес-правила уникальности временного слота → составной `UNIQUE KEY`.
- Выбор стратегии `RESTRICT` vs `CASCADE` для внешних ключей в зависимости от бизнес-логики.
- Ограничения `CHECK` в MySQL (нет подзапросов, межтабличных проверок) → вынесение на уровень приложения или триггеры.

**Приобретённые навыки:**
- Проектирование БД «от анализа до физической реализации».
- Создание таблиц, ограничений, индексов.
- Написание сложных SQL-запросов (JOIN, GROUP BY, HAVING, оконные функции, CTE).
- Тестирование ограничений целостности.
- Оформление технической документации.

**Возможные улучшения:**
- Триггеры для проверки даты просмотра (не в прошлом) и автообновления статуса.
- Хранимые процедуры для сложной бизнес-логики (запись с проверкой доступности риелтора).
- Представления для аналитики (статистика по риелторам, загрузка на неделю).

---

## Список литературы

1. Официальная документация MySQL. MySQL 8.0 Reference Manual [Электронный ресурс] // Oracle Corporation. — 2026. — Режим доступа: https://dev.mysql.com/doc/refman/8.0/en/
2. Официальная документация MySQL. MySQL 8.0 Release Notes [Электронный ресурс] // Oracle Corporation. — 2026. — Режим доступа: https://dev.mysql.com/doc/relnotes/mysql/8.0/en/
3. Гаврилов А.В. Проектирование реляционных баз данных: учебное пособие [Текст] / А.В. Гаврилов. — Москва: КноРус, 2025. — 231 с. — ISBN 978-5-406-14233-2
4. Проектирование и реализация баз данных в СУБД MySQL с использованием MySQL Workbench. Методы и средства проектирования информационных систем и технологий. Инструментальные средства информационных систем: учебное пособие [Текст]. — Москва: ИНФРА-М, 2025. — 160 с. — ISBN 978-5-8199-0517-3
5. Аклимов Р. Базы данных на SQL, MySQL, MS SQL и Postgre/PL/pgSQL. Проектирование и практическая реализация [Текст] / Р. Аклимов. — Санкт-Петербург: издательство БХВ, 2026. — 512 с. — ISBN 978-5-907592-91-9
```
