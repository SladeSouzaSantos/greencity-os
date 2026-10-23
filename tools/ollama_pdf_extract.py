#!/usr/bin/env python3
"""Extrai texto e tabelas de PDF localmente para testes com Ollama.

Requer: python -m pip install pymupdf
Contrato stdout: JSON {"text": "...", "pages": N}
Nenhum acesso à rede; não transmite nem armazena o documento.
"""
import json
import sys


def extract(file_path: str) -> dict:
    import fitz  # PyMuPDF

    sections = []
    with fitz.open(file_path) as document:
        if document.needs_pass:
            raise ValueError("PDF criptografado: remova a senha antes de importar.")
        for index, page in enumerate(document, start=1):
            parts = [f"\n--- PÁGINA {index} ---\n"]
            parts.append(page.get_text("text", sort=True) or "")
            # Preserva a associação entre cabeçalhos, modelos e colunas.
            # A API de tabelas depende da versão instalada do PyMuPDF.
            if hasattr(page, "find_tables"):
                try:
                    tables = page.find_tables().tables
                    for table in tables:
                        rows = table.extract() or []
                        if rows:
                            parts.append("\nTABELA (linhas/colunas):\n")
                            for row in rows:
                                parts.append(
                                    "| " + " | ".join(
                                        str(cell or "").replace("\n", " ").strip()
                                        for cell in row
                                    ) + " |\n"
                                )
                except (AttributeError, ValueError, RuntimeError):
                    # O texto da página já foi extraído acima.
                    pass
            sections.append("".join(parts))
        return {"text": "\n".join(sections), "pages": len(document)}


def main() -> int:
    if len(sys.argv) != 2:
        print("Uso: ollama_pdf_extract.py <arquivo.pdf>", file=sys.stderr)
        return 2
    try:
        data = extract(sys.argv[1])
        print(json.dumps(data, ensure_ascii=False))
        return 0
    except Exception as exc:
        # Nunca ecoar o conteúdo bruto do PDF nem credenciais.
        print(f"Falha local de extração: {type(exc).__name__}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
