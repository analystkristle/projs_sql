/* Background:
A global streaming service wants to optimize its content strategy by leveraging IMDb’s publicly available data. The aim is to identify trends in viewer ratings, popular genres, influential talent, and audience sentiment from reviews. Insights will be used to guide content acquisition, casting decisions, and marketing campaigns.

The initial task is to:
- Identify top-rated and most-voted titles.
- Look at review sentiment and ratings.
- Determine key talent (actors, directors, writers) based on audience ratings. */


-- A. Content Performance Analysis
-- List the top 20 titles by average rating (minimum 5,000 votes), including genres and release year.
SELECT
  TR.tconst
  , TB.primary_title
  , TB.original_title
  , TB.genres
  , TB.start_year AS release_year
  , TR.num_votes
  , TR.average_rating
FROM
  `bigquery-public-data.imdb.title_ratings` TR
LEFT JOIN
  `bigquery-public-data.imdb.title_basics` TB
  ON TR.tconst = TB.tconst
WHERE
  TR.num_votes >= 5000
ORDER BY
  TR.average_rating DESC, TR.num_votes DESC
LIMIT
  20;


-- Identify the top 5 genres by number of titles produced and average rating.
SELECT
  TB.genres
  , COUNT(TB.tconst) AS titles_produced
  , AVG(TR.average_rating) AS average_rating
FROM
  `bigquery-public-data.imdb.title_basics` TB
LEFT JOIN
  `bigquery-public-data.imdb.title_ratings` TR
  ON TB.tconst = TR.tconst
WHERE
  TR.average_rating IS NOT NULL
  AND TB.tconst IS NOT NULL
GROUP BY
  1
ORDER BY
  titles_produced DESC, average_rating DESC
LIMIT
  5;


-- Find the most successful release years by average rating and number of highly rated titles (rating ≥ 8.0).
SELECT
  TB.start_year
  , COUNT(TB.tconst) AS highly_rated_titles
  , AVG(TR.average_rating) AS average_rating
FROM
  `bigquery-public-data.imdb.title_basics` TB
LEFT JOIN
  `bigquery-public-data.imdb.title_ratings` TR
  ON TB.tconst = TR.tconst
WHERE
  (TR.average_rating >= 8)
  AND (TB.start_year IS NOT NULL)
GROUP BY
  1
ORDER BY
  highly_rated_titles DESC, average_rating DESC;


-- B. Audience Sentiment & Review Insights
-- Calculate the proportion of Positive vs. Negative reviews for each title.
SELECT
  RV.movie_id
  , RV.title
  , COUNT(*) AS total_reviews
  , COUNTIF(RV.label = 'Positive') AS positive_reviews
  , COUNTIF(RV.label = 'Positive')/COUNT(*) AS pct_positive
  , COUNTIF(RV.label = 'Negative') AS negative_reviews
  , COUNTIF(RV.label = 'Negative')/COUNT(*) AS pct_negative
FROM
  `bigquery-public-data.imdb.reviews` RV
GROUP BY
  1, 2;


-- Find the average reviewer rating by sentiment label for comparison.
SELECT
  RV.label
  , AVG(RV.reviewer_rating) AS avg_reviewer_rating
FROM
  `bigquery-public-data.imdb.reviews` RV
GROUP BY
  1;


-- C. Talent & Crew Impact
-- List the top 10 directors whose movies have the highest average ratings (minimum 3 titles).
SELECT
  TC.directors
  , NM.primary_name
  , COUNT(TC.tconst) AS movie_titles
  , AVG(RV.reviewer_rating) AS avg_reviewer_rating
FROM 
  `bigquery-public-data.imdb.title_crew` TC
LEFT JOIN
  `bigquery-public-data.imdb.reviews` RV
  ON TC.tconst = RV.movie_id
LEFT JOIN
  `bigquery-public-data.imdb.name_basics` NM
  ON TC.directors = NM.nconst
WHERE
  TC.directors IS NOT NULL
GROUP BY
  1, 2
HAVING
  COUNT(TC.tconst) > 3
ORDER BY
  avg_reviewer_rating DESC, movie_titles DESC
LIMIT
  10;


-- List the top 10 writers whose movies have the highest average ratings (minimum 3 titles).
SELECT
  TC.writers
  , NM.primary_name
  , COUNT(TC.tconst) AS movie_titles
  , AVG(RV.reviewer_rating) AS avg_reviewer_rating
FROM 
  `bigquery-public-data.imdb.title_crew` TC
LEFT JOIN
  `bigquery-public-data.imdb.reviews` RV
  ON TC.tconst = RV.movie_id
LEFT JOIN
  `bigquery-public-data.imdb.name_basics` NM
  ON TC.writers = NM.nconst
WHERE
  TC.writers IS NOT NULL
GROUP BY
  1, 2
HAVING
  COUNT(TC.tconst) > 3
ORDER BY
  avg_reviewer_rating DESC, movie_titles DESC
LIMIT
  10;


-- Identify actors appearing in the highest number of top-rated titles (rating ≥ 8.0).
SELECT
  TP.nconst
  , NM.primary_name
  , COUNT(TP.tconst) AS highly_rated_titles
  , AVG(TR.average_rating) AS average_rating
FROM
  `bigquery-public-data.imdb.title_principals` TP
LEFT JOIN
  `bigquery-public-data.imdb.title_ratings` TR
  ON TP.tconst = TR.tconst
LEFT JOIN
  `bigquery-public-data.imdb.name_basics` NM
  ON TP.nconst = NM.nconst
WHERE
  (TR.average_rating >= 8)
  AND (TP.nconst IS NOT NULL)
GROUP BY
  1, 2
ORDER BY
  highly_rated_titles DESC, average_rating DESC;