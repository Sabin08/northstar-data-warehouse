-- =====================================================================
-- NorthStar Solutions Canada - Enterprise Analytical Queries
-- =====================================================================

-- 1. Departmental Salary & Headcount Audit
-- Evaluates total operational overhead per department, accounting for unassigned/empty units.
SELECT 
    d.department_name,
    COUNT(e.employee_id) AS total_employees,
    SUM(COALESCE(e.salary, 0)) AS total_salary_expenditure
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_name
ORDER BY total_salary_expenditure DESC;


-- 2. Project Resource Allocation Audit (Director of Operations Report)
-- Tracks resource counts and total hours committed per project, including inactive/unassigned projects.
SELECT 
    p.project_name,
    p.status,
    COUNT(ea.employee_id) AS total_employees_assigned,
    SUM(COALESCE(ea.hours_allocated, 0)) AS total_hours_assigned
FROM employee_assignments ea 
RIGHT JOIN projects p ON ea.project_id = p.project_id 
GROUP BY p.project_name, p.status
ORDER BY total_hours_assigned DESC;


-- 3. Comprehensive HR Employee Roster
-- Pulls complete organizational hierarchy details, handling top-level execs and unassigned departments.
SELECT 
    e.employee_name,
    e.hire_date,
    e.salary,
    d.department_name,
    m.employee_name AS manager_name
FROM employees e 
LEFT JOIN departments d ON e.department_id = d.department_id
LEFT JOIN employees m ON e.manager_id = m.employee_id
ORDER BY 
    d.department_name ASC,
    e.employee_name ASC;


-- 4. Top-Tier Earners Relative to Department Average
-- Identifies employees whose salary strictly exceeds their respective department's mean baseline.
WITH dept_avg AS (
    SELECT 
        e.employee_name,
        d.department_name,
        e.salary,
        ROUND(AVG(e.salary) OVER (PARTITION BY e.department_id), 2) AS average_salary
    FROM employees e 
    JOIN departments d USING(department_id)
)
SELECT *
FROM dept_avg 
WHERE salary > average_salary
ORDER BY department_name ASC, salary DESC;


-- 5. Top 2 Highest-Paid Employees per Department (Rank-Based Tie Handling)
-- Uses window ranking to isolate leading earners while preserving future scalability for ties.
WITH salary_rank AS (
    SELECT 
        d.department_name,
        e.employee_name,
        e.salary,
        RANK() OVER (PARTITION BY e.department_id ORDER BY e.salary DESC) AS department_rank
    FROM employees e 
    JOIN departments d USING(department_id)
)
SELECT *
FROM salary_rank 
WHERE department_rank <= 2
ORDER BY department_name ASC, department_rank ASC;


-- 6. Salary Parity Audit: Employees Earning More Than Managers
-- Structural check for compensation anomalies across leadership lines.
SELECT 
    e1.employee_name,
    e1.salary,
    e2.employee_name AS manager_name,
    e2.salary AS manager_salary,
    e1.salary - e2.salary AS salary_difference
FROM employees e1 
JOIN employees e2 ON e1.manager_id = e2.employee_id
WHERE e1.salary > e2.salary
ORDER BY salary_difference DESC;


-- 7. Risk Audit: Unassigned Resources Report
-- Anti-join pattern tracking active staff currently not allocated to any enterprise projects.
SELECT 
    e.employee_name,
    e.salary,
    d.department_name 
FROM employees e 
LEFT JOIN employee_assignments ea ON e.employee_id = ea.employee_id 
JOIN departments d ON e.department_id = d.department_id
WHERE ea.assignment_id IS NULL
ORDER BY e.salary DESC;

-- =====================================================================
-- Problem 8: Recursive Organizational Hierarchy Audit
-- =====================================================================
-- Executive management wants to map out the complete organizational reporting 
-- structure below the top leadership. Write a query using a Recursive CTE to 
-- trace the hierarchy starting from the top executive (Aarav Sharma, employee_id = 1).
-- 
-- Your query should traverse down the reporting line to include all direct and 
-- indirect reports, returning:
-- 1. The employee's name
-- 2. Their manager's name
-- 3. Their depth level in the hierarchy (where Aarav is level 1, direct reports are level 2, etc.)
-- 
-- Sort the final output by depth level (ascending) and then by employee name (ascending).

with recursive emp_depth as (
    -- ANCHOR MEMBER: The starting point (Runs ONCE)
    select employee_id, employee_name,manager_id, 1 as depth_level
    from employees where manager_id is null

    UNION ALL
    -- recursive member, joins back to cte
    select e.employee_id, e.employee_name,e.manager_id, d.depth_level + 1
    from employees e
    join emp_depth d
    on d.employee_id = e.manager_id
)
-- 3. FINAL SELECT: Pulls everything out of the finished CTE
select * from emp_depth
order by depth_level, employee_name


-- =====================================================================
-- Problem 9: Departmental Salary Distribution Tier Audit
-- =====================================================================
-- Management wants a salary distribution audit across all departments. 
-- Write a query that categorizes employees into three salary tiers:
-- 1. "High Earner" (salary > 120000)
-- 2. "Mid Earner" (salary between 90000 and 120000 inclusive)
-- 3. "Standard Earner" (salary < 90000)
-- 
-- Return the department name, along with the count of employees in each 
-- of these three tiers (using conditional aggregation like CASE WHEN), 
-- and sort the final output by department name in ascending order.
SELECT 
    d.department_name,
    count(case when e.salary > 120000 then 1 end) as high_earner,
    count(case when e.salary between 90000 and 120000 then 1 end) as mid_earner,
    count(case when e.salary < 90000 then 1 end) as standard_earner
FROM employees e join departments d using(department_id)
group by d.department_name
order by d.department_name 
;

-- =====================================================================
-- Problem 10: Cumulative Salary Running Total by Department
-- =====================================================================
-- Finance wants to track how payroll overhead accumulates over time within 
-- each department based on employee hire dates. 
-- 
-- Write a query that returns:
-- 1. Department name
-- 2. Employee name
-- 3. Hire date
-- 4. Individual salary
-- 5. A running total (cumulative sum) of salaries within that department, 
--    ordered chronologically by hire date (and employee name as a tie-breaker).
-- 
-- Sort the final output by department name ascending, cumulative salary ascending.
SELECT 
    d.department_name,
    e.employee_name,
    e.hire_date,
    e.salary,
    sum(e.salary) over (partition by d.department_name order by e.hire_date asc, e.employee_name asc) as cumulative_salary
FROM EMPLOYEES e join DEPARTMENTS d using(department_id)
order by d.department_name asc, cumulative_salary asc;


-- =====================================================================
-- Problem 11: Above-Average Departmental Salary Benchmark
-- =====================================================================
-- Management wants to identify high-cost departments. Write a query to 
-- find all departments where the average employee salary is strictly higher 
-- than the overall company-wide average salary.
-- 
-- Return:
-- 1. Department name
-- 2. The department's average salary (rounded to 2 decimal places)
-- 3. The company-wide average salary for comparison (rounded to 2 decimal places)
-- 
-- Sort the final output by the department's average salary in descending order.
WITH company_summary AS (
    -- Calculate the overall company average once
    SELECT ROUND(AVG(salary), 2) AS company_average 
    FROM employees
),
dept_avg AS (
    -- Calculate each department's average
    SELECT 
        d.department_name,
        ROUND(AVG(e.salary), 2) AS department_average
    FROM employees e 
    JOIN departments d USING(department_id)
    GROUP BY d.department_name
)
-- Compare department average against company average
SELECT 
    da.department_name,
    da.department_average,
    cs.company_average
FROM dept_avg da
CROSS JOIN company_summary cs
WHERE da.department_average > cs.company_average
ORDER BY da.department_average DESC;

-- =====================================================================
-- Problem 12: Project Allocation Audit (Unassigned Resources)
-- =====================================================================
-- Operations wants to audit staffing efficiency by finding all employees 
-- who are currently not assigned to any projects.
-- 
-- Write a query to return:
-- 1. Employee name
-- 2. Employee salary
-- 3. Department name
-- 
-- Use a LEFT JOIN (or NOT IN / NOT EXISTS) between employees, departments, 
-- and employee_assignments to find those with zero project records.
-- Sort the final output by employee salary in descending order.
    
    select 
        e.employee_name,
        e.salary,
        d.department_name 
    from employees e 
    left join employee_assignments ea on e.employee_id = ea.employee_id
    join departments d on e.department_id = d.department_id
    where ea.assignment_id is null
    order by e.salary desc;

    -- =====================================================================
-- Problem 13: Highest-Paid Employee per Department
-- =====================================================================
-- Executive leadership wants to know the single highest-paid employee 
-- in each department. If there's a tie in salary, include all tied employees.
-- 
-- Write a query to return:
-- 1. Department name
-- 2. Employee name
-- 3. Salary
-- 
-- Use a ranking window function (like RANK() or DENSE_RANK()) partitioned 
-- by department and ordered by salary in descending order.
-- Sort the final output by department name in ascending order.
with salary_rank as (
    select 
        d.department_name,
        e.employee_name,
        e.salary,
        dense_rank() over(partition by e.department_id order by salary desc) as emp_rank
    from employees e join departments d using(department_id)
)
select 
    department_name,
    employee_name,
    salary
from salary_rank
where emp_rank = 1;