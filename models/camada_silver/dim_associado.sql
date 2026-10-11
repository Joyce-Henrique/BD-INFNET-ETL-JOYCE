SELECT
    -- 3, 4 e 6: Maiúsculas, Trim e Normalização de espaços duplos
    UPPER(REGEXP_REPLACE(TRIM(Nome_Associado), r'\s+', ' ')) AS Nome_Associado,
    
    -- 4, 5 e 7: Trim, Remoção de não-numéricos e conversão de vazios para NULL
    NULLIF(REGEXP_REPLACE(TRIM(CPF), r'[^0-9]', ''), '') AS CPF,

    -- 4, 7 e 12: Trim, conversão segura de data com múltiplas tentativas (COALESCE)
    COALESCE(
        SAFE.PARSE_DATE('%d/%m/%Y', TRIM(CAST(Data_Nascimento AS STRING))),
        SAFE.PARSE_DATE('%d.%m.%Y', TRIM(CAST(Data_Nascimento AS STRING))),
        SAFE.PARSE_DATE('%Y-%m-%d', TRIM(CAST(Data_Nascimento AS STRING)))
    ) AS Data_Nascimento,

    -- 4, 7 e 9: Trim, conversão de vazios e coerção para INT64
    SAFE_CAST(NULLIF(TRIM(CAST(Idade AS STRING)), '') AS INT64) AS Idade,

    -- 3, 4, 6 e 7: Tratamento categórico de texto com substituição de 'N/A'
    NULLIF(UPPER(REGEXP_REPLACE(TRIM(Formacao), r'\s+', ' ')), 'N/A') AS Formacao,

    -- 8: Padronização de Categorias (Estado Civil)
    CASE 
        WHEN LOWER(TRIM(Estado_Civil)) IN ('casado', 'casada', 'c') THEN 'CASADO'
        WHEN LOWER(TRIM(Estado_Civil)) IN ('solteiro', 'solteira', 's') THEN 'SOLTEIRO'
        WHEN LOWER(TRIM(Estado_Civil)) IN ('divorciado', 'divorciada', 'd') THEN 'DIVORCIADO'
        WHEN LOWER(TRIM(Estado_Civil)) IN ('viúvo', 'viúva', 'viuvo', 'viuva', 'v') THEN 'VIÚVO'
        ELSE NULL 
    END AS Estado_Civil,

    -- 8: Padronização de Categorias (Gênero)
    CASE 
        WHEN LOWER(TRIM(Genero)) IN ('feminino', 'f', 'fem') THEN 'FEMININO'
        WHEN LOWER(TRIM(Genero)) IN ('masculino', 'm', 'masc') THEN 'MASCULINO'
        ELSE NULL 
    END AS Genero,

    NULLIF(UPPER(REGEXP_REPLACE(TRIM(Cargo), r'\s+', ' ')), 'N/A') AS Cargo,

    -- 7, 10 e 11: Remoção de R$, substituição de vírgula por ponto e coerção para NUMERIC
    SAFE_CAST(
        NULLIF(
            REPLACE(
                REPLACE(
                    TRIM(CAST(Renda_Bruta AS STRING)), 
                    'R$', 
                    ''
                ),
                ',', 
                '.'
            ), 
            ''
        ) 
    AS NUMERIC) AS Renda_Bruta,

    UPPER(REGEXP_REPLACE(TRIM(Logradouro), r'\s+', ' ')) AS Logradouro,
    UPPER(REGEXP_REPLACE(TRIM(Cidade), r'\s+', ' ')) AS Cidade,
    UPPER(TRIM(UF)) AS UF,
    
    -- 4, 5 e 7: Remoção de caracteres especiais do Celular (mantém apenas números)
    NULLIF(REGEXP_REPLACE(TRIM(Celular), r'[^0-9]', ''), '') AS Celular,
    
    -- 1, 3, 4 e 7: Minúsculas, escape com crases por conter traço e substituição de 'n/a'
    NULLIF(NULLIF(LOWER(TRIM(`E-mail`)), 'n/a'), '') AS `E-mail`

FROM {{ source('consumo', 'DIM_ASSOCIADO') }}

-- Garante a remoção de CPFs nulos ou vazios e deduplica mantendo apenas a primeira ocorrência
WHERE NULLIF(REGEXP_REPLACE(TRIM(CPF), r'[^0-9]', ''), '') IS NOT NULL
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY NULLIF(REGEXP_REPLACE(TRIM(CPF), r'[^0-9]', ''), '') 
    ORDER BY Nome_Associado
) = 1