/* Moduł 9 – Pozostałe Struktury Danych – PROJEKT */

/* 1 */

CREATE OR REPLACE VIEW Janusz_transactions AS
	SELECT tc.category_name,
			ts.subcategory_name,
			tt.transaction_type_name,
			t.transaction_date,
			EXTRACT(YEAR FROM t.transaction_date) AS transaction_year,
			t.transaction_value,
			bat.ba_type
			FROM expense_tracker.transactions t
			JOIN expense_tracker.transaction_category tc
			ON t.id_trans_cat = tc.id_trans_cat
			JOIN expense_tracker.transaction_subcategory ts
			ON t.id_trans_subcat = ts.id_trans_subcat
			JOIN expense_tracker.transaction_type tt
			ON t.id_trans_type = tt.id_trans_type
			JOIN expense_tracker.transaction_bank_accounts tba
			ON t.id_trans_ba = tba.id_trans_ba
			JOIN expense_tracker.bank_account_types bat
			ON tba.id_ba_typ = bat.id_ba_type
			JOIN expense_tracker.bank_account_owner bao
			ON tba.id_ba_own = bao.id_ba_own
			WHERE bao.owner_name = 'Janusz Kowalski'; 
			
CREATE OR REPLACE VIEW Janusz_i_Grazynka_transactions AS
	SELECT tc.category_name,
			ts.subcategory_name,
			tt.transaction_type_name,
			t.transaction_date,
			EXTRACT(YEAR FROM t.transaction_date) AS transaction_year,
			t.transaction_value,
			bat.ba_type
			FROM expense_tracker.transactions t
			JOIN expense_tracker.transaction_category tc
			ON t.id_trans_cat = tc.id_trans_cat
			JOIN expense_tracker.transaction_subcategory ts
			ON t.id_trans_subcat = ts.id_trans_subcat
			JOIN expense_tracker.transaction_type tt
			ON t.id_trans_type = tt.id_trans_type
			JOIN expense_tracker.transaction_bank_accounts tba
			ON t.id_trans_ba = tba.id_trans_ba
			JOIN expense_tracker.bank_account_types bat
			ON tba.id_ba_typ = bat.id_ba_type
			JOIN expense_tracker.bank_account_owner bao
			ON tba.id_ba_own = bao.id_ba_own
			WHERE bao.owner_name = 'Janusz i Grażynka'; 
			
CREATE OR REPLACE VIEW Grazyna_transactions AS
	SELECT tc.category_name,
			ts.subcategory_name,
			tt.transaction_type_name,
			t.transaction_date,
			EXTRACT(YEAR FROM t.transaction_date) AS transaction_year,
			t.transaction_value,
			bat.ba_type
			FROM expense_tracker.transactions t
			JOIN expense_tracker.transaction_category tc
			ON t.id_trans_cat = tc.id_trans_cat
			JOIN expense_tracker.transaction_subcategory ts
			ON t.id_trans_subcat = ts.id_trans_subcat
			JOIN expense_tracker.transaction_type tt
			ON t.id_trans_type = tt.id_trans_type
			JOIN expense_tracker.transaction_bank_accounts tba
			ON t.id_trans_ba = tba.id_trans_ba
			JOIN expense_tracker.bank_account_types bat
			ON tba.id_ba_typ = bat.id_ba_type
			JOIN expense_tracker.bank_account_owner bao
			ON tba.id_ba_own = bao.id_ba_own
			WHERE bao.owner_name = 'Grażyna Kowalska'; 
			
/* 2 */
SELECT transaction_year,
		transaction_type_name,
		category_name,
		array_agg(DISTINCT subcategory_name) AS subcategory_list,
		sum(transaction_value)
		FROM Janusz_i_Grazynka_transactions
		GROUP BY transaction_year, transaction_type_name, category_name;
	
/* 3 */
CREATE TABLE IF NOT EXISTS expense_tracker.monthly_budget_planned (
	year_month VARCHAR(7) PRIMARY KEY,
	budget_planned NUMERIC(10, 2),
	left_budget NUMERIC(10, 2)
);

INSERT INTO expense_tracker.monthly_budget_planned (year_month, budget_planned, left_budget)
	VALUES ('2021-12', 1250, 1250);
	
SELECT * FROM expense_tracker.monthly_budget_planned;

/* 4 */
DROP FUNCTION transaction_budget CASCADE;
CREATE FUNCTION transaction_budget() 
   RETURNS TRIGGER 
   LANGUAGE plpgsql
	AS $$
		BEGIN
	        IF (TG_OP = 'DELETE') THEN 
		 		UPDATE expense_tracker.monthly_budget_planned  SET left_budget = left_budget - OLD.transaction_value
		  		WHERE expense_tracker.monthly_budget_planned.year_month = (EXTRACT ( YEAR FROM OLD.transaction_date) ||'-'||  EXTRACT (MONTH FROM OLD.transaction_date));
			ELSIF (TG_OP = 'UPDATE') THEN 
		  		UPDATE expense_tracker.monthly_budget_planned  SET left_budget = left_budget - OLD.transaction_value + NEW.transaction_value
		  		WHERE expense_tracker.monthly_budget_planned.year_month = (EXTRACT ( YEAR FROM  OLD.transaction_date) ||'-'||  EXTRACT (MONTH FROM OLD.transaction_date));
			ELSIF (TG_OP = 'INSERT') THEN 
		  		UPDATE expense_tracker.monthly_budget_planned  SET left_budget = left_budget + NEW.transaction_value
		  		WHERE expense_tracker.monthly_budget_planned.year_month = (EXTRACT ( YEAR FROM NEW.transaction_date) ||'-'||  EXTRACT (MONTH FROM NEW.transaction_date));
			END IF;
	        RETURN NULL; -- rezultat zignoruj
		END;
	$$;
		
CREATE TRIGGER transaction_budget_trigger 
	AFTER INSERT OR UPDATE OR DELETE
   	ON expense_tracker.transactions
	FOR EACH ROW 
    EXECUTE PROCEDURE transaction_budget();
	
SELECT * FROM expense_tracker.monthly_budget_planned

INSERT INTO expense_tracker.transactions (id_trans_ba, id_trans_cat, id_trans_subcat, id_trans_type, id_user, transaction_date, transaction_value,transaction_description) 
	VALUES (1,1,4,2,null,now(),-500.00,'opis');
	
UPDATE expense_tracker.transactions SET transaction_value = -600
	WHERE id_transaction = 7118;
	
/* 5 */
/*
1. Można przekroczyć zaplanowyany miesięczny budżet bez żadnych konsewkwencji ani informacji
2. Budżet na kolejny miesiąc trzeba dodać ręcznie, wtedy można by uwzględnić pozostały bądź przekroczony budżet z poprzedniego miesiąca i odpowiednio skorygować wpisywaną wartość.
3. Tabela nie posiada klucza głównego.
4. Tabela nie rozróżnia właścicieli ani kont, jest to planowany budżet dla wszystkich transakcji. Można by rozszeżyć tę tabelę o dane dotyczące konta i właściciela.
