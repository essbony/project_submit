FROM apache/superset:latest

# Passage en root pour installer les paquets système/pip

USER root

# Driver DuckDB pour SQLAlchemy + client DuckDB

RUN uv pip install --no-cache-dir duckdb duckdb-engine psycopg2-binary

# Retour à l'utilisateur non-privilégié attendu par l'image

USER superset
