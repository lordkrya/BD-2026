import psycopg2
import psycopg2.extras
import uuid
import random
import hashlib
from datetime import datetime, timedelta, date, time
import re
from faker import Faker

# Инициализация Faker для генерации реалистичных данных
fake = Faker('ru_RU')

# Параметры подключения к БД
DB_CONFIG = {
    'dbname': 'acid_sound',
    'user': 'postgres',
    'password': '123321',
    'host': 'localhost',
    'port': 54326
}

# ENUM значения
MOODS = ['energetic', 'melancholic', 'chill', 'playful', 'romantic']
SOURCES = ['search', 'recommendation', 'playlist', 'subscription', 'other']
TYPE_UUID = ['author', 'playlist', 'song', 'genre', 'album']
TYPE_AUTHOR = ['user', 'artist']
TYPE_PLAYLIST = ['public', 'private']


def get_connection():
    """Установка соединения с БД"""
    return psycopg2.connect(**DB_CONFIG)


def clear_all_data(conn):
    """Очистка всех таблиц от данных"""
    cursor = conn.cursor()

    tables = [
        'preferenceforartist', 'preferenceforgenre', 'preferenceforsongs', 'premiumfunc', '"user"',
        'tableofcontents', 'subscription', 'performance', 'producing',
        'listeninghistory', 'comment', 'song', 'album',
        'musicartist', 'playlist', 'musiccardhistory', 'musiccard',
        'bankcard', 'author', 'musicgenre'
    ]

    for table in tables:
        try:
            cursor.execute(f'DELETE FROM {table}')
            print(f"Очищена таблица: {table}")
        except Exception as e:
            print(f"Ошибка при очистке {table}: {e}")

    conn.commit()
    cursor.close()
    print("\nВсе данные удалены!")


# E1
def insert_users(conn, count):
    """Вставка данных в таблицу user (author создается триггером)"""
    cursor = conn.cursor()
    users = []
    
    for _ in range(count):
        user_id = uuid.uuid4()
        full_name = fake.name()
        date_of_birth = fake.date_of_birth(minimum_age=14, maximum_age=99)
        user_login = fake.user_name() + str(random.randint(1000, 9999))
        user_password = hashlib.sha256(fake.password().encode()).digest()
        # Очищаем номер от всего кроме цифр и '+'
        raw_phone = re.sub(r'[\s\-\(\)\.]', '', fake.phone_number())
        phone_number = raw_phone[:16]
        
        cursor.execute("""
            INSERT INTO "user" (id_author, full_name, date_of_birth, user_login, user_password, phone_number)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (user_id, full_name, date_of_birth, user_login, user_password, phone_number))
        users.append(user_id)
    
    conn.commit()
    cursor.close()
    print(f"Добавлено {len(users)} записей в user (author и musicCard созданы триггерами)")
    return users


# E6
def insert_music_artists(conn, count):
    """Вставка данных в таблицу musicArtist (author создается триггером)"""
    cursor = conn.cursor()
    artists = []
    
    for _ in range(count):
        artist_id = uuid.uuid4()
        name_artist = fake.company() + " " + fake.word().title()
        name_artist = name_artist[:253] + str(random.randint(100, 999))
        description = fake.text(max_nb_chars=200)
        
        cursor.execute("""
            INSERT INTO musicArtist (id_author, name_artist, discription)
            VALUES (%s, %s, %s)
        """, (artist_id, name_artist, description))
        artists.append(artist_id)
    
    conn.commit()
    cursor.close()
    print(f"Добавлено {len(artists)} записей в musicArtist (author созданы триггером)")
    return artists


# E2
def insert_bank_cards(conn, users):
    """Вставка данных в таблицу bankCard"""
    cursor = conn.cursor()
    count = 0
    
    for user_id in users:
        if random.choice([True, False]):
            card_number = hashlib.sha256(fake.credit_card_number().encode()).digest()
            cvc = hashlib.sha256(fake.credit_card_security_code().encode()).digest() if random.choice([True, False]) else None
            limitation = fake.date_between(start_date='today', end_date='+5y')
            
            cursor.execute("""
                INSERT INTO bankCard (id_author, card_number, cvc, limitation)
                VALUES (%s, %s, %s, %s)
            """, (user_id, card_number, cvc, limitation))
            count += 1
    
    conn.commit()
    cursor.close()
    print(f"Добавлено {count} записей в bankCard")


# E3 - удалена, так как musicCard создается триггером
# Но оставим функцию для обновления случайными данными
def update_music_cards(conn, users):
    """Обновление данных в таблице musicCard (созданных триггерами)"""
    cursor = conn.cursor()
    
    for user_id in users:
        frequency = random.randint(0, 1000)
        activity = random.randint(0, 500)
        mood = random.choice(MOODS)
        
        cursor.execute("""
            UPDATE musicCard 
            SET frequency = %s, activity = %s, mood = %s
            WHERE id_author = %s
        """, (frequency, activity, mood, user_id))
    
    conn.commit()
    cursor.close()
    print(f"Обновлено {len(users)} записей в musicCard")


# E7
def insert_music_genres(conn, count):
    """Вставка данных в таблицу musicGenre"""
    cursor = conn.cursor()
    genres = []
    
    genre_names = ['Rock', 'Pop', 'Jazz', 'Classical', 'Hip-Hop', 'Electronic', 'Metal', 'Blues', 'Country', 'Reggae']
    
    for i in range(min(count, len(genre_names))):
        genre_id = uuid.uuid4()
        name_genre = genre_names[i]
        description = fake.text(max_nb_chars=100)
        popularity = 0
        #popularity = random.randint(0, 100)
        
        cursor.execute("""
            INSERT INTO musicGenre (index_genre, name_genre, discription, popularity)
            VALUES (%s, %s, %s, %s)
        """, (genre_id, name_genre, description, popularity))
        genres.append(genre_id)
    
    conn.commit()
    cursor.close()
    print(f"Добавлено {len(genres)} записей в musicGenre")
    return genres


# E8
def insert_albums(conn, genres, count, avg_count):
    """Вставка данных в таблицу album"""
    cursor = conn.cursor()
    albums = []
    
    for _ in range(count):
        album_id = uuid.uuid4()
        genre = random.choice(genres) if genres and random.choice([True, False]) else None
        name_album = fake.catch_phrase()[:64]
        date_album = fake.date_between(start_date='-10y', end_date='today')
        number_of_songs = random.randint(1, avg_count * 2 - 1)
        
        cursor.execute("""
            INSERT INTO album (number_album, index_genre, name_album, date_album, number_of_songs)
            VALUES (%s, %s, %s, %s, %s)
        """, (album_id, genre, name_album, date_album, number_of_songs))
        albums.append((album_id, number_of_songs))
    
    conn.commit()
    cursor.close()
    print(f"Добавлено {len(albums)} записей в album")
    return albums


# E9
def insert_songs(conn, albums, genres, singles_count):
    """Вставка данных в таблицу song"""
    cursor = conn.cursor()
    songs = []

    # Вставка песен из альбомов
    for album_id, album_songs_count in albums:
        for _ in range(album_songs_count):
            song_id = uuid.uuid4()
            genre = random.choice(genres) if genres and random.choice([True, False]) else None
            name_song = fake.sentence(nb_words=3)[:64]
            text_song = fake.text(max_nb_chars=500) if random.choice([True, False]) else None
            # Время от 1 до 10 минут
            during = time(
                hour=0,
                minute=random.randint(0, 9),
                second=random.randint(1, 59)
            )

            cursor.execute("""
                INSERT INTO song (code_song, number_album, index_genre, name_song, text_song, during)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (song_id, album_id, genre, name_song, text_song, during))
            songs.append(song_id)

    # Вставка синглов
    for _ in range(singles_count):
        song_id = uuid.uuid4()
        genre = random.choice(genres) if genres and random.choice([True, False]) else None
        name_song = fake.sentence(nb_words=3)[:64]
        text_song = fake.text(max_nb_chars=500) if random.choice([True, False]) else None
        during = time(
            hour=0,
            minute=random.randint(1, 9),
            second=random.randint(0, 59)
        )

        cursor.execute("""
            INSERT INTO song (code_song, number_album, index_genre, name_song, text_song, during)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (song_id, None, genre, name_song, text_song, during))
        songs.append(song_id)

    conn.commit()
    cursor.close()
    print(f"Добавлено {len(songs)} записей в song")
    return songs


# E5
def insert_playlists(conn, users, count):
    """Вставка данных в таблицу playlist"""
    cursor = conn.cursor()
    playlists = []
    
    for _ in range(count):
        playlist_id = uuid.uuid4()
        user = random.choice(users) if users else None
        name_playlist = fake.catch_phrase() + str(_)
        type_playlist = random.choice(TYPE_PLAYLIST)
        date_playlist = fake.date_between(start_date='-5y', end_date='today')
        
        cursor.execute("""
            INSERT INTO playlist (index_playlist, id_author, name_playlist, type_playlist, date_playlist)
            VALUES (%s, %s, %s, %s, %s)
        """, (playlist_id, user, name_playlist, type_playlist, date_playlist))
        playlists.append(playlist_id)
    
    conn.commit()
    cursor.close()
    print(f"Добавлено {len(playlists)} записей в playlist")
    return playlists


# E11
def insert_premium_func(conn, users):
    """Вставка данных в таблицу premiumFunc"""
    cursor = conn.cursor()
    count = 0
    
    for user_id in users:
        if random.choice([True, False]):
            date_prem = fake.date_time_between(start_date='-1y', end_date='now')
            expiration = date_prem + timedelta(days=random.randint(1, 365))
            promo_code = fake.bothify(text='????-#####').upper() if random.choice([True, False]) else None
            
            cursor.execute("""
                INSERT INTO premiumFunc (id_author, date_prem, expiration, promo_code)
                VALUES (%s, %s, %s, %s)
            """, (user_id, date_prem, expiration, promo_code))
            count += 1
    
    conn.commit()
    cursor.close()
    print(f"Добавлено {count} записей в premiumFunc")


# E16
def insert_subscriptions(conn, users, artists):
    """Вставка данных в таблицу subscription"""
    cursor = conn.cursor()
    count = 0
    
    for user_id in users:
        num_subscriptions = random.randint(0, min(20, len(artists)))
        if num_subscriptions > 0:
            selected_artists = random.sample(artists, num_subscriptions)
            
            for artist_id in selected_artists:
                try:
                    cursor.execute("""
                        INSERT INTO subscription (id_author_user, id_author_artist)
                        VALUES (%s, %s)
                        ON CONFLICT DO NOTHING
                    """, (user_id, artist_id))
                    count += 1
                except:
                    pass
    
    conn.commit()
    cursor.close()
    print(f"Добавлено {count} записей в subscription")


# # E10
# def insert_comments(conn, users, songs, comments_per_user):
#     """Вставка данных в таблицу comment (number_comment генерируется автоматически)"""
#     cursor = conn.cursor()
#     count = 0
#
#     for user_id in users:
#         num_comments = random.randint(0, comments_per_user * 2)
#         for _ in range(num_comments):
#             song_id = random.choice(songs)
#             text_comment = fake.text(max_nb_chars=200) if random.choice([True, False]) else None
#             # grade - real от 1 до 10
#             grade = round(random.uniform(1, 10), 1) if random.choice([True, False]) or not text_comment else None
#             date_comment = fake.date_time_between(start_date='-30d', end_date='-1d')
#
#             cursor.execute("""
#                 INSERT INTO comment (id_author, code_song, text_comment, grade, date_comment)
#                 VALUES (%s, %s, %s, %s, %s)
#             """, (user_id, song_id, text_comment, grade, date_comment))
#             count += 1
#
#     conn.commit()
#     cursor.close()
#     print(f"Добавлено {count} записей в comment")


# E12
def insert_listening_history(conn, users, songs, listens_per_user, prob_comments):
    """Вставка данных в таблицу listeningHistory (code_listening генерируется автоматически)"""
    cursor = conn.cursor()
    count = 0
    count_comments = 0

    for user_id in users:
        num_listens = random.randint(0, listens_per_user * 2)
        for _ in range(num_listens):
            song_id = random.choice(songs)

            start_listen = fake.date_time_between(start_date='-30d', end_date='-1d')
            during = time(
                hour=0,
                minute=random.randint(1, 9),
                second=random.randint(0, 59)
            )
            source = random.choice(SOURCES)
            id_source = uuid.uuid4() if random.choice([True, False]) else None

            cursor.execute("""
                INSERT INTO listeningHistory (id_author, code_song, start_listen, during, source, id_source)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (user_id, song_id, start_listen, during, source, id_source))
            count += 1

            if random.random() < prob_comments:
                text_comment = fake.text(max_nb_chars=200) if random.choice([True, False]) else None
                # grade - real от 1 до 10
                grade = round(random.uniform(1, 10), 1) if random.choice([True, False]) or not text_comment else None
                cursor.execute("""
                    INSERT INTO comment (id_author, code_song, text_comment, grade, date_comment)
                        VALUES (%s, %s, %s, %s, %s)
                """, (user_id, song_id, text_comment, grade, start_listen))
                count_comments += 1

    conn.commit()
    cursor.close()
    print(f"Добавлено {count} записей в listeningHistory")
    print(f"Добавлено {count_comments} записей в comment")


# E4
# def insert_music_card_history(conn, users, artists, songs, genres, history_per_user):
#     """Вставка данных в таблицу musicCardHistory (code_change генерируется автоматически)"""
#     cursor = conn.cursor()
#     count = 0
#
#     type_mapping = {
#         'author': artists,
#         'song': songs,
#         'genre': genres
#     }
#     available_types = ['author', 'song', 'genre']
#
#     for user_id in users:
#         if random.choice([True, False]):
#             num_changes = random.randint(0, history_per_user * 2)
#             for _ in range(num_changes):
#                 date_change = fake.date_time_between(start_date='-30d', end_date='now')
#                 is_add_change = random.choice([True, False])
#                 type_id_change = random.choice(available_types)
#
#                 # Проверяем, что есть из чего выбирать
#                 if type_mapping[type_id_change]:
#                     id_uuid = random.choice(type_mapping[type_id_change])
#
#                     cursor.execute("""
#                         INSERT INTO musicCardHistory (id_author, date_change, is_add_change, type_id_change, id)
#                         VALUES (%s, %s, %s, %s, %s)
#                     """, (user_id, date_change, is_add_change, type_id_change, id_uuid))
#                     count += 1
#
#     conn.commit()
#     cursor.close()
#     print(f"Добавлено {count} записей в musicCardHistory")

# E13
def insert_producing(conn, artists, albums):
    """Вставка данных в таблицу producing"""
    cursor = conn.cursor()
    count = 0

    for album_id, _ in albums:
        num_artists = random.randint(1, min(3, len(artists)))
        if num_artists > 0:
            selected_artists = random.sample(artists, num_artists)

            for artist_id in selected_artists:
                try:
                    cursor.execute("""
                        INSERT INTO producing (id_author, number_album)
                        VALUES (%s, %s)
                        ON CONFLICT DO NOTHING
                    """, (artist_id, album_id))
                    count += 1
                except:
                    pass

    conn.commit()
    cursor.close()
    print(f"Добавлено {count} записей в producing")


# E14
def insert_performance(conn, users, artists, songs):
    """Вставка данных в таблицу performance (исполнителями могут быть и пользователи, и артисты)"""
    cursor = conn.cursor()
    count = 0
    
    # Объединяем пользователей и артистов как потенциальных исполнителей
    all_performers = users[:min(int(len(artists)/4), len(users))] + artists

    for song_id in songs:
        num_performances = random.randint(1, min(3, len(all_performers)))
        if num_performances > 0:
            selected_performers = random.sample(all_performers, num_performances)

            for performer_id in selected_performers:
                try:
                    cursor.execute("""
                        INSERT INTO performance (id_author, code_song)
                        VALUES (%s, %s)
                        ON CONFLICT DO NOTHING
                    """, (performer_id, song_id))
                    count += 1
                except:
                    pass

    conn.commit()
    cursor.close()
    print(f"Добавлено {count} записей в performance")


# E17
def insert_table_of_contents(conn, playlists, songs):
    """Вставка данных в таблицу tableOfContents"""
    cursor = conn.cursor()
    count = 0

    for playlist_id in playlists:
        num_songs = random.randint(1, min(19, len(songs)))
        if num_songs > 0:
            selected_songs = random.sample(songs, num_songs)

            for song_id in selected_songs:
                try:
                    cursor.execute("""
                        INSERT INTO tableOfContents (index_playlist, code_song)
                        VALUES (%s, %s)
                        ON CONFLICT DO NOTHING
                    """, (playlist_id, song_id))
                    count += 1
                except:
                    pass

    conn.commit()
    cursor.close()
    print(f"Добавлено {count} записей в tableOfContents")


# E18
def insert_preference_for_songs(conn, users, songs):
    """Вставка данных в таблицу preferenceForSongs"""
    cursor = conn.cursor()
    count = 0

    for user_id in users:
        num_preferences = random.randint(0, min(20, len(songs)))
        if num_preferences > 0:
            selected_songs = random.sample(songs, num_preferences)

            for song_id in selected_songs:
                try:
                    cursor.execute("""
                        INSERT INTO preferenceForSongs (id_author, code_song)
                        VALUES (%s, %s)
                        ON CONFLICT DO NOTHING
                    """, (user_id, song_id))
                    count += 1
                except:
                    pass

    conn.commit()
    cursor.close()
    print(f"Добавлено {count} записей в preferenceForSongs")


# E19
def insert_preference_for_genre(conn, users, genres):
    """Вставка данных в таблицу preferenceForGenre"""
    cursor = conn.cursor()
    count = 0

    for user_id in users:
        num_preferences = random.randint(0, min(20, len(genres)))
        if num_preferences > 0 and genres:
            selected_genres = random.sample(genres, num_preferences)

            for genre_id in selected_genres:
                try:
                    cursor.execute("""
                        INSERT INTO preferenceForGenre (id_author, index_genre)
                        VALUES (%s, %s)
                        ON CONFLICT DO NOTHING
                    """, (user_id, genre_id))
                    count += 1
                except:
                    pass

    conn.commit()
    cursor.close()
    print(f"Добавлено {count} записей в preferenceForGenre")


# E20
def insert_preference_for_artist(conn, users, artists):
    """Вставка данных в таблицу preferenceForArtist"""
    cursor = conn.cursor()
    count = 0

    for user_id in users:
        num_preferences = random.randint(0, min(20, len(artists)))
        if num_preferences > 0:
            selected_artists = random.sample(artists, num_preferences)

            for artist_id in selected_artists:
                try:
                    cursor.execute("""
                        INSERT INTO preferenceForArtist (id_author_user, id_author_artist)
                        VALUES (%s, %s)
                        ON CONFLICT DO NOTHING
                    """, (user_id, artist_id))
                    count += 1
                except:
                    pass

    conn.commit()
    cursor.close()
    print(f"Добавлено {count} записей в preferenceForArtist")


def insert_data_custom(conn):
    """Вставка данных с пользовательским вводом количества"""
    print("\n=== Введите количество записей для каждой таблицы ===\n")
    
    try:
        users_count = int(input("Количество пользователей (user): ") or "1000")
        artists_count = int(input("Количество исполнителей (musicArtist): ") or "100")
        genres_count = 10
        albums_count = int(input("Количество альбомов (album): ") or "200")
        avg_songs_count = int(input("Среднее количество песен в альбоме (song = album * avgSongsCount): ") or "5")
        singles_count = int(input("Количество синглов (song += Const): ") or "200")
        prob_comments = float(input("Вероятность комментария (comment): ") or "0.1")
        listens_per_user = int(input("Среднее количество прослушиваний пользователя (listeningHistory): ") or "100")
        playlists_count = int(input("Количество плейлистов (playlist): ") or "100")
        
    except ValueError:
        print("Ошибка: введите корректные числа!")
        return
    
    print("\n=== Начало вставки пользовательских данных ===\n")
    
    # Создаем пользователей (триггеры автоматически создадут author и musicCard)
    users = insert_users(conn, users_count)
    
    # Создаем артистов (триггер автоматически создаст author)
    artists = insert_music_artists(conn, artists_count)
    
    # Обновляем musicCard случайными данными
    update_music_cards(conn, users)
    
    # Создаем остальные сущности
    insert_bank_cards(conn, users)
    insert_premium_func(conn, users)
    playlists = insert_playlists(conn, users, playlists_count)
    
    genres = insert_music_genres(conn, genres_count)
    albums = insert_albums(conn, genres, albums_count, avg_songs_count)
    songs = insert_songs(conn, albums, genres, singles_count)

    # Связи N к N
    insert_producing(conn, artists, albums)
    insert_performance(conn, users, artists, songs)

    # Связи между сущностями
    insert_listening_history(conn, users, songs, listens_per_user, prob_comments)

    # Связи N к N
    insert_subscriptions(conn, users, artists)
    insert_table_of_contents(conn, playlists, songs)
    insert_preference_for_songs(conn, users, songs)
    insert_preference_for_genre(conn, users, genres)
    insert_preference_for_artist(conn, users, artists)
    
    print("\n=== Вставка данных завершена! ===\n")


def main():
    print("=== Программа заполнения БД тестовыми данными ===")
    print("0 - Удалить все данные")
    print("1 - Вставить данные с удалением")
    print("2 - Вставить данные без удаления")
    
    try:
        choice = input("\nВыберите действие (0/1/2): ").strip()
        while choice not in ['0', '1', '2']:
            print("Ошибка: введите 0, 1 или 2")
            choice = input("\nВыберите действие (0/1/2): ").strip()

        conn = get_connection()
        psycopg2.extras.register_uuid()
        
        if choice == '0':
            clear_all_data(conn)
        elif choice == '1':
            clear_all_data(conn)
            insert_data_custom(conn)
        elif choice == '2':
            insert_data_custom(conn)
        
        conn.close()
        
    except psycopg2.Error as e:
        print(f"Ошибка базы данных: {e}")
    except Exception as e:
        print(f"Ошибка: {e}")


if __name__ == "__main__":
    main()
