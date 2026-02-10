-- FAZER EXPLORAÇÃO E ANÁLISE DE DADOS PARA TODAS AS TABELAS
EXEC sp_help 'nome_tabela'


-- ALTERANDO "??" PARA CHINA, NA COLUNA "COUNTRY"
UPDATE dbo.dim_customers
SET Country = 'China'
WHERE Country = N'??'


-- CRIAR COLUNA FK "DATE_ID" NA FATO
ALTER TABLE fato_transactions
ADD Date_ID INT


-- POPULAR COLUNA FK "DATE_ID" NA FATO
UPDATE trans
SET trans.Date_ID = dim_tempo.Date_ID
FROM fato_transactions AS trans
JOIN dim_tempo
    ON trans.Date = dim_tempo.Date


-- ATRIBUIR FK A COLUNA "Date_ID" DA FATO
ALTER TABLE fato_transactions
ADD CONSTRAINT FK_fato_transactions_dim_tempo
FOREIGN KEY (Date_ID)
REFERENCES dim_tempo(Date_ID)


-- CRIAR COLUNA DE VALIDAÇAO "INVOICE_TOTAL"
ALTER TABLE fato_transactions
ADD Invoice_Total_Validacao FLOAT


-- POPULAR COLUNA INVOICE_TOTAL_CORRECT
UPDATE trans
SET trans.Invoice_Total_Correct =
    CASE 
        WHEN Transaction_Type <> 'RETURN' THEN temp.Total_Calc
        ELSE Invoice_Total
    END
FROM fato_transactions AS trans
JOIN (
    SELECT
        Invoice_ID,
        SUM(
        (Unit_Price * Quantity) -
        (Discount_Correct / 100) * (Unit_Price * Quantity)
        ) AS Total_Calc
    FROM fato_transactions
    GROUP BY Invoice_ID
) AS temp
    ON trans.Invoice_ID = temp.Invoice_ID


-- CRIAR COLUNA PK "DISCOUNT_ID" NA DIMENSAO
ALTER TABLE dim_discounts
ADD Discount_ID INT IDENTITY(1,1)


-- ATRIBUIR PK A COLUNA "DISCOUNT_ID" NA DIMENSAO
ALTER TABLE dim_discounts
ADD CONSTRAINT PK_dim_discounts
PRIMARY KEY (Discount_ID)


-- CRIAR COLUNA FK "Discount_ID" NA FATO
ALTER TABLE fato_transactions
ADD Discount_ID INT


-- POPULAR COLUNA FK "Discount_ID" NA FATO
UPDATE trans
SET trans.Discount_ID = dis.Discount_ID
FROM fato_transactions AS trans
JOIN dim_products AS prod
    ON trans.Product_ID = prod.Product_ID
JOIN dim_discounts AS dis
    ON trans.Discount_Correct = dis.Discount_Correct
    AND prod.Sub_Category = dis.Sub_Category
    AND prod.Category     = dis.Category
    AND trans.Date BETWEEN dis.Start_Date AND dis.End_Date


-- CRIAR COLUNA DISCONT_CORRECT
ALTER TABLE fato_transactions
ADD Discount_Correct FLOAT


-- POPULAR COLUNA NOVA
UPDATE fato_transactions
SET Discount_Correct =
    CASE 
        WHEN Discount < 10 THEN Discount * 10
        ELSE Discount
    END


-- CRIAR COLUNA DISCONT_CORRECT
ALTER TABLE dim_discounts
ADD Discount_Correct FLOAT


-- POPULAR COLUNA NOVA
UPDATE dim_discounts
SET Discount_Correct =
    CASE 
        WHEN Discount < 10 THEN Discount * 10
        ELSE Discount
    END


-- ALTERANDO "??" PARA CHINA, NA COLUNA "COUNTRY"
UPDATE dbo.dim_stores
SET Country = 'China'
WHERE Country = N'??'


-- CRIAR DIMENSAO TEMPO
CREATE TABLE dim_tempo (
    Date_ID         INT PRIMARY KEY,    -- 20260123
    Date            DATE,               -- 2026-01-23
    Ano             INT,                -- 2026
    Semestre        INT,                -- 1 ou 2
    Trimestre       INT,                -- 1 a 4
    Mes             INT,                -- 1 a 12
    Nome_Mes        VARCHAR(20),        -- Janeiro
    Ano_Mes         CHAR(7),            -- 2026-01
    Dia             INT,                -- 23
    Dia_Semana      INT,                -- 1=Seg - 7=Dom
    Nome_Dia        VARCHAR(3),         -- Seg
    Semana_Ano      INT,                -- 4
    Fim_De_Semana   CHAR(1),            -- 'S' ou 'N'
)


-- POPULAR DIMENSAO TEMPO
DECLARE @DataInicio DATE = '2023-01-01';
DECLARE @DataFim    DATE = '2024-12-31';

;WITH Calendario AS (
    SELECT @DataInicio AS Data
    UNION ALL
    SELECT DATEADD(DAY, 1, Data)
    FROM Calendario
    WHERE Data < @DataFim
)
INSERT INTO dim_tempo (
    Date_ID,
    Date,
    Ano,
    Semestre,
    Trimestre,
    Mes,
    Nome_Mes,
    Ano_Mes,
    Dia,
    Dia_Semana,
    Nome_Dia,
    Semana_Ano,
    Fim_De_Semana
)
SELECT
    CONVERT(INT, FORMAT(Date, 'yyyyMMdd'))              AS Date_ID,
    Data,
    YEAR(Date)                                          AS Ano,
    CASE WHEN MONTH(Date) <= 6 THEN 1 ELSE 2 END        AS Semestre,
    DATEPART(QUARTER, Date)                             AS Trimestre,
    MONTH(Date)                                         AS Mes,
    DATENAME(MONTH, Date)                               AS Nome_Mes,
    FORMAT(Date, 'yyyy-MM')                             AS Ano_Mes,
    DAY(Date)                                           AS Dia,
    DATEPART(WEEKDAY, Date)                             AS Dia_Semana,
    LEFT(DATENAME(WEEKDAY, Date), 3)                    AS Nome_Dia,
    DATEPART(WEEK, Date)                                AS Semana_Ano,
    CASE 
        WHEN DATEPART(WEEKDAY, Date) IN (1,7) THEN 'S' 
        ELSE 'N' 
    END                                              AS Fim_De_Semana
FROM Calendario
OPTION (MAXRECURSION 0)