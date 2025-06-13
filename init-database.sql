-- Tau Gamma Phi CBC Chapter Management System
-- Database initialization script for Ubuntu VPS deployment

-- Create database (run this as postgres user)
-- CREATE DATABASE tgp_chapter_db;
-- CREATE USER tgp_user WITH ENCRYPTED PASSWORD 'your_secure_password';
-- GRANT ALL PRIVILEGES ON DATABASE tgp_chapter_db TO tgp_user;
-- ALTER USER tgp_user CREATEDB;

-- Connect to the database as tgp_user
\c tgp_chapter_db;

-- Enable UUID extension if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Grant schema permissions
GRANT ALL ON SCHEMA public TO tgp_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO tgp_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO tgp_user;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO tgp_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO tgp_user;

-- Insert default admin user (password will be hashed by the application)
-- This is handled by the application's initialization process

-- Insert default chapter information
-- This will be handled by the application's setup process

-- Database is ready for Drizzle ORM schema push
-- Run: npm run db:push after application deployment