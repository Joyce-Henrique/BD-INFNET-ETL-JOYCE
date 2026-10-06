SELECT
    -- 1 e 6: Parsing de Data do Movimento para o tipo DATE
    COALESCE(
        SAFE.PARSE_DATE('%Y-%m-%d', TRIM(CAST(Data_Movimento AS STRING))),
        SAFE.PARSE_DATE('%d/%m/%Y', TRIM(CAST(Data_Movimento AS STRING))),
        SAFE.PARSE_DATE('%d.%m.%Y', TRIM(CAST(Data_Movimento AS STRING)))
    ) AS Data_Movimento,

    -- 3 e 6: Identificadores da Instituição (Cooperativa e PA)
    SAFE_CAST(NULLIF(TRIM(CAST(Numero_Cooperativa AS STRING)), '') AS INT64) AS Numero_Cooperativa,
    UPPER(REGEXP_REPLACE(TRIM(Nome_Cooperativa), r'\s+', ' ')) AS Nome_Cooperativa,
    SAFE_CAST(NULLIF(TRIM(CAST(Numero_PA AS STRING)), '') AS INT64) AS Numero_PA,

    -- 4: Dados do Associado
    UPPER(REGEXP_REPLACE(TRIM(Nome_Associado), r'\s+', ' ')) AS Nome_Associado,
    
    -- 2 e 6: Limpeza de CPF (removendo pontos e traços)
    NULLIF(REGEXP_REPLACE(TRIM(CPF), r'[^0-9]', ''), '') AS CPF,

    -- 2 e 3: Limpeza de Conta Corrente e conversão para INT64
    SAFE_CAST(
        NULLIF(REGEXP_REPLACE(TRIM(Conta_Corrente), r'[^0-9]', ''), '') 
    AS INT64) AS Conta_Corrente,

    -- 4: Situação da Conta
    UPPER(TRIM(Situacao_Conta_Corrente)) AS Situacao_Conta_Corrente,

    -- 4: Canal de Atendimento
    NULLIF(UPPER(TRIM(Codigo_Canal)), '') AS Codigo_Canal,
    
    -- 4: Padronização do Tipo de Atendimento (DIGITAL / FÍSICO)
    CASE 
        WHEN LOWER(TRIM(Tipo_Atendimento)) IN ('digital', 'dig', 'online', 'ib digital') THEN 'DIGITAL'
        WHEN LOWER(TRIM(Tipo_Atendimento)) IN ('físico', 'fisico', 'presencial', 'agência', 'agencia') THEN 'FÍSICO'
        ELSE UPPER(TRIM(Tipo_Atendimento))
    END AS Tipo_Atendimento,

    -- 5: Normalização do Indicador de Perfil Preenchido
    CASE 
        WHEN LOWER(TRIM(Perfil_Investidor_Preenchido)) IN ('sim', 's', '1', 'true') THEN 'SIM'
        WHEN LOWER(TRIM(Perfil_Investidor_Preenchido)) IN ('não', 'nao', 'n', '0', 'false') THEN 'NÃO'
        ELSE NULL 
    END AS Perfil_Investidor_Preenchido,

    -- 4: Perfil do Investidor e Produto
    UPPER(REGEXP_REPLACE(TRIM(Perfil_Investidor), r'\s+', ' ')) AS Perfil_Investidor,
    UPPER(REGEXP_REPLACE(TRIM(Numero_Aplicacao), r'\s+', ' ')) AS Numero_Aplicacao,
    UPPER(REGEXP_REPLACE(TRIM(Produto), r'\s+', ' ')) AS Produto

FROM {{ source('consumo', 'FATO_INVESTIMENTO') }}