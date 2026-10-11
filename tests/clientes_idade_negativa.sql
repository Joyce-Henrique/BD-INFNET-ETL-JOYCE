SELECT *
FROM {{ ref('dim_associado') }}
WHERE Idade <= 0