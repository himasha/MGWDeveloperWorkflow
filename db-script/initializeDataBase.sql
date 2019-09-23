/* 
 * MySQL Script - initializeDataBase.sql.
 * Create EMPLOYEE_RECORDS database and EMPLOYEES table.
 */
 
-- Create EMPLOYEE_RECORDS database
CREATE DATABASE IF NOT EXISTS bookstore;     

-- Switch to EMPLOYEE_RECORDS database
USE bookstore;

-- create EMPLOYEES table in the database
CREATE TABLE IF NOT EXISTS books(bookID INT, name VARCHAR(50), author VARCHAR(50), PRIMARY KEY (bookID));
