SELECT
    -- 1 e 2: Remoção de traço (ex: 10200-5 -> 102005) e conversão para INT64
    SAFE_CAST(
        NULLIF(REGEXP_REPLACE(TRIM(Conta_Corrente), r'[^0-9]', ''), '') 
    AS INT64) AS Conta_Corrente,

    -- 3: Normalização de Texto (Maiúsculas, Trim e remoção de espaços duplos)
    UPPER(REGEXP_REPLACE(TRIM(Nome_Associado), r'\s+', ' ')) AS Nome_Associado,

    -- 1 e 4: Remoção de pontuação do CPF (ex: 464.656.852-05) e conversão de vazios
    NULLIF(REGEXP_REPLACE(TRIM(CPF), r'[^0-9]', ''), '') AS CPF,

    -- 5: Conversão robusta de datas com múltiplas tentativas
    COALESCE(
        SAFE.PARSE_DATE('%d/%m/%Y', TRIM(CAST(Dt_Abertura AS STRING))),
        SAFE.PARSE_DATE('%d.%m.%Y', TRIM(CAST(Dt_Abertura AS STRING))),
        SAFE.PARSE_DATE('%Y-%m-%d', TRIM(CAST(Dt_Abertura AS STRING)))
    ) AS Dt_Abertura,

    -- 4 e 5: Tratamento de strings 'NULL' e Conversão de data
    COALESCE(
        SAFE.PARSE_DATE('%d/%m/%Y', NULLIF(UPPER(TRIM(CAST(Dt_Encerramento AS STRING))), 'NULL')),
        SAFE.PARSE_DATE('%d.%m.%Y', NULLIF(UPPER(TRIM(CAST(Dt_Encerramento AS STRING))), 'NULL')),
        SAFE.PARSE_DATE('%Y-%m-%d', NULLIF(UPPER(TRIM(CAST(Dt_Encerramento AS STRING))), 'NULL'))
    ) AS Dt_Encerramento,

    -- 6: Padronização de Categorias (Situação da Conta)
    CASE 
        WHEN LOWER(TRIM(Situacao_Conta_Corrente)) IN ('ativo', 'a', 'ativa', '1', 'true') THEN 'ATIVO'
        WHEN LOWER(TRIM(Situacao_Conta_Corrente)) IN ('inativo', 'i', 'inativa', 'encerrado', 'encerrada', '0', 'false') THEN 'INATIVO'
        ELSE NULL 
    END AS Situacao_Conta_Corrente

FROM {{ source('consumo', 'DIM_CONTA_CORRENTE') }}