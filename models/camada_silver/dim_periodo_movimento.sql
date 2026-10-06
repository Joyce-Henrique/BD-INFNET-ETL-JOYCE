SELECT
    -- 1 e 5: Conversão robusta de data (DATE) com tratamento de nulos
    COALESCE(
        SAFE.PARSE_DATE('%Y-%m-%d', TRIM(CAST(Data_Movimento AS STRING))),
        SAFE.PARSE_DATE('%d/%m/%Y', TRIM(CAST(Data_Movimento AS STRING))),
        SAFE.PARSE_DATE('%d.%m.%Y', TRIM(CAST(Data_Movimento AS STRING)))
    ) AS Data_Movimento,

    -- 2 e 5: Coerção segura de atributos temporais numéricos para INT64
    SAFE_CAST(NULLIF(TRIM(CAST(Ano AS STRING)), '') AS INT64) AS Ano,

    -- 3 e 4: Escape de coluna com hífen (crases) e normalização de texto
    NULLIF(UPPER(TRIM(`Ano-Mes`)), '') AS Ano_Mes,
    NULLIF(UPPER(TRIM(`Mes-Ano`)), '') AS Mes_Ano,

    -- 2 e 5: Indicadores numéricos de período
    SAFE_CAST(NULLIF(TRIM(CAST(Semestre AS STRING)), '') AS INT64) AS Semestre,
    SAFE_CAST(NULLIF(TRIM(CAST(Trimestre AS STRING)), '') AS INT64) AS Trimestre,
    SAFE_CAST(NULLIF(TRIM(CAST(Mes_Numero AS STRING)), '') AS INT64) AS Mes_Numero,

    -- 4: Padronização do nome do mês para maiúsculas (ex: JANEIRO)
    UPPER(REGEXP_REPLACE(TRIM(Mes_Nome), r'\s+', ' ')) AS Mes_Nome

FROM {{ source('consumo', 'DIM_PERIODO_MOVIMENTO') }}