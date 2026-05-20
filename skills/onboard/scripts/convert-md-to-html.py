#!/usr/bin/env python3
"""Convert onboard analysis agent markdown output to HTML.

Reads the agent's structured markdown (split by ## headers), converts each
section to HTML, and injects the results into the HTML template.

Usage:
    python3 convert-md-to-html.py \
        --template path/to/html-template.html \
        --input path/to/agent-output.md \
        --repo-name my-repo \
        --date 2026-04-16 \
        --scope . \
        --output docs/onboard/2026-04-16-my-repo-onboard.html
"""

import argparse
import html
import os
import re
import sys

# Maps agent section headers to HTML template placeholder names.
SECTION_MAP = {
    "Project Overview & Tech Stack": "project-overview",
    "Architecture Map": "architecture-map",
    "Dependency Graph": "dependency-graph",
    "Entry Points": "entry-points",
    "Data & State Flow": "data-state-flow",
    "Key Abstractions": "key-abstractions",
    "Test Landscape": "test-landscape",
    "Build & Run Instructions": "build-run",
    "Suggested Reading Order": "reading-order",
}

FALLBACK_CONTENT = "<p>No data available for this section.</p>"

# Section IDs for cross-linking
SECTION_IDS = {
    "Project Overview & Tech Stack": "project-overview",
    "Architecture Map": "architecture-map",
    "Dependency Graph": "dependency-graph",
    "Entry Points": "entry-points",
    "Data & State Flow": "data-state-flow",
    "Key Abstractions": "key-abstractions",
    "Test Landscape": "test-landscape",
    "Build & Run Instructions": "build-run",
    "Suggested Reading Order": "reading-order",
}


def parse_sections(markdown: str) -> dict[str, str]:
    """Split agent markdown output by ## headers into a dict."""
    sections: dict[str, str] = {}
    current_header = None
    current_lines: list[str] = []

    for line in markdown.splitlines():
        match = re.match(r"^## (.+)$", line)
        if match:
            if current_header is not None:
                sections[current_header] = "\n".join(current_lines).strip()
            current_header = match.group(1).strip()
            current_lines = []
        elif current_header is not None:
            current_lines.append(line)

    if current_header is not None:
        sections[current_header] = "\n".join(current_lines).strip()

    return sections


def convert_markdown_to_html(md: str) -> str:
    """Convert a section's markdown content to HTML.

    Handles: headings, paragraphs, unordered/ordered lists, code blocks,
    inline code, bold, dep-arrows, and tables.
    """
    lines = md.splitlines()
    html_parts: list[str] = []
    i = 0

    while i < len(lines):
        line = lines[i]

        # Code block
        if line.strip().startswith("```"):
            code_lines: list[str] = []
            i += 1
            while i < len(lines) and not lines[i].strip().startswith("```"):
                code_lines.append(html.escape(lines[i]))
                i += 1
            i += 1  # skip closing ```
            html_parts.append(
                "<pre><code>" + "\n".join(code_lines) + "</code></pre>"
            )
            continue

        # Table
        if "|" in line and i + 1 < len(lines) and re.match(
            r"^\s*\|[\s\-:|]+\|\s*$", lines[i + 1]
        ):
            table_lines: list[str] = []
            while i < len(lines) and "|" in lines[i]:
                table_lines.append(lines[i])
                i += 1
            html_parts.append(_convert_table(table_lines))
            continue

        # Heading
        h4_match = re.match(r"^#### (.+)$", line)
        if h4_match:
            html_parts.append(f"<h4>{_inline(h4_match.group(1))}</h4>")
            i += 1
            continue

        h3_match = re.match(r"^### (.+)$", line)
        if h3_match:
            html_parts.append(f"<h3>{_inline(h3_match.group(1))}</h3>")
            i += 1
            continue

        # Unordered list
        if re.match(r"^\s*- ", line):
            items: list[str] = []
            while i < len(lines) and re.match(r"^\s*- ", lines[i]):
                item_text = re.sub(r"^\s*- ", "", lines[i])
                items.append(f"<li>{_inline(item_text)}</li>")
                i += 1
            html_parts.append("<ul>" + "\n".join(items) + "</ul>")
            continue

        # Ordered list
        if re.match(r"^\s*\d+\.\s", line):
            items = []
            while i < len(lines) and re.match(r"^\s*\d+\.\s", lines[i]):
                item_text = re.sub(r"^\s*\d+\.\s", "", lines[i])
                items.append(f"<li>{_inline(item_text)}</li>")
                i += 1
            html_parts.append("<ol>" + "\n".join(items) + "</ol>")
            continue

        # Empty line
        if not line.strip():
            i += 1
            continue

        # Paragraph (collect consecutive non-empty, non-special lines)
        para_lines: list[str] = []
        while (
            i < len(lines)
            and lines[i].strip()
            and not lines[i].strip().startswith("#")
            and not lines[i].strip().startswith("```")
            and not re.match(r"^\s*[-\d]", lines[i])
            and not (
                "|" in lines[i]
                and i + 1 < len(lines)
                and re.match(r"^\s*\|[\s\-:|]+\|\s*$", lines[i + 1])
            )
        ):
            para_lines.append(lines[i])
            i += 1
        if para_lines:
            html_parts.append(f"<p>{_inline(' '.join(para_lines))}</p>")

    return "\n".join(html_parts)


def _inline(text: str) -> str:
    """Convert inline markdown: bold, code, dep-arrows, cross-links."""
    # Inline code
    text = re.sub(r"`([^`]+)`", r"<code>\1</code>", text)
    # Bold
    text = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", text)
    # Dep arrows
    text = text.replace("\u2192", '<span class="dep-arrow">\u2192</span>')
    # Cross-link section references
    for section_name, section_id in SECTION_IDS.items():
        text = text.replace(
            section_name, f'<a href="#{section_id}">{section_name}</a>'
        )
    return text


def _convert_table(lines: list[str]) -> str:
    """Convert a markdown table to HTML."""
    rows: list[list[str]] = []
    for line in lines:
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        rows.append(cells)

    if len(rows) < 2:
        return ""

    # First row is header, second is separator (skip it)
    header = rows[0]
    body = rows[2:]

    parts = ["<table>"]
    parts.append("<thead><tr>")
    for cell in header:
        parts.append(f"<th>{_inline(cell)}</th>")
    parts.append("</tr></thead>")

    if body:
        parts.append("<tbody>")
        for row in body:
            parts.append("<tr>")
            for cell in row:
                parts.append(f"<td>{_inline(cell)}</td>")
            parts.append("</tr>")
        parts.append("</tbody>")

    parts.append("</table>")
    return "\n".join(parts)


def assemble(
    template: str,
    sections: dict[str, str],
    repo_name: str,
    date: str,
    scope: str,
) -> str:
    """Replace all placeholders in the template with content."""
    result = template

    # Meta placeholders
    result = result.replace("<!-- META:repo-name -->", html.escape(repo_name))
    result = result.replace("<!-- META:date -->", html.escape(date))
    result = result.replace("<!-- META:scope -->", html.escape(scope))

    # Content placeholders
    for section_header, placeholder_name in SECTION_MAP.items():
        placeholder = f"<!-- CONTENT:{placeholder_name} -->"
        md_content = sections.get(section_header, "")
        if md_content:
            html_content = convert_markdown_to_html(md_content)
        else:
            html_content = FALLBACK_CONTENT
        result = result.replace(placeholder, html_content)

    # Fill any remaining placeholders
    result = re.sub(
        r"<!-- CONTENT:[a-z-]+ -->",
        FALLBACK_CONTENT,
        result,
    )
    result = re.sub(
        r"<!-- META:[a-z-]+ -->",
        "unknown",
        result,
    )

    return result


def validate(assembled_html: str) -> list[str]:
    """Check the assembled HTML for common issues. Returns a list of errors."""
    errors: list[str] = []

    if not assembled_html.strip():
        errors.append("Output HTML is empty")
        return errors

    if "<!-- CONTENT:" in assembled_html:
        errors.append("Unfilled CONTENT placeholders remain in output")

    if "<!-- META:" in assembled_html:
        errors.append("Unfilled META placeholders remain in output")

    # Check that key sections have real content
    for section_name in ["project-overview", "architecture-map"]:
        section_id = f'id="{section_name}"'
        if section_id in assembled_html:
            # Find the section content between the section tags
            idx = assembled_html.index(section_id)
            # Check if the section only has fallback content
            section_chunk = assembled_html[idx : idx + 2000]
            if (
                FALLBACK_CONTENT in section_chunk
                and section_chunk.count("<p>") == 1
            ):
                errors.append(
                    f"Section '{section_name}' contains only fallback "
                    "content — agent output may be malformed"
                )

    return errors


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert onboard agent markdown to HTML"
    )
    parser.add_argument(
        "--template", required=True, help="Path to html-template.html"
    )
    parser.add_argument(
        "--input", required=True, help="Path to agent markdown output"
    )
    parser.add_argument("--repo-name", required=True, help="Repository name")
    parser.add_argument(
        "--date", required=True, help="Date in YYYY-MM-DD format"
    )
    parser.add_argument(
        "--scope", required=True, help="Analysis scope (. or path)"
    )
    parser.add_argument("--output", required=True, help="Output HTML path")
    args = parser.parse_args()

    # Read inputs
    with open(args.template, encoding="utf-8") as f:
        template = f.read()

    with open(args.input, encoding="utf-8") as f:
        markdown = f.read()

    # Parse and convert
    sections = parse_sections(markdown)
    assembled = assemble(template, sections, args.repo_name, args.date, args.scope)

    # Validate
    errors = validate(assembled)
    if errors:
        for error in errors:
            print(f"WARNING: {error}", file=sys.stderr)

    # Write output
    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    with open(args.output, "w", encoding="utf-8") as f:
        f.write(assembled)

    print(f"Generated: {args.output} ({len(assembled)} bytes)")

    if errors:
        print(
            f"\n{len(errors)} warning(s) — review the output file.",
            file=sys.stderr,
        )
        sys.exit(1)


if __name__ == "__main__":
    main()
