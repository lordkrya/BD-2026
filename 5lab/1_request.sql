WITH user_listening_stats AS (
    SELECT
        id_author,
        COUNT(code_listening) AS total_listens,
        COUNT(DISTINCT code_song) AS unique_songs,
        MAX(start_listen) AS last_listen,
        AVG(EXTRACT(EPOCH FROM lh.during)) AS avg_seconds
    FROM listeningHistory lh
    GROUP BY id_author
),
user_artists_stats AS (
    SELECT
        lh.id_author,
        COUNT(DISTINCT p.id_author) AS unique_artists
    FROM listeningHistory lh
    LEFT JOIN performance p ON lh.code_song = p.code_song
    GROUP BY lh.id_author
),
user_genre_stats AS (
    SELECT DISTINCT ON (lh.id_author)
        lh.id_author,
        mg.name_genre AS top_genre,
        COUNT(*) AS genre_listens
    FROM listeningHistory lh
    LEFT JOIN song s ON lh.code_song = s.code_song
    JOIN musicGenre mg ON s.index_genre = mg.index_genre
    GROUP BY lh.id_author, mg.name_genre
    ORDER BY lh.id_author, genre_listens DESC
),
premium_status AS (
    SELECT
        pf.id_author,
        CASE
            WHEN pf.expiration > CURRENT_TIMESTAMP THEN 'Active'
            ELSE 'Expired'
        END AS premium_status
    FROM premiumFunc pf
)

SELECT
    u.id_author,
    u.user_login,
    u.full_name,
    COALESCE(uls.total_listens, 0) AS total_listens,
    COALESCE(uls.unique_songs, 0) AS unique_songs,
    COALESCE(uas.unique_artists, 0) AS unique_artists,
    ugs.top_genre AS top_genre,
    uls.last_listen,
    (uls.avg_seconds / 60)::NUMERIC(10,2) AS avg_minutes,
    COALESCE(ps.premium_status, 'Отсутствует') AS premium_status
FROM "user" u
LEFT JOIN user_listening_stats uls ON u.id_author = uls.id_author
LEFT JOIN user_artists_stats uas ON u.id_author = uas.id_author
LEFT JOIN user_genre_stats ugs ON u.id_author = ugs.id_author
LEFT JOIN premium_status ps ON u.id_author = ps.id_author;
