CREATE OR REPLACE PROCEDURE update_music_card()
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_record RECORD;
    v_min_listening_percent float := 0.7;
    v_song_threshold float := 3;
    v_artist_threshold float := 4.5;
    v_genre_threshold float := 6;
    v_week_interval interval := INTERVAL '7 days';

BEGIN

    CREATE TEMP TABLE prep_song_weights ON COMMIT DROP AS
    SELECT
        lh.code_song,
        lh.id_author,
        s.index_genre,
        -- Вес прослушивания: линейный от 1.0 (70%) до 1.5 (100%)
        1.0 + (0.5 * ((EXTRACT(EPOCH FROM lh.during) / EXTRACT(EPOCH FROM s.during) - v_min_listening_percent) / (1.0 - v_min_listening_percent))) AS listen_weight
    FROM listeningHistory lh
    JOIN song s ON lh.code_song = s.code_song
    WHERE lh.start_listen >= CURRENT_TIMESTAMP - v_week_interval
        AND lh.during >= s.during * v_min_listening_percent;


    -- Обходим всех пользователей, у которых есть прослушивания за последнюю неделю
    FOR v_user_record IN
    	-- 0. Проверяем, что пользователь прослушал >= 3 произведений за последний день
        SELECT psw.id_author
        FROM prep_song_weights psw
        GROUP BY psw.id_author
        HAVING COUNT(*) >= 7
    LOOP
    
        -- 1. ОБНОВЛЕНИЕ preferenceForSongs

        DELETE FROM preferenceForSongs pfs
        WHERE pfs.id_author = v_user_record.id_author;

        WITH song_weights AS (
            SELECT
                psw.code_song
            FROM prep_song_weights psw
            LEFT JOIN preferenceForSongs pfs ON pfs.code_song = psw.code_song AND pfs.id_author = v_user_record.id_author
            WHERE psw.id_author = v_user_record.id_author
                AND NOT EXISTS (  -- Исключаем disliked треки
                    SELECT 1
                    FROM tableOfContents toc
                    INNER JOIN playlist pl ON toc.index_playlist = pl.index_playlist
                    WHERE pl.id_author = v_user_record.id_author
                        AND pl.name_playlist = 'disliked'
                        AND toc.code_song = psw.code_song
                )
            GROUP BY psw.code_song
            -- Бонус, если песня уже в preferenceForSongs
            HAVING SUM(psw.listen_weight) + COUNT(pfs.code_song) * 0.5 >= v_song_threshold
        )

        INSERT INTO preferenceForSongs (id_author, code_song)
        SELECT v_user_record.id_author, code_song
        FROM song_weights
        ON CONFLICT (id_author, code_song) DO NOTHING;

        -- 2. ОБНОВЛЕНИЕ preferenceForGenre

        DELETE FROM preferenceForGenre pfg
        WHERE pfg.id_author = v_user_record.id_author;

        WITH genre_weights AS (
            SELECT
                psw.index_genre
            FROM prep_song_weights psw
            LEFT JOIN preferenceForGenre pfg ON psw.index_genre = pfg.index_genre AND pfg.id_author = v_user_record.id_author
            WHERE psw.id_author = v_user_record.id_author
                AND psw.index_genre IS NOT NULL
                AND NOT EXISTS (  -- Исключаем disliked треки
                    SELECT 1
                    FROM tableOfContents toc
                    INNER JOIN playlist pl ON toc.index_playlist = pl.index_playlist
                    WHERE pl.id_author = v_user_record.id_author
                        AND pl.type_playlist = 'disliked'
                        AND toc.code_song = psw.code_song
                )
            GROUP BY psw.index_genre
            HAVING SUM(psw.listen_weight) + COUNT(pfg.index_genre) * 0.5 >= v_genre_threshold
        )

        INSERT INTO preferenceForGenre (id_author, index_genre)
        SELECT v_user_record.id_author, index_genre
        FROM genre_weights
        ON CONFLICT (id_author, index_genre) DO NOTHING;

        -- 3. ОБНОВЛЕНИЕ preferenceForArtist

        DELETE FROM preferenceForArtist pfa
        WHERE pfa.id_author_user = v_user_record.id_author;

        WITH artist_weights AS (
            SELECT
                p.id_author as artist_id
            FROM prep_song_weights psw
            JOIN performance p ON psw.code_song = p.code_song
            LEFT JOIN preferenceForArtist pfa ON p.id_author = pfa.id_author_artist AND pfa.id_author_user = v_user_record.id_author
            WHERE psw.id_author = v_user_record.id_author
                AND p.id_author IN (SELECT id_author FROM musicArtist)
                AND NOT EXISTS (  -- Исключаем disliked треки
                    SELECT 1
                    FROM tableOfContents toc
                    INNER JOIN playlist pl ON toc.index_playlist = pl.index_playlist
                    WHERE pl.id_author = v_user_record.id_author
                        AND pl.type_playlist = 'disliked'
                        AND toc.code_song = psw.code_song
                )
            GROUP BY p.id_author
            HAVING SUM(psw.listen_weight) + COUNT(pfa.id_author_artist) * 0.5 >= v_artist_threshold
        )

        INSERT INTO preferenceForArtist (id_author_user, id_author_artist)
        SELECT v_user_record.id_author, artist_id
        FROM artist_weights
        ON CONFLICT (id_author_user, id_author_artist) DO NOTHING;

        RAISE NOTICE 'Music card updated for user %', v_user_record.id_author;

    END LOOP;

    RAISE NOTICE 'Music card update completed for all active users';
END;
$$;
