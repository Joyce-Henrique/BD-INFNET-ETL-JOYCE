SELECT
    -- 1, 2, 3 e 4: Normalização completa de Texto (Maiúsculas, Trim, Espaços Duplos e Nulos)
    NULLIF(UPPER(REGEXP_REPLACE(TRIM(Produto), r'\s+', ' ')), '') AS Produto,
    
    NULLIF(UPPER(REGEXP_REPLACE(TRIM(Modalidade), r'\s+', ' ')), '') AS Modalidade,
    
    NULLIF(UPPER(REGEXP_REPLACE(TRIM(Submodalidade), r'\s+', ' ')), '') AS Submodalidade,
    
    NULLIF(UPPER(REGEXP_REPLACE(TRIM(Perfil_Investidor_Produto), r'\s+', ' ')), '') AS Perfil_Investidor_Produto

FROM {{ source('consumo', 'DIM_INVESTIMENTO') }}