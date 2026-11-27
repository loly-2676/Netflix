SELECT TOP 100 * FROM clean_netflix;


SELECT
    type,
    COUNT(*) AS total_titles,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM clean_netflix), 1) AS pct
FROM clean_netflix
GROUP BY type;


SELECT
    CAST(year_added AS INT) AS year_added,
    type,
    COUNT(*) AS titles_added
FROM clean_netflix
WHERE year_added IS NOT NULL
GROUP BY year_added, type
ORDER BY year_added, type;


SELECT
    LTRIM(RTRIM(s.value)) AS country,
    COUNT(*) AS total_titles
FROM clean_netflix
CROSS APPLY STRING_SPLIT(country, ',') AS s
WHERE LTRIM(RTRIM(s.value)) <> ''
GROUP BY LTRIM(RTRIM(s.value))
ORDER BY total_titles DESC;

 أكتر 10 تصنيفات
SELECT TOP 10
    LTRIM(RTRIM(s.value)) AS genre,
    COUNT(*) AS total_titles
FROM clean_netflix
CROSS APPLY STRING_SPLIT(listed_in, ',') AS s
WHERE LTRIM(RTRIM(s.value)) <> ''
GROUP BY LTRIM(RTRIM(s.value))
ORDER BY total_titles DESC;


SELECT
    COALESCE(NULLIF(LTRIM(RTRIM(rating)), ''), 'Not Rated') AS rating,
    COUNT(*) AS total_titles
FROM clean_netflix
GROUP BY COALESCE(NULLIF(LTRIM(RTRIM(rating)), ''), 'Not Rated')
ORDER BY total_titles DESC;


SELECT
    age_group,
    type,
    COUNT(*) AS total_titles
FROM clean_netflix
GROUP BY age_group, type
ORDER BY age_group, total_titles DESC;


SELECT
    release_year - (release_year % 10) AS decade,
    ROUND(AVG(CAST(duration_value AS FLOAT)), 1) AS avg_minutes,
    COUNT(*) AS movies
FROM clean_netflix
WHERE type = 'Movie'
GROUP BY release_year - (release_year % 10)
ORDER BY decade;


SELECT
    duration_value AS seasons,
    COUNT(*) AS shows
FROM clean_netflix
WHERE type = 'TV Show'
GROUP BY duration_value
ORDER BY duration_value;

-- 9) أكتر 10 مخرجين (مع فصل المخرجين المتعددين)
SELECT TOP 10
    LTRIM(RTRIM(s.value)) AS director,
    COUNT(*) AS total_titles
FROM clean_netflix
CROSS APPLY STRING_SPLIT(director, ',') AS s
WHERE LTRIM(RTRIM(s.value)) <> ''
GROUP BY LTRIM(RTRIM(s.value))
ORDER BY total_titles DESC;


SELECT
    CAST(month_added AS INT) AS month_added,
    month_name,
    COUNT(*) AS titles_added
FROM clean_netflix
WHERE month_added IS NOT NULL
GROUP BY month_added, month_name
ORDER BY titles_added DESC;


SELECT
    type,
    ROUND(AVG(CAST(years_to_netflix AS FLOAT)), 1) AS avg_years_gap
FROM clean_netflix
WHERE years_to_netflix IS NOT NULL
GROUP BY type;


WITH exploded AS (
    SELECT
        LTRIM(RTRIM(c.value)) AS country,
        LTRIM(RTRIM(g.value)) AS genre
    FROM clean_netflix
    CROSS APPLY STRING_SPLIT(country, ',') AS c
    CROSS APPLY STRING_SPLIT(listed_in, ',') AS g
    WHERE LTRIM(RTRIM(c.value)) <> ''
      AND LTRIM(RTRIM(g.value)) <> ''
),
top_countries AS (
    SELECT TOP 5 country
    FROM exploded
    GROUP BY country
    ORDER BY COUNT(*) DESC
),
country_genres AS (
    SELECT e.country, e.genre, COUNT(*) AS n
    FROM exploded e
    JOIN top_countries t ON e.country = t.country
    GROUP BY e.country, e.genre
),
ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY country ORDER BY n DESC) AS rn
    FROM country_genres
)
SELECT country, genre, n
FROM ranked
WHERE rn <= 3
ORDER BY country, rn;

WITH yearly AS (
    SELECT CAST(year_added AS INT) AS year_added, COUNT(*) AS n
    FROM clean_netflix
    WHERE year_added IS NOT NULL
    GROUP BY CAST(year_added AS INT)
)
SELECT
    year_added,
    n,
    SUM(n) OVER (ORDER BY year_added) AS running_total
FROM yearly
ORDER BY year_added;


SELECT
    SUM(CASE WHEN director   IS NULL OR LTRIM(RTRIM(director))   IN ('', 'NULL') THEN 1 ELSE 0 END) AS missing_director,
    SUM(CASE WHEN [cast]     IS NULL OR LTRIM(RTRIM([cast]))     IN ('', 'NULL') THEN 1 ELSE 0 END) AS missing_cast,
    SUM(CASE WHEN country    IS NULL OR LTRIM(RTRIM(country))    IN ('', 'NULL') THEN 1 ELSE 0 END) AS missing_country,
    SUM(CASE WHEN rating     IS NULL OR LTRIM(RTRIM(rating))     IN ('', 'NULL') THEN 1 ELSE 0 END) AS missing_rating
FROM clean_netflix;
