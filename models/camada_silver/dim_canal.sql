SELECT
    -- 1, 2 e 3: Conversão Numérica de ID, Trim e conversão de vazios para NULL
    SAFE_CAST(
        NULLIF(TRIM(CAST(Canal AS STRING)), '') 
    AS INT64) AS Canal,

    -- 2, 3 e 4: Trim, Maiúsculas e conversão de vazios para NULL
    NULLIF(UPPER(TRIM(Codigo_Canal)), '') AS Codigo_Canal,

    -- 2, 4 e 5: Normalização de Texto (Maiúsculas, Trim e remoção de espaços duplos)
    UPPER(
        REGEXP_REPLACE(TRIM(Nome_Canal), r'\s+', ' ')
    ) AS Nome_Canal,

    -- 2 e 6: Trim e Padronização de Categorias (Tipo de Atendimento)
    CASE 
        WHEN LOWER(TRIM(Tipo_Atendimento)) IN ('digital', 'dig', 'online') THEN 'DIGITAL'
        WHEN LOWER(TRIM(Tipo_Atendimento)) IN ('físico', 'fisico', 'presencial', 'agência', 'agencia') THEN 'FÍSICO'
        ELSE NULL 
    END AS Tipo_Atendimento

FROM {{ source('consumo', 'DIM_CANAL') }}