# 🌟 NorthStar Solutions Canada – Enterprise PostgreSQL Data Warehouse & Analytics Suite

A portfolio-grade relational database and advanced analytics suite built from scratch in **PostgreSQL**. This project simulates an enterprise data architecture for a mock Canadian corporation, managing organizational hierarchies, project resource allocation, and complex financial/HR auditing.

---

## 🏗️ Architecture & Database Schema

The relational schema is fully normalized and enforces strict enterprise integrity using primary keys, foreign key constraints, cascading behaviors, and self-referencing relationships.

* **`departments`**: Stores business units across Canadian tech hubs (Toronto, Vancouver, Montreal, etc.).
* **`projects`**: Tracks active, completed, and on-hold company initiatives alongside financial budgets.
* **`employees`**: Houses organizational staff, salaries, hire dates, and a **self-referencing manager hierarchy** (`manager_id` mapping to `employee_id`).
* **`employee_assignments`**: A junction table mapping many-to-many relationships between employees and projects with allocated work hours.

---

## 📂 Repository Structure

```text
├── schema.sql      # DDL script establishing tables, relationships, and constraints
├── seed.sql        # Comprehensive data insertion script (50+ employees, projects, and assignments)
└── analysis.sql    # Advanced analytical SQL queries and enterprise reporting scripts
