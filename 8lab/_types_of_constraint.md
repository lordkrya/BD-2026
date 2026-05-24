# Типы constraints

- Primary Key - по сути ограничение unique + not null

- Foreign Key - ссылочная целостность

- Unique - уникальность значений

- Check - проверка условия

- Not Null - запрет NULL

SELECT * FROM pg_constraint WHERE conrelid = 'premiumFunc'::regclass;

