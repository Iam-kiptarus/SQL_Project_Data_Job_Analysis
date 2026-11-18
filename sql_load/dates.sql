SELECT
    job_title_short AS title,
    job_location AS location,
    job_posted_date AT TIME ZONE'UTC' AT TIME ZONE 'EST' AS posted_date,
    extract(MONTH FROM job_posted_date) as date_month,
    extract(YEAR FROM job_posted_date) as date_year
FROM
    job_postings_fact
LIMIT 5;

SELECT 
    count(job_id) as job_posted_count,
    EXTRACT(MONTH FROM job_posted_date) AS month
FROM
    job_postings_fact
WHERE job_title_short = 'Data Analyst'
GROUP BY
    month
ORDER BY
    job_posted_count DESC;

SELECT
    AVG(salary_year_avg) as yearly_avg_salary,
    AVG(salary_hour_avg) as hourly_avg_salary
FROM
    job_postings_fact
WHERE
    job_posted_date > '2023-05-01';


CREATE TABLE january_jobs AS
        SELECT *
        FROM job_postings_fact
        WHERE EXTRACT(MONTH FROM job_posted_date) = 1;

CREATE TABLE february_jobs AS
        SELECT *
        FROM job_postings_fact
        WHERE EXTRACT(MONTH FROM job_posted_date) = 2;

CREATE TABLE march_jobs AS
        SELECT *
        FROM job_postings_fact
        WHERE EXTRACT(MONTH FROM job_posted_date) = 3;

SELECT *
FROM march_jobs;

SELECT
    COUNT(job_id) AS number_of_jobs,
    CASE
        WHEN job_location = 'Anywhere' THEN 'Remote'
        WHEN job_location = 'New York, NY' THEN 'Local'
        ELSE 'Onsite'
    END AS location_category
FROM job_postings_fact
WHERE
    job_title_short = 'Data Analyst'
GROUP BY
    location_category;

SELECT
    job_id,
    job_title,
    salary_year_avg,
    CASE
        WHEN salary_year_avg >= 100000 THEN 'High'
        WHEN salary_year_avg >= 60000  THEN 'Standard'
        ELSE 'Low'
    END AS salary_category
FROM job_postings_fact
WHERE job_title_short = 'Data Analyst' AND salary_year_avg IS NOT NULL
ORDER BY salary_year_avg DESC;

SELECT
    CASE
        WHEN salary_year_avg >= 100000 THEN 'High'
        WHEN salary_year_avg >= 60000  THEN 'Standard'
        ELSE 'Low'
    END AS salary_category,
    COUNT(*) AS job_count
FROM job_postings_fact
WHERE job_title_short = 'Data Analyst'
  AND salary_year_avg IS NOT NULL
GROUP BY salary_category
ORDER BY job_count DESC;

SELECT *
FROM (
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 1
) AS january_jobs;

WITH january_jobs AS (
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 1
)
SELECT *
FROM january_jobs;

SELECT company_id,name AS company_name
FROM company_dim
WHERE company_id IN (
    SELECT company_id
    FROM job_postings_fact
    WHERE job_no_degree_mention = true
    ORDER BY company_id
)

WITH company_job_count AS (
        SELECT
                company_id,
                COUNT(*) AS total_jobs
        FROM
                job_postings_fact
        GROUP BY
                company_id
)
SELECT name AS company_name, total_jobs
FROM company_dim
LEFT JOIN company_job_count 
    ON company_job_count.company_id = company_dim.company_id
order by total_jobs DESC;

SELECT
    skills_dim.skills,
    top_skills.skill_count
FROM
    skills_dim
INNER JOIN (
    SELECT
        skill_id,
        COUNT(*) AS skill_count
    FROM
        skills_job_dim
    GROUP BY
        skill_id
    ORDER BY
        skill_count DESC
    LIMIT 5
) AS top_skills
ON skills_dim.skill_id = top_skills.skill_id
ORDER BY top_skills.skill_count DESC;

SELECT
    company_id,
    total_jobs,
    CASE
        WHEN total_jobs < 10 THEN 'Small'
        WHEN total_jobs BETWEEN 10 AND 50 THEN 'Medium'
        WHEN total_jobs > 50 THEN 'Large'
    END AS company_size
FROM (
    SELECT
        company_id,
        COUNT(*) AS total_jobs
    FROM
        job_postings_fact
    GROUP BY
        company_id
) AS company_job_count
ORDER BY
    total_jobs DESC;

SELECT
    company_size,
    COUNT(*) AS company_count
FROM (
    SELECT
        company_id,
        CASE
            WHEN total_jobs < 10 THEN 'Small'
            WHEN total_jobs BETWEEN 10 AND 50 THEN 'Medium'
            WHEN total_jobs > 50 THEN 'Large'
        END AS company_size
    FROM (
        SELECT
            company_id,
            COUNT(*) AS total_jobs
        FROM
            job_postings_fact
        GROUP BY
            company_id
    ) AS company_job_count
) AS company_categories
GROUP BY
    company_size
ORDER BY
    company_count DESC;

WITH remote_job_skils AS(
        SELECT
                skill_id,
                COUNT(*) AS skill_count
        FROM
                skills_job_dim as skills_to_job
        INNER JOIN job_postings_fact as job_postings ON job_postings.job_id= skills_to_job.job_id
        WHERE
                job_postings.job_work_from_home = TRUE AND
                job_postings.job_title_short = 'Data Analyst'
        GROUP BY skill_id
)
SELECT
        skill.skill_id,
        skills AS skill_name,
        skill_count
FROM remote_job_skils
INNER JOIN skills_dim AS skill ON skill.skill_id = remote_job_skils.skill_id
ORDER BY skill_count DESC
limit 5;

SELECT
    skills_dim.skill_id,
    skills_dim.skills,
    COUNT(skills_job_dim.job_id) AS skill_count
FROM
    job_postings_fact
INNER JOIN skills_job_dim
    ON job_postings_fact.job_id = skills_job_dim.job_id
INNER JOIN skills_dim
    ON skills_job_dim.skill_id = skills_dim.skill_id
WHERE
    job_postings_fact.job_work_from_home = TRUE
GROUP BY
    skills_dim.skill_id,
    skills_dim.skills
ORDER BY
    skill_count DESC
LIMIT 5;

SELECT
        job_title_short,
        job_location,
        job_via,
        job_posted_date :: DATE,
        salary_year_avg
FROM(
        SELECT *
        FROM january_jobs
        UNION ALL
        SELECT *
        FROM february_jobs
        UNION ALL
        SELECT *
        FROM march_jobs
) AS quarter1_job_postings
WHERE
        quarter1_job_postings.salary_year_avg > 70000 AND
        quarter1_job_postings.job_title_short = 'Data Analyst'
ORDER BY
        quarter1_job_postings.salary_year_avg DESC