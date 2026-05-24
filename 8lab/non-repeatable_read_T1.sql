-- SET default_transaction_isolation = 'repeatable read';
-- repeatable read - изоляция предотвратит эту аномалию
-- default_transaction_isolation настройка сессии, 
-- для разных пользователей/сессий нужно указывать переменную отдельно
SET default_transaction_isolation = 'read committed';

-- Транзакция T1
BEGIN;

-- Первое чтение: смотрим информацию о премиум-статусе пользователя
SELECT id_author, date_prem, expiration, promo_code 
FROM premiumFunc 
WHERE id_author = '26081949-630d-40c0-bbdd-664e5b597aad' FOR SHARE
;
-- FOR SHARE не стройгий "mutex", позволяет читать нескольким транзакциям, 
-- но без возможности записи от других транзакций.
-- Это позволит решить проблему Non-repeatable read,
-- Но никак не поможет с Phantom read

-- Здесь будет пауза, во время которой выполнится T2

-- Второе чтение: снова читаем того же пользователя
SELECT id_author, date_prem, expiration, promo_code 
FROM premiumFunc 
WHERE id_author = '26081949-630d-40c0-bbdd-664e5b597aad';

COMMIT;


-- Время    T1                                    T2
----------------------------------------------------------
-- t1      BEGIN;
-- t2      SELECT ... (первое чтение)  
        -- видит исходные данные
-- t3                                             BEGIN;
-- t4                                             UPDATE ... (меняет данные)
-- t5                                             COMMIT;
-- t6      SELECT ... (второе чтение)
        -- видит ИЗМЕНЕННЫЕ данные (аномалия!)
-- t7      COMMIT;
