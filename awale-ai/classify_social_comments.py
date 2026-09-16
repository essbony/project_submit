"""
Classification en masse des commentaires sociaux (social_comments) via
OpenRouter (modèle OpenAI au choix), à partir du prompt versionné dans
prompts/social_comments_classifier_v1.py.

Usage :
    python awale-ai/classify_social_comments.py

Lit la table raw_social_comments dans le fichier DuckDB du projet, classe
chaque commentaire (langue, sentiment, thème, spam), écrit le résultat dans
une nouvelle table `social_comments_classified`, et affiche un rapport de
coût à la fin (nombre de tokens, coût estimé).

Le coût est calculé à partir du nombre de tokens réellement consommés
(entrée + sortie), reporté par l'API — pas une estimation a priori — pour
donner un chiffre fiable et actionnable pour Aïcha/Kômian.
"""

import json
import os
import sys
import time
from dataclasses import dataclass
from dotenv import load_dotenv

import duckdb
from langchain_openai import ChatOpenAI
from langchain_core.messages import SystemMessage, HumanMessage

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "prompts"))
from social_comments_classifier_v1 import SYSTEM_PROMPT, USER_PROMPT_TEMPLATE  # noqa: E402

PROMPT_VERSION = "v1"

load_dotenv()  

DUCKDB_PATH = os.environ.get("DUCKDB_PATH", "/home/bony/project_submit/dbt/my_db.duckdb")
OPENROUTER_API_KEY = os.environ["OPENROUTER_API_KEY"]
OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1"
MODEL_ID = os.environ.get("MODEL_ID", "openai/gpt-4o-mini")


PRICE_PER_1K_INPUT_TOKENS_USD = 0.00015
PRICE_PER_1K_OUTPUT_TOKENS_USD = 0.0006


@dataclass
class ClassificationResult:
    comment_id: str
    language: str
    sentiment: str
    theme: str
    is_spam: bool
    confidence: float
    input_tokens: int
    output_tokens: int
    parse_error: bool


def get_llm() -> ChatOpenAI:
    return ChatOpenAI(
        model=MODEL_ID,
        base_url=OPENROUTER_BASE_URL,
        api_key=OPENROUTER_API_KEY,
        temperature=0,
        max_tokens=200,
    )


def classify_comment(llm: ChatOpenAI, comment_id: str, comment_text: str) -> ClassificationResult:
    messages = [
        SystemMessage(content=SYSTEM_PROMPT),
        HumanMessage(content=USER_PROMPT_TEMPLATE.format(comment_text=comment_text)),
    ]
    response = llm.invoke(messages)

    usage = getattr(response, "usage_metadata", None) or {}
    input_tokens = usage.get("input_tokens", 0)
    output_tokens = usage.get("output_tokens", 0)

    raw = response.content.strip()
    # Nettoyage défensif si le modèle entoure la réponse de ```json ... ```
    if raw.startswith("```"):
        raw = raw.strip("`")
        raw = raw.replace("json\n", "", 1) if raw.startswith("json\n") else raw

    try:
        parsed = json.loads(raw)
        return ClassificationResult(
            comment_id=comment_id,
            language=parsed.get("language", "other"),
            sentiment=parsed.get("sentiment", "neutral"),
            theme=parsed.get("theme", "autre"),
            is_spam=bool(parsed.get("is_spam", False)),
            confidence=float(parsed.get("confidence", 0.0)),
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            parse_error=False,
        )
    except (json.JSONDecodeError, ValueError, TypeError):
        # Échec de parsing : on garde une trace au lieu de planter tout le
        # batch. Ces lignes doivent être revues manuellement (voir rapport
        # final).
        return ClassificationResult(
            comment_id=comment_id,
            language="other",
            sentiment="neutral",
            theme="autre",
            is_spam=False,
            confidence=0.0,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            parse_error=True,
        )


def main() -> None:
    con = duckdb.connect(DUCKDB_PATH)

    comments = con.execute(
        "SELECT comment_id, comment_text FROM raw_social_comments"
    ).fetchall()

    print(f"{len(comments)} commentaires à classifier (prompt {PROMPT_VERSION})...")

    llm = get_llm()
    results: list[ClassificationResult] = []
    start = time.time()

    for i, (comment_id, comment_text) in enumerate(comments, start=1):
        result = classify_comment(llm, comment_id, comment_text or "")
        results.append(result)
        if i % 50 == 0:
            print(f"  {i}/{len(comments)} traités...")

    elapsed = time.time() - start

    con.execute("DROP TABLE IF EXISTS social_comments_classified")
    con.execute(
        """
        CREATE TABLE social_comments_classified (
            comment_id VARCHAR,
            language VARCHAR,
            sentiment VARCHAR,
            theme VARCHAR,
            is_spam BOOLEAN,
            confidence DOUBLE,
            prompt_version VARCHAR,
            parse_error BOOLEAN,
            classified_at TIMESTAMP DEFAULT current_timestamp
        )
        """
    )
    con.executemany(
        """
        INSERT INTO social_comments_classified
            (comment_id, language, sentiment, theme, is_spam, confidence, prompt_version, parse_error)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """,
        [
            (r.comment_id, r.language, r.sentiment, r.theme, r.is_spam, r.confidence, PROMPT_VERSION, r.parse_error)
            for r in results
        ],
    )
    con.close()

    # --- Rapport de coût et de qualité ---
    total_input = sum(r.input_tokens for r in results)
    total_output = sum(r.output_tokens for r in results)
    cost_usd = (
        total_input / 1000 * PRICE_PER_1K_INPUT_TOKENS_USD
        + total_output / 1000 * PRICE_PER_1K_OUTPUT_TOKENS_USD
    )
    parse_errors = sum(1 for r in results if r.parse_error)

    print("\n--- Rapport d'exécution ---")
    print(f"Commentaires classifiés : {len(results)}")
    print(f"Durée totale : {elapsed:.1f}s ({elapsed / max(len(results), 1):.2f}s/commentaire)")
    print(f"Tokens entrée/sortie : {total_input} / {total_output}")
    print(f"Coût estimé de cette exécution : ${cost_usd:.4f} USD")
    print(f"Erreurs de parsing JSON : {parse_errors} ({parse_errors / max(len(results), 1) * 100:.1f}%)")
    print(
        "\nRappel : ce coût est par exécution. Pour un coût mensuel, "
        "multiplier par le nombre d'exécutions prévues (ex: 1x/mois si le "
        "pipeline tourne une fois par mois sur les nouveaux commentaires)."
    )


if __name__ == "__main__":
    main()