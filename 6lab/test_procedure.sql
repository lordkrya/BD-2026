-- Простой скрипт для теста работоспособности процедур и триггеров


-- 1_procedure

-- Выбираем пользователя с активной премиум-подпиской
SELECT id_author, expiration 
FROM premiumFunc 
WHERE expiration > CURRENT_TIMESTAMP 
LIMIT 5;

CALL generate_daily_playlist_weighted('a0ff3e7e-941b-4df1-a407-5c44ca90f4e5');
CALL generate_daily_playlist_weighted('26081949-630d-40c0-bbdd-664e5b597aad');

SELECT toc.* FROM tableOfContents toc WHERE toc.index_playlist = '100738cf-431b-44eb-956d-873625bc0f58';

-- 2_procedure

SELECT * FROM preferenceForSongs WHERE id_author = 'a0ff3e7e-941b-4df1-a407-5c44ca90f4e5';
SELECT * FROM preferenceForGenre WHERE id_author = '26081949-630d-40c0-bbdd-664e5b597aad';
SELECT * FROM preferenceForArtist WHERE id_author = '26081949-630d-40c0-bbdd-664e5b597aad';

CALL update_music_card();

SELECT * FROM preferenceForSongs WHERE id_author = 'a0ff3e7e-941b-4df1-a407-5c44ca90f4e5';
SELECT * FROM preferenceForGenre WHERE id_author = '26081949-630d-40c0-bbdd-664e5b597aad';
SELECT * FROM preferenceForArtist WHERE id_author = '26081949-630d-40c0-bbdd-664e5b597aad';


-- trigger 2
SELECT toc.code_song
FROM tableOfContents toc
JOIN playlist p ON p.index_playlist = toc.index_playlist
WHERE p.type_playlist = 'favorite'
AND p.id_author = '7a2b44e6-2627-4a1b-b3e2-120891f2acb0';



SELECT c.code_song, c.grade
FROM comment c
WHERE c.id_author = '7a2b44e6-2627-4a1b-b3e2-120891f2acb0';


-- eac802fe-ee8d-44b1-a497-9284711733a5
