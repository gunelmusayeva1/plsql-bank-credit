/* =====================================================================
   AZ: Bank müştəri churn (bankı tərk etmə) layihəsi - PL/SQL şərhli versiya
   EN: Bank customer churn project - PL/SQL commented version
   ===================================================================== */


/* ---------------------------------------------------------------------
   TASK 1
   AZ: CUSTOMER_INFO - müştəri məlumatlarını saxlayan cədvəl.
   EN: CUSTOMER_INFO - table holding customer personal information.
--------------------------------------------------------------------- */

CREATE TABLE customer_info (cif NUMBER PRIMARY KEY,           -- AZ: müştərinin unikal identifikatoru (əsas açar) | EN: unique customer identifier (primary key)
                            NAME VARCHAR2(20),                  -- AZ: adı | EN: first name
                            surname VARCHAR2(30),                -- AZ: soyadı | EN: last name
                            gender VARCHAR2(3),                  -- AZ: cinsi | EN: gender
                            age NUMBER,                          -- AZ: yaşı | EN: age
                            job VARCHAR2(30),                    -- AZ: peşəsi | EN: job
                            marital VARCHAR2(20),                -- AZ: ailə vəziyyəti | EN: marital status
                            education VARCHAR2(20),              -- AZ: təhsili | EN: education
                            country VARCHAR2(30));               -- AZ: ölkəsi | EN: country

SELECT * FROM customer_info FOR UPDATE;      -- AZ: cədvəldəki sətirləri kilidləyərək seçir (dəyişiklik üçün hazırlıq) | EN: selects rows with a lock, preparing them for update


/* ---------------------------------------------------------------------
   TASK 2
   AZ: Customer_churn_info cədvəlini yaratmaq. Bank churn etmiş (bankı
       tərk etmiş) müştərilər üçün kampaniya aparmaq, kreditvermə
       şərtləri üzərində işləmək istəyir. Datanı FOR UPDATE ilə cədvələ
       daxil etmək.
   EN: Create the Customer_churn_info table. The bank wants to run
       campaigns for churned (departed) customers and work on their
       lending terms. Data is selected with FOR UPDATE.
--------------------------------------------------------------------- */

CREATE TABLE customer_churn_info (customer_id NUMBER PRIMARY KEY,  -- AZ: müştəri ID-si (əsas açar) | EN: customer id (primary key)
                                  credit_score NUMBER,               -- AZ: kredit reytinqi (skoru) | EN: credit score
                                  tenure NUMBER,                     -- AZ: bankda olma müddəti | EN: tenure with the bank
                                  balance NUMBER(12,2),              -- AZ: hesab balansı | EN: account balance
                                  products_number NUMBER,            -- AZ: istifadə etdiyi məhsul sayı | EN: number of products used
                                  credit_card NUMBER,                -- AZ: kredit kartının olub-olmaması | EN: whether they have a credit card
                                  active_member NUMBER,              -- AZ: aktiv müştəri olub-olmaması | EN: whether they are an active member
                                  estimated_salary NUMBER(12,2),     -- AZ: təxmini maaş | EN: estimated salary
                                  churn NUMBER);                     -- AZ: churn statusu (1-tərk edib, 0-etməyib) | EN: churn status (1-churned, 0-not churned)
                                  
SELECT * FROM customer_churn_info FOR UPDATE;   -- AZ: kilidləyərək seçim | EN: select with lock


/* ---------------------------------------------------------------------
   TASK 3
   AZ: Updated_list cədvəlini yaratmaq. Əgər Customer_churn_info-da
       həmin müştəri varsa, updated_list-dəki balans və churn
       məlumatlarını Customer_churn_info-nun müvafiq sütunlarına yazıb
       yeniləmək (UPDATE). Əgər updated_list-də olub Customer_churn_info-da
       olmayan sətir varsa, onu Customer_churn_info-ya əlavə etmək (INSERT).
       Bu MERGE əməliyyatı bir procedure daxilində, AUTONOMOUS_TRANSACTION
       kimi icra olunur.
   EN: Create the Updated_list table. If a customer already exists in
       Customer_churn_info, update its balance and churn columns from
       updated_list (UPDATE). If a row exists in updated_list but not
       in Customer_churn_info, insert it (INSERT). This MERGE logic
       runs inside a procedure as an AUTONOMOUS_TRANSACTION.
--------------------------------------------------------------------- */

CREATE TABLE updated_list (customer_id NUMBER PRIMARY KEY,
                                  credit_score NUMBER,
                                  tenure NUMBER,
                                  balance NUMBER(12,2),
                                  products_number NUMBER,
                                  credit_card NUMBER,
                                  active_member NUMBER,
                                  estimated_salary NUMBER(12,2),
                                  churn NUMBER);

SELECT * FROM updated_list FOR UPDATE;

CREATE OR REPLACE PROCEDURE set_sync_customer_info IS
  PRAGMA AUTONOMOUS_TRANSACTION;             -- AZ: müstəqil əməliyyat kimi işləyir, öz COMMIT-i olur | EN: runs as an independent transaction with its own COMMIT
BEGIN
  MERGE INTO customer_churn_info cci
  USING updated_list ul
  ON (cci.customer_id = ul.customer_id)      -- AZ: uyğunluq şərti - eyni customer_id | EN: match condition - same customer_id
  
  WHEN MATCHED THEN
    UPDATE SET cci.balance = ul.balance, cci.churn = ul.churn   -- AZ: uyğun sətir tapılarsa balans və churn yenilənir | EN: if matched, update balance and churn
    
  
  WHEN NOT MATCHED THEN
    INSERT                                    -- AZ: uyğun sətir yoxdursa yeni sətir əlavə olunur | EN: if not matched, insert a new row
      (customer_id,
       credit_score,
       tenure,
       balance,
       products_number,
       credit_card,
       active_member,
       estimated_salary,
       churn)
    VALUES
      (ul.customer_id,
       ul.credit_score,
       ul.tenure,
       ul.balance,
       ul.products_number,
       ul.credit_card,
       ul.active_member,
       ul.estimated_salary,
       ul.churn);
  COMMIT;
END;

BEGIN
  set_sync_customer_info;                    -- AZ: procedure-un çağırılması | EN: calling the procedure
END;


/* ---------------------------------------------------------------------
   TASK 4
   AZ: Customer_churn_info cədvəlinə Max_cre_amount sütununu əlavə
       etmək (bu sütun bir müştəriyə verilə biləcək maksimum kredit
       məbləğini göstərəcək).
   EN: Add a Max_cre_amount column to Customer_churn_info (this column
       will hold the maximum credit amount that can be offered to a
       customer).
--------------------------------------------------------------------- */

ALTER TABLE customer_churn_info
ADD max_cre_amount NUMBER;


/* ---------------------------------------------------------------------
   TASK 5
   AZ: Ən çox churn edən müştərilərin hansı cinsdən olduğunu təyin
       etmək. Nəticə SYS_REFCURSOR vasitəsilə funksiyadan qaytarılır
       və bloklarda FETCH edilərək çap olunur.
   EN: Determine which gender has the highest number of churned
       customers. The result is returned via a SYS_REFCURSOR from a
       function and fetched/printed in an anonymous block.
--------------------------------------------------------------------- */

--1 → müştəri churn edib / customer has churned
--0 → müştəri churn etməyib / customer has not churned

CREATE OR REPLACE FUNCTION get_churn_count
  RETURN SYS_REFCURSOR IS
  count_of_churn SYS_REFCURSOR;
BEGIN
  OPEN count_of_churn FOR
    SELECT ci.gender, COUNT(*) AS churn_count           -- AZ: cins üzrə churn edən müştəri sayı | EN: churned customer count per gender
      FROM customer_churn_info cci
      JOIN customer_info ci
        ON ci.cif = cci.customer_id
     WHERE churn = 1                                    -- AZ: yalnız churn edənlər | EN: only churned customers
     GROUP BY ci.gender
     ORDER BY COUNT(*) DESC
     FETCH FIRST 1 ROWS ONLY;                            -- AZ: ən çox churn edən 1 cins | EN: the single gender with the highest churn count
  RETURN count_of_churn;
END;

DECLARE
     count_of_churn SYS_REFCURSOR;
     v_gender customer_info.gender%TYPE;
     v_count NUMBER;
BEGIN
    count_of_churn := get_churn_count;                  -- AZ: funksiyanın çağırılıb kursorun alınması | EN: calling the function to get the cursor
    LOOP
       FETCH count_of_churn 
       INTO v_gender, v_count;
       EXIT WHEN count_of_churn%NOTFOUND;                -- AZ: nəticə qalmadıqda dövrdən çıxış | EN: exit loop when no more rows
       dbms_output.put_line('Gender: ' || v_gender || ' Count: ' || v_count);
    END LOOP;
    CLOSE count_of_churn;
END; 


/* ---------------------------------------------------------------------
   TASK 6
   AZ: Churn etməyən müştərilər arasından, ən az maaş alan müştərini
       çıxmaqla, ən az maaş alan növbəti 3 müştərini tapmaq
       (FETCH/OFFSET istifadə etmədən, DENSE_RANK ilə).
   EN: Among non-churned customers, excluding the single lowest-paid
       customer, find the next 3 lowest-paid customers (without using
       FETCH/OFFSET, using DENSE_RANK instead).
--------------------------------------------------------------------- */

--1 → müştəri churn edib / customer has churned
--0 → müştəri churn etməyib / customer has not churned

CREATE OR REPLACE FUNCTION get_mins_salary_list
RETURN SYS_REFCURSOR
IS
  customers_churn_list SYS_REFCURSOR;
BEGIN
  OPEN customers_churn_list FOR
  SELECT customer_id,
         estimated_salary
    FROM (SELECT cci.customer_id,
                 cci.estimated_salary,
                 dense_rank() OVER (ORDER BY estimated_salary ASC) AS dr   -- AZ: maaşa görə artan sırada reytinq | EN: rank by ascending salary
            FROM customer_churn_info cci
           WHERE churn = 0)                                                -- AZ: yalnız churn etməyənlər | EN: only non-churned customers
   WHERE dr > 1                                                            -- AZ: ən aşağı maaşlını (1-ci reytinq) çıxarır | EN: excludes the very lowest-paid (rank 1)
     AND dr <= 4;                                                          -- AZ: növbəti 3 nəfəri (2,3,4-cü reytinqləri) götürür | EN: takes the next 3 (ranks 2, 3, 4)
RETURN customers_churn_list;
END;

DECLARE
  customers_churn_list SYS_REFCURSOR;
  v_customer_id customer_churn_info.customer_id%TYPE;
  v_estimated_salary customer_churn_info.estimated_salary%TYPE;
BEGIN
  customers_churn_list := get_mins_salary_list;
  LOOP
    FETCH customers_churn_list
    INTO v_customer_id,v_estimated_salary;
    EXIT WHEN customers_churn_list%NOTFOUND;
    dbms_output.put_line('Customer_id : ' || v_customer_id);
    dbms_output.put_line('Salary: ' || v_estimated_salary);
   END LOOP;
   CLOSE customers_churn_list;
END;


/* ---------------------------------------------------------------------
   TASK 7
   AZ: Churn edən müştərilərin sayının ən çox olduğu TOP 10 ölkəni
       təyin etmək (bərabər say olduqda WITH TIES sayəsində 10-dan
       çox nəticə də ola bilər). BULK COLLECT ilə RECORD/TABLE tipli
       kolleksiyaya yığılır və dövrlə çap olunur.
   EN: Determine the TOP 10 countries with the most churned customers
       (with WITH TIES, ties can produce more than 10 rows). Results
       are BULK COLLECTed into a RECORD/TABLE collection and printed
       in a loop.
--------------------------------------------------------------------- */

DECLARE 
  TYPE type_churn_count IS RECORD (count_of_churn NUMBER,     -- AZ: ölkə üzrə churn sayını saxlayan record tipi | EN: record type holding churn count per country
                                   country customer_info.country%TYPE);
  TYPE type_count_of_churn IS TABLE OF type_churn_count;       -- AZ: record-lardan ibarət kolleksiya tipi | EN: collection type of records
  count_of_churn type_count_of_churn;
BEGIN                                          
  SELECT
    COUNT(cci.customer_id) AS count_of_churn,
    ci.country
  BULK COLLECT INTO count_of_churn                              -- AZ: nəticələr birbaşa kolleksiyaya yığılır | EN: results are bulk-collected into the collection
  FROM customer_info ci JOIN customer_churn_info cci ON (ci.cif = cci.customer_id)
  WHERE churn = 1
  GROUP BY ci.country
  ORDER BY COUNT(cci.customer_id) DESC FETCH FIRST 10 ROWS WITH ties;  
      -- AZ: ən çox churn olan 10 ölkə (bərabərlik varsa əlavə sətirlər də daxil olur)
      -- EN: top 10 countries by churn count (ties included if the 10th value repeats)
  
  FOR i IN count_of_churn.first .. count_of_churn.last LOOP
    dbms_output.put_line(count_of_churn(i).count_of_churn);
    dbms_output.put_line(count_of_churn(i).country);
  END LOOP;
END;

/* ---------------------------------------------------------------------
   TASK 8
   AZ: Churn edən müştərilərdən balansı ən çox olan TOP 10 müştərini
       tapmaq. Nəticə BULK COLLECT ilə kolleksiyaya yığılır.
   EN: Find the top 10 churned customers with the highest balance.
       Results are bulk-collected into a collection.
--------------------------------------------------------------------- */

DECLARE
  TYPE type_top_customer IS RECORD (customer_id customer_churn_info.customer_id%TYPE,
                                    balance customer_churn_info.balance%TYPE);
  TYPE top_customer_list IS TABLE OF type_top_customer;
  top_list top_customer_list;
BEGIN
  SELECT
    customer_id,
    balance
  BULK COLLECT INTO top_list
    FROM (SELECT 
            customer_id,
            balance,
            dense_rank() OVER (ORDER BY balance DESC) AS dr   -- AZ: balansa görə azalan sırada reytinq | EN: rank by descending balance
          FROM customer_churn_info
          WHERE churn = 1)                                    -- AZ: yalnız churn edənlər | EN: only churned customers
    WHERE dr <= 10;                                            -- AZ: ilk 10 reytinq | EN: top 10 ranks
    
    IF top_list.count > 0 THEN
      FOR i IN top_list.first .. top_list.last LOOP
        dbms_output.put_line(' Customer: ' || top_list(i).customer_id || 
                             ' Balance: ' || top_list(i).balance);
        END LOOP;
    END IF;
END;



/* ---------------------------------------------------------------------
   TASK 9
   AZ: Churn etmiş müştəri yenidən bankdan kredit götürmək istəyir.
       Bu müştəriyə kreditin verilmə mümkünlüyünü yoxlayan package
       qurmaq:
       1. Müştərinin skoru 500-dən aşağıdırsa, churn edibsə və
          balansı 2000-dən aşağıdırsa, kredit verilməyəcək. Bunu
          təyin edən subprogram (funksiya) yazmaq. Müştəri yoxdursa
          exception-da nəzərə almaq.
       2. AUTONOMOUS_TRANSACTION tətbiq etmək. Müştərilərin kredit
          müraciətləri credit_request cədvəlində loglanır: hansı
          müştəri, nə zaman, nə qədər məbləğ üçün müraciət edib və
          nəticə (1-müsbət, 0-mənfi).
       3. Kredit verilməsi mümkün olan müştərilərin CIF (customer_id)
          üzrə veriləcək maksimal kredit məbləğini hesablayan
          credit_offer_amount funksiyası: credit_score 1000-dən
          kiçikdirsə → balance*2; credit_score 1000-dən böyük VƏ
          balance 2000-dən çoxdursa → balance*5.
       4. Eyni məntiq, lakin müştərinin ad-soyadına görə axtarılan
          credit_offer_amount overload-u: credit_score 1000-dən
          kiçikdirsə → balance*1.5; credit_score 1000-dən böyük VƏ
          balance 2000-dən çoxdursa → balance*2.5.
   EN: A churned customer wants to take out a new loan from the bank.
       Build a package that checks whether credit can be granted:
       1. If credit_score < 500, churn = 1, and balance < 2000, credit
          is denied. Write a function for this, handling the case
          where the customer doesn't exist via an exception.
       2. Apply AUTONOMOUS_TRANSACTION. Log every credit request in
          the credit_request table: which customer, when, how much,
          and the result (1-approved, 0-denied).
       3. A credit_offer_amount function that computes the max credit
          for a customer by customer_id: if credit_score < 1000 →
          balance*2; if credit_score > 1000 AND balance > 2000 →
          balance*5.
       4. An overloaded credit_offer_amount function that computes
          the max credit by first/last name instead: if
          credit_score < 1000 → balance*1.5; if credit_score > 1000
          AND balance > 2000 → balance*2.5.
--------------------------------------------------------------------- */

CREATE TABLE credit_request (customer_id NUMBER,        -- AZ: müraciət edən müştəri | EN: requesting customer
                             sys_date DATE,               -- AZ: müraciət tarixi | EN: request date
                             amount NUMBER (10,2),         -- AZ: tələb olunan məbləğ | EN: requested amount
                             credit_result NUMBER);        -- AZ: nəticə (1-müsbət, 0-mənfi) | EN: result (1-approved, 0-denied)
                             

CREATE OR REPLACE PACKAGE check_credit_list IS
  -- AZ: müştərinin kredit alıb-almayacağını mətn şəklində qaytaran funksiya
  -- EN: function returning whether the customer qualifies for credit (as text)
  FUNCTION get_credit_list (p_customer_id customer_churn_info.customer_id%TYPE) RETURN VARCHAR2;
  
  -- AZ: kredit müraciətini yoxlayıb credit_request cədvəlində loglayan procedure
  -- EN: procedure that checks a credit request and logs it in credit_request
  PROCEDURE check_credit_request(p_customer_id IN customer_churn_info.customer_id%TYPE,
                                                                p_amount      IN NUMBER,
                                                                p_result      OUT NUMBER);
  
  -- AZ: customer_id üzrə maksimal kredit məbləğini hesablayan funksiya
  -- EN: function calculating max credit amount by customer_id
  FUNCTION credit_offer_amount (p_customer_id customer_churn_info.customer_id%TYPE) RETURN NUMBER;
  
  -- AZ: ad və soyad üzrə maksimal kredit məbləğini hesablayan overload funksiya
  -- EN: overloaded function calculating max credit amount by first/last name
  FUNCTION credit_offer_amount(p_name customer_info.name%TYPE,
                               p_surname customer_info.surname%TYPE)
  RETURN NUMBER;
  
END;
  
CREATE OR REPLACE PACKAGE BODY check_credit_list IS

FUNCTION get_credit_list (p_customer_id customer_churn_info.customer_id%TYPE) RETURN VARCHAR2
IS
customer_data customer_churn_info%ROWTYPE;
BEGIN
  SELECT *
  INTO customer_data
  FROM customer_churn_info
  WHERE customer_id = p_customer_id;
  
  IF customer_data.credit_score < 500                    -- AZ: kredit skoru aşağı | EN: low credit score
    AND customer_data.churn = 1                            -- AZ: churn edib | EN: has churned
    AND customer_data.balance < 2000 THEN                  -- AZ: balans aşağı | EN: low balance
    RETURN 'Kredit verilmir';                              -- AZ: hər üç şərt eyni vaxtda ödəndikdə kredit rədd edilir | EN: credit denied when all three conditions hold
  ELSE
    RETURN 'Kredit verile biler';
  END IF;
  
  EXCEPTION
    WHEN no_data_found THEN
      RETURN 'Musteri tapilmadi';                          -- AZ: müştəri tapılmadıqda | EN: when customer not found
    WHEN OTHERS THEN
      RETURN 'xeta bas verdi';                              -- AZ: digər gözlənilməz xətalar | EN: any other unexpected error
END get_credit_list;


PROCEDURE check_credit_request(p_customer_id IN customer_churn_info.customer_id%TYPE,
                                                                p_amount      IN NUMBER,
                                                                p_result      OUT NUMBER) IS
  PRAGMA AUTONOMOUS_TRANSACTION;                            -- AZ: müstəqil əməliyyat - əsas əməliyyatdan asılı olmadan COMMIT olunur | EN: independent transaction, committed regardless of the outer transaction
  v_customer_info customer_churn_info%ROWTYPE;
  customer_not_found EXCEPTION;                             -- AZ: xüsusi (user-defined) exception | EN: custom user-defined exception
BEGIN
  SELECT *
    INTO v_customer_info
    FROM customer_churn_info
   WHERE customer_id = p_customer_id;

  IF v_customer_info.credit_score < 500 AND v_customer_info.churn = 1 AND
     v_customer_info.balance < 200 THEN
    p_result := 0;                                          -- AZ: kredit rədd edilir | EN: credit denied
  ELSE
    p_result := 1;                                           -- AZ: kredit təsdiqlənir | EN: credit approved
  END IF;

  INSERT INTO credit_request                                 -- AZ: müraciət credit_request cədvəlində loglanır | EN: request is logged into credit_request
    (customer_id, sys_date, amount, credit_result)
  VALUES
    (p_customer_id, SYSDATE, p_amount, p_result);
    
  IF v_customer_info.customer_id IS NULL THEN
    RAISE customer_not_found;
  END IF;
  COMMIT;
  
EXCEPTION
  WHEN customer_not_found THEN
    dbms_output.put_line ('Customer not found');
END check_credit_request;


FUNCTION credit_offer_amount (p_customer_id customer_churn_info.customer_id%TYPE)
  RETURN NUMBER
IS
  v_credit_score customer_churn_info.credit_score%TYPE;
  v_balance customer_churn_info.balance%TYPE;
  v_churn customer_churn_info.churn%TYPE;
BEGIN
  SELECT credit_score, balance, churn
  INTO v_credit_score, v_balance, v_churn
  FROM customer_churn_info
  WHERE customer_id = p_customer_id;
  
  IF v_churn = 1 THEN
    RETURN 0;                                                -- AZ: churn edibsə kredit verilmir | EN: no credit if churned
  END IF;
  
  IF v_credit_score < 1000 THEN
    RETURN v_balance * 2;                                    -- AZ: skor aşağıdırsa balansın 2 misli | EN: 2x balance if low score
  ELSIF v_credit_score > 1000 AND v_balance > 2000 THEN
    RETURN v_balance * 5;                                    -- AZ: skor yüksək və balans böyükdürsə 5 misli | EN: 5x balance if high score and high balance
  END IF;
RETURN 0;

EXCEPTION
  WHEN no_data_found THEN
    RETURN 0;                                                -- AZ: müştəri tapılmadıqda 0 qaytarılır | EN: return 0 if customer not found
END credit_offer_amount;


FUNCTION credit_offer_amount(p_name customer_info.name%TYPE,
                             p_surname customer_info.surname%TYPE)
  RETURN NUMBER 
  IS
  v_credit_score customer_churn_info.credit_score%TYPE;
  v_balance      customer_churn_info.balance%TYPE;
  v_churn        customer_churn_info.churn%TYPE;
BEGIN
  SELECT cci.credit_score, cci.balance, cci.churn
    INTO v_credit_score, v_balance, v_churn
    FROM customer_churn_info cci
    JOIN customer_info ci
      ON cci.customer_id = ci.cif
   WHERE ci.name = p_name
         AND ci.surname = p_surname 
         AND cci.churn = 1;                                  -- AZ: yalnız churn edən müştərilər üçün axtarılır | EN: only searches among churned customers
         
  IF v_churn = 0 THEN
    RETURN 0;
  END IF;

  IF v_credit_score < 1000 THEN
    RETURN v_balance * 1.5;                                  -- AZ: skor aşağıdırsa balansın 1.5 misli | EN: 1.5x balance if low score
  ELSIF v_credit_score > 1000 AND v_balance > 2000 THEN
    RETURN v_balance * 2.5;                                  -- AZ: skor yüksək və balans böyükdürsə 2.5 misli | EN: 2.5x balance if high score and high balance
  END IF;

EXCEPTION
  WHEN no_data_found THEN
    RETURN 0;
END credit_offer_amount;

END check_credit_list;

--1 function
-- AZ: müştərinin kredit ala biləcəyini yoxlamaq (mətn nəticəsi) | EN: check if the customer qualifies for credit (text result)
SELECT
  check_credit_list.get_credit_list(1156496)
FROM dual;

--2 procedure
-- AZ: kredit müraciətini yoxlayıb loglamaq | EN: check the credit request and log it
DECLARE
  v_result NUMBER;
BEGIN
  check_credit_list.check_credit_request(p_customer_id => 2365987,
                       p_amount      => 10000,
                       p_result      => v_result);
  dbms_output.put_line(v_result);
END;

--3 function
-- AZ: customer_id üzrə maksimal kredit məbləğini hesablamaq | EN: calculate max credit amount by customer_id
DECLARE
  v_number NUMBER;
BEGIN
  v_number := check_credit_list.credit_offer_amount(p_customer_id => 1155981);
  dbms_output.put_line('Max Credit amount: ' || v_number);
END;

--4
-- AZ: ad-soyad üzrə maksimal kredit məbləğini hesablamaq | EN: calculate max credit amount by name/surname
DECLARE
  v_number NUMBER;
BEGIN
  v_number := check_credit_list.credit_offer_amount(p_name =>'Elia', 
                                                    p_surname => 'Fawcett');
  dbms_output.put_line('Max Credit amount: ' || v_number);
END;


/* ---------------------------------------------------------------------
   TASK 5 (davamı / continued)
   AZ: Job vasitəsilə hər ayın 1-ci günü, bütün müştərilər üçün
       credit_offer_amount funksiyasının nəticəsi mövcud
       max_cre_amount dəyərindən fərqlidirsə, bu sütunu yeniləmək
       (UPDATE) və funksiyanın yeni nəticəsini yazmaq.
   EN: Via a scheduled job, on the 1st day of every month, for every
       customer whose credit_offer_amount function result differs
       from the current max_cre_amount, update that column with the
       new function result.
--------------------------------------------------------------------- */

UPDATE customer_churn_info
SET max_cre_amount = check_credit_list.credit_offer_amount(customer_id)
WHERE NVL(max_cre_amount,0) <> check_credit_list.credit_offer_amount(customer_id);   
    -- AZ: mövcud dəyər ilə funksiyanın yeni nəticəsi fərqlidirsə yenilənir (NULL halları NVL ilə idarə olunur)
    -- EN: updates only when the current value differs from the function's new result (NULLs handled via NVL)

BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
   job_name        => 'update_data',                       -- AZ: job-un adı | EN: job name
   job_type        => 'plsql_block',                        -- AZ: PL/SQL blok tipli job | EN: PL/SQL block type job
   job_action      => q'[BEGIN UPDATE customer_churn_info
                            SET max_cre_amount = check_credit_list.credit_offer_amount(customer_id)
                            WHERE NVL(max_cre_amount,0) <> check_credit_list.credit_offer_amount(customer_id); 
                        COMMIT;
                        END;]',                              -- AZ: job icra olunduqda çalışdırılacaq kod | EN: code executed when the job runs
   repeat_interval => 'FREQ=MONTHLY;BYMONTHDAY=1',           -- AZ: hər ayın 1-ci günü təkrarlanır | EN: repeats on the 1st day of every month
   enabled         => TRUE,                                  -- AZ: job aktivdir | EN: job is enabled
   auto_drop       => FALSE);                                -- AZ: bir dəfə işlədikdən sonra silinmir | EN: not dropped after running once
END;
