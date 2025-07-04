USE hospital_db;

-- ENCOUNTERS OVERVIEW

-- Identifying the number of total encounters occurred each year

SELECT YEAR(start) AS year, COUNT(id) AS total_encounters
FROM encounters
GROUP BY year
ORDER BY year;

-- Identifying for each year, what percentage of all encounters belonged to each encounter class
-- (ambulatory, outpatient, wellness, urgent care, emergency, and inpatient)

SELECT YEAR(start) AS year, 
	ROUND(SUM(CASE WHEN ENCOUNTERCLASS = 'ambulatory' THEN 1 ELSE 0 END)/ COUNT(*) * 100, 1) AS'ambulatory',
	ROUND(SUM(CASE WHEN ENCOUNTERCLASS = 'outpatient' THEN 1 ELSE 0 END)/ COUNT(*) * 100, 1) AS 'outpatient',
    ROUND(SUM(CASE WHEN ENCOUNTERCLASS = 'wellness' THEN 1 ELSE 0 END)/ COUNT(*) * 100, 1)  AS 'wellness',
    ROUND(SUM(CASE WHEN ENCOUNTERCLASS = 'urgentcare' THEN 1 ELSE 0 END)/ COUNT(*) * 100, 1) AS 'urgent_care',
    ROUND(SUM(CASE WHEN ENCOUNTERCLASS = 'emergency' THEN 1 ELSE 0 END)/ COUNT(*) * 100, 1) AS 'emergency',
    ROUND(SUM(CASE WHEN ENCOUNTERCLASS = 'inpatient' THEN 1 ELSE 0 END)/ COUNT(*) * 100, 1) AS 'inpatient'
FROM encounters
GROUP BY year
ORDER BY year;

-- Identifying the most common procedures for emergency encounters

SELECT pr.description, COUNT(*) AS num_times
FROM procedures pr
JOIN encounters e ON pr.encounter = e.id
WHERE e.encounterclass = 'emergency'
GROUP BY pr.description
ORDER BY num_times DESC
LIMIT 10;

-- Calculating the percentage of encounters that were over 24 hours versus under 24 hours

SELECT COUNT(id),
ROUND(SUM(CASE WHEN TIMESTAMPDIFF(HOUR, START, STOP) <=24 THEN 1 ELSE 0 END)/ COUNT(*) * 100, 1) AS under_24h,
ROUND(SUM(CASE WHEN TIMESTAMPDIFF(HOUR, START, STOP)  >24 THEN 1 ELSE 0 END)/ COUNT(*) * 100, 1) AS over_24h
FROM encounters

-- Calculating the average length of stay by encounter type

SELECT encounterclass,
       ROUND(AVG(TIMESTAMPDIFF(HOUR, start, stop)), 1) AS avg_duration_hours
FROM encounters
GROUP BY encounterclass
ORDER BY avg_duration_hours DESC

-- COST & COVERAGE INSIGHTS

-- Calculating how many encounters had zero payer coverage, and what percentage of total encounters does this represent

SELECT SUM(CASE WHEN PAYER_COVERAGE = 0 THEN 1 ELSE 0 END) AS total_encounters_zero_coverage,
	 COUNT(id) AS total_encounters,
	ROUND(SUM(CASE WHEN PAYER_COVERAGE = 0 THEN 1 ELSE 0 END)/COUNT(*)*100, 1) AS zero_payer_coverage_perc
FROM encounters

-- Calculating what are the top 10 most frequent procedures performed and the average base cost for each

SELECT description AS procedure_name, COUNT(*) AS number_procedures,  ROUND(AVG(base_cost),2) AS avg_base_cost
FROM procedures
GROUP BY description
ORDER BY number_procedures DESC
LIMIT 10;

-- Identifying the top 10 procedures with the highest average base cost and the number of times they were performed

SELECT description AS procedure_name, ROUND(AVG(base_cost),2) AS avg_base_cost, COUNT(*) AS number_procedures
FROM procedures
GROUP BY description
ORDER BY avg_base_cost DESC
LIMIT 10;

-- Calculating the average total claim cost for encounters, broken down by payer

SELECT p.name AS name_payer, ROUND(AVG(total_claim_cost),2) AS avg_total_claim_cost
FROM payers AS p
JOIN encounters AS e
ON e.payer = p.id
GROUP BY name_payer
ORDER BY avg_total_claim_cost DESC

-- Identifying top costly procedures per payer

SELECT pa.name AS payer, pr.description, ROUND(AVG(pr.base_cost),2) AS avg_cost
FROM procedures pr
JOIN encounters e ON pr.encounter = e.id
JOIN payers pa ON e.payer = pa.id
GROUP BY pa.name, pr.description
ORDER BY avg_cost DESC
LIMIT 10;

-- PATIENT BEHAVIOR ANALYSIS

-- Identifying encounter count by gender

SELECT p.gender, COUNT(e.id) AS encounter_count
FROM encounters e
JOIN patients p ON e.patient = p.id
GROUP BY p.gender;

-- Calculating how many unique patients were admitted each quarter over time

SELECT YEAR(START) AS year_admitted, QUARTER(START) AS quarter_admitted, COUNT(DISTINCT PATIENT) AS unique_patients
FROM encounters
GROUP BY  year_admitted, quarter_admitted

-- Calculating how many patients were readmitted within 30 days of a previous encounter

WITH cte AS
     (SELECT patient, start, stop, LEAD (start) OVER( PARTITION BY patient ORDER BY start) AS next_start_date 
     FROM encounters)
 
SELECT COUNT(DISTINCT patient) AS num_patients 
FROM cte
WHERE DATEDIFF(next_start_date, stop) < 30;

-- Identifying which patients had the most readmissions

WITH cte AS
     (SELECT patient, start, stop, LEAD (start) OVER( PARTITION BY patient ORDER BY start) AS next_start_date 
     FROM encounters)

SELECT patient, COUNT(*) AS num_readmissions
FROM cte
WHERE DATEDIFF(next_start_date, stop) < 30
GROUP BY patient
ORDER BY num_readmissions DESC
LIMIT 20