-- Hora inicio 11:17AM 

SELECT *
FROM chargers
;

SELECT *
FROM sessions
;

SELECT *
FROM users
;
-- LEVEL 1

-- Question 1: Number of users with sessions
SELECT
    COUNT(id) AS number_of_user
FROM users
;

-- Question 2: Number of chargers used by user with id 1
SELECT
    COUNT(ch.id) AS num_of_charger
FROM chargers ch
JOIN sessions ss
    ON ch.id = ss.charger_id
JOIN users cs
    ON ss.user_id = cs.id
WHERE cs.id = "1"
;

-- LEVEL 2

-- Question 3: Number of sessions per charger type (AC/DC):
SELECT 
    ch.type,
    COUNT(ss.id) AS num_of_session
FROM chargers ch
JOIN sessions ss
    ON ch.id = ss.charger_id
GROUP BY ch.type
;

-- Question 4: Chargers being used by more than one user
SELECT
    ch.id,
    COUNT(DISTINCT ss.user_id) AS num_user
FROM chargers ch
JOIN sessions ss
    ON ch.id = ss.charger_id  
GROUP BY ch.id
HAVING COUNT(DISTINCT ss.user_id) > 1
;

-- Question 5: Average session time per charger
SELECT
    new_t.id,
    ROUND(AVG(new_t.minutes),2) AS Avg_session_minute
FROM (
    SELECT
        ch.id,
        (STRFTIME("%s", ss.end_time)-STRFTIME("%s", ss.start_time))/60 AS minutes
    FROM chargers ch
    JOIN sessions ss
        ON ch.id = ss.charger_id  
) AS new_t
GROUP BY new_t.id
;

-- LEVEL 3

-- Question 6: Full username of users that have used more than one charger in one day (NOTE: for date only consider start_time)
WITH new_t AS (
    SELECT 
        STRFTIME("%d",start_time) AS rent_date
    FROM chargers ch
    JOIN sessions ss
        ON ch.id = ss.charger_id
    JOIN users cs
        ON ss.user_id = cs.id
    )
SELECT
    cs.name,
    cs.surname
FROM users cs
HAVING COUNT(DISTINCT rent_date) > 1
;

-- Question 7: Top 3 chargers with longer sessions
SELECT 
    ch.id,
    (STRFTIME("%s", ss.end_time)-STRFTIME("%s", ss.start_time))/60 AS minutes
FROM chargers ch
JOIN sessions ss
    ON ch.id = ss.charger_id
GROUP BY ch.id
ORDER BY minutes DESC
LIMIT 3
;

-- Question 8: Average number of users per charger (per charger in general, not per charger_id specifically)
SELECT
    AVG(new_t.num_users) AS avg_user
FROM (
    SELECT
        ch.id AS charger_id,
        cs.id AS user_id,
        COUNT(DISTINCT ss.user_id) AS num_users
    FROM chargers ch
    JOIN sessions ss
        ON ch.id = ss.charger_id
    JOIN users cs
        ON ss.user_id = cs.id
    ) AS new_t
;

-- Question 9: Top 3 users with more chargers being used 
SELECT 
    cs.id AS user_id,
    COUNT(DISTINCT ch.id) AS rent_num
FROM users cs
JOIN sessions ss
    ON cs.id = ss.user_id
JOIN chargers ch
    ON ss.charger_id = ch.id
GROUP BY cs.id
ORDER BY COUNT(DISTINCT ch.id) DESC
LIMIT 3
;

-- LEVEL 4

-- Question 10: Number of users that have used only AC chargers, DC chargers or both
SELECT 
    COUNT(DISTINCT CASE WHEN AC_count > 0 AND DC_count = 0 THEN new_t.id END) AS num_user_AC,
    COUNT(DISTINCT CASE WHEN AC_count = 0 AND DC_count > 0 THEN new_t.id END) AS num_user_DC,
    COUNT(DISTINCT CASE WHEN AC_count > 0 AND DC_count > 0 THEN new_t.id END) AS num_user_BOTH
FROM (
    SELECT
        cs.id AS id,
        COUNT(DISTINCT CASE WHEN ch.type="AC" THEN ss.id END) AS AC_count,
        COUNT(DISTINCT CASE WHEN ch.type="DC" THEN ss.id END) AS DC_count
    FROM chargers ch
    JOIN sessions ss
        ON ch.id = ss.charger_id
    JOIN users cs
        ON ss.user_id = cs.id
    GROUP BY cs.id
    ) AS new_t
;

-- Question 11: Monthly average number of users per charger
SELECT 
    *
FROM (
    SELECT
        ch.id AS id,
        strftime("%Y-%m", ss.start_time) AS month,
        ROUND(AVG(cs.id),2) AS avg_user_num
    FROM chargers ch
    JOIN sessions ss ON ch.id = ss.charger_id
    JOIN users cs ON ss.user_id = cs.id
    GROUP BY ch.id
    ) AS new_t
;

-- Question 12: Top 3 users per charger (for each charger, number of sessions)
WITH Row_num AS (
    SELECT
        ch.id AS charger_id,        
        cs.*,
        COUNT(ss.id) AS session_num,
        ROW_NUMBER() OVER (PARTITION BY ch.id ORDER BY COUNT(ss.id) DESC) AS usage_count
    FROM chargers ch
    JOIN sessions ss ON ch.id = ss.charger_id
    JOIN users cs ON ss.user_id = cs.id
    GROUP BY ch.id, cs.id
    )
SELECT
    charger_id,
    id,
    name,
    surname,
    usage_count
FROM Row_num
WHERE usage_count = 1 OR usage_count = 2 OR usage_count = 3
;
    
-- LEVEL 5

-- Question 13: Top 3 users with longest sessions per month (consider the month of start_time)
WITH session_time AS (
    SELECT 
        cs.*,
        (SUM(STRFTIME("%s", ss.end_time) - STRFTIME("%s", ss.start_time)))/60 AS minutes
    FROM chargers ch
    JOIN sessions ss ON ch.id = ss.charger_id
    JOIN users cs ON ss.user_id = cs.id
    GROUP BY cs.id
    )
SELECT
    id,
    name,
    surname,
    minutes
FROM session_time
ORDER BY minutes DESC
LIMIT 3
;

-- Question 14. Average time between sessions for each charger for each month (consider the month of start_time)
WITH start_time_rank AS (
    SELECT 
        ch.id AS charger_id,
        ss.start_time AS time_1
    FROM chargers ch
    JOIN sessions ss ON ch.id = ss.charger_id
    GROUP BY ch.id, ss.start_time
    ),
    time_pre AS (
        SELECT
            time_1,
            charger_id,        
            LAG(time_1,1,0) OVER (PARTITION BY charger_id) AS previous_time
        FROM start_time_rank
        )
SELECT
    charger_id,   
    ROUND((AVG(time_1-previous_time)),2) AS "avg_time_between(min)"
FROM time_pre
GROUP BY charger_id
;