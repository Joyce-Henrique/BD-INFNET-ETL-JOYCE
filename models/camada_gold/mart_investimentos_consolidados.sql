{{ config(materialized='table') }}

WITH fato AS (
    SELECT * FROM {{ ref('fato_investimento') }}
),

periodo AS (
    SELECT * FROM {{ ref('dim_periodo_movimento') }}
),

-- 1. Criação das métricas totais por investidor (Lifetime)
metricas_investidor AS (
    SELECT 
        CPF,
        SUM(Valor_Aplicado) AS total_aplicado_investidor,
        MIN(Data_Movimento) AS primeira_aplicacao,
        MAX(Data_Movimento) AS ultima_aplicacao,
        -- Nova sugestão: Conta produtos únicos para ver quem diversifica a carteira
        COUNT(DISTINCT Produto) AS qtd_produtos_diferentes,
        -- Calcula o tempo de permanência em meses
        DATE_DIFF(MAX(Data_Movimento), MIN(Data_Movimento), MONTH) AS tempo_meses_como_investidor
    FROM fato
    GROUP BY CPF
),

-- 2. Geração dos Rankings Gerais
ranking_investidores AS (
    SELECT
        CPF,
        total_aplicado_investidor,
        tempo_meses_como_investidor,
        ultima_aplicacao,
        qtd_produtos_diferentes,
        -- Rank por maior volume financeiro total
        RANK() OVER (ORDER BY total_aplicado_investidor DESC) AS rank_maior_investidor_valor,
        -- Rank por maior tempo de investimento
        RANK() OVER (ORDER BY tempo_meses_como_investidor DESC, total_aplicado_investidor DESC) AS rank_investidor_mais_tempo
    FROM metricas_investidor
),

-- 3. Cruzamento com a base transacional
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
        p.ano_mes,
        f.Valor_Aplicado,
        f.Saldo_Atual_Investido,
        r.total_aplicado_investidor,
        r.tempo_meses_como_investidor,
        r.ultima_aplicacao,
        r.qtd_produtos_diferentes,
        r.rank_maior_investidor_valor,
        r.rank_investidor_mais_tempo
    FROM fato f
    LEFT JOIN periodo p ON f.Data_Movimento = p.data_movimento
    LEFT JOIN ranking_investidores r ON f.CPF = r.CPF
)

-- 4. Seleção Final e Regras de Segmentação
SELECT 
    *,
    -- Métrica Analítica Principal (Sua ideia): Participação % desta aplicação no total já investido
    SAFE_DIVIDE(Valor_Aplicado, total_aplicado_investidor) AS participacao_percentual_carteira,
    
    -- Nova Sugestão: Rendimento Absoluto e ROI %
    (Saldo_Atual_Investido - Valor_Aplicado) AS rendimento_absoluto,
    SAFE_DIVIDE((Saldo_Atual_Investido - Valor_Aplicado), Valor_Aplicado) AS roi_percentual,

    -- Segmentação 1: Top Investidores
    CASE 
        WHEN rank_maior_investidor_valor <= 10 THEN '1. Top 10 Investidores'
        WHEN rank_maior_investidor_valor <= 50 THEN '2. Top 50 Investidores'
        WHEN rank_maior_investidor_valor <= 100 THEN '3. Top 100 Investidores'
        ELSE '4. Demais Investidores'
    END AS segmento_ranking_valor,

    -- Segmentação 2: Fidelidade/Tempo como Investidor
    CASE 
        WHEN tempo_meses_como_investidor >= 60 THEN '1. Longo Prazo (Mais de 5 anos)'
        WHEN tempo_meses_como_investidor >= 24 THEN '2. Médio Prazo (2 a 5 anos)'
        WHEN tempo_meses_como_investidor > 0 THEN '3. Curto Prazo (Até 2 anos)'
        ELSE '4. Aplicação Única / Recente'
    END AS segmento_fidelidade_tempo,
    
    -- Segmentação 3 (Nova Sugestão): Perfil de Diversificação
    CASE
        WHEN qtd_produtos_diferentes >= 4 THEN '1. Altamente Diversificado (4+ Produtos)'
        WHEN qtd_produtos_diferentes BETWEEN 2 AND 3 THEN '2. Parcialmente Diversificado (2-3 Produtos)'
        ELSE '3. Concentrado (Apenas 1 Produto)'
    END AS segmento_diversificacao,

    -- Segmentação 4 (Nova Sugestão): Status de Engajamento / Risco de Saída
    CASE
        WHEN DATE_DIFF(CURRENT_DATE(), ultima_aplicacao, MONTH) <= 3 THEN '1. Super Ativo (Investiu há menos de 3 meses)'
        WHEN DATE_DIFF(CURRENT_DATE(), ultima_aplicacao, MONTH) <= 6 THEN '2. Ativo (Investiu entre 3 e 6 meses)'
        WHEN DATE_DIFF(CURRENT_DATE(), ultima_aplicacao, MONTH) <= 12 THEN '3. Em Alerta (Sem investir há 6 a 12 meses)'
        ELSE '4. Risco de Evasão (Sem novos aportes há mais de 1 ano)'
    END AS status_recencia_investimento

FROM base_consolidada