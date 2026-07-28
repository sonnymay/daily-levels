#!/usr/bin/env python3
"""Validate the checked-in App Store listing against its hard field limits."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
METADATA_PATH = ROOT / "AppStore" / "METADATA.md"

ENGLISH_LIMITS = {
    "App name / Title": 30,
    "Subtitle": 30,
    "Keywords": 100,
    "Promotional text": 170,
    "Description": 4_000,
    "What's New": 4_000,
}
LOCALIZED_LIMITS = {
    "Title": 30,
    "Subtitle": 30,
    "Keywords": 100,
}
EXPECTED_LOCALES = {"es", "pt-BR", "de", "fr", "ja"}


def code_block(document: str, heading: str) -> str | None:
    pattern = re.compile(
        rf"^## {re.escape(heading)}[^\n]*\n```[^\n]*\n(.*?)\n```",
        re.MULTILINE | re.DOTALL,
    )
    match = pattern.search(document)
    return match.group(1) if match else None


def keyword_errors(label: str, value: str) -> list[str]:
    errors: list[str] = []
    if any(character.isspace() for character in value):
        errors.append(f"{label} keywords must not contain spaces")
    keywords = value.split(",")
    if any(not keyword for keyword in keywords):
        errors.append(f"{label} keywords contain an empty entry")
    folded = [keyword.casefold() for keyword in keywords]
    if len(folded) != len(set(folded)):
        errors.append(f"{label} keywords contain a duplicate")
    return errors


def localized_listings(document: str) -> dict[str, dict[str, str]]:
    headings = list(
        re.finditer(r"^### .+ \((es|pt-BR|de|fr|ja)\)\s*$", document, re.MULTILINE)
    )
    listings: dict[str, dict[str, str]] = {}
    for index, heading in enumerate(headings):
        end = headings[index + 1].start() if index + 1 < len(headings) else len(document)
        block = document[heading.end():end]
        listings[heading.group(1)] = {
            field: value
            for field, value in re.findall(
                r"^- \*\*(Title|Subtitle|Keywords):\*\* `([^`]*)`",
                block,
                re.MULTILINE,
            )
        }
    return listings


def validate_document(document: str) -> list[str]:
    errors: list[str] = []
    english: dict[str, str] = {}

    for field, limit in ENGLISH_LIMITS.items():
        value = code_block(document, field)
        if value is None:
            errors.append(f"missing English {field} code block")
            continue
        english[field] = value
        if len(value) > limit:
            errors.append(f"English {field} is {len(value)} characters; maximum is {limit}")

    if "Keywords" in english:
        errors.extend(keyword_errors("English", english["Keywords"]))
        indexed_words = set(
            re.findall(
                r"[^\W_]+",
                f"{english.get('App name / Title', '')} {english.get('Subtitle', '')}".casefold(),
            )
        )
        repeated = sorted(
            keyword
            for keyword in english["Keywords"].split(",")
            if keyword.casefold() in indexed_words
        )
        if repeated:
            errors.append(
                "English keywords repeat title/subtitle terms: " + ", ".join(repeated)
            )

    support_url = code_block(document, "Support URL")
    if support_url is None or not support_url.startswith("https://"):
        errors.append("Support URL must be a secure HTTPS URL")

    listings = localized_listings(document)
    missing_locales = EXPECTED_LOCALES - listings.keys()
    if missing_locales:
        errors.append("missing localized listings: " + ", ".join(sorted(missing_locales)))

    for locale, fields in listings.items():
        for field, limit in LOCALIZED_LIMITS.items():
            value = fields.get(field)
            if value is None:
                errors.append(f"{locale} listing is missing {field}")
                continue
            if len(value) > limit:
                errors.append(
                    f"{locale} {field} is {len(value)} characters; maximum is {limit}"
                )
        if "Keywords" in fields:
            errors.extend(keyword_errors(locale, fields["Keywords"]))

    return errors


def main() -> None:
    document = METADATA_PATH.read_text(encoding="utf-8")
    errors = validate_document(document)
    if errors:
        for error in errors:
            print(f"App Store metadata validation failed: {error}", file=sys.stderr)
        raise SystemExit(1)

    print(
        "App Store metadata validation passed: "
        f"{len(ENGLISH_LIMITS)} English fields and {len(EXPECTED_LOCALES)} localized listings."
    )


if __name__ == "__main__":
    main()
