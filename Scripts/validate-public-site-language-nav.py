#!/usr/bin/env python3

from html.parser import HTMLParser
from pathlib import Path
import sys


class LanguageNavigationParser(HTMLParser):
    """Collect current-page markers inside and outside the language navigation."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.language_navigation_count = 0
        self.language_navigation_depth = 0
        self.current_locations: list[bool] = []
        self.current_language_hrefs: list[str | None] = []

    def handle_starttag(self, tag: str, attributes: list[tuple[str, str | None]]) -> None:
        attribute_map = dict(attributes)
        if tag == "nav":
            classes = set((attribute_map.get("class") or "").split())
            if "language-nav" in classes:
                self.language_navigation_count += 1
                self.language_navigation_depth += 1
            elif self.language_navigation_depth:
                self.language_navigation_depth += 1
        is_current = (attribute_map.get("aria-current") or "").casefold() == "page"
        if is_current:
            inside_language_navigation = self.language_navigation_depth > 0
            self.current_locations.append(inside_language_navigation)
            if tag == "a" and inside_language_navigation:
                self.current_language_hrefs.append(attribute_map.get("href"))

    def handle_endtag(self, tag: str) -> None:
        if tag == "nav" and self.language_navigation_depth:
            self.language_navigation_depth -= 1


def validate(page: Path, expected_href: str) -> list[str]:
    """Return structural language-navigation errors for one localized page."""
    parser = LanguageNavigationParser()
    parser.feed(page.read_text(encoding="utf-8"))
    parser.close()
    errors: list[str] = []
    if parser.language_navigation_count != 1 or parser.language_navigation_depth != 0:
        errors.append("expected one closed language navigation")
    if parser.current_locations != [True]:
        errors.append("expected one current marker inside the language navigation")
    if parser.current_language_hrefs != [expected_href]:
        errors.append(f"expected current language href {expected_href!r}")
    return errors


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("usage: validate-public-site-language-nav.py PAGE EXPECTED_HREF")
    validation_errors = validate(Path(sys.argv[1]), sys.argv[2])
    if validation_errors:
        print("; ".join(validation_errors), file=sys.stderr)
        raise SystemExit(1)
