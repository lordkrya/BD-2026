SET default_transaction_isolation = 'repeatable read';
-- SET default_transaction_isolation = 'read committed';

-- Транзакция T2
BEGIN;

-- READ: читаем текущее значение
SELECT expiration FROM premiumFunc 
WHERE id_author = '26081949-630d-40c0-bbdd-664e5b597aad' -- FOR UPDATE
;

-- На клиенте: вычисляем новое значение

-- WRITE: обновляем на основе прочитанного значения
UPDATE premiumFunc 
SET expiration = '2026-09-20 00:00:00'
WHERE id_author = '26081949-630d-40c0-bbdd-664e5b597aad';

COMMIT;
