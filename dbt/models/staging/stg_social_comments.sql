WITH source AS (
    SELECT * FROM {{ source('raw', 'raw_social_comments') }}
),

cleaned AS (
    SELECT
        TRIM(comment_id) AS comment_id,
        LOWER(TRIM(platform)) AS platform,
        TRIM(post_id) AS post_id,

        COALESCE(
            TRY_STRPTIME(CAST(published_at AS VARCHAR), '%Y-%m-%d %H:%M:%S'),
            TRY_STRPTIME(CAST(published_at AS VARCHAR), '%Y-%m-%d'),
            TRY_STRPTIME(CAST(published_at AS VARCHAR), '%d/%m/%Y')
        )::TIMESTAMP AS published_at,

        TRIM(author_handle) AS author_handle,
        TRIM(comment_text) AS comment_text,
        CAST(like_count AS INTEGER) AS like_count,
        TRIM(reply_to_id) AS reply_to_id

    FROM source
    WHERE comment_id IS NOT NULL AND comment_text IS NOT NULL
),

deduplicated AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY comment_id, author_handle, comment_text
            ORDER BY published_at DESC
        ) AS rn
    FROM cleaned
),

classified AS (
    SELECT * FROM {{ source('raw', 'social_comments_classified') }}
),

joined AS (
    SELECT
        d.comment_id,
        d.platform,
        d.post_id,
        d.published_at,
        d.author_handle,
        d.comment_text,
        d.like_count,
        d.reply_to_id,
        c.language,
        c.sentiment,
        c.theme,
        c.is_spam,
        c.confidence AS classification_confidence,
        c.prompt_version,
        c.parse_error AS classification_parse_error
    FROM deduplicated d
    LEFT JOIN classified c
        ON d.comment_id = c.comment_id
    WHERE d.rn = 1
)

SELECT *
FROM joined
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY comment_id 
    ORDER BY classification_confidence DESC NULLS LAST
) = 1


