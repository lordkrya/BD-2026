CREATE OR REPLACE PROCEDURE generate_daily_playlist_weighted(p_id_author uuid)
LANGUAGE plpgsql
AS $$
DECLARE
    v_has_premium boolean;
    v_new_playlist_id uuid;
    v_playlist_name varchar(256);
    v_songs_added integer;
    rec RECORD;
BEGIN
    -- 1. Проверка Premium-подписки
    SELECT EXISTS (
        SELECT 1
        FROM premiumFunc
        WHERE id_author = p_id_author
          AND expiration > CURRENT_TIMESTAMP
    ) INTO v_has_premium;

    IF NOT v_has_premium THEN
        RAISE EXCEPTION 'Premium subscription required for daily playlist generation. User % does not have an active premium subscription.', p_id_author;
    END IF;

    -- 2. Формируем название плейлиста
    v_playlist_name := 'Daily Playlist ' || TO_CHAR(CURRENT_DATE, 'DD.MM.YYYY');

    -- 3. Создаём новый плейлист
    INSERT INTO playlist (id_author, name_playlist, type_playlist, date_playlist)
    VALUES (p_id_author, v_playlist_name, 'private', CURRENT_DATE)
    RETURNING index_playlist INTO v_new_playlist_id;

    -- 4. Заполняем плейлист с весовыми коэффициентами
    WITH source_songs AS (
        -- Песни из подписок (множитель 1.25)
        SELECT DISTINCT
            s.code_song,
            s.popularity,
            1.25 as source_multiplier,
            'subscription' as source_type
        FROM song s
        INNER JOIN performance p ON s.code_song = p.code_song
        INNER JOIN subscription sub ON p.id_author = sub.id_author_artist
        WHERE sub.id_author_user = p_id_author

        UNION

        -- Песни из favorite (множитель 1.5)
        SELECT DISTINCT
            s.code_song,
            s.popularity,
            1.5 as source_multiplier,
            'playlist' as source_type
        FROM song s
        INNER JOIN tableOfContents toc ON s.code_song = toc.code_song
        INNER JOIN playlist pl ON toc.index_playlist = pl.index_playlist
        WHERE pl.id_author = p_id_author
          AND pl.type_playlist = 'favorite'

        UNION

        -- Песни из preferenceForSongs (множитель 2)
        SELECT DISTINCT
            s.code_song,
            s.popularity,
            2.0 as source_multiplier,
            'recommendation' as source_type
        FROM song s
        INNER JOIN preferenceForSongs pfs ON s.code_song = pfs.code_song
        WHERE pfs.id_author = p_id_author
    ),
    -- Исключаем запрещённые песни и добавляем информацию о последнем прослушивании
    eligible_songs AS (
        SELECT DISTINCT
            ss.code_song,
            ss.popularity,
            ss.source_multiplier,
            ss.source_type,
            MAX(lh.start_listen) as last_listen,
            -- Коэффициент времени (0 - только что, 1 - неделя и более)
            CASE
                WHEN MAX(lh.start_listen) IS NULL THEN 1.0
                WHEN MAX(lh.start_listen) <= CURRENT_TIMESTAMP - INTERVAL '7 days' THEN 1.0
                ELSE
                    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX(lh.start_listen))) / (7 * 86400)
            END as time_multiplier
        FROM source_songs ss
        LEFT JOIN listeningHistory lh ON ss.code_song = lh.code_song AND lh.id_author = p_id_author
        WHERE ss.code_song NOT IN (
            -- Исключаем песни из disliked
            SELECT code_song
            FROM tableOfContents toc2
            INNER JOIN playlist pl2 ON toc2.index_playlist = pl2.index_playlist
            WHERE pl2.id_author = p_id_author
              AND pl2.type_playlist = 'disliked'
        )
        GROUP BY ss.code_song, ss.popularity, ss.source_multiplier, ss.source_type
        -- Исключаем песни, которые были полностью прослушаны недавно (time_multiplier = 0)
        HAVING NOT (
            MAX(lh.start_listen) IS NOT NULL
            AND MAX(lh.start_listen) > CURRENT_TIMESTAMP - INTERVAL '1 day'
        )
    ),
    -- Рассчитываем итоговый рейтинг
    ranked_songs AS (
        SELECT DISTINCT ON (code_song)
            code_song,
            popularity,
            source_multiplier,
            source_type,
            last_listen,
            time_multiplier,
            -- Итоговый рейтинг: popularity * множитель_источника * множитель_времени
            COALESCE(popularity, 0) * source_multiplier * time_multiplier as final_rank
        FROM eligible_songs
        ORDER BY code_song
    )

    -- 5. Вставляем топ-25 треков
    INSERT INTO tableOfContents (index_playlist, code_song)
    SELECT v_new_playlist_id, code_song
    FROM ranked_songs
    ORDER BY final_rank DESC
    LIMIT 25;

    -- GET DIAGNOSTICS определяет количество строк, обработанных последней командой
    GET DIAGNOSTICS v_songs_added = ROW_COUNT;

    -- Для отладки
    RAISE NOTICE 'Daily playlist generated for user %. Added % songs to playlist "%" <=> %',
                 p_id_author, v_songs_added, v_playlist_name, v_new_playlist_id;

EXCEPTION
    WHEN OTHERS THEN
        IF v_new_playlist_id IS NOT NULL THEN
            DELETE FROM playlist WHERE index_playlist = v_new_playlist_id;
        END IF;
        RAISE;
END;
$$;
