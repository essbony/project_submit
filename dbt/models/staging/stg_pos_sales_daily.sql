WITH source AS (
    SELECT * FROM {{ source('raw', 'raw_pos_sales_daily') }}
),

cleaned AS (
    SELECT
        TRY_CAST(sale_date AS DATE) AS sale_date,
        
        -- Résolution d'entité des POS (unification des variantes textuelles instables : Cocody Angré, angre 8e tranche, etc.)
        TRIM(pos_name) AS raw_pos_name,
        CASE 
            WHEN UPPER(pos_name) LIKE '%ANGRE%' OR UPPER(pos_name) LIKE '%COCODY%' THEN 'POS_COCODY_ANGRE_8E'
            ELSE UPPER(TRIM(pos_name))
        END AS canonical_pos_id,
        
        CASE 
            WHEN UPPER(pos_name) LIKE '%ANGRE%' OR UPPER(pos_name) LIKE '%COCODY%' THEN 'Cocody Angré 8e Tranche'
            ELSE TRIM(pos_name)
        END AS canonical_pos_name,
        
        TRIM(commune) AS commune,
        LOWER(TRIM(channel)) AS channel,
        TRIM(product_sku) AS product_sku,
        
        -- Casting des volumes et du chiffre d'affaires
        CAST(units_sold AS INTEGER) AS units_sold,
        CAST(revenue_fcfa AS DOUBLE) AS revenue_fcfa,
        
        -- Détection et isolation explicite des retours (montants ou unités négatifs)
        CASE 
            WHEN CAST(revenue_fcfa AS DOUBLE) < 0 OR CAST(units_sold AS INTEGER) < 0 THEN TRUE 
            ELSE FALSE 
        END AS is_return

    FROM source
    WHERE sale_date IS NOT NULL
)

SELECT 
    sale_date,
    canonical_pos_id,
    canonical_pos_name,
    raw_pos_name,
    commune,
    channel,
    product_sku,
    units_sold,
    revenue_fcfa,
    is_return,
    -- Isolation du CA brut et de l'impact des retours pour restitution financière propre
    CASE WHEN NOT is_return THEN revenue_fcfa ELSE 0 END AS gross_revenue_fcfa,
    CASE WHEN is_return THEN revenue_fcfa ELSE 0 END AS return_impact_fcfa
FROM cleaned