SELECT 
    CPF,
    COUNT(*) AS quantidade
FROM {{ ref('dim_associado') }}
WHERE CPF IS NOT NULL
GROUP BY CPF
HAVING COUNT(*) > 1