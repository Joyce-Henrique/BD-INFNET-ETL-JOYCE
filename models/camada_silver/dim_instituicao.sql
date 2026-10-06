SELECT
    -- 2 e 5: Tipagem segura de ID e tratamento de nulos
    SAFE_CAST(
        NULLIF(TRIM(CAST(Numero_Cooperativa AS STRING)), '') 
    AS INT64) AS Numero_Cooperativa,

    -- 3: Normalização de Texto (Maiúsculas, Trim e remoção de espaços duplos)
    UPPER(REGEXP_REPLACE(TRIM(Nome_Cooperativa), r'\s+', ' ')) AS Nome_Cooperativa,

    -- 1, 2 e 5: Escape de coluna com espaço (Backticks), alias corrigido e conversão numérica
    SAFE_CAST(
        NULLIF(TRIM(CAST(`Numero PA` AS STRING)), '') 
    AS INT64) AS Numero_PA,

    -- 3: Normalização de Texto para Nomes e Endereços
    UPPER(REGEXP_REPLACE(TRIM(Nome_PA), r'\s+', ' ')) AS Nome_PA,
    UPPER(REGEXP_REPLACE(TRIM(Logradouro), r'\s+', ' ')) AS Logradouro,
    UPPER(REGEXP_REPLACE(TRIM(Cidade), r'\s+', ' ')) AS Cidade,
    
    -- 4: Tratamento simples de Maiúsculas e Trim para siglas de Estado
    UPPER(TRIM(UF)) AS UF,
    
    -- 3: Normalização de Texto do Responsável
    UPPER(REGEXP_REPLACE(TRIM(Nome_Gerente), r'\s+', ' ')) AS Nome_Gerente

FROM {{ source('consumo', 'DIM_INSTITUICAO') }}