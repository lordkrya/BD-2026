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
    'port': 5432
}

# ENUM значения
MOODS = ['energetic', 'melancholic', 'chill', 'playful', 'romantic']
SOURCES = ['search', 'recommendation', 'playlist', 'subscription', 'other']
TYPE_UUID = ['author', 'playlist', 'song', 'genre', 'album']
TYPE_AUTHOR = ['user', 'artist']


def get_connection():
    """Установка соединения с БД"""
    return psycopg2.connect(**DB_CONFIG)


def clear_all_data(conn):
    """Очистка всех таблиц от данных"""
    cursor = conn.cursor()

    tables = [
        'preferenceforartist', 'preferenceforgenre', 'preferenceforsongs',
        'tableofcontents', 'subscription', 'performance', 'producing',
        'listeninghistory', 'premiumfunc', 'comment', 'song', 'album',
        'musicartist', 'playlist', 'musiccardhistory', 'musiccard',
        'bankcard', '"user"', 'author', 'musicgenre'
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

# E15
def insert_authors(conn, count, count_users):
    """Вставка данных в таблицу author"""
    cursor = conn.cursor()
    authors = []
    index = 0
    
    for _ in range(count):
        author_id = uuid.uuid4()
        type_author = TYPE_AUTHOR[0] if index < count_users else TYPE_AUTHOR[1]
        cursor.execute(
            "INSERT INTO author (id_author, type_author) VALUES (%s, %s)",
            (author_id, type_author)
        )
        authors.append((author_id, type_author))
        index += 1
    
    conn.commit()
    cursor.close()
    print(f"Добавлено {count} записей в author")
    return authors

# E1
def insert_users(conn, authors):
    """Вставка данных в таблицу user"""
    cursor = conn.cursor()
    users = []
    user_authors = [a for a in authors if a[1] == 'user']
    
    for author_id, _ in user_authors:
        full_name = fake.name()
        date_of_birth = fake.date_of_birth(minimum_age=18, maximum_age=80)
        user_login = fake.user_name() + str(len(users))
        user_password = hashlib.sha256(fake.password().encode()).digest()
        phone_number = re.sub(r'[\s\-\(\)]', '', fake.phone_number())[:15]
        
        cursor.execute("""
            INSERT INTO "user" (id_author, full_name, date_of_birth, user_login, user_password, phone_number)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (author_id, full_name, date_of_birth, user_login, user_password, phone_number))
        users.append(author_id)
    
    conn.commit()
    cursor.close()
    print(f"Добавлено {len(users)} записей в user")
    return users

# E6
def insert_music_artists(conn, authors):
    """Вставка данных в таблицу musicArtist"""
    cursor = conn.cursor()
    artists = []
    artist_authors = [a for a in authors if a[1] == 'artist']
    
    for author_id, _ in artist_authors:
        name_artist = fake.company() + str(len(artists))
        description = fake.text(max_nb_chars=200)
        
        cursor.execute("""
            INSERT INTO musicArtist (id_author, name_artist, discription)
            VALUES (%s, %s, %s)
        """, (author_id, name_artist, description))
        artists.append(author_id)
    
    conn.commit()
    cursor.close()
    print(f"Добавлено {len(artists)} записей в musicArtist")
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

# E3
def insert_music_cards(conn, users):
    """Вставка данных в таблицу musicCard"""
    cursor = conn.cursor()
    
    for user_id in users:
        frequency = random.randint(0, 1000)
        activity = random.randint(0, 500)
        mood = random.choice(MOODS)
        
        cursor.execute("""
            INSERT INTO musicCard (id_author, frequency, activity, mood)
            VALUES (%s, %s, %s, %s)
        """, (user_id, frequency, activity, mood))
    
    conn.commit()
    cursor.close()
    print(f"Добавлено {len(users)} записей в musicCard")

#7
def insert_music_genres(conn, count):
    """Вставка данных в таблицу musicGenre"""
    cursor = conn.cursor()
    genres = []
    
    genre_names = ['Rock', 'Pop', 'Jazz', 'Classical', 'Hip-Hop', 'Electronic', 'Metal', 'Blues', 'Country', 'Reggae']
    
    for i in range(min(count, len(genre_names))):
        genre_id = uuid.uuid4()
        name_genre = genre_names[i]
        description = fake.text(max_nb_chars=100)
        popularity = random.randint(0, 100)
        
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
        number_of_songs = random.randint(1, avg_count*2 - 1)
        
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
            during = time(hour=random.randint(0, 1), minute=random.randint(0, 59), second=random.randint(0, 59))

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
        during = time(hour=random.randint(0, 1), minute=random.randint(0, 59), second=random.randint(0, 59))

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
        name_playlist = fake.catch_phrase()
        date_playlist = fake.date_between(start_date='-5y', end_date='today')
        
        cursor.execute("""
            INSERT INTO playlist (index_playlist, id_author, name_playlist, date_playlist)
            VALUES (%s, %s, %s, %s)
        """, (playlist_id, user, name_playlist, date_playlist))
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
        num_subscriptions = random.randint(0, 10)
        selected_artists = random.sample(artists, min(num_subscriptions, len(artists)))
        
        for artist_id in selected_artists:
            try:
                cursor.execute("""
                    INSERT INTO subscription (id_author_user, id_author_artist)
                    VALUES (%s, %s)
                """, (user_id, artist_id))
                count += 1
            except:
                pass
    
    conn.commit()
    cursor.close()
    print(f"Добавлено {count} записей в subscription")

# E10
def insert_comments(conn, users, songs, comments_per_user):
    """Вставка данных в таблицу comment"""
    cursor = conn.cursor()
    count = 0

    for user_id in users:
        num_comments = random.randint(0, comments_per_user)
        for i in range(num_comments):
            song_id = random.choice(songs)
            text_comment = fake.text(max_nb_chars=200) if random.choice([True, False]) else None
            grade = random.choice(['1', '2', '3', '4', '5', '6', '7', '8', '9', 'A']) if random.choice([True, False]) or not text_comment else None

            cursor.execute("""
                INSERT INTO comment (number_comment, id_author, code_song, text_comment, grade)
                VALUES (%s, %s, %s, %s, %s)
            """, (i + 1, user_id, song_id, text_comment, grade))
            count += 1

    conn.commit()
    cursor.close()
    print(f"Добавлено {count} записей в comment")

# E12
def insert_listening_history(conn, users, songs, listens_per_user):
    """Вставка данных в таблицу listeningHistory"""
    cursor = conn.cursor()
    count = 0

    for user_id in users:
        num_listens = random.randint(0, listens_per_user)
        for i in range(num_listens):
            song_id = random.choice(songs)
            start_listen = fake.date_time_between(start_date='-30d', end_date='now')
            during = time(hour=random.randint(0, 1), minute=random.randint(0, 59), second=random.randint(1, 59))
            source = random.choice(SOURCES)
            id_source = uuid.uuid4() if random.choice([True, False]) else None

            cursor.execute("""
                INSERT INTO listeningHistory (code_listening, id_author, code_song, start_listen, during, source, id_source)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (i + 1, user_id, song_id, start_listen, during, source, id_source))
            count += 1

    conn.commit()
    cursor.close()
    print(f"Добавлено {count} записей в listeningHistory")

# E4
def insert_music_card_history(conn, users, authors, songs, genres, history_per_user):
    """Вставка данных в таблицу musicCardHistory"""
    cursor = conn.cursor()
    count = 0

    type_mapping = {
        'author': authors,
        'song': songs,
        'genre': genres
    }
    available_types = ['author', 'song', 'genre']

    for user_id in users:
        if random.choice([True, False]):
            num_changes = random.randint(0, history_per_user)
            for i in range(num_changes):
                date_change = fake.date_time_between(start_date='-30d', end_date='now')
                is_add_change = random.choice([True, False])
                type_id_change = random.choice(available_types)
                id_uuid = random.choice(type_mapping[type_id_change])

                cursor.execute("""
                    INSERT INTO musicCardHistory (code_change, id_author, date_change, is_add_change, type_id_change, id)
                    VALUES (%s, %s, %s, %s, %s, %s)
                """, (i + 1, user_id, date_change, is_add_change, type_id_change, id_uuid))
                count += 1

    conn.commit()
    cursor.close()
    print(f"Добавлено {count} записей в musicCardHistory")

# E13
def insert_producing(conn, artists, albums):
    """Вставка данных в таблицу producing"""
    cursor = conn.cursor()
    count = 0

    for album_id, _ in albums:
        num_artists = random.randint(1, 2)
        selected_artists = random.sample(artists, min(num_artists, len(artists)))

        for artist_id in selected_artists:
            cursor.execute("""
                INSERT INTO producing (id_author, number_album)
                VALUES (%s, %s)
            """, (artist_id, album_id))
            count += 1

    conn.commit()
    cursor.close()
    print(f"Добавлено {count} записей в producing")

# E14
def insert_performance(conn, authors, songs):
    """Вставка данных в таблицу performance"""
    cursor = conn.cursor()
    count = 0

    for song_id in songs:
        num_performances = random.randint(1, 2)
        selected_author = random.sample(authors, min(num_performances, len(authors)))

        for author_id, _ in selected_author:
            cursor.execute("""
                INSERT INTO performance (id_author, code_song)
                VALUES (%s, %s)
            """, (author_id, song_id))
            count += 1

    conn.commit()
    cursor.close()
    print(f"Добавлено {count} записей в performance")

# E17
def insert_table_of_contents(conn, playlists, songs):
    """Вставка данных в таблицу tableOfContents"""
    cursor = conn.cursor()
    count = 0

    for playlist_id in playlists:
        num_songs = random.randint(1, 20)
        selected_songs = random.sample(songs, min(num_songs, len(songs)))

        for song_id in selected_songs:
            cursor.execute("""
                INSERT INTO tableOfContents (index_playlist, code_song)
                VALUES (%s, %s)
            """, (playlist_id, song_id))
            count += 1

    conn.commit()
    cursor.close()
    print(f"Добавлено {count} записей в tableOfContents")

# E18
def insert_preference_for_songs(conn, users, songs):
    """Вставка данных в таблицу preferenceForSongs"""
    cursor = conn.cursor()
    count = 0

    for user_id in users:
        num_preferences = random.randint(0, 10)
        selected_songs = random.sample(songs, min(num_preferences, len(songs)))

        for song_id in selected_songs:
            cursor.execute("""
                INSERT INTO preferenceForSongs (id_author, code_song)
                VALUES (%s, %s)
            """, (user_id, song_id))
            count += 1

    conn.commit()
    cursor.close()
    print(f"Добавлено {count} записей в preferenceForSongs")

# E19
def insert_preference_for_genre(conn, users, genres):
    """Вставка данных в таблицу preferenceForGenre"""
    cursor = conn.cursor()
    count = 0

    for user_id in users:
        num_preferences = random.randint(0, 10)
        selected_genres = random.sample(genres, min(num_preferences, len(genres)))

        for genre_id in selected_genres:
            cursor.execute("""
                INSERT INTO preferenceForGenre (id_author, index_genre)
                VALUES (%s, %s)
            """, (user_id, genre_id))
            count += 1

    conn.commit()
    cursor.close()
    print(f"Добавлено {count} записей в preferenceForGenre")

# E20
def insert_preference_for_artist(conn, users, artists):
    """Вставка данных в таблицу preferenceForArtist"""
    cursor = conn.cursor()
    count = 0

    for user_id in users:
        num_preferences = random.randint(0, 10)
        selected_artists = random.sample(artists, min(num_preferences, len(artists)))

        for artist_id in selected_artists:
            cursor.execute("""
                INSERT INTO preferenceForArtist (id_author_user, id_author_artist)
                VALUES (%s, %s)
            """, (user_id, artist_id))
            count += 1

    conn.commit()
    cursor.close()
    print(f"Добавлено {count} записей в preferenceForArtist")


def insert_data_custom(conn):
    """Вставка данных с пользовательским вводом количества"""
    print("\n=== Введите количество записей для каждой таблицы ===\n")
    
    try:
        users_count = int(input("Количество пользователей (user): ") or "1000")
        artists_count = int(input("Количество исполнителей (musicArtist): ") or "50")
        authors_count = users_count + artists_count
        genres_count = 10
        albums_count = int(input("Количество альбомов (album): ") or "100")
        avg_songs_count = int(input("Среднее количество песен в альбоме (song = album * avgSongsCount): ") or "5")
        singles_count = int(input("Количество синглов (song += Const): ") or "100")
        comments_per_user = int(input("Среднее количество комментариев у пользователя (comment = commentsPerUser * song): ") or "3")
        listens_per_user = int(input("Среднее количество прослушиваний пользователя (listeningHistory): ") or "5")
        history_per_user = int(input("Среднее количество изменений музыкальной карты (musicCardHistory): ") or "3")
        playlists_count = int(input("Количество плейлистов (playlist): ") or "100")
        
    except ValueError:
        print("Ошибка: введите корректные числа!")
        return
    
    print("\n=== Начало вставки пользовательских данных ===\n")
    
    authors = insert_authors(conn, authors_count, users_count)

    users = [a[0] for a in authors if a[1] == TYPE_AUTHOR[0]]
    artists = [a[0] for a in authors if a[1] == TYPE_AUTHOR[1]]

    # Работа с пользователем
    insert_users(conn, [(uid, 'user') for uid in users])
    insert_bank_cards(conn, users)
    insert_music_cards(conn, users)
    insert_premium_func(conn, users)
    playlists = insert_playlists(conn, users, playlists_count)

    # Работа с артистом
    insert_music_artists(conn, [(aid, 'artist') for aid in artists])
    genres = insert_music_genres(conn, genres_count)
    albums = insert_albums(conn, genres, albums_count, avg_songs_count)
    songs = insert_songs(conn, albums, genres, singles_count)

    # Связи между артистом и пользователем
    insert_comments(conn, users, songs, comments_per_user)
    insert_listening_history(conn, users, songs, listens_per_user)
    insert_music_card_history(conn, users, artists, songs, genres, history_per_user)

    # Разрешение связи N к N
    insert_producing(conn, artists, albums)
    insert_performance(conn, authors, songs)
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
