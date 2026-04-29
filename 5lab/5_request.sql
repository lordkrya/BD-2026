WITH artist_stats AS (
    -- Основная статистика по исполнителям
    SELECT 
        ma.id_author,
        ma.name_artist,
        COUNT(DISTINCT p.code_song) AS total_songs,
        COUNT(lh.code_listening) AS total_listens
    FROM musicArtist ma
    LEFT JOIN performance p ON p.id_author = ma.id_author
    LEFT JOIN listeningHistory lh ON lh.code_song = p.code_song
    GROUP BY ma.id_author, ma.name_artist
),
subscription_stats AS (
    -- Основная статистика по подписчикам
    SELECT 
        s.id_author_artist,
        COUNT(s.id_author_user) AS subscribers_count
    FROM subscription s
    GROUP BY s.id_author_artist
),
comment_stats AS (
    -- Основная статистика по рейтингу песен
    SELECT
        css.id_author, 
        AVG(css.avg_rating_song) AS avg_rating
    FROM (
        SELECT 
            p.id_author, 
            p.code_song,
            AVG(c.grade) AS avg_rating_song
        FROM performance p
        LEFT JOIN comment c ON c.code_song = p.code_song
        GROUP BY p.id_author, p.code_song
    ) css
    GROUP BY css.id_author
),
playlist_stats AS (
    -- Основная статистика по плейлистам
    SELECT 
        p.id_author,
        COUNT(DISTINCT tc.index_playlist) playlist_additions
    FROM performance p
    LEFT JOIN tableOfContents tc ON p.code_song = tc.code_song
    GROUP BY p.id_author
)

SELECT 
    a.id_author,
    a.name_artist,
    COALESCE(ss.subscribers_count, 0) AS subscribers_count,
    COALESCE(a.total_songs, 0) AS total_songs,
    COALESCE(a.total_listens, 0) AS total_listens,
    COALESCE(cs.avg_rating, 0) AS avg_rating,
    COALESCE(ps.playlist_additions, 0) AS playlist_additions,
    ROW_NUMBER() OVER (ORDER BY a.total_listens DESC, cs.avg_rating DESC NULLS LAST) AS popularity_rank
FROM artist_stats a
LEFT JOIN subscription_stats ss ON a.id_author = ss.id_author_artist
LEFT JOIN comment_stats cs ON a.id_author = cs.id_author
LEFT JOIN playlist_stats ps ON a.id_author = ps.id_author;
