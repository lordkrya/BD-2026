-- \connect acid_sound
-- psql -U postgres -W -p 5432 -h localhost -d acid_sound
-- \! chcp 1251
-- \dt

-- DROP DATABASE IF EXISTS ACID_Sound;

-- CREATE DATABASE ACID_Sound;


-- Проверка на то, что таблиц не существует, иначе пересоздаём

DROP TABLE IF EXISTS author CASCADE; -- E15
DROP TABLE IF EXISTS "user" CASCADE; -- E1
DROP TABLE IF EXISTS bankCard CASCADE; -- E2
DROP TABLE IF EXISTS musicCard CASCADE; -- E3
DROP TABLE IF EXISTS musicCardHistory CASCADE; -- E4
DROP TABLE IF EXISTS playlist CASCADE; -- E5
DROP TABLE IF EXISTS musicArtist CASCADE; -- E6
DROP TABLE IF EXISTS musicGenre CASCADE; -- E7
DROP TABLE IF EXISTS album CASCADE; -- E8
DROP TABLE IF EXISTS song CASCADE; -- E9
DROP TABLE IF EXISTS comment CASCADE; -- E10
DROP TABLE IF EXISTS premiumFunc CASCADE; -- E11
DROP TABLE IF EXISTS listeningHistory CASCADE; -- E12
DROP TABLE IF EXISTS producing CASCADE; -- E13
DROP TABLE IF EXISTS performance CASCADE; -- E14
DROP TABLE IF EXISTS subscription CASCADE; -- E16
DROP TABLE IF EXISTS tableOfContents CASCADE; -- E17
DROP TABLE IF EXISTS preferenceForSongs CASCADE; -- E18
DROP TABLE IF EXISTS preferenceForGenre CASCADE; -- E19
DROP TABLE IF EXISTS preferenceForArtist CASCADE; -- E20

-- Проверка на то, что ENUM не существуют, иначе пересоздаём

DROP TYPE IF EXISTS Mood;
DROP TYPE IF EXISTS TypeUuid;
DROP TYPE IF EXISTS Source;
DROP TYPE IF EXISTS TypeAuthor;

-- Создание ENUM

CREATE TYPE Mood AS ENUM ('energetic', 'melancholic', 'chill', 'playful', 'romantic');
CREATE TYPE TypeUuid AS ENUM ('author', 'playlist', 'song', 'genre', 'album');
CREATE TYPE Source AS ENUM ('search', 'recommendation', 'playlist', 'subscription', 'other');
CREATE TYPE TypeAuthor AS ENUM ('user', 'artist');
CREATE TYPE TypePlaylist AS ENUM ('public', 'private', 'favorite', 'disliked');

-- Создание таблиц

-- E15 
CREATE TABLE author (
    id_author uuid DEFAULT gen_random_uuid() PRIMARY KEY, 
    type_author TypeAuthor NOT NULL
);

-- E1
CREATE TABLE "user" (
    id_author uuid PRIMARY KEY, 
    full_name varchar(256),
    date_of_birth date CHECK (date_of_birth >= '1900-01-01' AND date_of_birth <= CURRENT_DATE),
    user_login varchar(64) UNIQUE NOT NULL,
    user_password bytea NOT NULL,
    phone_number varchar(16) UNIQUE CHECK (phone_number ~ '(\+)?[0-9]{1,15}'),
    CONSTRAINT fk_id_author
        FOREIGN KEY (id_author)
        REFERENCES author(id_author)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);
-- Функция для автоматического создания родителя
CREATE OR REPLACE FUNCTION create_author_for_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO author (id_author, type_author) 
    VALUES (NEW.id_author, 'user');
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Вешаем триггер на user
CREATE TRIGGER trg_user_before_insert
BEFORE INSERT ON "user"
FOR EACH ROW EXECUTE FUNCTION create_author_for_user();
-- Функция для удаления записи из author при удалении пользователя
CREATE OR REPLACE FUNCTION delete_author_for_user()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM author WHERE id_author = OLD.id_author;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;
-- Триггер на user
CREATE TRIGGER trg_user_delete_author
AFTER DELETE ON "user"
FOR EACH ROW EXECUTE FUNCTION delete_author_for_user();


-- E2
CREATE TABLE bankCard (
    id_author uuid PRIMARY KEY,
    card_number bytea NOT NULL,
    cvc bytea,
    limitation date,
    CONSTRAINT fk_id_author 
        FOREIGN KEY (id_author)
        REFERENCES "user"(id_author)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- E3
CREATE TABLE musicCard (
    id_author uuid PRIMARY KEY,
    frequency integer CHECK (frequency >= 0),
    activity integer CHECK (activity >= 0),
    mood Mood,
    CONSTRAINT fk_id_author 
        FOREIGN KEY (id_author)
        REFERENCES "user"(id_author)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
-- Функция для автоматического создания музыкальной карты
CREATE OR REPLACE FUNCTION create_music_card_for_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO musicCard (id_author, frequency, activity, mood) 
    VALUES (NEW.id_author, 0, 0, NULL); -- Начальные значения
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Триггер на user
CREATE TRIGGER trg_user_create_card
AFTER INSERT ON "user"
FOR EACH ROW EXECUTE FUNCTION create_music_card_for_user();


-- E4
CREATE TABLE musicCardHistory (
    code_change bigint GENERATED ALWAYS AS IDENTITY,
    id_author uuid,
    date_change timestamp NOT NULL CHECK (date_change <= CURRENT_TIMESTAMP),
    is_add_change boolean NOT NULL, -- 1 - добавление рекомендации, 0 удаление из рекомендаций
    type_id_change TypeUuid NOT NULL,
    id uuid NOT NULL,
    CONSTRAINT pk_card_history 
        PRIMARY KEY (code_change, id_author),
    CONSTRAINT fk_id_author
        FOREIGN KEY (id_author)
        REFERENCES musicCard(id_author)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- E5
CREATE TABLE playlist (
    index_playlist uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    id_author uuid,
    name_playlist varchar(256) NOT NULL,
    type_playlist TypePlaylist NOT NULL,
    date_playlist date NOT NULL CHECK (date_playlist <= CURRENT_DATE),
    CONSTRAINT fk_id_author
        FOREIGN KEY (id_author)
        REFERENCES "user"(id_author)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT unique_user_playlist
        UNIQUE (id_author, name_playlist)
);

-- Функция для автоматического создания плейлиста favorite/disliked при добавлении пользователя
CREATE OR REPLACE FUNCTION create_favorite_playlist()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO playlist (id_author, name_playlist, type_playlist, date_playlist)
    VALUES (NEW.id_author, 'favorite', 'favorite', CURRENT_DATE);
    INSERT INTO playlist (id_author, name_playlist, type_playlist, date_playlist)
    VALUES (NEW.id_author, 'disliked', 'disliked', CURRENT_DATE);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Триггер на user для создания плейлиста favorite/disliked
CREATE TRIGGER trg_user_create_favorite_playlist
AFTER INSERT ON "user"
FOR EACH ROW EXECUTE FUNCTION create_favorite_playlist();

-- Функция для защиты от удаления плейлиста favorite/disliked (кроме случая каскадного удаления)
CREATE OR REPLACE FUNCTION prevent_favorite_playlist_deletion()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.type_playlist = 'favorite' OR OLD.type_playlist = 'disliked' THEN
		IF EXISTS (SELECT 1 FROM "user" WHERE id_author = OLD.id_author) THEN
			RAISE EXCEPTION 'Cannot delete favorite/disliked playlist directly. It will be deleted automatically when the user is deleted.';
		END IF;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;
-- Триггер на playlist для защиты от удаления favorite плейлиста
CREATE TRIGGER trg_playlist_before_delete
BEFORE DELETE ON playlist
FOR EACH ROW EXECUTE FUNCTION prevent_favorite_playlist_deletion();

-- Дополнительная защита от обновления favorite/disliked плейлиста (нельзя изменить тип)
CREATE OR REPLACE FUNCTION protect_favorite_playlist_update()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.type_playlist = 'favorite' OR OLD.type_playlist = 'disliked' THEN
    	RAISE EXCEPTION 'Cannot modify favorite/disliked playlist type.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Триггер на playlist для защиты от изменения favorite плейлиста
CREATE TRIGGER trg_playlist_before_update
BEFORE UPDATE ON playlist
FOR EACH ROW EXECUTE FUNCTION protect_favorite_playlist_update();



-- E6
CREATE TABLE musicArtist (
    id_author uuid PRIMARY KEY,
    name_artist varchar(256) UNIQUE NOT NULL,
    discription text,
    popularity integer DEFAULT 0,
    CONSTRAINT fk_id_author
        FOREIGN KEY (id_author)
        REFERENCES author(id_author)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);
-- Функция для артиста
CREATE OR REPLACE FUNCTION create_author_for_artist()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO author (id_author, type_author) 
    VALUES (NEW.id_author, 'artist'); -- Тип 'artist'
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Триггер для артиста
CREATE TRIGGER trg_artist_before_insert
BEFORE INSERT ON musicArtist
FOR EACH ROW EXECUTE FUNCTION create_author_for_artist();
-- Функция для удаления записи из author при удалении артиста
CREATE OR REPLACE FUNCTION delete_author_for_artist()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM author WHERE id_author = OLD.id_author;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;
-- Триггер на musicArtist
CREATE TRIGGER trg_artist_delete_author
AFTER DELETE ON musicArtist
FOR EACH ROW EXECUTE FUNCTION delete_author_for_artist();


-- E7
CREATE TABLE musicGenre (
    index_genre uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name_genre varchar(64) UNIQUE NOT NULL,
    discription text,
    popularity integer DEFAULT 0
);

-- E8
CREATE TABLE album (
    number_album uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    index_genre uuid,
    name_album varchar(64) NOT NULL,
    date_album date CHECK (date_album <= CURRENT_DATE),
    number_of_songs integer CHECK (number_of_songs > 0),
    popularity integer DEFAULT 0,
    CONSTRAINT fk_index_genre 
        FOREIGN KEY (index_genre)
        REFERENCES musicGenre(index_genre)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- E9
CREATE TABLE song (
    code_song uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    number_album uuid,
    index_genre uuid,
    name_song varchar(64) NOT NULL,
    text_song text,
    during time NOT NULL CHECK (during > '00:00:00'::time),
    popularity integer DEFAULT 0,
    CONSTRAINT fk_number_album
        FOREIGN KEY (number_album)
        REFERENCES album(number_album)
        ON DELETE set NULL
        ON UPDATE CASCADE,
    CONSTRAINT fk_index_genre
        FOREIGN KEY (index_genre)
        REFERENCES musicGenre(index_genre)
        ON DELETE set NULL
        ON UPDATE CASCADE
);

-- E10
CREATE TABLE comment (
    number_comment bigint GENERATED ALWAYS AS IDENTITY,
    id_author uuid,
    code_song uuid NOT NULL,
    text_comment text,
    grade real CHECK (grade BETWEEN 1 AND 10),
    date_comment timestamp NOT NULL CHECK (date_comment <= CURRENT_DATE),
    CONSTRAINT pk_comment
        PRIMARY KEY (number_comment, id_author),
    CONSTRAINT fk_code_song
        FOREIGN KEY (code_song)
        REFERENCES song(code_song)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_id_author
        FOREIGN KEY (id_author)
        REFERENCES "user"(id_author)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT at_least_one_not_null 
        CHECK (text_comment IS NOT NULL OR grade IS NOT NULL)
);

-- E11
CREATE TABLE premiumFunc (
    id_author uuid PRIMARY KEY,
    date_prem timestamp NOT NULL CHECK (date_prem <= CURRENT_TIMESTAMP),
    expiration timestamp NOT NULL CHECK (expiration > date_prem),
    promo_code varchar(16),
    CONSTRAINT fk_id_author 
        FOREIGN KEY (id_author)
        REFERENCES "user"(id_author)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- E12
CREATE TABLE listeningHistory (
    code_listening bigint GENERATED ALWAYS AS IDENTITY,
    id_author uuid,
    code_song uuid NOT NULL,
    start_listen timestamp NOT NULL CHECK (start_listen <= CURRENT_TIMESTAMP),
    during time NOT NULL CHECK (during > '00:00:00'::time),
    source Source NOT NULL,
    id_source uuid,
    CONSTRAINT pk_listening
        PRIMARY KEY (code_listening, id_author),
    CONSTRAINT fk_code_song
        FOREIGN KEY (code_song)
        REFERENCES song(code_song)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_id_author
        FOREIGN KEY (id_author)
        REFERENCES musicCard(id_author)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- E13
CREATE TABLE producing (
    id_author uuid,
    number_album uuid,
    CONSTRAINT pk_producing
        PRIMARY KEY (id_author, number_album),
    CONSTRAINT kf_id_author
        FOREIGN KEY (id_author)
        REFERENCES musicArtist(id_author)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT kf_number_album
        FOREIGN KEY (number_album)
        REFERENCES album(number_album)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- E14
CREATE TABLE performance (
    id_author uuid,
    code_song uuid,
    CONSTRAINT pk_performance
        PRIMARY KEY (id_author, code_song),
    CONSTRAINT fk_id_author
        FOREIGN KEY (id_author)
        REFERENCES author(id_author)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_code_song
        FOREIGN KEY (code_song)
        REFERENCES song(code_song)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- E16
CREATE TABLE subscription (
    id_author_user uuid,
    id_author_artist uuid,
    CONSTRAINT pk_subscription
        PRIMARY KEY (id_author_user, id_author_artist),
    CONSTRAINT fk_id_author_user
        FOREIGN KEY (id_author_user)
        REFERENCES "user"(id_author)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_id_author_artist
        FOREIGN KEY (id_author_artist)
        REFERENCES musicArtist(id_author)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- E17
CREATE TABLE tableOfContents (
    index_playlist uuid,
    code_song uuid,
    CONSTRAINT pk_table
        PRIMARY KEY (index_playlist, code_song),
    CONSTRAINT fk_index_playlist
        FOREIGN KEY (index_playlist)
        REFERENCES playlist(index_playlist)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_code_song
        FOREIGN KEY (code_song)
        REFERENCES song(code_song)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- E18
CREATE TABLE preferenceForSongs (
    id_author uuid,
    code_song uuid,
    CONSTRAINT pk_preferenceForSongs
        PRIMARY KEY (id_author, code_song),
    CONSTRAINT fk_id_author
        FOREIGN KEY (id_author)
        REFERENCES musicCard(id_author)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_code_song
        FOREIGN KEY (code_song)
        REFERENCES song(code_song)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- E19
CREATE TABLE preferenceForGenre (
    id_author uuid,
    index_genre uuid,
    CONSTRAINT pk_preferenceForGenre
        PRIMARY KEY (id_author, index_genre),
    CONSTRAINT fk_id_author
        FOREIGN KEY (id_author)
        REFERENCES musicCard(id_author)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_index_genre
        FOREIGN KEY (index_genre)
        REFERENCES musicGenre(index_genre)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- E20
CREATE TABLE preferenceForArtist (
    id_author_user uuid,
    id_author_artist uuid,
    CONSTRAINT pk_preferenceForArtist
        PRIMARY KEY (id_author_user, id_author_artist),
    CONSTRAINT fk_id_author_user
        FOREIGN KEY (id_author_user)
        REFERENCES musicCard(id_author)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_id_author_artist
        FOREIGN KEY (id_author_artist)
        REFERENCES musicArtist(id_author)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
