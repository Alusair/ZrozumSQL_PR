/* Moduł 5 Data Manipulation Language – PROJEKT */

/* Moduł 4 Data Control Language – PROJEKT */
/* 1 */
CREATE ROLE expense_tracker_user WITH LOGIN PASSWORD 'si1neh4s10'; 

/* 2 */
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

/* 3 */
DROP SCHEMA IF EXISTS expense_tracker CASCADE;

/* 4 */
CREATE ROLE expense_tracker_group;

/* 5 */
CREATE SCHEMA expense_tracker AUTHORIZATION expense_tracker_group;

/* 6 */
GRANT CONNECT ON DATABASE postgres TO expense_tracker_group;
GRANT USAGE, CREATE ON SCHEMA expense_tracker TO expense_tracker_group;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA expense_tracker TO expense_tracker_group;

/* 7 */
GRANT expense_tracker_group TO expense_tracker_user;

/* Moduł 3 Data Definition Language – PROJEKT */
/* 1 */
/* CREATE SCHEMA IF NOT EXISTS expense_tracker; */

/* 2 */
/* bank_account_owner */
DROP TABLE IF EXISTS expense_tracker.bank_account_owner CASCADE;

CREATE TABLE IF NOT EXISTS expense_tracker.bank_account_owner (
	id_ba_own SERIAL PRIMARY KEY,
	owner_name varchar(50) NOT NULL,
	owner_desc varchar(250),
	user_login int NOT NULL,
	active boolean DEFAULT true NOT NULL,
	insert_date timestamp DEFAULT CURRENT_TIMESTAMP,
	update_date timestamp DEFAULt CURRENT_TIMESTAMP
);

INSERT INTO expense_tracker.bank_account_owner (owner_name, owner_desc, user_login)
VALUES ('Aneta', 'pierwszy użytkownik', 1);

/* bank_account_types */
DROP TABLE IF EXISTS expense_tracker.bank_account_types CASCADE;

CREATE TABLE IF NOT EXISTS expense_tracker.bank_account_types (
	id_ba_type SERIAL PRIMARY KEY,
	ba_type varchar(50) NOT NULL,
	ba_desc varchar(250),
	active boolean DEFAULT true NOT NULL,
	is_common_account boolean DEFAULT false NOT NULL,
	id_ba_own int,
	insert_date timestamp DEFAULT CURRENT_TIMESTAMP,
	update_date timestamp DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY (id_ba_own) REFERENCES expense_tracker.bank_account_owner (id_ba_own)
);

INSERT INTO expense_tracker.bank_account_types (ba_type, ba_desc, id_ba_own)
VALUES ('konto internetowe', 'konto bankowe dla płatności internetowych', 1);

/* transaction_bank_accounts */
DROP TABLE IF EXISTS expense_tracker.transaction_bank_accounts CASCADE;

CREATE TABLE IF NOT EXISTS expense_tracker.transaction_bank_accounts(
	id_trans_ba SERIAL PRIMARY KEY,
	id_ba_own int,
	id_ba_type int,
	bank_account_name varchar(50) NOT NULL,
	bank_account_desc varchar(250),
	active boolean DEFAULT true NOT NULL,
	insert_date timestamp DEFAULT CURRENT_TIMESTAMP,
	update_date timestamp DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY (id_ba_own) REFERENCES expense_tracker.bank_account_owner (id_ba_own),
	FOREIGN KEY (id_ba_type) REFERENCES expense_tracker.bank_account_types (id_ba_type)
);

INSERT INTO expense_tracker.transaction_bank_accounts (id_ba_own, id_ba_type, bank_account_name, bank_account_desc)
VALUES (1, 1, 'Bank Polski', 'Bank Polski z siedzibą w Poznaniu');

/* transaction_category */
DROP TABLE IF EXISTS expense_tracker.transaction_category CASCADE;

CREATE TABLE IF NOT EXISTS expense_tracker.transaction_category (
	id_trans_cat SERIAL PRIMARY KEY,
	category_name varchar(50) NOT NULL,
	category_description varchar(250),
	active boolean DEFAULT true NOT NULL,
	insert_date timestamp DEFAULT CURRENT_TIMESTAMP,
	update_date timestamp DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO expense_tracker.transaction_category (category_name, category_description)
VALUES ('Żywność', 'Wydatki związane z żywnością');

/* transaction_subcategory */
DROP TABLE IF EXISTS expense_tracker.transaction_subcategory CASCADE;

CREATE TABLE IF NOT EXISTS expense_tracker.transaction_subcategory (
	id_trans_subcat SERIAL PRIMARY KEY,
	id_trans_cat int,
	subcategory_name varchar(50) NOT NULL,
	subcategory_description varchar(250),
	actiive boolean DEFAULT true NOT NULL,
	insert_date timestamp DEFAULT CURRENT_TIMESTAMP,
	update_date timestamp DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY (id_trans_cat) REFERENCES expense_tracker.transaction_category (id_trans_cat)
);

INSERT INTO expense_tracker.transaction_subcategory (id_trans_cat, subcategory_name, subcategory_description)
VALUES (1, 'Restauracja', 'Wydatki związane z zakupem posiłków w restauracjach');

/* transaction_type */
DROP TABLE IF EXISTS expense_tracker.transaction_type CASCADE;

CREATE TABLE IF NOT EXISTS expense_tracker.transaction_type (
	id_trans_type SERIAL PRIMARY KEY,
	transaction_type varchar(50) NOT NULL,
	transaction_type_desc varchar(250),
	active boolean DEFAULT true NOT NULL,
	insert_date timestamp DEFAULT CURRENT_TIMESTAMP,
	update_date timestamp DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO expense_tracker.transaction_type (transaction_type, transaction_type_desc)
VALUES ('Płatność kartą', 'Płatność z użyciem karty płatniczej');

/* users */
DROP TABLE IF EXISTS expense_tracker.users CASCADE;

CREATE TABLE IF NOT EXISTS expense_tracker.users (
	id_user SERIAL PRIMARY KEY,
	user_login varchar(25) NOT NULL,
	user_name varchar(50) NOT NULL,
	user_password varchar(100) NOT NULL,
	password_salt varchar(100) NOT NULL,
	active boolean DEFAULT true NOT NULL,
	insert_date timestamp DEFAULT CURRENT_TIMESTAMP,
	update_date timestamp DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO expense_tracker.users (user_login, user_name, user_password, password_salt)
VALUES ('aneta', 'Aneta', '$i1neh4$10', 'qwerty');

/* transactions */
DROP TABLE IF EXISTS expense_tracker.transactions CASCADE;

CREATE TABLE IF NOT EXISTS expense_tracker.transactions (
	id_transaction SERIAL PRIMARY KEY,
	id_trans_ba int,
	id_trans_cat int,
	id_trans_subcat int,
	id_trans_type int,
	id_user int,
	transaction_date date DEFAULT current_date,
	transaction_value numeric(9, 2),
	transaction_description text,
	insert_date timestamp DEFAULT CURRENT_TIMESTAMP,
	update_date timestamp DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY (id_trans_ba) REFERENCES expense_tracker.transaction_bank_accounts (id_trans_ba),
	FOREIGN KEY (id_trans_cat) REFERENCES expense_tracker.transaction_category (id_trans_cat),
	FOREIGN KEY (id_trans_subcat) REFERENCES expense_tracker.transaction_subcategory (id_trans_subcat),
	FOREIGN KEY (id_trans_type) REFERENCES expense_tracker.transaction_type (id_trans_type),
	FOREIGN KEY (id_user) REFERENCES expense_tracker.users (id_user)
);

INSERT INTO expense_tracker.transactions (id_trans_ba, id_trans_cat, id_trans_subcat, id_trans_type, id_user, transaction_value, transaction_description)
VALUES (1, 1, 1, 1, 1, 88.96, 'Obiad w restauracji');


/* 3 */
pg_dump --host localhost ^
        --port 5432 ^
        --username postgres ^
        --format plain ^
        --file "C:\SQL\PostgreSQL_dump\expense_tracker_pr.sql" ^
		--clean ^
        postgres


psql -U postgres -p 5432 -h localhost -d postgres -f "C:\SQL\PostgreSQL_dump\expense_tracker_pr.sql"