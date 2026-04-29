-- Функция для проверки прослушивания и автоматического добавления в favorite/disliked
CREATE OR REPLACE FUNCTION check_listening_and_update_playlists()
RETURNS TRIGGER AS $$
DECLARE
    v_has_listened boolean;
    v_favorite_playlist_id uuid;
    v_disliked_playlist_id uuid;
BEGIN
    -- Проверяем, прослушивал ли пользователь этот трек ранее
    SELECT EXISTS (
        SELECT 1
        FROM listeningHistory
        WHERE id_author = NEW.id_author
          AND code_song = NEW.code_song
    ) INTO v_has_listened;

    IF NOT v_has_listened THEN
        RAISE EXCEPTION 'Cannot rate a song that has not been listened to. User % has not listened to song %',
                        NEW.id_author, NEW.code_song;
    END IF;

    -- Получаем ID плейлистов favorite и disliked пользователя
    SELECT index_playlist INTO v_favorite_playlist_id
    FROM playlist
    WHERE id_author = NEW.id_author AND name_playlist = 'favorite';

    SELECT index_playlist INTO v_disliked_playlist_id
    FROM playlist
    WHERE id_author = NEW.id_author AND name_playlist = 'disliked';

    -- В зависимости от оценки добавляем/удаляем из плейлистов
    IF NEW.grade >= 7 THEN

        -- Добавляем в favorite
		INSERT INTO tableOfContents (index_playlist, code_song)
		VALUES (v_favorite_playlist_id, NEW.code_song)
		ON CONFLICT (index_playlist, code_song) DO NOTHING;


    ELSIF NEW.grade <= 4 THEN
        -- Оценка 4 и ниже: добавляем в disliked, удаляем из favorite

        -- Добавляем в disliked
		INSERT INTO tableOfContents (index_playlist, code_song)
		VALUES (v_disliked_playlist_id, NEW.code_song)
		ON CONFLICT (index_playlist, code_song) DO NOTHING;

    ELSE
        -- Оценки 5-6: удаляем из обоих плейлистов
		DELETE FROM tableOfContents
		WHERE index_playlist = v_favorite_playlist_id
			AND code_song = NEW.code_song;

		DELETE FROM tableOfContents
		WHERE index_playlist = v_disliked_playlist_id
			AND code_song = NEW.code_song;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер на таблицу comment
CREATE TRIGGER trg_comment_before_insert
BEFORE INSERT ON comment
FOR EACH ROW WHEN (NEW.grade IS NOT NULL)
EXECUTE FUNCTION check_listening_and_update_playlists();
