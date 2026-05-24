SET default_transaction_isolation = 'repeatable read';
-- SET default_transaction_isolation = 'read committed';

-- Транзакция T1
BEGIN;

-- READ: читаем текущее значение
SELECT expiration FROM premiumFunc 
WHERE id_author = '26081949-630d-40c0-bbdd-664e5b597aad' -- FOR UPDATE
-- Данная нестрогая блокировка разрешит Lost Update аномалию
;

-- На клиенте: вычисляем новое значение

-- Пауза для выполнения T2

-- WRITE: обновляем на основе прочитанного значения
UPDATE premiumFunc 
SET expiration = '2026-07-20 00:00:00'
WHERE id_author = '26081949-630d-40c0-bbdd-664e5b597aad';

COMMIT;

-- Время    T1                                      T2
----------------------------------------------------------
-- t1      BEGIN;
-- t2      SELECT expiration → '2026-06-20'
-- t3                                              BEGIN;
-- t4                                              SELECT expiration → '2026-06-20'
-- t5                                              -- вычисляет '2026-08-19'
-- t6      -- вычисляет '2026-07-20'
-- t7      UPDATE SET expiration = '2026-07-20'
-- t8      COMMIT;
-- t9                                              UPDATE SET expiration = '2026-08-19'
-- t10                                             COMMIT;
