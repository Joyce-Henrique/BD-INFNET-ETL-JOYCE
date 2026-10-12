{{ config(materialized='table') }}

WITH fato_investimento AS (
    SELECT * FROM {{ ref('fato_investimento') }}
),

dim_associado AS (
    SELECT * FROM {{ ref('dim_associado') }}
),

-- Adicionando a dimensão de Conta Capital para pegar a data de abertura (Tempo de Associado)
dim_conta_capital AS (
    SELECT * FROM {{ ref('dim_conta_capital') }}
),

comportamento_investidor AS (
    SELECT 
        CPF,
        COUNT(Numero_Aplicacao) AS qtd_movimentacoes,
        SUM(Valor_Aplicado) AS volume_total_investido,
        AVG(Valor_Aplicado) AS ticket_medio_investimento,
        MIN(Data_Movimento) AS primeira_data_aplicacao
    FROM fato_investimento
    GROUP BY CPF
),

base_associado AS (
    SELECT 
        a.CPF,
        a.Nome_Associado,
        a.Idade, 
        a.Renda_Bruta, -- Corrigido para o nome exato da sua tabela
        a.Formacao,    -- Incluído da sua tabela
        a.Cargo,       -- Incluído da sua tabela
        cc.Dt_Abertura, 
        COALESCE(c.qtd_movimentacoes, 0) AS qtd_movimentacoes,
        COALESCE(c.volume_total_investido, 0) AS volume_total_investido,
        COALESCE(c.ticket_medio_investimento, 0) AS ticket_medio_investimento,
        c.primeira_data_aplicacao
    FROM dim_associado a
    LEFT JOIN comportamento_investidor c ON a.CPF = c.CPF
    LEFT JOIN dim_conta_capital cc ON a.CPF = cc.CPF 
)

SELECT 
    *,
    
    -- 1. FAIXA ETÁRIA
    CASE 
        WHEN Idade < 25 THEN 'Até 24 anos'
        WHEN Idade BETWEEN 25 AND 34 THEN '25 a 34 anos'
        WHEN Idade BETWEEN 35 AND 44 THEN '35 a 44 anos'
        WHEN Idade BETWEEN 45 AND 54 THEN '45 a 54 anos'
        WHEN Idade >= 55 THEN 'Acima de 55 anos'
        ELSE 'Não Informado'
    END AS faixa_etaria,

    -- 2. FAIXA DE RENDA (Usando a coluna Renda_Bruta)
    CASE 
        WHEN Renda_Bruta <= 5000 THEN 'Até R$ 5.000'
        WHEN Renda_Bruta > 5000 AND Renda_Bruta <= 10000 THEN 'R$ 5.001 a R$ 10.000'
        WHEN Renda_Bruta > 10000 AND Renda_Bruta <= 20000 THEN 'R$ 10.001 a R$ 20.000'
        WHEN Renda_Bruta > 20000 THEN 'Acima de R$ 20.000'
        ELSE 'Não Informado'
    END AS faixa_renda,

    -- 3. FAIXA DE TEMPO DE ASSOCIADO
    CASE 
        WHEN Dt_Abertura IS NULL THEN 'Não Informado'
        WHEN DATE_DIFF(CURRENT_DATE(), Dt_Abertura, YEAR) < 1 THEN 'Menos de 1 ano'
        WHEN DATE_DIFF(CURRENT_DATE(), Dt_Abertura, YEAR) BETWEEN 1 AND 3 THEN '1 a 3 anos'
        WHEN DATE_DIFF(CURRENT_DATE(), Dt_Abertura, YEAR) BETWEEN 4 AND 10 THEN '4 a 10 anos'
        WHEN DATE_DIFF(CURRENT_DATE(), Dt_Abertura, YEAR) > 10 THEN 'Mais de 10 anos'
    END AS faixa_tempo_associado,

    -- 4. FAIXA DE TEMPO COMO INVESTIDOR
    CASE 
        WHEN primeira_data_aplicacao IS NULL THEN 'Não é investidor'
        WHEN DATE_DIFF(CURRENT_DATE(), primeira_data_aplicacao, MONTH) <= 6 THEN 'Novo (Até 6 meses)'
        WHEN DATE_DIFF(CURRENT_DATE(), primeira_data_aplicacao, MONTH) <= 24 THEN 'Intermediário (6 meses a 2 anos)'
        WHEN DATE_DIFF(CURRENT_DATE(), primeira_data_aplicacao, MONTH) > 24 THEN 'Veterano (Mais de 2 anos)'
    END AS faixa_tempo_investidor,

    -- 5. FAIXA POR MOVIMENTAÇÃO (Engajamento)
    CASE 
        WHEN qtd_movimentacoes = 0 THEN 'Sem Movimento'
        WHEN qtd_movimentacoes BETWEEN 1 AND 5 THEN 'Baixo Engajamento'
        WHEN qtd_movimentacoes BETWEEN 6 AND 20 THEN 'Médio Engajamento'
        WHEN qtd_movimentacoes > 20 THEN 'Alto Engajamento'
    END AS faixa_engajamento_conta,

    -- 6. PERFIL DE INVESTIDOR (Por volume financeiro)
    CASE 
        WHEN volume_total_investido > 100000 THEN 'High Yield (Alto Volume)'
        WHEN volume_total_investido > 20000 THEN 'Standard (Médio Volume)'
        WHEN volume_total_investido > 0 THEN 'Starter (Baixo Volume)'
        ELSE 'Inativo'
    END AS perfil_investidor_calculado,

    -- 7. SEGMENTAÇÃO POR ÁREA DE ATUAÇÃO (Combinando Formacao e Cargo reais da sua base)
    CASE 
        WHEN LOWER(Formacao) LIKE '%tecnologia%' OR LOWER(Cargo) LIKE '%dba%' THEN 'Tecnologia'
        WHEN LOWER(Formacao) LIKE '%administração%' OR LOWER(Formacao) LIKE '%contabilidade%' OR LOWER(Cargo) LIKE '%gerente%' OR LOWER(Cargo) LIKE '%supervisor%' OR LOWER(Cargo) LIKE '%controladdor%' THEN 'Administração, Negócios e Finanças'
        WHEN LOWER(Formacao) LIKE '%odontologia%' OR LOWER(Cargo) LIKE '%ortodontista%' THEN 'Saúde'
        WHEN LOWER(Formacao) LIKE '%direito%' OR LOWER(Cargo) LIKE '%advogado%' THEN 'Jurídico'
        WHEN Formacao IS NOT NULL OR Cargo IS NOT NULL THEN 'Outros Setores'
        ELSE 'Não Informado'
    END AS segmento_atuacao

FROM base_associado