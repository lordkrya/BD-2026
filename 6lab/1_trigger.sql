-- Функция для обновления popularity при добавлении трека в плейлист favorite
CREATE OR REPLACE FUNCTION update_popularity_on_favorite_add()
RETURNS TRIGGER AS $$
DECLARE
    v_playlist_type TypePlaylist;
    v_id_user uuid;
    v_number_album uuid;
    v_index_genre uuid;
    v_id_author_artist uuid;
BEGIN
    -- Проверяем, что трек добавляется именно в плейлист типа 'favorite'
    SELECT type_playlist, id_author INTO v_playlist_type, v_id_user
    FROM playlist
    WHERE playlist.index_playlist = NEW.index_playlist;

    IF v_playlist_type = 'favorite' THEN

		-- Удаляем тут песню из плейлиста disliked
		DELETE FROM tableOfContents
		WHERE code_song = NEW.code_song AND
			index_playlist = (
				SELECT index_playlist
				FROM playlist
				WHERE id_author = v_id_user AND name_playlist = 'disliked'
			);


		-- Обновляем предпочтения
    	INSERT INTO preferenceForSongs (id_author, code_song)
        VALUES (v_id_user, NEW.code_song);

        -- Получаем информацию о песне
        SELECT number_album, index_genre
        INTO v_number_album, v_index_genre
        FROM song
        WHERE song.code_song = NEW.code_song;

        -- 1. Обновляем popularity песни
        UPDATE song
        SET popularity = COALESCE(popularity, 0) + 1
        WHERE code_song = NEW.code_song;

        -- 2. Обновляем popularity жанра (если есть)
        IF v_index_genre IS NOT NULL THEN
            UPDATE musicGenre
            SET popularity = COALESCE(popularity, 0) + 1
            WHERE index_genre = v_index_genre;
        END IF;

        -- 3. Обновляем popularity альбома (если есть)
        IF v_number_album IS NOT NULL THEN
            UPDATE album
            SET popularity = COALESCE(popularity, 0) + 1
            WHERE number_album = v_number_album;
        END IF;

        -- 4. Обновляем popularity всех исполнителей этой песни
        FOR v_id_author_artist IN
            SELECT id_author
            FROM performance
            WHERE code_song = NEW.code_song
        LOOP
            UPDATE musicArtist
            SET popularity = COALESCE(popularity, 0) + 1
            WHERE id_author = v_id_author_artist;
        END LOOP;

    ELSIF v_playlist_type = 'disliked' THEN

		DELETE FROM tableOfContents
		WHERE code_song = NEW.code_song AND
			index_playlist = (
				SELECT index_playlist
				FROM playlist
				WHERE id_author = v_id_user AND name_playlist = 'favorite'
			);

    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер на tableOfContents (срабатывает при добавлении песни в любой плейлист)
CREATE TRIGGER trg_table_of_contents_after_insert
AFTER INSERT ON tableOfContents
FOR EACH ROW EXECUTE FUNCTION update_popularity_on_favorite_add();

--------------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_popularity_on_favorite_remove()
RETURNS TRIGGER AS $$
DECLARE
    v_playlist_type TypePlaylist;
    v_id_user uuid;
    v_number_album uuid;
    v_index_genre uuid;
    v_id_author_artist uuid;
BEGIN
    -- Проверяем, что трек удаляется именно из плейлиста типа 'favorite'
    SELECT type_playlist, id_author INTO v_playlist_type, v_id_user
    FROM playlist
    WHERE index_playlist = OLD.index_playlist;

    IF v_playlist_type = 'favorite' THEN

		-- Удаляем песню из предпочтений
    	DELETE FROM preferenceForSongs AS pfs
        WHERE pfs.id_author = v_id_user AND pfs.code_song = OLD.code_song;

        -- Получаем информацию о песне
        SELECT number_album, index_genre
        INTO v_number_album, v_index_genre
        FROM song
        WHERE code_song = OLD.code_song;

        -- Уменьшаем popularity (но не ниже 0)
        UPDATE song
        SET popularity = GREATEST(COALESCE(popularity, 0) - 1, 0)
        WHERE code_song = OLD.code_song;

        IF v_index_genre IS NOT NULL THEN
            UPDATE musicGenre
            SET popularity = GREATEST(COALESCE(popularity, 0) - 1, 0)
            WHERE index_genre = v_index_genre;
        END IF;

        IF v_number_album IS NOT NULL THEN
            UPDATE album
            SET popularity = GREATEST(COALESCE(popularity, 0) - 1, 0)
            WHERE number_album = v_number_album;
        END IF;

        FOR v_id_author_artist IN
            SELECT id_author
            FROM performance
            WHERE code_song = OLD.code_song
        LOOP
            UPDATE musicArtist
            SET popularity = GREATEST(COALESCE(popularity, 0) - 1, 0)
            WHERE id_author = v_id_author_artist;
        END LOOP;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_table_of_contents_before_delete
BEFORE DELETE ON tableOfContents
FOR EACH ROW EXECUTE FUNCTION update_popularity_on_favorite_remove();
