-- 1_procedure

-- Выбираем пользователя с активной премиум-подпиской
SELECT id_author, expiration 
FROM premiumFunc 
WHERE expiration > CURRENT_TIMESTAMP 
LIMIT 5;

CALL generate_daily_playlist_weighted('2c508364-f298-4bb3-9f1e-7738d8da0a58');
CALL generate_daily_playlist_weighted('2c508364-f298-4bb3-9f1e-7738d8da0a58');

-- 2_procedure

SELECT * FROM preferenceForSongs WHERE id_author = '2c508364-f298-4bb3-9f1e-7738d8da0a58';
SELECT * FROM preferenceForGenre WHERE id_author = '2c508364-f298-4bb3-9f1e-7738d8da0a58';
SELECT * FROM preferenceForArtist WHERE id_author = '2c508364-f298-4bb3-9f1e-7738d8da0a58';

CALL update_music_card();

SELECT * FROM preferenceForSongs WHERE id_author = '2c508364-f298-4bb3-9f1e-7738d8da0a58';
SELECT * FROM preferenceForGenre WHERE id_author = '2c508364-f298-4bb3-9f1e-7738d8da0a58';
SELECT * FROM preferenceForArtist WHERE id_author = '2c508364-f298-4bb3-9f1e-7738d8da0a58';

