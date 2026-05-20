CREATE TABLE clients (
    client_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Уникальный идентификатор клиента',
    last_name VARCHAR(50) NOT NULL COMMENT 'Фамилия клиента',
    first_name VARCHAR(50) NOT NULL COMMENT 'Имя клиента',
    phone VARCHAR(20) NOT NULL UNIQUE COMMENT 'Номер телефона в формате +7XXXXXXXXXX',
    email VARCHAR(100) NOT NULL UNIQUE COMMENT 'Адрес электронной почты',
    CONSTRAINT chk_client_phone CHECK (phone REGEXP '^\\+7[0-9]{10}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Клиенты агентства недвижимости';

-- ============================================================
-- 2. Таблица риелторов
-- Хранит информацию о сотрудниках агентства недвижимости
-- ============================================================
CREATE TABLE realtors (
    realtor_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Уникальный идентификатор риелтора',
    last_name VARCHAR(50) NOT NULL COMMENT 'Фамилия риелтора',
    first_name VARCHAR(50) NOT NULL COMMENT 'Имя риелтора',
    phone VARCHAR(20) NOT NULL UNIQUE COMMENT 'Номер телефона',
    hire_date DATE NOT NULL DEFAULT (CURRENT_DATE) COMMENT 'Дата найма на работу'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Риелторы агентства';

-- ============================================================
-- 3. Таблица объектов недвижимости
-- Хранит информацию о квартирах, домах и апартаментах
-- ============================================================
CREATE TABLE properties (
    property_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Уникальный идентификатор объекта',
    address VARCHAR(255) NOT NULL COMMENT 'Полный адрес объекта',
    property_type ENUM('квартира', 'дом', 'апартаменты') NOT NULL COMMENT 'Тип объекта недвижимости',
    rooms TINYINT UNSIGNED NOT NULL COMMENT 'Количество комнат',
    area DECIMAL(7,2) NOT NULL COMMENT 'Общая площадь в кв. метрах',
    price DECIMAL(12,2) NOT NULL COMMENT 'Цена объекта в рублях',
    realtor_id INT NOT NULL COMMENT 'Ответственный риелтор',
    CONSTRAINT chk_rooms_positive CHECK (rooms > 0),
    CONSTRAINT chk_area_positive CHECK (area > 0),
    CONSTRAINT chk_price_positive CHECK (price > 0),
    FOREIGN KEY (realtor_id) REFERENCES realtors(realtor_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_property_realtor (realtor_id),
    INDEX idx_property_type (property_type),
    INDEX idx_property_price (price)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Объекты недвижимости';

-- ============================================================
-- 4. Таблица записей на просмотр (основная таблица системы)
-- Фиксирует факт записи клиента на просмотр конкретного объекта
-- ============================================================
CREATE TABLE viewings (
    viewing_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Уникальный идентификатор записи',
    client_id INT NOT NULL COMMENT 'Клиент, записавшийся на просмотр',
    property_id INT NOT NULL COMMENT 'Объект недвижимости для просмотра',
    realtor_id INT NOT NULL COMMENT 'Риелтор, проводящий просмотр',
    viewing_datetime DATETIME NOT NULL COMMENT 'Дата и время проведения просмотра',
    status ENUM('запланирован', 'проведён', 'сделка', 'отменён') NOT NULL DEFAULT 'запланирован' COMMENT 'Статус просмотра',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания записи',
    FOREIGN KEY (client_id) REFERENCES clients(client_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (property_id) REFERENCES properties(property_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (realtor_id) REFERENCES realtors(realtor_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    UNIQUE KEY unique_viewing_slot (property_id, viewing_datetime) COMMENT 'Один объект не может быть показан двум клиентам одновременно',
    INDEX idx_viewing_datetime (viewing_datetime),
    INDEX idx_viewing_client (client_id),
    INDEX idx_viewing_realtor (realtor_id),
    INDEX idx_viewing_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Записи на просмотр объектов недвижимости';

-- ============================================================
-- 5. Таблица избранных объявлений
-- Реализует связь "многие-ко-многим" между клиентами и объектами
-- ============================================================
CREATE TABLE favorites (
    client_id INT NOT NULL COMMENT 'Идентификатор клиента',
    property_id INT NOT NULL COMMENT 'Идентификатор объекта',
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата добавления в избранное',
    PRIMARY KEY (client_id, property_id),
    FOREIGN KEY (client_id) REFERENCES clients(client_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (property_id) REFERENCES properties(property_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Избранные объявления клиентов';

-- ============================================================
-- НАПОЛНЕНИЕ ТЕСТОВЫМИ ДАННЫМИ
-- ============================================================

-- Клиенты (5 записей)
INSERT INTO clients (last_name, first_name, phone, email) VALUES
('Григорьев', 'Алексей', '+79161112233', 'grigoriev@example.com'),
('Морозова', 'Екатерина', '+79262223344', 'morozova@example.com'),
('Соколов', 'Дмитрий', '+79363334455', 'sokolov@example.com'),
('Кузнецова', 'Анна', '+79464445566', 'kuznetsova@example.com'),
('Васильев', 'Игорь', '+79565556677', 'vasiliev@example.com');

-- Риелторы (4 записи)
INSERT INTO realtors (last_name, first_name, phone, hire_date) VALUES
('Волкова', 'Ольга', '+79031112233', '2023-03-15'),
('Смирнов', 'Артём', '+79032223344', '2022-09-01'),
('Ершова', 'Марина', '+79033334455', '2024-01-10'),
('Фёдоров', 'Никита', '+79034445566', '2023-07-20');

-- Объекты недвижимости (5 записей)
INSERT INTO properties (address, property_type, rooms, area, price, realtor_id) VALUES
('ул. Ленина, д. 15, кв. 45', 'квартира', 2, 56.50, 7500000.00, 1),
('пр. Мира, д. 8, кв. 12', 'квартира', 1, 38.00, 5200000.00, 1),
('ул. Садовая, д. 23', 'дом', 4, 120.00, 14500000.00, 2),
('ул. Чехова, д. 7, кв. 88', 'квартира', 3, 78.20, 11200000.00, 3),
('пер. Цветочный, д. 3', 'дом', 3, 95.00, 9800000.00, 4);

-- Записи на просмотр (7 записей)
INSERT INTO viewings (client_id, property_id, realtor_id, viewing_datetime, status) VALUES
(1, 1, 1, '2026-05-25 10:00:00', 'запланирован'),
(2, 1, 1, '2026-05-25 15:00:00', 'проведён'),
(3, 2, 1, '2026-05-26 11:00:00', 'сделка'),
(4, 3, 2, '2026-05-27 13:30:00', 'сделка'),
(5, 4, 3, '2026-05-28 09:00:00', 'отменён'),
(1, 5, 4, '2026-05-29 12:00:00', 'запланирован'),
(2, 3, 2, '2026-05-30 11:00:00', 'проведён');

-- Избранные объявления (5 записей)
INSERT INTO favorites (client_id, property_id) VALUES
(1, 3),
(1, 4),
(2, 1),
(3, 5),
(4, 2);
