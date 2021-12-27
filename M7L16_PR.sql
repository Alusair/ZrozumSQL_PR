/* Moduł 7 Złączenia - JOINS – PROJEKT */

/* 1 */
SELECT bao.owner_name, bao.owner_desc, bao.active, bao.user_login, bat.ba_type, bat.ba_desc 
	FROM expense_tracker.bank_account_owner bao 
	JOIN expense_tracker.bank_account_types bat ON bao.id_ba_own = bat.id_ba_own 
	WHERE bao.owner_name = 'Janusz Kowalski';

/* 2 */
SELECT tc.category_name, ts.subcategory_name 
	FROM expense_tracker.transactiON_category tc 
	JOIN expense_tracker.transactiON_subcategory ts ON tc.id_trans_cat = ts.id_trans_cat 
	WHERE tc.active = '1' 
	AND ts.active = '1' 
	ORDER BY tc.id_trans_cat ASC;

/* 3 */
SELECT t.id_transaction, t.transaction_date, tc.category_name 
	FROM expense_tracker.transactions t 
	JOIN expense_tracker.transaction_category tc ON t.id_trans_cat = tc.id_trans_cat 
	WHERE EXTRACT(YEAR FROM t.transaction_date) = '2016' 
	AND tc.category_name = 'JEDZENIE';

/* 4 */ 
WITH transactions_jedzenie_2016 AS
	(SELECT t.id_transaction 
		FROM expense_tracker.transactions t 
		JOIN expense_tracker.transaction_category tc ON t.id_trans_cat = tc.id_trans_cat 
		WHERE EXTRACT(YEAR FROM t.transaction_date) = '2016' 
		AND tc.category_name = 'JEDZENIE' 
		AND t.id_trans_subcat = -1)
	UPDATE expense_tracker.transactions t
	SET id_trans_subcat = (SELECT id_trans_subcat FROM expense_tracker.transaction_subcategory WHERE subcategory_name = 'Owoce')
	WHERE EXISTS (SELECT 1
		FROM transactions_jedzenie_2016
		WHERE transactions_jedzenie_2016.id_transaction = t.id_transaction);


SELECT t.id_transaction, t.transaction_date, tc.category_name 
	FROM expense_tracker.transactions t 
	JOIN expense_tracker.transaction_category tc ON t.id_trans_cat = tc.id_trans_cat 
	WHERE EXTRACT(YEAR FROM t.transaction_date) = '2016' 
	AND tc.category_name = 'JEDZENIE' 
	AND t.id_trans_subcat = (SELECT id_trans_subcat FROM expense_tracker.transaction_subcategory WHERE subcategory_name = 'Owoce');

/* /* 5 */ 
SELECT tc.category_name, ts.subcategory_name, tt.transaction_type_name, t.transaction_date, t.transaction_value 
	FROM expense_tracker.transactions t 
	LEFT JOIN expense_tracker.transaction_type tt ON t.id_trans_type = tt.id_trans_type 
	LEFT JOIN expense_tracker.transaction_category tc ON t.id_trans_cat = tc.id_trans_cat 
	LEFT JOIN expense_tracker.transaction_subcategory ts ON t.id_trans_subcat = ts.id_trans_subcat 
	LEFT JOIN expense_tracker.transaction_bank_accounts tba ON t.id_trans_ba = tba.id_trans_ba 
	LEFT JOIN expense_tracker.bank_account_owner bao ON tba.id_ba_own = bao.id_ba_own 
	WHERE bao.owner_name = 'Janusz i Grażynka'

