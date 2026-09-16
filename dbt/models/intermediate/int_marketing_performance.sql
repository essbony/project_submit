with spend as (
    select
        campaign_name,
        platform,
        date_start,
        spend as spend_FCFA,
        impressions,
        clicks
    from {{ ref('stg_campaign_spend_export') }}
)

select
    platform,
    campaign_name,
    date_start as start_date,
    date_trunc('month', date_start) as campaign_month,
    spend_fcfa,
    impressions,
    clicks,
    case 
        when clicks > 0 then spend_fcfa / clicks 
        else 0 
    end as cpc_fcfa
from spend