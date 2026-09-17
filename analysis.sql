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