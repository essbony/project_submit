with pos_sales as (
    select
        sale_date as transaction_date,
        date_trunc('month', sale_date) as transaction_month,
        'POS' as channel_code,
        'Magasin Physique' as channel_name,
        canonical_pos_id as location_id,
        canonical_pos_name as location_name,
        CAST(NULL AS VARCHAR) as customer_identifier,
        CAST(NULL AS VARCHAR) as product_id,
        gross_revenue_fcfa,
        return_impact_fcfa,
        gross_revenue_fcfa - return_impact_fcfa as net_revenue_fcfa
    from {{ ref('stg_pos_sales_daily') }}
),

whatsapp_orders as (
    select
        CAST(received_at AS DATE) as transaction_date,
        date_trunc('month', CAST(received_at AS DATE)) as transaction_month,
        'WHATSAPP' as channel_code,
        'WhatsApp Direct' as channel_name,
        'Digital / Online' as location_id,
        'Canal Digital WhatsApp' as location_name,
        customer_id as customer_identifier,
        extracted_product as product_id,
        amount_fcfa as gross_revenue_fcfa,
        0.0 as return_impact_fcfa,
        amount_fcfa as net_revenue_fcfa
    from {{ ref('stg_whatsapp_orders') }}
)

select * from pos_sales
union all
select * from whatsapp_orders