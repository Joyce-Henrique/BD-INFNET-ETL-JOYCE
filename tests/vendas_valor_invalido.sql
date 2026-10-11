SELECT *
FROM {{ ref('fato_vendas') }}
WHERE valor_total <= 0 
   OR quantidade <= 0