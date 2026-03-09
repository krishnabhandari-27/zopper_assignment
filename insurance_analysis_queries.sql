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
SELECT SUM(Premium) AS Total_Premium
FROM policy_sales;
-- 2. Calculate the total claim cost for each year (2025 and 2026) with a monthly breakdown. 
SELECT  
EXTRACT(YEAR FROM Claim_Date) AS Year,
EXTRACT(MONTH FROM Claim_Date) AS Month,
SUM(Claim_Amount) AS Total_Claims
FROM claims_data
GROUP BY 
EXTRACT(YEAR FROM Claim_Date),
EXTRACT(MONTH FROM Claim_Date)
ORDER BY Year, Month;
-- 3. Calculate the claim cost to premium ratio for each policy tenure (1, 2, 3, and 4 years). 
SELECT 
p.Policy_Tenure,
SUM(c.Claim_Amount) AS Total_Claims,
SUM(p.Premium) AS Total_Premium,
SUM(c.Claim_Amount) / SUM(p.Premium) AS Claim_Premium_Ratio
FROM policy_sales p
JOIN claims_data c
ON p.Vehicle_ID = c.Vehicle_ID
GROUP BY p.Policy_Tenure;
-- 4. Calculate the claim cost to premium ratio by the month in which the policy was sold 
-- (January–December 2024). 
SELECT 
EXTRACT(MONTH FROM p.Policy_Purchase_Date) AS Sale_Month,
SUM(c.Claim_Amount) AS Total_Claims,
SUM(p.Premium) AS Total_Premium,
SUM(c.Claim_Amount) / SUM(p.Premium) AS Ratio
FROM policy_sales p
JOIN claims_data c
ON p.Vehicle_ID = c.Vehicle_ID
GROUP BY EXTRACT(MONTH FROM p.Policy_Purchase_Date)
ORDER BY Sale_Month;
-- 5. If every vehicle that has not yet made a claim eventually files exactly one claim during the 
-- remaining policy tenure, estimate the total potential claim liability. 
SELECT 
(COUNT(*) - COUNT(c.Vehicle_ID)) * 10000 AS Potential_Liability
FROM policy_sales p
LEFT JOIN claims_data c
ON p.Vehicle_ID = c.Vehicle_ID;
-- 6. Assume daily premium = Total Premium ÷ Total Policy Tenure Days. Based on this: 
-- (i) Calculate the premium already earned by the company up to February 28, 2026. 
-- (ii) Estimate the premium expected to be earned monthly for the remaining policy period 
-- (assume 46 months remaining).

--(i)
SELECT 
SUM(CASE WHEN Policy_Start_Date <= '2026-02-28' 
THEN ('2026-02-28'::date - Policy_Start_Date)
ELSE 0
END
) 
*
(SUM(Premium) / SUM(Policy_Tenure * 365)) 
AS earned_premium
FROM policy_sales;

--(ii)
SELECT 
(
SUM(Premium) - 
(
SUM(
CASE 
WHEN Policy_Start_Date <= '2026-02-28'
THEN ('2026-02-28'::date - Policy_Start_Date)
ELSE 0
END
) 
*
(SUM(Premium) / SUM(Policy_Tenure * 365))
)
) / 46 AS monthly_remaining_premium
FROM policy_sales;