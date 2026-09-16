WITH source AS (
    SELECT * FROM {{ source('raw', 'raw_media_plan') }}
),

cleaned AS (
    SELECT
        TRIM(plan_id) AS plan_id,
        TRIM(month) AS media_month,
        
        -- Harmonisaton des canaux vers une dimension unique (Mapping des libellés du plan vers la nomenclature cible)
        -- Résout la divergence "FB/IG" vs "Meta", et regroupe les 3 stations radio sous un canal unifié ou distinct selon le besoin
        CASE 
            WHEN UPPER(channel) LIKE '%FB%' OR UPPER(channel) LIKE '%IG%' OR UPPER(channel) LIKE '%META%' THEN 'Paid Social (Meta)'
            WHEN UPPER(channel) LIKE '%TIKTOK%' THEN 'Paid Social (TikTok)'
            WHEN UPPER(channel) LIKE '%GOOGLE%' THEN 'Search / Display (Google)'
            WHEN UPPER(channel) LIKE '%RADIO%' THEN 'Radio (Offline)'
            WHEN UPPER(channel) LIKE '%INFLUENCER%' OR UPPER(channel) LIKE '%INFLULENCEUR%' THEN 'Influencers'
            WHEN UPPER(channel) LIKE '%TERRAIN%' OR UPPER(channel) LIKE '%ACTIVATION%' THEN 'Field Activation'
            ELSE TRIM(channel)
        END AS canonical_channel,
        
        TRIM(channel) AS raw_channel,
        
        -- Normalisation des budgets et des facturations (gestion des valeurs nulles)
        CAST(planned_budget_fcfa AS DOUBLE) AS planned_budget_fcfa,
        CAST(invoiced_fcfa AS DOUBLE) AS invoiced_fcfa,
        
        -- Signalement explicite de l'écart entre le budget planifié et le montant facturé (pour la transparence financière)
        COALESCE(invoiced_fcfa, 0) - COALESCE(planned_budget_fcfa, 0) as budget_variance_fcfa,
        
        TRIM(objective) AS objective,
        TRIM(owner) AS owner,
        TRIM(notes) AS notes

    FROM source
    WHERE plan_id IS NOT NULL
)

SELECT * FROM cleaned