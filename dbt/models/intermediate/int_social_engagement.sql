SELECT
    comment_id,
    platform,
    post_id,
    published_at,
    DATE_TRUNC('day', published_at) AS engagement_date,
    DATE_TRUNC('month', published_at) AS engagement_month,
    author_handle,
    comment_text,
    like_count,

    -- Sentiment réel issu du classificateur IA (remplace l'ancien proxy
    -- engagement_level basé uniquement sur les likes)
    language,
    sentiment,
    theme,
    is_spam,
    classification_confidence

FROM {{ ref('stg_social_comments') }}