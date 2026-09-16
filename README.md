# 🚀 Awalé Boissons — Plateforme Décisionnelle & Agent AI Unifié

> **Documentation Technique & Guide Complet du Projet** — Centralisation, transformation des données, intelligence décisionnelle et agent conversationnel intelligent.

---

## 📋 Table des Matières
1. [Explication & Conception du Projet](#1-explication--conception-du-projet)
2. [Architecture Technique](#2-architecture-technique)
3. [Guide d'Installation & Configuration](#3-guide-dinstallation--configuration)
4. [Étapes de Nettoyage & Data Quality (dbt)](#4-étapes-de-nettoyage--data-quality-dbt)
5. [Guide d'Utilisation d'Apache Superset & Résolution des Contours](#5-guide-dutilisation-dapache-superset--résolution-des-contours)
6. [Déploiement de l'Agent sur Streamlit Cloud](#6-déploiement-de-lagent-sur-streamlit-cloud)
7. [Difficultés Rencontrées & Solutions](#7-difficultés-rencontrées--solutions)

---

## 🎯 1. Explication & Conception du Projet

**Awalé Boissons** est une solution d'ingénierie des données et de Business Intelligence (BI) de bout en bout conçue pour répondre à un double enjeu stratégique :
* **Unifier les données hétérogènes** : Consolider les sources de ventes physiques (magasins), les canaux de conversion directe (WhatsApp Direct) et les investissements publicitaires digitaux (TikTok & Meta).
* **Démocratiser l'accès aux insights** : Offrir aux équipes métier un tableau de bord analytique visuel (Apache Superset) couplé à un assistant conversationnel intelligent (Streamlit & LangChain) capable de répondre en langage naturel à des questions complexes sur les performances.

---

## 🏗️ 2. Architecture Technique

```text
[Sources Brutes / Fichiers EXCEL] 
       │
       ▼ (Dans duckdb INSTALL spatial; puis LOAD spatial; & dbt run)
[DuckDB (Entrepôt local)] ──> stg_models ──> fct_business_performance
       │
       ├──> [Apache Superset] (Visualisation & Tableaux de bord décisionnels)
       └──> [Streamlit + LangChain Agent] (Text-to-SQL en langage naturel)
```

* **Stockage & Moteur Analytique** : DuckDB (léger, rapide, embarqué).
* **Transformation des données** : dbt (Data Build Tool) avec un ordre strict : f.xlsx-> `run` -> `test`.
* **Visualisation** : Apache Superset (Dashboards décisionnels).
* **Intelligence Artificielle** : Agent Streamlit connecté à DuckDB via LangChain.

---

## ⚙️ 3. Guide d'Installation & Configuration

### Prérequis
* Python 3.10+
* Git
* Environnement virtuel Python

### Étape A : Clonage et Configuration de l'Environnement
```bash
# Cloner le dépôt
git clone https://github.com/essbony/project_submit.git
cd project_submit

# Créer et activer l'environnement virtuel
python3 -m venv .venv
source .venv/bin/activate ou .env/Scripts/Activate.ps1

# Installer les dépendances pour agent awale
Installer et utiliser UV 
uv pip install -r awale_agent/requirements.txt
[Lien agentt-awale](https://awale-agent.streamlit.app/)
```

### Étape B : Configuration des Secrets (`.env`)
Créez un fichier `.env` à la racine contenant vos clés d'API (OpenAI, etc.) :
```env
OPENROUTER_API_KEY="....."

LLM_CACHE_PATH=/tmp/llm_cache.sqlite

## 🧹 4. Étapes de Nettoyage & Data Quality (dbt)

Le pipeline dbt garantit la propreté, l'unicité et la validité des données avant leur exposition dans Superset.

### Ordre d'exécution obligatoire :
1. **`spatial et st_read(...) `** : Charge les fichiers EXCEL  statiques de référence et de mapping dans DuckDB.
2. **`dbt run`** : Exécute les modèles de staging et les marts analytiques (`fct_business_performance`).
3. **`dbt test`** : Valide l'intégrité des données (tests d'unicité sur les `comment_id`, non-nullité des clés).

Commandes d'exécution :
```bash
cd dbt/
dbt run
dbt test
cd ..
```

---

## 📊 5. Guide d'Utilisation d'Apache Superset & Résolution des Contours

Superset sert de couche de restitution visuelle pour le pilotage commercial et marketing.

### Configuration du Tableau de bord (`[ VUE DECISIONNELLE ]`)
* **Connexion à DuckDB** : Pointage vers la base de données locale/conteneurisée.
* **Modèle centralisé** : Utilisation de la table `main_marts.fct_business_performance`.

### Résolution d'un contour critique (Visibilité des Canaux Marketing) :
* **Problème rencontré** : Dans le graphique des dépenses marketing, seuls "Magasin Physique" et "WhatsApp Direct" apparaissaient, tandis que TikTok et Meta semblaient absents ou affichaient 0 en chiffre d'affaires.
* **Explication** : Les plateformes digitales (TikTok / Meta) concentrent les investissements publicitaires (`marketing_spend_fcfa`) mais génèrent des conversions indirectes ou un suivi de notoriété (Chiffre d'affaires à 0 dans cette table, contrairement aux canaux de vente directe).
* **Solution dans Superset** : 
  1. Éditer le graphique de dépenses marketing (`Edit chart`).
  2. S'assurer que le champ **Group by** pointe bien sur `channel_or_platform`.
  3. Vérifier que la métrique sélectionnée est la somme de `marketing_spend_fcfa` pour que les barres de TikTok et Meta s'affichent correctement aux côtés des autres canaux.

---

## ☁️ 6. Déploiement de l'Agent sur Streamlit Cloud

Pour rendre l'agent IA accessible en ligne via Streamlit Cloud :

1. **Préparation du dépôt GitHub** : 
   * Nettoyer les sous-dossiers `.git` internes pour éviter les liens bloqués sur GitHub.
   * Veiller à ce que `my_db.duckdb` soit ignoré via `.gitignore`.
2. **Configuration sur Streamlit Cloud** :
   * Connecter le dépôt GitHub `essbony/project_submit`.
   * Spécifier le fichier principal (ex: `awale_agent/app.py`).
3. **Gestion du cache en environnement Read-Only** :
   * Pour éviter l'erreur `sqlite3.OperationalError: attempt to write a readonly database`, configurer explicitement le chemin du cache LangChain vers `/tmp/llm_cache.sqlite` dans le code de l'agent ou les variables d'environnement de la plateforme.


*Généré pour le projet Awalé Boissons — Documentation technique validée.*

## Tech Stack


  <img src="describe.svg" alt="Architecture Awalé Boissons" width="100%" />