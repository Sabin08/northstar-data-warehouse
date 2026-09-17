-- =====================================================================
-- NorthStar Solutions Canada - Database Schema Setup
-- Database: PostgreSQL
-- =====================================================================

-- Drop tables if they already exist (in correct dependency order)
DROP TABLE IF EXISTS employee_assignments CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

-- 1. Departments Table
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    location VARCHAR(100)
);

-- 2. Projects Table
CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(150) NOT NULL,
    budget NUMERIC(12, 2),
    status VARCHAR(50) NOT NULL
);

-- 3. Employees Table (Includes Self-Referencing Manager Relationship)
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    employee_name VARCHAR(100) NOT NULL,
    department_id INT REFERENCES departments(department_id) ON DELETE SET NULL,
    manager_id INT REFERENCES employees(employee_id) ON DELETE SET NULL,
    salary NUMERIC(10, 2) NOT NULL,
    hire_date DATE NOT NULL
);

-- 4. Employee Assignments Junction Table
CREATE TABLE employee_assignments (
    assignment_id SERIAL PRIMARY KEY,
    employee_id INT REFERENCES employees(employee_id) ON DELETE CASCADE,
    project_id INT REFERENCES projects(project_id) ON DELETE CASCADE,
    hours_allocated NUMERIC(6, 2) NOT NULL
);