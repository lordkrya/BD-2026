INSERT INTO "user" (id_author, full_name, date_of_birth, user_login, user_password, phone_number)
VALUES (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'John Doe2a',
    '2000-01-01',
    'user_login_aaaa',
    decode('48656c6c6f20576f726c64', 'hex'),
    '+12345678901'
), (
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'John Doe3b',
    '2000-01-01',
    'user_login_bbbb',
    decode('48656c6c6f20576f726c64', 'hex'),
    '+12345678902'
);



-- Заодно проверим, что Read uncommitted работает аналогично read committed
SET default_transaction_isolation = 'read uncommitted';

-- Начинаем транзакцию
BEGIN;

-- Вставляем первую запись
INSERT INTO premiumFunc (id_author, date_prem, expiration, promo_code)
VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '30 days', 'SAVE1');

-- Создаем savepoint
SAVEPOINT my_savepoint;

-- Вставляем вторую запись (которую потом откатим)
INSERT INTO premiumFunc (id_author, date_prem, expiration, promo_code)
VALUES ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '30 days', 'SAVE2');

-- Проверяем: обе записи видны
SELECT * FROM premiumFunc
WHERE id_author='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' OR id_author='bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

-- Откатываем к savepoint (вторая запись исчезнет)
ROLLBACK TO my_savepoint;

-- Проверяем: обе записи видны
SELECT * FROM premiumFunc
WHERE id_author IN ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');

-- Фиксируем изменения
COMMIT;




DELETE FROM "user" WHERE id_author IN ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
