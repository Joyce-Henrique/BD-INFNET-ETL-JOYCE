{{ config(materialized='table') }}

WITH fato AS (
    SELECT * FROM {{ ref('fato_investimento') }}
),

periodo AS (
    SELECT * FROM {{ ref('dim_periodo_movimento') }}
),

base_consolidada AS (
    SELECT 
        f.Data_Movimento,
        f.CPF,
        f.Nome_Associado,
        f.Numero_Cooperativa,
        f.Conta_Corrente,
        f.Tipo_Atendimento,
        f.Produto,
        f.Modalidade,
        p.ano_mes, -- Assumindo que sua dimensão de período possui esse campo
        f.Valor_Aplicado,
        f.Saldo_Atual_Investido
    FROM fato f
    LEFT JOIN periodo p 
        ON f.Data_Movimento = p.data_movimento -- Chave temporal real
)

SELECT 
    *,
    -- Métrica Analítica 1: Participação % do valor aplicado em relação ao total do mês
    SAFE_DIVIDE(Valor_Aplicado, SUM(Valor_Aplicado) OVER (PARTITION BY ano_mes)) AS participacao_percentual_mes,
    
    -- Métrica Analítica 2: Ranking de aplicações por modalidade dentro do mês
    RANK() OVER (PARTITION BY ano_mes, Modalidade ORDER BY Valor_Aplicado DESC) AS rank_valor_modalidade_mes
FROM base_consolidada