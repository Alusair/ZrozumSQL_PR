/* Moduł 11 – Wydajność – PROJEKT */


EXPLAIN ANALYZE
SELECT t.id_transaction, t.transaction_date, tc.category_name 
	FROM expense_tracker.transactions t 
	JOIN expense_tracker.transaction_category tc ON t.id_trans_cat = tc.id_trans_cat 
	WHERE EXTRACT(YEAR FROM t.transaction_date) = '2016' 
	AND tc.category_name = 'JEDZENIE' 
	AND t.id_trans_subcat = (SELECT id_trans_subcat FROM expense_tracker.transaction_subcategory WHERE subcategory_name = 'Owoce');

/* Przed:
Planning Time: 6.157 ms
Execution Time: 7.248 ms */

/* Po:
Planning Time: 2.736 ms
Execution Time: 0.412 ms */

EXPLAIN ANALYZE
SELECT tc.category_name, sum(t.transaction_value)
	FROM expense_tracker.transactions t 
	JOIN expense_tracker.transaction_category tc
	ON t.id_trans_cat = tc.id_trans_cat
	JOIN expense_tracker.transaction_bank_accounts tba
	ON t.id_trans_ba = tba.id_trans_ba
	JOIN expense_tracker.bank_account_owner bao
	ON tba.id_ba_own = bao.id_ba_own
	WHERE tc.category_name = 'UŻYWKI'
	AND bao.owner_name = 'Janusz Kowalski'
	AND tba.bank_account_name = 'ROR - Janusz'
	AND EXTRACT(YEAR FROM t.transaction_date) = '2020'
	GROUP BY tc.category_name;
	
/* Przed:
Planning Time: 5.440 ms
Execution Time: 2.456 ms */

/* Po:
Planning Time: 1.386 ms
Execution Time: 0.204 ms */

EXPLAIN ANALYZE
SELECT t.id_transaction,
	t.transaction_date,
    LAST_VALUE(t.transaction_date) OVER (ORDER BY t.transaction_date 
                                        GROUPS BETWEEN CURRENT ROW AND 1 FOLLOWING 
                                            EXCLUDE CURRENT ROW) as next_technology_transaction,
    LAST_VALUE(t.transaction_date) OVER (ORDER BY t.transaction_date 
                                        GROUPS BETWEEN CURRENT ROW AND 1 FOLLOWING 
                                           EXCLUDE CURRENT ROW) - t.transaction_date AS days_since_previous_tech_transaction,
	t.transaction_value, 
	t.transaction_description
	FROM expense_tracker.transactions t 
	JOIN expense_tracker.transaction_type tt 
	ON t.id_trans_type =tt.id_trans_type
	JOIN expense_tracker.transaction_subcategory ts 
	ON ts.id_trans_subcat=t.id_trans_subcat
	JOIN expense_tracker.transaction_bank_accounts tba 
	ON t.id_trans_ba =tba.id_trans_ba
	JOIN expense_tracker.bank_account_types bat 
	ON bat.id_ba_type=tba.id_ba_typ
	JOIN expense_tracker.bank_account_owner bao 
	ON bao.id_ba_own=bat.id_ba_own
	WHERE 
		EXTRACT (quarter FROM t.transaction_date) = 1 
		AND EXTRACT (year FROM t.transaction_date)= 2020 
		AND tt.transaction_type_name = 'Obciążenie' 
		AND ts.subcategory_name = 'Technologie' 
		AND bat.ba_type = 'ROR'  
		AND bao.owner_name = 'Janusz Kowalski';
		
/* Przed:
Planning Time: 5.113 ms 
Execution Time: 4.576 ms */

/* Po:
Planning Time: 0.375 ms
Execution Time: 2.539 ms */

/* Utworzone indeksy: */
CREATE INDEX idx_subcat_subcat_name ON expense_tracker.transaction_subcategory (subcategory_name);
CREATE INDEX idx_cat_cat_name ON expense_tracker.transaction_category (category_name);
CREATE INDEX idx_tba_bank_acc_name ON expense_tracker.transaction_bank_accounts (bank_account_name);
CREATE INDEX idx_trans_year ON expense_tracker.transactions (extract(year from transaction_date));


/* Utworzenie widoku */

CREATE  MATERIALIZED VIEW view_JK AS 
SELECT t.id_transaction,
	t.transaction_date,
    LAST_VALUE(t.transaction_date) OVER (ORDER BY t.transaction_date 
                                        GROUPS BETWEEN CURRENT ROW AND 1 FOLLOWING 
                                            EXCLUDE CURRENT ROW) as next_technology_transaction,
    LAST_VALUE(t.transaction_date) OVER (ORDER BY t.transaction_date 
                                        GROUPS BETWEEN CURRENT ROW AND 1 FOLLOWING 
                                           EXCLUDE CURRENT ROW) - t.transaction_date AS days_since_previous_tech_transaction,
	t.transaction_value, 
	t.transaction_description
	FROM expense_tracker.transactions t 
	JOIN expense_tracker.transaction_type tt 
	ON t.id_trans_type =tt.id_trans_type
	JOIN expense_tracker.transaction_subcategory ts 
	ON ts.id_trans_subcat=t.id_trans_subcat
	JOIN expense_tracker.transaction_bank_accounts tba 
	ON t.id_trans_ba =tba.id_trans_ba
	JOIN expense_tracker.bank_account_types bat 
	ON bat.id_ba_type=tba.id_ba_typ
	JOIN expense_tracker.bank_account_owner bao 
	ON bao.id_ba_own=bat.id_ba_own
	WHERE 
		EXTRACT (quarter FROM t.transaction_date) = 1 
		AND EXTRACT (year FROM t.transaction_date)= 2020 
		AND tt.transaction_type_name = 'Obciążenie' 
		AND ts.subcategory_name = 'Technologie' 
		AND bat.ba_type = 'ROR'  
		AND bao.owner_name = 'Janusz Kowalski';

EXPLAIN ANALYZE
SELECT * FROM view_JK;

/* Przed:
Planning Time: 5.113 ms 
Execution Time: 4.576 ms */

/* Po:
Planning Time: 0.033 ms
Execution Time: 0.016 ms
*/


/* Partycjonowanie */
CREATE TABLE IF NOT EXISTS expense_tracker.transactions_partittioned(
	id_transaction serial ,
	id_trans_ba integer references expense_tracker.transaction_bank_accounts (id_trans_ba), 
	id_trans_cat integer references expense_tracker.transaction_category (id_trans_cat),
	id_trans_subcat integer references expense_tracker.transaction_subcategory (id_trans_subcat),
	id_trans_type integer references expense_tracker.transaction_type (id_trans_type),
 	id_user integer references expense_tracker.users (id_user),
	transaction_date date DEFAULT current_date,
	transaction_value NUMERIC(9,2),
	transaction_description TEXT,
	insert_date timestamp DEFAULT current_timestamp,
	update_date timestamp DEFAULT current_timestamp,
	primary key (id_transaction, transaction_date)
) PARTITION BY RANGE(transaction_date);

CREATE TABLE transactions_2015 PARTITION OF expense_tracker.transactions_partittioned 
	FOR VALUES FROM ('2015-01-01') TO ('2016-01-01'); 

CREATE TABLE transactions_2016 PARTITION OF expense_tracker.transactions_partittioned 
	FOR VALUES FROM ('2016-01-01') TO ('2017-01-01'); 

CREATE TABLE transactions_2017 PARTITION OF expense_tracker.transactions_partittioned 
	FOR VALUES FROM ('2017-01-01') TO ('2018-01-01'); 

CREATE TABLE transactions_2018 PARTITION OF expense_tracker.transactions_partittioned 
	FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');

CREATE TABLE transactions_2019 PARTITION OF expense_tracker.transactions_partittioned 
	FOR VALUES FROM ('2019-01-01') TO ('2020-01-01');
	
	
EXPLAIN ANALYZE
INSERT INTO expense_tracker.transactions_partittioned
SELECT id_transaction , id_trans_ba , id_trans_cat, id_trans_subcat, id_trans_type ,
 	id_user , transaction_date , transaction_value , transaction_description , insert_date , update_date
FROM expense_tracker.transactions
WHERE transaction_date BETWEEN '2015-01-01' AND '2019-12-31';

/* Execution Time: 219.516 ms */


EXPLAIN ANALYZE
SELECT t.id_transaction, t.transaction_date, tc.category_name 
	FROM expense_tracker.transactions t 
	JOIN expense_tracker.transaction_category tc ON t.id_trans_cat = tc.id_trans_cat 
	WHERE t.transaction_date BETWEEN '2017-04-01' AND '2017-06-30'
	AND tc.category_name = 'JEDZENIE';
	
/* Planning Time: 0.264 ms
Execution Time: 0.952 ms */

EXPLAIN ANALYZE
SELECT t.id_transaction, t.transaction_date, tc.category_name 
	FROM expense_tracker.transactions_partittioned  t 
	JOIN expense_tracker.transaction_category tc ON t.id_trans_cat = tc.id_trans_cat 
	WHERE t.transaction_date BETWEEN '2017-04-01' AND '2017-06-30'
	AND tc.category_name = 'JEDZENIE';
	
/* Planning Time: 0.171 ms
Execution Time: 0.246 ms */