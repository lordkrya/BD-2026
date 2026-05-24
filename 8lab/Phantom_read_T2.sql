-- SET default_transaction_isolation = 'repeatable read';
SET default_transaction_isolation = 'read committed';

-- Транзакция T2
BEGIN;

INSERT INTO "user" (id_author, full_name, date_of_birth, user_login, user_password, phone_number)
VALUES (
    '44444444-4444-4444-4444-444444444444',
    'John Doe',
    '2000-01-01',
    'user_login_4444',
    decode('48656c6c6f20576f726c64', 'hex'),
    '+1234567890'
);

-- Вставляем новую запись за последние 3 дня
INSERT INTO premiumFunc (id_author, date_prem, expiration, promo_code)
VALUES (
    '44444444-4444-4444-4444-444444444444',
    '2026-01-12 20:24:21',
    '2026-10-02 23:41:55',
    'PROMO'
);

COMMIT;



DELETE FROM premiumFunc WHERE id_author = '44444444-4444-4444-4444-444444444444';
