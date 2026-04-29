WITH song_info AS (
    SELECT
        s.code_song,
        s.name_song,
        s.during,
        (
            SELECT STRING_AGG(
                CASE
                    WHEN au.type_author = 'artist' THEN ma.name_artist
                    ELSE u.full_name
                END,
                ', '
            )
            FROM performance p
            LEFT JOIN author au ON p.id_author = au.id_author
            LEFT JOIN musicArtist ma ON p.id_author = ma.id_author
            LEFT JOIN "user" u ON p.id_author = u.id_author
            WHERE p.code_song = s.code_song
        ) AS artists,
        mg.name_genre
    FROM song s
    LEFT JOIN musicGenre mg ON s.index_genre = mg.index_genre
),
song_stats AS (
    SELECT
        si.*,
        COUNT(DISTINCT lh.code_listening) AS total_listens,
        COUNT(DISTINCT lh.id_author) AS unique_listeners
    FROM song_info si
    LEFT JOIN listeningHistory lh ON si.code_song = lh.code_song
    GROUP BY si.code_song, si.name_song, si.during, si.artists, si.name_genre
),
song_rank AS (
    SELECT
        st.*,
        COUNT(*) FILTER (WHERE c.grade > 5) AS likes,
        COUNT(*) FILTER (WHERE c.grade <= 5) AS dislikes,
        AVG(c.grade) AS avg_rating
    FROM song_stats st
    LEFT JOIN comment c ON st.code_song = c.code_song
    GROUP BY st.code_song, st.name_song, st.during, st.artists, st.name_genre, st.total_listens, st.unique_listeners
),
song_with_rank AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY total_listens DESC, avg_rating DESC NULLS LAST) AS popularity_rank
    FROM song_rank
)

SELECT
    popularity_rank,
    name_song,
    COALESCE(artists, 'Неизвестный исполнитель') AS artists,
    COALESCE(name_genre, 'Без жанра') AS genre,
    COALESCE(total_listens, 0) AS total_listens,
    COALESCE(unique_listeners, 0) AS unique_listeners,
    COALESCE(likes, 0) AS likes,
    COALESCE(dislikes, 0) AS dislikes,
    avg_rating,
    during
FROM song_with_rank;
--ORDER BY popularity_rank;
