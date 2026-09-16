import duckdb
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import streamlit as st

# Configuration de la page
st.set_page_config(
    page_title="Executive BI - Aïcha", page_icon="🚀", layout="wide"
)

# --- STYLE CSS PERSONNALISÉ (Thème Orange & Vert / Design Cards) ---
st.markdown(
    """
    <style>
    .main { background-color: #f8f9fa; }
    .kpi-card {
        background-color: #ffffff;
        border: 1px solid #e0e0e0;
        padding: 20px;
        border-radius: 10px;
        box-shadow: 0 4px 6px rgba(0,0,0,0.05);
        text-align: center;
    }
    .kpi-title { font-size: 14px; color: #6c757d; font-weight: 600; text-transform: uppercase; }
    .kpi-value { font-size: 24px; color: #2c3e50; font-weight: 700; margin-top: 5px; }
    </style>
""",
    unsafe_allow_html=True,
)


# --- CHARGEMENT DES DONNÉES (Sans cache rigide pour refléter les changements de la base) ---
def load_data():
    con = duckdb.connect(
        "/home/bony/project_submit/dbt/my_db.duckdb", read_only=True
    )
    df = con.execute("SELECT * FROM main_marts.fct_business_performance").fetchdf()
    con.close()
    return df


with st.spinner("🔄 Connexion à l'entrepôt DuckDB..."):
    df_perf = load_data()


# --- BARRE LATÉRALE : FILTRES INTERACTIFS ---
st.sidebar.header("🎛️ Filtres Dynamiques")

# 1. Filtre interactif par Mois (Janvier, Février, Mars, etc.)
all_months = sorted(df_perf["performance_month"].dropna().unique().tolist())
selected_months = st.sidebar.multiselect(
    "📅 Sélectionner le(s) Mois",
    options=all_months,
    default=all_months,  # Par défaut, tout est sélectionné
)

# 2. Filtre par Canal / Domaine
all_channels = list(df_perf["channel_or_platform"].unique())
selected_channels = st.sidebar.multiselect(
    "🛒 Filtrer par Domaine / Canal",
    options=all_channels,
    default=all_channels,
)

# Application des filtres sur le DataFrame
df_filtered = df_perf[
    (df_perf["performance_month"].isin(selected_months))
    & (df_perf["channel_or_platform"].isin(selected_channels))
]


# --- EN-TÊTE DU DASHBOARD ---
st.title("📊 Executive Dashboard — Pilotage Global des Dépenses")
st.markdown(
    "Visualisation dynamique de toutes les dépenses et performances par mois et par domaine (Mis à jour en temps réel depuis DuckDB)."
)
st.markdown("---")


# --- 1. LES KPI GLOBAUX (Basés sur la sélection du mois) ---
total_revenue = df_filtered["net_revenue_fcfa"].sum()
total_spend = df_filtered["marketing_spend_fcfa"].sum()
global_roi = (
    round(total_revenue / total_spend, 2) if total_spend > 0 else 0
)
total_customers = df_filtered["unique_customers"].sum()

c1, c2, c3, c4 = st.columns(4)

with c1:
    st.markdown(
        f"""
        <div class="kpi-card">
            <div class="kpi-title">Chiffre d'Affaires Net</div>
            <div class="kpi-value" style="color: #27ae60;">{total_revenue:,.0f} FCFA</div>
        </div>
        """,
        unsafe_allow_html=True,
    )
with c2:
    st.markdown(
        f"""
        <div class="kpi-card">
            <div class="kpi-title">Dépenses Totales (Marketing)</div>
            <div class="kpi-value" style="color: #e67e22;">{total_spend:,.0f} FCFA</div>
        </div>
        """,
        unsafe_allow_html=True,
    )
with c3:
    st.markdown(
        f"""
        <div class="kpi-card">
            <div class="kpi-title">ROI Global</div>
            <div class="kpi-value" style="color: #2980b9;">{global_roi}x</div>
        </div>
        """,
        unsafe_allow_html=True,
    )
with c4:
    st.markdown(
        f"""
        <div class="kpi-card">
            <div class="kpi-title">Clients Uniques</div>
            <div class="kpi-value" style="color: #8e44ad;">{total_customers:,}</div>
        </div>
        """,
        unsafe_allow_html=True,
    )

st.markdown("<br>", unsafe_allow_html=True)


# --- 2. SECTION CENTRALE : LE TABLEAU INTERACTIF DES DÉPENSES ---
st.subheader("📋 Tableau Détaillé des Dépenses par Domaine et par Mois")
st.markdown(
    "Ce tableau se met à jour instantanément selon le mois ou les domaines cochés dans la barre latérale. Si de nouvelles données entrent dans DuckDB, un simple rechargement de la page actualisera le tout."
)

# Affichage propre du tableau filtré
st.dataframe(
    df_filtered.rename(
        columns={
            "performance_month": "Mois",
            "channel_or_platform": "Domaine / Canal",
            "net_revenue_fcfa": "Revenu Net (FCFA)",
            "marketing_spend_fcfa": "Dépenses (FCFA)",
            "unique_customers": "Clients",
        }
    ),
    use_container_width=True,
    hide_index=True,
)


# --- 3. GRAPHIQUE D'ÉVOLUTION ---
st.markdown("---")
st.subheader("📈 Comparatif Visuel : Dépenses vs Revenus par Mois")

df_monthly = (
    df_filtered.groupby("performance_month")[
        ["net_revenue_fcfa", "marketing_spend_fcfa"]
    ]
    .sum()
    .reset_index()
)
df_monthly = df_monthly.sort_values("performance_month")

fig_line = go.Figure()
fig_line.add_trace(
    go.Bar(
        x=df_monthly["performance_month"],
        y=df_monthly["marketing_spend_fcfa"],
        name="Dépenses",
        marker_color="#e67e22",  # Orange signature
        opacity=0.8,
    )
)
fig_line.add_trace(
    go.Scatter(
        x=df_monthly["performance_month"],
        y=df_monthly["net_revenue_fcfa"],
        name="Revenu Net",
        mode="lines+markers",
        line=dict(color="#27ae60", width=4),  # Vert signature
        marker=dict(size=8),
    )
)

fig_line.update_layout(
    template="plotly_white",
    xaxis_title="Mois",
    yaxis_title="Montant (FCFA)",
    legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
    margin=dict(l=10, r=10, t=30, b=10),
)

st.plotly_chart(fig_line, use_container_width=True)

# Footer
st.markdown("---")
st.markdown(
    "<p style='text-align: center; color: #7f8c8d;'>Tableau de bord interactif — Propulsé par dbt, DuckDB & Streamlit</p>",
    unsafe_allow_html=True,
)