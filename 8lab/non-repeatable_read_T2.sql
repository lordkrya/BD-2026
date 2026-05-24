-- SET default_transaction_isolation = 'repeatable read';
SET default_transaction_isolation = 'read committed';

-- Транзакция T2
BEGIN;

-- Обновляем срок истечения премиума expiration и promo_code
UPDATE premiumFunc 
SET expiration = CURRENT_TIMESTAMP + INTERVAL '30 days',
    promo_code = '123'
WHERE id_author = '26081949-630d-40c0-bbdd-664e5b597aad';

COMMIT;
