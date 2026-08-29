#!/usr/bin/env python3
import os
import sys
import argparse
import logging
import re
from pathlib import Path

from openai import OpenAI
import anthropic
import psycopg2 

# Konfiguracja logowania
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

def parse_args():
    parser = argparse.ArgumentParser(description="LLM SQL Evaluator & Executor")
    parser.add_argument("-s", "--system", required=True, help="Plik .md z system promptem")
    parser.add_argument("-i", "--input", required=True, help="Plik .txt z wierszami do ewaluacji")
    parser.add_argument("-p", "--provider", choices=['openai', 'claude'], default='openai', help="Wybierz dostawcę LLM (domyślnie: openai)")
    parser.add_argument("--reset", action="store_true", help="Ignoruj plik postępu i zacznij od nowa")
    return parser.parse_args()

def extract_sql(llm_response: str) -> str:
    lines = llm_response.strip().splitlines()
    
    # Usuń pierwszą linię jeśli to startowy blok markdown
    if lines and lines[0].strip().lower().startswith('```'):
        lines = lines[1:]
        
    # Usuń ostatnią linię jeśli model zdążył poprawnie zamknąć blok
    if lines and lines[-1].strip() == '```':
        lines = lines[:-1]
        
    return '\n'.join(lines).strip()

def get_db_connection():
    nome = os.getenv("NOME")
    agandskode = os.getenv("AGANDSKODE")
    mina = os.getenv("MINA")
    
    if not all([nome, agandskode, mina]):
        logger.error("Brak wymaganych zmiennych środowiskowych (NOME, AGANDSKODE, MINA).")
        sys.exit(1)

    logger.info(f"Nawiązywanie połączenia z bazą na porcie {mina}...")
    try:
        conn = psycopg2.connect(
            user=nome,
            password=agandskode,
            port=mina,
            host="127.0.0.1",
            dbname='agonez_db'
        )
        conn.autocommit = True 
        return conn
    except Exception as e:
        logger.error(f"Błąd połączenia z bazą: {e}")
        sys.exit(1)

def get_progress(progress_file: Path, reset: bool) -> int:
    if reset or not progress_file.exists():
        return 0
    try:
        return int(progress_file.read_text().strip())
    except ValueError:
        return 0

def save_progress(progress_file: Path, line_index: int):
    progress_file.write_text(str(line_index))

def main():
    args = parse_args()
    system_file = Path(args.system)
    input_file = Path(args.input)
    progress_file = input_file.with_suffix('.progress')

    if not system_file.exists():
        logger.error(f"Plik system promptu nie istnieje: {system_file}")
        sys.exit(1)
    if not input_file.exists():
        logger.error(f"Plik wejściowy nie istnieje: {input_file}")
        sys.exit(1)

    system_prompt = system_file.read_text(encoding='utf-8')
    lines = [line.strip() for line in input_file.read_text(encoding='utf-8').splitlines() if line.strip()]
    
    start_index = get_progress(progress_file, args.reset)
    
    if start_index >= len(lines):
        logger.info("Wszystkie wiersze z tego pliku zostały już przetworzone. Użyj --reset, aby ponowić.")
        sys.exit(0)

    # Inicjalizacja odpowiedniego klienta API
    if args.provider == 'openai':
        client = OpenAI() # Wymaga OPENAI_API_KEY
    else:
        client = anthropic.Anthropic() # Wymaga ANTHROPIC_API_KEY

    conn = get_db_connection()
    cursor = conn.cursor()

    logger.info(f"Rozpoczynam przetwarzanie od wiersza {start_index + 1}/{len(lines)} przy użyciu {args.provider.upper()}")

    for i in range(start_index, len(lines)):
        user_prompt = lines[i]
        logger.info(f"--- [Wiersz {i + 1}] ---")
        logger.info(f"User Prompt: {user_prompt}")

        try:
            logger.debug("Oczekiwanie na odpowiedź LLM...")

            # Logika specyficzna dla dostawcy
            if args.provider == 'openai':
                response = client.chat.completions.create(
                    model="gpt-4o",
                    messages=[
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": user_prompt}
                    ],
                    temperature=0.0
                )
                raw_sql = response.choices[0].message.content

            elif args.provider == 'claude':
                logger.debug("Oczekiwanie na odpowiedź LLM (streaming, do 32k tokenów)...")
                
                stream = client.messages.create(
                    model="claude-sonnet-5",
                    max_tokens=65536,
                    system=system_prompt,
                    messages=[
                        {"role": "user", "content": user_prompt}
                    ],
                    stream=True  
                )

                raw_sql = ""
                stop_reason = None

                # Przetwarzanie strumienia zdarzeń
                for event in stream:
                    # Wyłapujemy tylko fragmenty tekstu (omijając bloki thinking_delta)
                    if event.type == "content_block_delta":
                        if event.delta.type == "text_delta":
                            raw_sql += event.delta.text
                            # Jeśli chcesz widzieć SQL generowany na żywo w terminalu, odkomentuj poniższą linię:
                            # sys.stdout.write(event.delta.text); sys.stdout.flush()
                            
                    # Wyłapujemy powód zakończenia strumienia
                    elif event.type == "message_delta":
                        if getattr(event.delta, 'stop_reason', None):
                            stop_reason = event.delta.stop_reason

                # Zabezpieczenie przed uciętym SQL
                if stop_reason == 'max_tokens':
                    logger.error("KRYTYCZNE: Odpowiedź została ucięta (limit tokenów)! Wykonanie tego SQL uszkodziłoby bazę.")
                    raise RuntimeError("Zbyt krótki limit tokenów dla tego zapytania.")
                
                if not raw_sql:
                    raise ValueError("Model przetrawił tokeny, ale nie zwrócił żadnego bloku z tekstem.")
            
            clean_sql = extract_sql(raw_sql)
            logger.info(f"Wygenerowany SQL:\n{clean_sql}")

            logger.debug("Wykonywanie zapytania w bazie...")
            cursor.execute(clean_sql)
            logger.info("Sukces: SQL wykonany pomyślnie.")

            save_progress(progress_file, i + 1)

        except Exception as e:
            logger.error(f"Błąd podczas przetwarzania wiersza {i + 1}: {e}")
            logger.info("Zatrzymywanie skryptu. Zapisano stan.")
            cursor.close()
            conn.close()
            sys.exit(1)

    logger.info("Przetwarzanie pliku zakończone sukcesem!")
    cursor.close()
    conn.close()

if __name__ == "__main__":
    main()