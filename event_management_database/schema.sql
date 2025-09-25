-- Event Management Database Schema (MySQL 8.0+)

-- Create database and grant (run as root if not exists)
-- CREATE DATABASE IF NOT EXISTS event_management;
-- GRANT ALL PRIVILEGES ON event_management.* TO 'appuser'@'%';
-- FLUSH PRIVILEGES;

USE event_management;

-- Users
CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  email VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(100) NULL,
  last_name VARCHAR(100) NULL,
  role ENUM('admin','organizer','attendee') NOT NULL DEFAULT 'attendee',
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Events
CREATE TABLE IF NOT EXISTS events (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  organizer_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT NULL,
  location VARCHAR(255) NULL,
  start_time DATETIME NOT NULL,
  end_time DATETIME NOT NULL,
  capacity INT UNSIGNED NULL,
  status ENUM('draft','published','cancelled','completed') NOT NULL DEFAULT 'draft',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_events_organizer_id (organizer_id),
  KEY idx_events_start_time (start_time),
  CONSTRAINT fk_events_organizer FOREIGN KEY (organizer_id)
    REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_events_time CHECK (end_time > start_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Attendees
CREATE TABLE IF NOT EXISTS attendees (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  event_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NULL,
  email VARCHAR(255) NOT NULL,
  name VARCHAR(200) NULL,
  status ENUM('invited','registered','checked_in','cancelled','waitlisted') NOT NULL DEFAULT 'registered',
  checked_in_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_attendees_event_email (event_id, email),
  KEY idx_attendees_event_id (event_id),
  KEY idx_attendees_user_id (user_id),
  CONSTRAINT fk_attendees_event FOREIGN KEY (event_id)
    REFERENCES events(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_attendees_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Schedules
CREATE TABLE IF NOT EXISTS schedules (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  event_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT NULL,
  location VARCHAR(255) NULL,
  start_time DATETIME NOT NULL,
  end_time DATETIME NOT NULL,
  sort_order INT UNSIGNED NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_schedules_event_id (event_id),
  KEY idx_schedules_start_time (start_time),
  CONSTRAINT fk_schedules_event FOREIGN KEY (event_id)
    REFERENCES events(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT chk_schedules_time CHECK (end_time > start_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Event collaborators (optional)
CREATE TABLE IF NOT EXISTS event_users (
  event_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  role ENUM('organizer','staff','viewer') NOT NULL DEFAULT 'viewer',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (event_id, user_id),
  CONSTRAINT fk_event_users_event FOREIGN KEY (event_id)
    REFERENCES events(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_event_users_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Helpful secondary indexes
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_events_status_start ON events(status, start_time);
CREATE INDEX idx_attendees_status ON attendees(status);
