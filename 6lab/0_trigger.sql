-- Триггер для preferenceForSongs (добавление песни в предпочтения)
CREATE OR REPLACE FUNCTION log_preference_songs_add()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO musicCardHistory (id_author, date_change, is_add_change, type_id_change, id)
    VALUES (
        NEW.id_author,
        CURRENT_TIMESTAMP,
        TRUE,  -- добавление рекомендации
        'song',  -- TypeUuid = 'song'
        NEW.code_song
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_preference_songs_after_insert
AFTER INSERT ON preferenceForSongs
FOR EACH ROW EXECUTE FUNCTION log_preference_songs_add();

-- Триггер для preferenceForSongs (удаление песни из предпочтений)
CREATE OR REPLACE FUNCTION log_preference_songs_remove()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO musicCardHistory (id_author, date_change, is_add_change, type_id_change, id)
    VALUES (
        OLD.id_author,
        CURRENT_TIMESTAMP,
        FALSE,  -- удаление из рекомендаций
        'song',
        OLD.code_song
    );

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_preference_songs_before_delete
BEFORE DELETE ON preferenceForSongs
FOR EACH ROW EXECUTE FUNCTION log_preference_songs_remove();


-- Триггер для preferenceForGenre (добавление жанра в предпочтения)
CREATE OR REPLACE FUNCTION log_preference_genre_add()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO musicCardHistory (id_author, date_change, is_add_change, type_id_change, id)
    VALUES (
        NEW.id_author,
        CURRENT_TIMESTAMP,
        TRUE,  -- добавление рекомендации
        'genre',  -- TypeUuid = 'genre'
        NEW.index_genre
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trp_preference_genre_after_insert
AFTER INSERT ON preferenceForGenre
FOR EACH ROW EXECUTE FUNCTION log_preference_genre_add();

-- Триггер для preferenceForGenre (удаление жанра из предпочтений)
CREATE OR REPLACE FUNCTION log_preference_genre_remove()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO musicCardHistory (id_author, date_change, is_add_change, type_id_change, id)
    VALUES (
        OLD.id_author,
        CURRENT_TIMESTAMP,
        FALSE,  -- удаление из рекомендаций
        'genre',
        OLD.index_genre
    );

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trp_preference_genre_before_delete
BEFORE DELETE ON preferenceForGenre
FOR EACH ROW EXECUTE FUNCTION log_preference_genre_remove();


-- Триггер для preferenceForArtist (добавление артиста в предпочтения)
CREATE OR REPLACE FUNCTION log_preference_artist_add()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO musicCardHistory (id_author, date_change, is_add_change, type_id_change, id)
    VALUES (
        NEW.id_author_user,
        CURRENT_TIMESTAMP,
        TRUE,  -- добавление рекомендации
        'author',  -- TypeUuid = 'author' (артист - это тоже author)
        NEW.id_author_artist
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_preference_artist_after_insert
AFTER INSERT ON preferenceForArtist
FOR EACH ROW EXECUTE FUNCTION log_preference_artist_add();

-- Триггер для preferenceForArtist (удаление артиста из предпочтений)
CREATE OR REPLACE FUNCTION log_preference_artist_remove()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO musicCardHistory (id_author, date_change, is_add_change, type_id_change, id)
    VALUES (
        OLD.id_author_user,
        CURRENT_TIMESTAMP,
        FALSE,  -- удаление из рекомендаций
        'author',
        OLD.id_author_artist
    );

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_preference_artist_before_delete
BEFORE DELETE ON preferenceForArtist
FOR EACH ROW EXECUTE FUNCTION log_preference_artist_remove();