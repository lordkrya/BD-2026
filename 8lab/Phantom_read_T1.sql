-- SET default_transaction_isolation = 'repeatable read';
SET default_transaction_isolation = 'read committed';

-- Транзакция T1
BEGIN;

-- Первое чтение: выбираем записи за последние 3 дня
SELECT id_author, date_prem, expiration, promo_code 
FROM premiumFunc 
WHERE date_prem BETWEEN '2026-01-12' AND '2026-01-15'
ORDER BY date_prem;

-- Здесь будет пауза, во время которой выполнится T2

-- Второе чтение: снова выбираем записи за последние 3 дня
SELECT id_author, date_prem, expiration, promo_code 
FROM premiumFunc 
WHERE date_prem BETWEEN '2026-01-12' AND '2026-01-15'
ORDER BY date_prem;

COMMIT;

-- Время    T1                                    T2
----------------------------------------------------------
-- t1      BEGIN;
-- t2      SELECT ... (первое чтение)  
        -- видит N записей
-- t3                                             BEGIN;
-- t4                                             INSERT ... (добавляет новую запись)
-- t5                                             COMMIT;
-- t6      SELECT ... (второе чтение)
        -- видит N+1 записей
-- t7      COMMIT;
