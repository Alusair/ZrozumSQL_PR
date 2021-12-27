/* Moduł 12 – Tips & Tricks – PROJEKT */

/* 1 */
CREATE EXTENSION pgcrypto;

SELECT * FROM expense_tracker.users;

ALTER TABLE  expense_tracker.users DROP COLUMN password_salt;

UPDATE expense_tracker.users SET user_password = crypt(user_password, gen_salt('md5'));

/* 2a */
/* Sprawdzenie które z tabel należących do schematu expense_tracker posiadają ograniczenie typu FOREIGN KEY - klucz obcy */
SELECT table_name, 
	count(*) AS number_F_key
	FROM information_schema.table_constraints  
		WHERE constraint_type = 'FOREIGN KEY' AND table_schema = 'expense_tracker'
		GROUP BY table_name;

/* Policzenie dla każdej z tabeli która posiada klucz obcy liczbę elementów z wartością -1 lub <unknown> */
SELECT COUNT(*) AS number_F_key_null,
		'bank_account_types' AS table_name
		FROM expense_tracker.bank_account_types
		WHERE ba_type = '-1' OR ba_type = '<unknown>'
UNION
SELECT COUNT(*),
		'transaction_bank_accounts'
		FROM expense_tracker.transaction_bank_accounts
		WHERE id_ba_own = '-1' OR id_ba_typ = '-1'
UNION
SELECT COUNT(*),
		'transaction_subcategory'
		FROM expense_tracker.transaction_subcategory
		WHERE id_trans_cat = '-1'
UNION
SELECT COUNT(*),
		'transactions'
		FROM expense_tracker.transactions
		WHERE id_trans_ba = '-1'
		OR id_trans_cat = '-1'
		OR id_trans_subcat = '-1'
		OR id_trans_type = '-1'
		OR id_user = '-1'

/* Sprawdzenie dla których kluczy obcych w tabeli transactions występuje najwięcej wartości -1 */ 
SELECT COUNT(*) AS number_f_key_null,
		'id_trans_ba' AS id_name
		FROM expense_tracker.transactions
		WHERE id_trans_ba = '-1'
UNION
SELECT COUNT(*),
		'id_trans_cat'
		FROM expense_tracker.transactions
		WHERE id_trans_cat = '-1'
UNION
SELECT COUNT(*),
		'id_trans_subcat'
		FROM expense_tracker.transactions
		WHERE id_trans_subcat = '-1'
UNION
SELECT COUNT(*),
		'id_trans_type'
		FROM expense_tracker.transactions
		WHERE id_trans_type = '-1'
UNION
SELECT COUNT(*),
		'id_user'
		FROM expense_tracker.transactions
		WHERE id_user = '-1'
				
SELECT *
		FROM expense_tracker.transactions
		WHERE id_trans_subcat = '-1'

/* 2b */
/* Liczba pustych elementów dla każdej z kolumn z tabeli transactions */
SELECT COUNT(*) AS number_of_null,
	'id_transaction' AS column_name
	FROM expense_tracker.transactions
	WHERE id_transaction IS NULL
UNION
SELECT COUNT(*),
	'id_trans_ba'
	FROM expense_tracker.transactions
	WHERE id_trans_ba IS NULL
UNION
SELECT COUNT(*),
	'id_trans_cat'
	FROM expense_tracker.transactions
	WHERE id_trans_cat IS NULL
UNION
SELECT COUNT(*),
	'id_trans_subcat'
	FROM expense_tracker.transactions
	WHERE id_trans_subcat IS NULL
UNION
SELECT COUNT(*),
	'id_trans_type'
	FROM expense_tracker.transactions
	WHERE id_trans_type IS NULL
UNION
SELECT COUNT(*),
	'id_user'
	FROM expense_tracker.transactions
	WHERE id_user IS NULL
UNION
SELECT COUNT(*),
	'transaction_date'
	FROM expense_tracker.transactions
	WHERE transaction_date IS NULL
UNION
SELECT COUNT(*),
	'transaction_value'
	FROM expense_tracker.transactions
	WHERE transaction_value IS NULL
UNION
SELECT COUNT(*),
	'transaction_description'
	FROM expense_tracker.transactions
	WHERE transaction_description IS NULL
UNION
SELECT COUNT(*),
	'insert_date'
	FROM expense_tracker.transactions
	WHERE insert_date IS NULL
UNION
SELECT COUNT(*),
	'update_date'
	FROM expense_tracker.transactions
	WHERE update_date IS NULL
	
SELECT *,
	'id_user'
	FROM expense_tracker.transactions
	WHERE id_user IS NULL

/* Liczba wszystkich pustych elementów w porównaniu do liczby wszystkich elementów w tabeli transactions */
WITH counting_records AS (
SELECT COUNT(*) * 
(SELECT COUNT(*)
	FROM INFORMATION_SCHEMA.COLUMNS
	WHERE table_schema = 'expense_tracker' 
	AND table_name = 'transactions') AS all_records,
	SUM(CASE WHEN id_transaction IS NULL THEN 1 ELSE 0 END) + 
	SUM(CASE WHEN id_trans_ba IS NULL THEN 1 ELSE 0 END) +
	SUM(CASE WHEN id_trans_cat IS NULL THEN 1 ELSE 0 END) +
	SUM(CASE WHEN id_trans_subcat IS NULL THEN 1 ELSE 0 END) +
	SUM(CASE WHEN id_trans_type IS NULL THEN 1 ELSE 0 END) +
	SUM(CASE WHEN id_user IS NULL THEN 1 ELSE 0 END) +
	SUM(CASE WHEN transaction_date IS NULL THEN 1 ELSE 0 END) +
	SUM(CASE WHEN transaction_value  IS NULL THEN 1 ELSE 0 END) +
	SUM(CASE WHEN transaction_description IS NULL THEN 1 ELSE 0 END) +
	SUM(CASE WHEN insert_date IS NULL THEN 1 ELSE 0 END) +
	SUM(CASE WHEN update_date IS NULL THEN 1 ELSE 0 END) null_records
FROM expense_tracker.transactions 
) SELECT null_records,
		all_records,
		null_records::float/all_records::float * 100 AS percent_of_null_records
		FROM counting_records
		
/* 3 */
/*Zastanów się i rozpisz w kilku krokach, Twoje podejście do wykorzystania
przygotowanego schematu, jako rzeczywistego elementu aplikacji.
Wymagania:
 - Korzysta z niej wiele rodzin / osób (czy trzymasz wszystko w jednym schemacie / czy schemat per użytkownik (rodzina) ?) 
 - Jak zarządzasz użytkownikami i hasłami? 
 - Jak wykorzystasz wnioski z poprzednich modułów (które tabele, klucze obce zostają / nie zostają, jak podejdziesz do wydajności itd.) */
 
 /* - Dla każdej rodziny tworzony jest nowy schemat
	- Użytkownicy przechowywani są w odpowiedniej tabeli users, hasła są szyfrowane np. za pomocą rozszerzenia pgcrypto, sól do haseł generowana za pomocą funkcji, nie przechowywana w tabeli
	- Modyfikacje schematu:
		- wszystkie tabele oraz klucze obce zostają,
		- w tabeli users usunę kolumnę password_salt - bezpieczniej generować ją wykorzystując do tego odpowienią funkcję,
		- partcjonowanie tabeli transactions ze względu na rok transakcji,
		- utworzenie indeksów:
			- transaction_subcategory - subcategory_name,
			- transaction_category - category_name,
			- transaction_bank_accounts - bank_account_name,
			- bank_account_owner - owner_name,
			- transactions - extract(year from transaction_date)
		- utworzenie funkcji na tabeli transactions.
	Modyfikacje schematu wykonam na swoim skrypcie z modułu 5
	
/* Skrypt z modułu 5 */
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

/* users */
DROP TABLE IF EXISTS expense_tracker.users CASCADE;

CREATE TABLE IF NOT EXISTS expense_tracker.users (
	id_user SERIAL PRIMARY KEY,
	user_login varchar(25) NOT NULL,
	user_name varchar(50) NOT NULL,
	user_password varchar(100) NOT NULL,
	active boolean DEFAULT true NOT NULL,
	insert_date timestamp DEFAULT CURRENT_TIMESTAMP,
	update_date timestamp DEFAULT CURRENT_TIMESTAMP
);

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

/* Partycjonowanie tabeli transactions */
CREATE TABLE transactions_2015 PARTITION OF expense_tracker.transactions
	FOR VALUES FROM ('2015-01-01') TO ('2016-01-01'); 

CREATE TABLE transactions_2016 PARTITION OF expense_tracker.transactions
	FOR VALUES FROM ('2016-01-01') TO ('2017-01-01'); 

CREATE TABLE transactions_2017 PARTITION OF expense_tracker.transactions
	FOR VALUES FROM ('2017-01-01') TO ('2018-01-01'); 

CREATE TABLE transactions_2018 PARTITION OF expense_tracker.transactions
	FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');

CREATE TABLE transactions_2019 PARTITION OF expense_tracker.transactions
	FOR VALUES FROM ('2019-01-01') TO ('2020-01-01');
	
CREATE TABLE transactions_2020 PARTITION OF expense_tracker.transactions
	FOR VALUES FROM ('2020-01-01') TO ('2021-01-01');

CREATE TABLE transactions_2021 PARTITION OF expense_tracker.transactions
	FOR VALUES FROM ('2021-01-01') TO ('2022-01-01');
	
/* Utworzenie odpowiednich indeksów */
CREATE INDEX idx_subcat_subcat_name ON expense_tracker.transaction_subcategory (subcategory_name);
CREATE INDEX idx_cat_cat_name ON expense_tracker.transaction_category (category_name);
CREATE INDEX idx_tba_bank_acc_name ON expense_tracker.transaction_bank_accounts (bank_account_name);
CREATE INDEX idx_bao_owner_name ON expense_tracker.bank_account_owner (owner_name);
CREATE INDEX idx_trans_year ON expense_tracker.transactions (extract(year from transaction_date));

/* Utworzenie funkcji */
/* Liczba transakcji w wybranym roku */
CREATE OR REPLACE FUNCTION count_of_transactions_for_year(y integer)  
	RETURNS integer
	LANGUAGE plpgsql
	AS $$	
		DECLARE count_t integer;
		BEGIN
			SELECT count(*) INTO count_t
			  FROM expense_tracker.transactions 
			 WHERE EXTRACT(YEAR FROM transaction_date) = y;

			RETURN count_t;
		END
	$$;
 
SELECT count_of_transactions_for_year(2019)

/* Suma wartości transakcji w wybranym roku */
CREATE OR REPLACE FUNCTION sum_of_transactions_for_year(y integer)  
	RETURNS float
	LANGUAGE plpgsql
	AS $$	
		DECLARE sum_t integer;
		BEGIN
			SELECT sum(transaction_value) INTO sum_t
			  FROM expense_tracker.transactions 
			 WHERE EXTRACT(YEAR FROM transaction_date) = y;

			RETURN sum_t;
		END
	$$;
SELECT sum_of_transactions_for_year(2019)

/* Liczba transakcji w wybranym roku w podziale na kategorie oraz podkategorie */
CREATE OR REPLACE FUNCTION count_of_transactions_for_year_cat_subcat(y integer)  
	RETURNS TABLE (category_name text, subcategory_name text, count_t bigint)
	LANGUAGE sql
	AS $$	
			SELECT tc.category_name,
			ts.subcategory_name,
			count(t.*)
				FROM expense_tracker.transactions t
				JOIN expense_tracker.transaction_category tc
				ON t.id_trans_cat = tc.id_trans_cat
				JOIN expense_tracker.transaction_subcategory ts
				ON t.id_trans_subcat = ts.id_trans_subcat
				WHERE EXTRACT(YEAR FROM t.transaction_date) = y
				GROUP BY tc.category_name, ts.subcategory_name
				ORDER BY count(t.*) DESC;
	$$;

SELECT count_of_transactions_for_year_cat_subcat(2019)