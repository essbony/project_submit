WITH source AS (
    SELECT * FROM {{ source('raw', 'raw_whatsapp_orders') }}
),

cleaned AS (
    SELECT
        TRIM(order_ref) AS order_ref,

        -- Normalisation de la date/horodatage (gestion des formats mixtes)
        -- Ordre important : tester les formats avec heure AVANT les formats
        -- date seule du même style, sinon COALESCE peut s'arrêter trop tôt.
        COALESCE(
            TRY_STRPTIME(received_at, '%Y-%m-%d %H:%M:%S'),
            TRY_STRPTIME(received_at, '%Y-%m-%d'),
            TRY_STRPTIME(received_at, '%d/%m/%Y %H:%M:%S'),
            TRY_STRPTIME(received_at, '%d/%m/%Y %H:%M'),
            TRY_STRPTIME(received_at, '%d/%m/%Y')
        )::TIMESTAMP AS received_at,

        -- Flag explicite quand la date n'a pas pu être parsée du tout,
        -- pour ne jamais la traiter silencieusement comme "aucune commande"
        CASE
            WHEN COALESCE(
                TRY_STRPTIME(received_at, '%Y-%m-%d %H:%M:%S'),
                TRY_STRPTIME(received_at, '%Y-%m-%d'),
                TRY_STRPTIME(received_at, '%d/%m/%Y %H:%M:%S'),
                TRY_STRPTIME(received_at, '%d/%m/%Y %H:%M'),
                TRY_STRPTIME(received_at, '%d/%m/%Y')
            ) IS NULL THEN TRUE
            ELSE FALSE
        END AS is_received_at_missing,

        -- Normalisation stricte du numéro de téléphone ivoirien pour créer une clé client unique
        -- Suppression des espaces, des tirets et de l'indicatif +225 pour uniformiser sur 10 chiffres
        REGEXP_REPLACE(
            REGEXP_REPLACE(
                REGEXP_REPLACE(TRIM(customer_phone), '[^0-9+]', '', 'g'),
                '^\+225', '', 'g'
            ),
            '^00225', '', 'g'
        ) AS customer_phone_normalized,

        TRIM(items_text) AS items_text,

        -- Gestion des montants et signalement des valeurs manquantes
        CAST(amount_fcfa AS DOUBLE) AS amount_fcfa,
        CASE WHEN amount_fcfa IS NULL THEN TRUE ELSE FALSE END AS is_amount_missing,

        TRIM(delivery_zone) AS delivery_zone,
        LOWER(TRIM(status)) AS status

    FROM source
    WHERE order_ref IS NOT NULL
),

-- Extraction basée sur des règles (regex) pour parser les articles textuels courants (ex: "2 bissap 1L")
parsed_items AS (
    SELECT
        *,
        REGEXP_EXTRACT(LOWER(items_text), '([0-9]+)\s*(?:bouteille|b|bt)?\s*(bissap|gingembre|dolo|citron)', 2) AS extracted_product,
        COALESCE(TRY_CAST(REGEXP_EXTRACT(LOWER(items_text), '([0-9]+)\s*(?:bouteille|b|bt)?\s*(?:bissap|gingembre|dolo|citron)', 1) AS INTEGER), 1) AS extracted_quantity
    FROM cleaned
),

-- Déduplication basée sur la référence de commande si elle se répète
deduplicated AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY order_ref, customer_phone_normalized, received_at ORDER BY amount_fcfa DESC) AS rn
    FROM parsed_items
)

SELECT
    order_ref,
    received_at,
    is_received_at_missing,
    customer_phone_normalized AS customer_id,
    items_text,
    extracted_product,
    extracted_quantity,
    amount_fcfa,
    is_amount_missing,
    delivery_zone,
    status
FROM deduplicated
WHERE rn = 1