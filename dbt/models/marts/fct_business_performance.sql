with sales_agg as (
    select
        transaction_month as period,
        channel_code,
        channel_name,
        count(distinct customer_identifier) as unique_customers_count,
        sum(gross_revenue_fcfa) as total_gross_revenue_fcfa,
        sum(net_revenue_fcfa) as total_net_revenue_fcfa
    from {{ ref('int_sales_unified') }}
    where transaction_month is not null
    group by 1, 2, 3
),

marketing_agg as (
    select
        campaign_month as period,
        upper(platform) as platform,
        sum(spend_fcfa) as total_spend_fcfa,
        sum(impressions) as total_impressions,
        sum(clicks) as total_clicks
    from {{ ref('int_marketing_performance') }}
    where campaign_month is not null
    group by 1, 2
),

-- Sentiment agrégé par mois uniquement (pas par canal) : les commentaires
-- sociaux n'ont pas de dimension canal directement comparable à
-- channel_code/platform des dépenses marketing. Diffusé sur toutes les
-- lignes du mois plutôt que perdu faute de clé de jointure fiable.
sentiment_agg as (
    select
        engagement_month as period,
        count(*) as total_comments,
        count(*) filter (where sentiment = 'positive' and not is_spam) as positive_comments,
        count(*) filter (where sentiment = 'negative' and not is_spam) as negative_comments,
        count(*) filter (where sentiment = 'neutral' and not is_spam) as neutral_comments,
        count(*) filter (where is_spam) as spam_comments
    from {{ ref('int_social_engagement') }}
    where engagement_month is not null
    group by 1
)

select
    coalesce(s.period, m.period, '1970-01-01') as performance_month,
    coalesce(s.channel_name, m.platform, 'Marketing Hors-Vente') as channel_or_platform,
    coalesce(s.total_net_revenue_fcfa, 0) as net_revenue_fcfa,
    coalesce(m.total_spend_fcfa, 0) as marketing_spend_fcfa,
    coalesce(s.unique_customers_count, 0) as unique_customers,
    case
        when coalesce(m.total_spend_fcfa, 0) > 0
        then round(coalesce(s.total_net_revenue_fcfa, 0) / m.total_spend_fcfa, 2)
        else null
    end as revenue_per_fcfa_spent,

    coalesce(se.total_comments, 0) as total_comments,
    coalesce(se.positive_comments, 0) as positive_comments,
    coalesce(se.negative_comments, 0) as negative_comments,
    coalesce(se.neutral_comments, 0) as neutral_comments,
    coalesce(se.spam_comments, 0) as spam_comments

from sales_agg s
full outer join marketing_agg m
    on s.period = m.period
    and s.channel_code = m.platform
left join sentiment_agg se
    on coalesce(s.period, m.period) = se.period
    