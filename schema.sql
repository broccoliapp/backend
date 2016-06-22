DROP SCHEMA IF EXISTS broccoli CASCADE;
CREATE SCHEMA broccoli;
SET search_path = broccoli;

BEGIN;

CREATE TABLE users (
	user_id SERIAL PRIMARY KEY,
	username VARCHAR(20) NOT NULL,
	is_online BOOLEAN NOT NULL DEFAULT FALSE,
	is_reddit_linked BOOLEAN NOT NULL DEFAULT FALSE,
	email TEXT,
	password TEXT,
	created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	CHECK (
		(is_reddit_linked AND email IS NULL AND password IS NULL) OR
		(NOT is_reddit_linked AND email IS NOT NULL AND password IS NOT NULL)),
	UNIQUE (username),
	UNIQUE (email)
);

CREATE TABLE rooms (
	room_id SERIAL PRIMARY KEY,
	name VARCHAR(20) NOT NULL,
	topic TEXT,
	created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	UNIQUE (name)
);

CREATE TABLE subscriptions (
	user_id INT NOT NULL,
	room_id INT NOT NULL,
	is_moderator BOOLEAN NOT NULL DEFAULT FALSE,
	status TEXT,
	PRIMARY KEY (user_id, room_id),
	FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE,
	FOREIGN KEY (room_id) REFERENCES rooms (room_id) ON DELETE CASCADE
);

CREATE INDEX user_sub_index ON subscriptions (user_id);
CREATE INDEX room_sub_index ON subscriptions (room_id);
CREATE INDEX room_mod_index ON subscriptions (room_id, is_moderator);

CREATE TYPE message_type AS
	ENUM ('message', 'join', 'leave', 'kick', 'ban', 'report',
		'shadowban', 'topic_change', 'status_change');

CREATE TABLE messages (
	message_id SERIAL PRIMARY KEY,
	room_id INT NOT NULL,
	user_id INT NOT NULL,
	time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	type message_type NOT NULL,
	message TEXT,
	target_user INT,
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
	FOREIGN KEY (room_id) REFERENCES rooms (room_id) ON DELETE CASCADE,
	FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE,
	FOREIGN KEY (target_user) REFERENCES users (user_id) ON DELETE CASCADE,
	FOREIGN KEY (target_message) REFERENCES messages (message_id) ON DELETE CASCADE
);

CREATE INDEX room_message_index ON messages (room_id);
CREATE INDEX user_message_index ON messages (user_id);

CREATE TABLE upvotes (
	message_id INT NOT NULL,
	upvoter INT NOT NULL,
	PRIMARY KEY (message_id, upvoter),
	FOREIGN KEY (message_id) REFERENCES messages (message_id) ON DELETE CASCADE,
	FOREIGN KEY (upvoter) REFERENCES users (user_id) ON DELETE CASCADE
);

CREATE INDEX message_upvotes ON upvotes (message_id);

CREATE TABLE reports (
	message_id INT NOT NULL,
	reporter INT NOT NULL,
	PRIMARY KEY (message_id, reporter),
	FOREIGN KEY (message_id) REFERENCES messages (message_id) ON DELETE CASCADE,
	FOREIGN KEY (reporter) REFERENCES users (user_id) ON DELETE CASCADE
);

CREATE INDEX message_reports ON reports (message_id);

CREATE TABLE bans (
	room_id INT NOT NULL,
	user_id INT NOT NULL,
	FOREIGN KEY (room_id) REFERENCES rooms (room_id) ON DELETE CASCADE,
	FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
);

CREATE INDEX room_bans_index ON bans (room_id);

CREATE TABLE shadowbans (
	room_id INT NOT NULL,
	user_id INT NOT NULL,
	FOREIGN KEY (room_id) REFERENCES rooms (room_id) ON DELETE CASCADE,
	FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
);

CREATE INDEX room_shadowbans_index ON shadowbans (room_id);

CREATE TABLE blocked_users (
	user_id INT NOT NULL,
	target_user INT NOT NULL,
	FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE,
	FOREIGN KEY (target_user) REFERENCES users (user_id) ON DELETE CASCADE
);

CREATE TABLE groups (
	group_id SERIAL PRIMARY KEY,
	topic TEXT
);

CREATE TABLE group_subscriptions (
	user_id INT NOT NULL,
	group_id INT,
	FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE,
	FOREIGN KEY (group_id) REFERENCES groups (group_id) ON DELETE CASCADE
);

CREATE TABLE group_messages (
	message_id SERIAL PRIMARY KEY,
	group_id INT NOT NULL,
	user_id INT NOT NULL,
	time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	type message_type NOT NULL,
	message TEXT,
	CHECK (
		((type = 'message' OR type = 'topic_change') AND message IS NOT NULL) OR
		((type = 'join' OR type = 'leave') AND message IS NULL)),
	FOREIGN KEY (group_id) REFERENCES groups (group_id) ON DELETE CASCADE,
	FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
);

CREATE INDEX group_message_index ON group_messages (group_id);
CREATE INDEX user_group_message_index ON group_messages (user_id);

CREATE TABLE group_upvotes (
	message_id INT NOT NULL,
	upvoter INT NOT NULL,
	PRIMARY KEY (message_id, upvoter),
	FOREIGN KEY (message_id) REFERENCES group_messages (message_id) ON DELETE CASCADE,
	FOREIGN KEY (upvoter) REFERENCES users (user_id) ON DELETE CASCADE
);

COMMIT;
