WITH top_genre AS (
	SELECT DISTINCT ON (lh.id_author)
		lh.id_author,
		s.index_genre,
		mg.name_genre,
		COUNT(*) AS pop_genre
	FROM listeningHistory lh
	LEFT JOIN song s ON lh.code_song = s.code_song
	LEFT JOIN musicGenre mg ON mg.index_genre = s.index_genre
	WHERE s.index_genre IN (
		SELECT index_genre
		FROM preferenceForGenre pfg
		WHERE pfg.id_author = lh.id_author
	)
	GROUP BY lh.id_author, s.index_genre, mg.name_genre
	ORDER BY lh.id_author, pop_genre DESC
),
top_artist AS (
	SELECT DISTINCT ON (lh.id_author)
		lh.id_author AS id_author_user,
		p.id_author AS id_author_artist,
		ma.name_artist,
		COUNT(*) AS pop_artist
	FROM listeningHistory lh
	LEFT JOIN performance p ON lh.code_song = p.code_song
	LEFT JOIN musicArtist ma ON ma.id_author = p.id_author
	WHERE p.id_author IN (
		SELECT id_author_artist
		FROM preferenceForArtist pfa
		WHERE pfa.id_author_user = lh.id_author
	)
	GROUP BY lh.id_author, p.id_author, ma.name_artist
	ORDER BY lh.id_author, pop_artist DESC
),
comment_stats AS (
	SELECT
		c.id_author,
		COUNT(*) AS count_com,
        COUNT(*) FILTER (WHERE c.grade > 5) AS likes,
        COUNT(*) FILTER (WHERE c.grade <= 5) AS dislikes
	FROM comment c
	GROUP BY c.id_author
),
last_update_card AS (
	SELECT
		mch.id_author,
		MAX(date_change) AS last_change
	FROM musicCardHistory mch
	GROUP BY mch.id_author
)

SELECT
	mc.id_author,
	COALESCE(tg.name_genre, 'Без жанра') AS name_genre,
	COALESCE(ta.name_artist, 'Неизвестный исполнитель') AS name_artist,
	cs.likes,
	cs.dislikes,
	cs.count_com,
	mc.activity,
	luc.last_change
FROM musicCard mc
LEFT JOIN top_genre tg ON mc.id_author = tg.id_author
LEFT JOIN top_artist ta ON mc.id_author = ta.id_author_user
LEFT JOIN comment_stats cs ON mc.id_author = cs.id_author
LEFT JOIN last_update_card luc ON mc.id_author = luc.id_author;





--SELECT
--*
--FROM preferenceForArtist pfa
--LEFT JOIN musicArtist ma ON pfa.id_author_artist = ma.id_author
--WHERE pfa.id_author_user = '00792e59-deb9-477e-a863-8cb86c5e60ac';


--SELECT
--	lh.id_author,
--	p.code_song,
--	ma.name_artist
--FROM listeningHistory lh
--LEFT JOIN song s ON s.code_song = lh.code_song
--LEFT JOIN performance p ON p.code_song = s.code_song
--lEFT JOIN musicArtist ma ON p.id_author = ma.id_author
--WHERE lh.id_author = '00792e59-deb9-477e-a863-8cb86c5e60ac';
