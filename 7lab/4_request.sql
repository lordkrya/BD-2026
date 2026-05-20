-- Покрывает все поля, нужные из song: during, index_genre
-- Позволяет избежать обращения к таблице
CREATE INDEX idx_song_covering_listening 
ON song (code_song) 
INCLUDE (during, index_genre, name_song);


-- Состовная + покрывающая индексация. И для JOIN, и для GROUP BY
CREATE INDEX idx_listening_optimal 
ON listeningHistory(source, code_song) 
INCLUDE (during, id_author);


-- Составная для быстрого поиска по жанрам
CREATE INDEX idx_genre_performance 
ON musicGenre (index_genre, name_genre);


DROP INDEX IF EXISTS
	idx_genre_performance,
	idx_listening_optimal,
	idx_song_covering_listening;


EXPLAIN (ANALYZE, FORMAT JSON)
WITH listening_with_duration AS (
    -- Добавляем полную длительность трека к каждому прослушиванию
    SELECT
        lh.code_listening,
        lh.id_author,
        lh.code_song,
        lh.source,
        EXTRACT(EPOCH FROM lh.during) AS listen_seconds,
        EXTRACT(EPOCH FROM s.during) AS song_seconds,
        s.index_genre
    FROM listeningHistory lh
    JOIN song s ON lh.code_song = s.code_song
),
source_stats AS (
    -- Базовая статистика по каждому источнику
    SELECT
        source,
        COUNT(*) AS total_listens,
        ROUND(
            100.0 * COUNT(*) FILTER (
                WHERE listen_seconds / NULLIF(song_seconds, 0) > 0.7
            ) / NULLIF(COUNT(*), 0),
            2
        ) AS completion_rate_70,
        AVG(listen_seconds) AS avg_listen_seconds
    FROM listening_with_duration
    GROUP BY source
),
source_top_genres AS (
    -- Топ-3 жанра для каждого источника через оконные функции
    SELECT
        source,
        name_genre,
        ROW_NUMBER() OVER (PARTITION BY source ORDER BY COUNT(*) DESC) AS genre_rank
    FROM listening_with_duration lwd
    JOIN musicGenre mg ON lwd.index_genre = mg.index_genre
    GROUP BY source, mg.name_genre
),
source_top3_genres AS (
    -- Собираем топ-3 в строку
    SELECT
        source,
        STRING_AGG(name_genre, ', ' ORDER BY genre_rank) AS top_genres
    FROM source_top_genres
    WHERE genre_rank <= 3
    GROUP BY source
)

SELECT
    ss.source,
    ss.total_listens,
    ss.completion_rate_70 AS actual_listens,
    ss.avg_listen_seconds,
    COALESCE(stg.top_genres, 'Без жанра') AS popular_genres
FROM source_stats ss
LEFT JOIN source_top3_genres stg ON ss.source = stg.source;
