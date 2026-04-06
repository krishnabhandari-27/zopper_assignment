CREATE TABLE policy_sales (
    Customer_ID INT NOT NULL,
    Vehicle_ID INT PRIMARY KEY,
    Vehicle_Value NUMERIC(10,2) NOT NULL CHECK (Vehicle_Value > 0),
    Premium NUMERIC(10,2) NOT NULL CHECK (Premium > 0),
    Policy_Purchase_Date DATE NOT NULL,
    Policy_Start_Date DATE NOT NULL,
    Policy_End_Date DATE NOT NULL,
    Policy_Tenure INT NOT NULL CHECK (Policy_Tenure IN (1,2,3,4))
);

CREATE TABLE claims_data (
    Claim_ID SERIAL PRIMARY KEY,
    Customer_ID INT NOT NULL,
    Vehicle_ID INT NOT NULL,
    Claim_Amount NUMERIC(10,2) NOT NULL CHECK (Claim_Amount > 0),
    Claim_Date DATE NOT NULL,
    Claim_Type INT NOT NULL CHECK (Claim_Type IN (1,2)),
    
    CONSTRAINT fk_vehicle
    FOREIGN KEY (Vehicle_ID)
    REFERENCES policy_sales(Vehicle_ID)
);

SELECT * FROM policy_sales;
SELECT * FROM claims_data;

-- Part 3 Analytical Queries 


-- 1. Calculate the total premium collected during the year 2024. 
SELECT SUM(premium) AS total_premium_2024
FROM policy_sales_data
WHERE YEAR(policy_start_date) = 2024;
-- 2. Calculate the total claim cost for each year (2025 and 2026) with a monthly breakdown. 
SELECT 
    YEAR(claim_date) AS year,
    MONTH(claim_date) AS month,
    SUM(claim_amount) AS total_claim_cost
FROM claims_data
WHERE YEAR(claim_date) IN (2025, 2026)
GROUP BY YEAR(claim_date), MONTH(claim_date)
ORDER BY year, month;
-- 3. Calculate the claim cost to premium ratio for each policy tenure (1, 2, 3, and 4 years). 
SELECT 
    p.policy_tenure_years,
    SUM(c.claim_amount) / SUM(p.premium) AS claim_to_premium_ratio
FROM policy_sales_data p
LEFT JOIN claims_data c 
    ON p.policy_id = c.policy_id
GROUP BY p.policy_tenure_years
ORDER BY p.policy_tenure_years;
-- 4. Calculate the claim cost to premium ratio by the month in which the policy was sold 
-- (January–December 2024). 
SELECT 
    MONTH(p.policy_start_date) AS month,
    SUM(c.claim_amount) / SUM(p.premium) AS ratio
FROM policy_sales_data p
LEFT JOIN claims_data c 
    ON p.policy_id = c.policy_id
WHERE YEAR(p.policy_start_date) = 2024
GROUP BY MONTH(p.policy_start_date)
ORDER BY month;
-- 5. If every vehicle that has not yet made a claim eventually files exactly one claim during the 
-- remaining policy tenure, estimate the total potential claim liability. 
SELECT 
    SUM(p.premium) AS estimated_liability
FROM policy_sales_data p
LEFT JOIN claims_data c 
    ON p.policy_id = c.policy_id
WHERE c.policy_id IS NULL;
-- 6. Assume daily premium = Total Premium ÷ Total Policy Tenure Days. Based on this: 
-- (i) Calculate the premium already earned by the company up to February 28, 2026. 
-- (ii) Estimate the premium expected to be earned monthly for the remaining policy period 
-- (assume 46 months remaining).

--(i)
SELECT 
    SUM(
        (DATEDIFF(LEAST('2026-02-28', policy_end_date), policy_start_date) + 1)
        / (DATEDIFF(policy_end_date, policy_start_date) + 1)
        * premium
    ) AS earned_premium
FROM policy_sales_data
WHERE policy_start_date <= '2026-02-28';

--(ii)
SELECT 
    SUM(premium) / 46 AS monthly_expected_premium
FROM policy_sales_data;
*
(SUM(Premium) / SUM(Policy_Tenure * 365))
)
) / 46 AS monthly_remaining_premium
FROM policy_sales;
