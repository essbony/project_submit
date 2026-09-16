with source as (
    select * from {{ source('raw', 'social_comments_classified') }}
)

select
    comment_id,
    language,
    sentiment,
    theme,
    is_spam,
    cast(confidence as decimal(3,2)) as confidence,
    prompt_version,
    parse_error,
    classified_at::timestamp as classified_at
from source