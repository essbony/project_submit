with source as (
    select * from {{ source('raw', 'raw_campaign_spend_export') }}
),

cleaned as (
    select
        platform,
        campaign_name,
        
        -- 1. Traitement propre de date_start
        coalesce(
            try_strptime(date_start, '%Y-%m-%d'),
            try_strptime(date_start, '%d/%m/%Y'),
            try_strptime(date_start, '%d-%m-%Y'),
            try_strptime(
                replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(
                    regexp_replace(lower(date_start), '([0-9]{1,2})er', '\1', 'g'),
                    'janvier', '01'),
                    'février', '02'),
                    'mars', '03'),
                    'avril', '04'),
                    'mai', '05'),
                    'juin', '06'),
                    'juillet', '07'),
                    'août', '08'),
                    'septembre', '09'),
                    'octobre', '10'),
                    'novembre', '11'),
                    'décembre', '12'),
                '%d %m %Y'
            )
        )::date as date_start,
        
        -- 2. Traitement propre de date_end
        coalesce(
            try_strptime(date_end, '%Y-%m-%d'),
            try_strptime(date_end, '%d/%m/%Y'),
            try_strptime(date_end, '%d-%m-%Y'),
            try_strptime(
                replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(
                    regexp_replace(lower(date_end), '([0-9]{1,2})er', '\1', 'g'),
                    'janvier', '01'),
                    'février', '02'),
                    'mars', '03'),
                    'avril', '04'),
                    'mai', '05'),
                    'juin', '06'),
                    'juillet', '07'),
                    'août', '08'),
                    'septembre', '09'),
                    'octobre', '10'),
                    'novembre', '11'),
                    'décembre', '12'),
                '%d %m %Y'
            )
        )::date as date_end,
        
        cast(impressions as integer) as impressions,
        cast(clicks as integer) as clicks,
        
        -- 3. Nettoyage et conversion des devises en FCFA
        case 
            when lower(spend) like '%eur%' or spend like '%€%' then 
                cast(regexp_replace(spend, '[^0-9]', '', 'g') as decimal(18,2)) * 655.957
            when lower(spend) like '%usd%' or spend like '%$%' then 
                cast(regexp_replace(spend, '[^0-9]', '', 'g') as decimal(18,2)) * 600.00
            else 
                cast(regexp_replace(spend, '[^0-9]', '', 'g') as decimal(18,2))
        end as spend,
        
        objective
    from source
)

select 
    platform,
    campaign_name,
    date_start,
    date_end,
    impressions,
    clicks,
    spend,
    objective
from cleaned