DROP SCHEMA IF EXISTS broccoli CASCADE;
CREATE SCHEMA broccoli;
SET search_path = broccoli;

BEGIN;

CREATE TABLE users (
	username VARCHAR(20) PRIMARY KEY,
	is_online BOOLEAN NOT NULL DEFAULT FALSE,
	is_reddit_linked BOOLEAN NOT NULL DEFAULT FALSE,
	email TEXT,
	password TEXT,
	CHECK (
		(is_reddit_linked AND email IS NULL AND password IS NULL) OR
		(NOT is_reddit_linked AND email IS NOT NULL AND password IS NOT NULL)),
	UNIQUE (email)
);

CREATE TABLE rooms (
	name VARCHAR(20) PRIMARY KEY,
	topic TEXT
);

CREATE TABLE subscriptions (
	username VARCHAR(20) NOT NULL,
	room VARCHAR(20) NOT NULL,
	is_moderator BOOLEAN NOT NULL DEFAULT FALSE,
	status TEXT,
	PRIMARY KEY (username, room),
	FOREIGN KEY (username) REFERENCES users (username) ON DELETE CASCADE,
	FOREIGN KEY (room) REFERENCES rooms (name) ON DELETE CASCADE
);

CREATE INDEX user_sub_index ON subscriptions (username);
CREATE INDEX room_sub_index ON subscriptions (room);
CREATE INDEX room_mod_index ON subscriptions (room, is_moderator);

CREATE TYPE message_type AS
	ENUM ('message', 'join', 'leave', 'kick', 'ban', 'report',
		'shadowban', 'topic_change', 'status_change');

CREATE TABLE messages (
	id SERIAL PRIMARY KEY,
	room VARCHAR(20) NOT NULL,
	username VARCHAR(20) NOT NULL,
	time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	type message_type NOT NULL,
	message TEXT,
	target_user VARCHAR(20),
	target_message INT
	CHECK (
		((type = 'message' OR type = 'topic_change' OR type = 'status_change') AND
			message IS NOT NULL AND target_user IS NULL AND target_message IS NULL) OR
		((type = 'kick' OR type = 'ban' OR type = 'shadowban') AND
			message IS NULL AND target_user IS NOT NULL AND target_message IS NULL) OR
		(type = 'report' AND
			message IS NULL AND target_user IS NULL AND target_message IS NOT NULL) OR
		((type = 'join' OR type = 'leave') AND
			message IS NULL AND target_user IS NULL AND target_message IS NULL)),
	FOREIGN KEY (room) REFERENCES rooms (name) ON DELETE CASCADE,
	FOREIGN KEY (username) REFERENCES users (username) ON DELETE CASCADE,
	FOREIGN KEY (target_user) REFERENCES users (username) ON DELETE CASCADE,
	FOREIGN KEY (target_message) REFERENCES messages (id) ON DELETE CASCADE
);

CREATE INDEX room_message_index ON messages (room);
CREATE INDEX user_message_index ON messages (username);

CREATE TABLE upvotes (
	message INT NOT NULL,
	upvoter VARCHAR(20) NOT NULL,
	PRIMARY KEY (message, upvoter),
	FOREIGN KEY (message) REFERENCES messages (id) ON DELETE CASCADE,
	FOREIGN KEY (upvoter) REFERENCES users (username) ON DELETE CASCADE
);

CREATE INDEX message_upvotes ON upvotes (message);

CREATE TABLE reports (
	message INT NOT NULL,
	reporter VARCHAR(20) NOT NULL,
	PRIMARY KEY (message, reporter),
	FOREIGN KEY (message) REFERENCES messages (id) ON DELETE CASCADE,
	FOREIGN KEY (reporter) REFERENCES users (username) ON DELETE CASCADE
);

CREATE INDEX message_reports ON reports (message);

CREATE TABLE bans (
	room VARCHAR(20) NOT NULL,
	username VARCHAR(20) NOT NULL,
	FOREIGN KEY (room) REFERENCES rooms (name) ON DELETE CASCADE,
	FOREIGN KEY (username) REFERENCES users (username) ON DELETE CASCADE
);

CREATE INDEX room_bans_index ON bans (room);
CREATE INDEX user_bans_index ON bans (username);

CREATE TABLE shadowbans (
	room VARCHAR(20) NOT NULL,
	username VARCHAR(20) NOT NULL,
	FOREIGN KEY (room) REFERENCES rooms (name) ON DELETE CASCADE,
	FOREIGN KEY (username) REFERENCES users (username) ON DELETE CASCADE
);

CREATE INDEX room_shadowbans_index ON shadowbans (room);

CREATE TABLE blocked_users (
	username VARCHAR(20) NOT NULL,
	target_user VARCHAR(20) NOT NULL,
	FOREIGN KEY (username) REFERENCES users (username) ON DELETE CASCADE,
	FOREIGN KEY (target_user) REFERENCES users (username) ON DELETE CASCADE
);

CREATE TABLE groups (
	id SERIAL PRIMARY KEY,
	topic TEXT
);

CREATE TABLE group_subscriptions (
	username VARCHAR(20) NOT NULL,
	group_id INT,
	FOREIGN KEY (username) REFERENCES users (username) ON DELETE CASCADE,
	FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE
);

CREATE TABLE group_messages (
	id SERIAL PRIMARY KEY,
	group_id INT NOT NULL,
	username VARCHAR(20) NOT NULL,
	time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	type message_type NOT NULL,
	message TEXT,
	CHECK (
		((type = 'message' OR type = 'topic_change') AND message IS NOT NULL) OR
		((type = 'join' OR type = 'leave') AND message IS NULL)),
	FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE,
	FOREIGN KEY (username) REFERENCES users (username) ON DELETE CASCADE
);

CREATE INDEX group_message_index ON group_messages (group_id);
CREATE INDEX user_group_message_index ON group_messages (username);

CREATE TABLE group_upvotes (
	message INT NOT NULL,
	upvoter VARCHAR(20) NOT NULL,
	PRIMARY KEY (message, upvoter),
	FOREIGN KEY (message) REFERENCES group_messages (id) ON DELETE CASCADE,
	FOREIGN KEY (upvoter) REFERENCES users (username) ON DELETE CASCADE
);

COMMIT;
