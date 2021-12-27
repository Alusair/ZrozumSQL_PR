/* Moduł 8 – Funkcje Grupujące i Analityczne – PROJEKT */

/* 1 */
SELECT tc.category_name, sum(t.transaction_value) 
	FROM expense_tracker.transactions t 
	JOIN expense_tracker.transaction_category tc
	ON t.id_trans_cat = tc.id_trans_cat
	GROUP BY tc.category_name;
	
/* 2 */ 
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
	
/* 3 */
SELECT EXTRACT(YEAR FROM t.transaction_date) transaction_year,
		(EXTRACT(YEAR FROM t.transaction_date) || '-' || EXTRACT(QUARTER FROM t.transaction_date)) transaction_year_quarter,
		(EXTRACT(YEAR FROM t.transaction_date) || '-' || EXTRACT(MONTH FROM t.transaction_date)) transaction_year_month,
		GROUPING(EXTRACT(YEAR FROM t.transaction_date),
		(EXTRACT(YEAR FROM t.transaction_date) || '-' || EXTRACT(MONTH FROM t.transaction_date)),
				EXTRACT(YEAR FROM t.transaction_date) || '-' || EXTRACT(QUARTER FROM t.transaction_date)),
		sum(t.transaction_value)
	FROM expense_tracker.transactions t
	JOIN expense_tracker.transaction_type tt
	ON t.id_trans_type = tt.id_trans_type
	JOIN expense_tracker.bank_account_types bat
	ON t.id_trans_ba = bat.id_ba_type
	WHERE tt.transaction_type_name = 'Obciążenie'
    AND bat.ba_type = 'ROR - WSPÓLNY'
	AND EXTRACT(YEAR FROM t.transaction_date) = 2019
GROUP BY ROLLUP (EXTRACT(YEAR FROM t.transaction_date),
				EXTRACT(YEAR FROM t.transaction_date) || '-' || EXTRACT(QUARTER FROM t.transaction_date),
				EXTRACT(YEAR FROM t.transaction_date) || '-' || EXTRACT(MONTH FROM t.transaction_date))
ORDER BY 1,2,3

/* 4 */
SELECT EXTRACT (YEAR FROM t.transaction_date) year_sal,
       sum(t.transaction_value) total_sales,
	   lag(sum(t.transaction_value)) OVER (ORDER BY EXTRACT (YEAR FROM t.transaction_date)) previous_year_sales,
       sum(t.transaction_value) - lag(sum(t.transaction_value)) OVER (ORDER BY EXTRACT (YEAR FROM t.transaction_date)) balance_yoy
  FROM expense_tracker.transactions t
  JOIN (SELECT * 
          FROM expense_tracker.transaction_bank_accounts tba 
         WHERE id_ba_own = 3 AND id_ba_typ = 5) sub1 ON t.id_trans_ba = sub1.id_trans_ba
  JOIN (SELECT * 
           FROM expense_tracker.transaction_type tt WHERE tt.transaction_type_name LIKE '%bciążenie%') sub2 ON t.id_trans_type = sub2.id_trans_type
WHERE EXTRACT (YEAR FROM t.transaction_date) >= 2015
GROUP BY year_sal;

/* 5 */
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
	
	
	
SELECT t.id_transaction, t.transaction_date, tt.transaction_type_name, ts.subcategory_name, bat.ba_type, bao.owner_name
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
	