SELECT * FROM projects;

-- 1. CONVERSION OF EPOCH DATE TO NATURAL DATE --
ALTER TABLE projects ADD COLUMN created_date DATE;
SET SQL_SAFE_UPDATES=0;
UPDATE projects
SET created_date = FROM_UNIXTIME(created_at, '%Y-%m-%d');
SELECT * FROM projects;

# SUCESSFUL DATE #
ALTER TABLE projects ADD COLUMN successful_date DATE;
SET SQL_SAFE_UPDATES=0;
UPDATE projects
SET successful_date = FROM_UNIXTIME(successful_at, '%Y-%m-%d')
WHERE successful_at IS NOT NULL AND successful_at > 0;
SELECT * FROM projects;


-- CREATE CALANDER TABLE --
CREATE TABLE calendar (
    project_id INT,
    created_date DATE
);

INSERT INTO calendar (project_id, created_date)
SELECT p.ProjectID, p.created_date
FROM projects p
JOIN calendar c ON p.ProjectID = c.project_id;

SELECT * FROM calendar;
INSERT INTO calendar (project_id, created_date)
SELECT ProjectID,created_date 
FROM projects;	

-- YEAR --
ALTER TABLE calendar
ADD COLUMN cr_Year INT;
UPDATE calendar
SET cr_Year = YEAR(created_date);

-- MONTH NUMBER -- 
ALTER TABLE calendar
ADD COLUMN cr_MonthNumber INT;
UPDATE calendar
SET cr_MonthNumber = MONTH(created_date);

-- MONTH NAME -- 
ALTER TABLE calendar
ADD COLUMN cr_MonthName VARCHAR(50);
UPDATE calendar
SET cr_MonthName = monthname(created_date);

-- QUARTER --
ALTER TABLE calendar
ADD COLUMN cr_Quarter VARCHAR(50);
UPDATE calendar
SET cr_Quarter = concat('Q',QUARTER(created_date));
SELECT * FROM calendar;

-- YEAR-MONTH -- 
ALTER TABLE calendar
ADD COLUMN cr_YearMonth VARCHAR(50);
UPDATE calendar
SET cr_YearMonth = concat(YEAR(created_date),"-",MONTHNAME(created_date));
SELECT * FROM calendar;

-- WEEKDAY NUMBER -- 
ALTER TABLE calendar
ADD COLUMN cr_WeekdayNumber INT;
UPDATE calendar
SET cr_WeekdayNumber = DAYOFWEEK(created_date);

-- WEEKDAY NAME -- 
ALTER TABLE calendar
ADD COLUMN cr_WeekdayName VARCHAR(50);
UPDATE calendar
SET cr_WeekdayName = DAYNAME(created_date);

-- FINANCIAL MONTH -- 
ALTER TABLE calendar
ADD COLUMN Financial_month VARCHAR(50);

UPDATE calendar
SET Financial_month = CONCAT('FM-',
CASE
 WHEN MONTH(created_date)>=4 THEN MONTH(created_date) -3
 ELSE MONTH(created_date)+9
 END);
SELECT * FROM calendar;

-- FINANCIAL QUARTER -- 
ALTER TABLE calendar
ADD COLUMN Financial_quarter VARCHAR(50);

UPDATE calendar
SET Financial_quarter = CASE 
        WHEN MONTH(created_date) IN (4, 5, 6) THEN 'FQ1'
        WHEN MONTH(created_date) IN (7, 8, 9) THEN 'FQ2'
        WHEN MONTH(created_date) IN (10, 11, 12) THEN 'FQ3'
        WHEN MONTH(created_date) IN (1, 2, 3) THEN 'FQ4'
    END;

-- CONVERTING GOAL AMOUNT INTO STATIC USD RATE -- 
ALTER TABLE projects
ADD COLUMN goal_static_usd INT;
SET SQL_SAFE_UPDATES=0;
UPDATE projects 
SET goal_static_usd = goal*static_usd_rate;
SELECT * FROM projects;

-- TOTAL NUMBER OF PROJECTS BASED ON OUTCOMES -- 
SELECT state, COUNT(*) AS total_projects
FROM projects
GROUP BY state;

-- TOTAL NUMBER OF PROJECTS BASED ON LOCATIONS --
SELECT country, COUNT(*) AS total_projects
FROM projects
GROUP BY country;

-- TOTAL NUMBER OF PROJECTS BASED ON CATEGORY --     
SELECT c.category AS category_name, COUNT(p.ProjectID) AS total_projects
FROM projects p
JOIN Category c ON p.category_id = c.id
GROUP BY c.category
ORDER BY total_projects DESC;

-- TOTAL NUMBER OF PROJECTS BASED ON YEAR, QUARTER, MONTH -- 
-- YEAR -- 
SELECT YEAR(created_date) AS project_year, COUNT(*) AS total_projects
FROM projects
GROUP BY project_year;

-- QUARTER -- 
SELECT YEAR(created_date) AS project_year, CONCAT("Q",QUARTER(created_date)) AS project_quarter, COUNT(*) AS total_projects
FROM projects 
WHERE YEAR(created_date) = 2010
GROUP BY project_year, project_quarter;

-- MONTH -- 
SELECT YEAR(created_date) AS project_year, MONTHNAME(created_date) AS project_month, COUNT(*) AS total_projects
FROM projects
WHERE MONTHNAME(created_date) = "January" AND YEAR(created_date) = 2010
GROUP BY project_year, project_month;

-- AMOUNT RAISED BY SUCCESSFUL PROJECTS -- 
SELECT 
    CONCAT("$", ROUND(SUM(pledged) / 1000000), "M") AS Amount_raised_in_millions
FROM 
    projects
WHERE 
    state = 'successful';

-- NUMBER OF BACKERS FOR SUCCESSFUL -- 
SELECT 
    CONCAT(ROUND(SUM(backers_count) / 1000000), "M") AS Total_backers_in_millions
FROM 
    projects
WHERE 
    state = 'successful';
 
-- AVERAGE NUMBER OF DAYS FOR SUCCESSFUL PROJECTS -- 
ALTER TABLE projects
DROP COLUMN total_days;

SELECT AVG(DATEDIFF(successful_date, created_date)) AS avg_days
FROM projects
WHERE state = 'successful' AND successful_date IS NOT NULL AND created_date IS NOT NULL;
SELECT * FROM projects WHERE state = 'successful' AND successful_date IS NOT NULL;

-- TOP 10 SUCCESSFUL PROJECTS BASED ON NUMBER OF BACKERS -- 
SELECT 
    name,       
    SUM(backers_count) AS no_of_backers
FROM 
    projects
WHERE 
    state = 'successful'  
GROUP BY 
    name                     
ORDER BY 
    no_of_backers DESC          
LIMIT 10;                  

-- TOP 10 SUCCESSFUL PROJECTS BASED ON AMOUNT RAISED -- 
SELECT 
    name,       
    CONCAT(FORMAT(SUM(pledged) / 1000000,2),"M") AS Amount_raised_millions  
FROM 
    projects
WHERE 
    state = 'successful'  
GROUP BY 
    name                     
ORDER BY 
    Amount_raised_millions DESC          
LIMIT 10;

-- PERCENTAGE OF SUCCESSFUL PROJECTS OVERALL --
SELECT 
    COUNT(CASE WHEN state = 'Successful' THEN 1 END) AS successful_projects,
    COUNT(*) AS total_projects,
    CONCAT(ROUND((COUNT(CASE WHEN state = 'Successful' THEN 1 END) / COUNT(*)) * 100, 2), '%') AS success_percentage
FROM 
    projects;

-- PERCENTAGE OF SUCCESSFUL PROJECTS BY CATEGORY -- 
SELECT 
    c.category, 
    COUNT(CASE WHEN p.state = 'Successful' THEN 1 END) AS successful_projects,
    COUNT(*) AS total_projects,
    CONCAT(ROUND((COUNT(CASE WHEN p.state = 'Successful' THEN 1 END) / COUNT(*)) * 100, 2), '%') AS success_percentage
FROM 
    projects p
JOIN 
    category c ON p.category_id = c.id
GROUP BY 
    c.category;

-- PERCENTAGE OF SUCCESSFUL PROJECTS BY YEAR, MONTH ETC. -- 
## YEAR ##
SELECT 
    YEAR(created_date) AS project_year,
    COUNT(CASE WHEN state = 'Successful' THEN 1 END) AS successful_projects,
    COUNT(*) AS total_projects,
   CONCAT(ROUND((COUNT(CASE WHEN state = 'Successful' THEN 1 END) / COUNT(*)) * 100, 2), '%') AS success_percentage
FROM 
    projects
GROUP BY 
    YEAR(created_date)
ORDER BY 
    project_year;
    
## MONTH ## 
SELECT 
    YEAR(created_date) AS project_year,
    MONTHNAME(created_date) AS project_month,
    COUNT(CASE WHEN state = 'Successful' THEN 1 END) AS successful_projects,
    COUNT(*) AS total_projects,
   CONCAT(ROUND((COUNT(CASE WHEN state = 'Successful' THEN 1 END) / COUNT(*)) * 100, 2), '%') AS success_percentage
FROM 
    projects
GROUP BY 
    YEAR(created_date), 
    MONTHNAME(created_date)
ORDER BY 
    project_year, project_month;
    
-- PERCENTAGE OF SUCCESSFUL PROJECTS BY GOAL RANGE -- 
SELECT 
    CASE
        WHEN goal BETWEEN 0 AND 10000 THEN '0 - 10,000'
        WHEN goal BETWEEN 10001 AND 50000 THEN '10,001 - 50,000'
        WHEN goal BETWEEN 50001 AND 100000 THEN '50,001 - 100,000'
        ELSE '100,001 and above'
    END AS goal_range,
    COUNT(CASE WHEN state = 'Successful' THEN 1 END) AS successful_projects,
    COUNT(*) AS total_projects,
    CONCAT(ROUND((COUNT(CASE WHEN state = 'Successful' THEN 1 END) / COUNT(*)) * 100, 2), '%') AS success_percentage
FROM 
    projects
GROUP BY 
    goal_range
ORDER BY 
    goal_range;




