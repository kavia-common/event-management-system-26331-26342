# Event Management Database Schema (MySQL)

Database: event_management

This document describes the initial relational schema and constraints for the Event Management System.

Tables:
1) users
- id BIGINT UNSIGNED PK AUTO_INCREMENT
- email VARCHAR(255) NOT NULL UNIQUE (uq_users_email)
- password_hash VARCHAR(255) NOT NULL
- first_name VARCHAR(100) NULL
- last_name VARCHAR(100) NULL
- role ENUM('admin','organizer','attendee') NOT NULL DEFAULT 'attendee'
- is_active TINYINT(1) NOT NULL DEFAULT 1
- created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
- updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
Indexes:
- PRIMARY KEY (id)
- UNIQUE (email)
- SECONDARY: idx_users_created_at ON created_at

2) events
- id BIGINT UNSIGNED PK AUTO_INCREMENT
- organizer_id BIGINT UNSIGNED NOT NULL -> users.id
- title VARCHAR(255) NOT NULL
- description TEXT NULL
- location VARCHAR(255) NULL
- start_time DATETIME NOT NULL
- end_time DATETIME NOT NULL
- capacity INT UNSIGNED NULL
- status ENUM('draft','published','cancelled','completed') NOT NULL DEFAULT 'draft'
- created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
- updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
Constraints/Indexes:
- PRIMARY KEY (id)
- FOREIGN KEY (organizer_id) REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE
- CHECK (end_time > start_time)
- INDEX idx_events_organizer_id (organizer_id)
- INDEX idx_events_start_time (start_time)
- INDEX idx_events_status_start (status, start_time)

3) attendees
- id BIGINT UNSIGNED PK AUTO_INCREMENT
- event_id BIGINT UNSIGNED NOT NULL -> events.id
- user_id BIGINT UNSIGNED NULL -> users.id (nullable for guest attendees)
- email VARCHAR(255) NOT NULL
- name VARCHAR(200) NULL
- status ENUM('invited','registered','checked_in','cancelled','waitlisted') NOT NULL DEFAULT 'registered'
- checked_in_at DATETIME NULL
- created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
- updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
Constraints/Indexes:
- PRIMARY KEY (id)
- FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE ON UPDATE CASCADE
- FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
- UNIQUE (event_id, email) to ensure same email is not registered twice per event
- INDEX idx_attendees_event_id (event_id)
- INDEX idx_attendees_user_id (user_id)
- INDEX idx_attendees_status (status)

4) schedules
- id BIGINT UNSIGNED PK AUTO_INCREMENT
- event_id BIGINT UNSIGNED NOT NULL -> events.id
- title VARCHAR(255) NOT NULL
- description TEXT NULL
- location VARCHAR(255) NULL
- start_time DATETIME NOT NULL
- end_time DATETIME NOT NULL
- sort_order INT UNSIGNED NOT NULL DEFAULT 0
- created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
- updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
Constraints/Indexes:
- PRIMARY KEY (id)
- FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE ON UPDATE CASCADE
- CHECK (end_time > start_time)
- INDEX idx_schedules_event_id (event_id)
- INDEX idx_schedules_start_time (start_time)

5) event_users (collaborators)
- event_id BIGINT UNSIGNED NOT NULL -> events.id
- user_id BIGINT UNSIGNED NOT NULL -> users.id
- role ENUM('organizer','staff','viewer') NOT NULL DEFAULT 'viewer'
- created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
Constraints/Indexes:
- PRIMARY KEY (event_id, user_id)
- FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE ON UPDATE CASCADE
- FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE

Connection details
- A MySQL server runs locally on port 5000 (per startup.sh).
- Database user:
  - root / dbuser123
  - appuser / dbuser123 (has privileges on event_management)
- Quick connect command:
  mysql -u appuser -pdbuser123 -h localhost -P 5000 event_management

Notes
- Timestamp defaults and ON UPDATE clauses ensure automatic tracking of created/updated times.
- CHECK constraints are defined (supported by MySQL 8.0+).
- Foreign key cascades are configured to keep data consistent (e.g., delete attendees and schedules when their event is deleted).
- attendees.user_id is nullable to support guest registrations by email without requiring a full user account.

Operational steps executed
- Created database event_management (as root) and granted privileges to appuser.
- Created tables users, events, attendees, schedules, event_users.
- Added indexes:
  - idx_users_created_at (users.created_at)
  - idx_events_status_start (events.status, events.start_time)
  - idx_attendees_status (attendees.status)

Environment variables for db_visualizer (already maintained by startup.sh)
- db_visualizer/mysql.env gets generated with:
  - MYSQL_URL, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DB, MYSQL_PORT
  You can update MYSQL_DB to event_management if needed.
