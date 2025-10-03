#!/usr/bin/env python3
"""Generate a mapping between Terraform outputs and Resource Manager schema."""
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any, Dict, Iterable, List, Tuple

import hcl2
import yaml

REPO_ROOT = Path(__file__).resolve().parents[3]
OUTPUTS_PATH = REPO_ROOT / "deploy/coolify/outputs.tf"
SCHEMA_PATH = REPO_ROOT / "deploy/coolify/schema.yaml"
TARGET_PATH = REPO_ROOT / "deploy/coolify/docs/application-information-mapping.md"


def load_terraform_outputs() -> List[Tuple[str, Dict[str, Any]]]:
    with OUTPUTS_PATH.open("r", encoding="utf-8") as fh:
        parsed = hcl2.load(fh)
    terraform_outputs: List[Tuple[str, Dict[str, Any]]] = []
    for block in parsed.get("output", []):
        if not isinstance(block, dict):
            continue
        (name, body), = block.items()
        terraform_outputs.append((name, body))
    return terraform_outputs


def load_schema() -> Tuple[Dict[str, Any], List[Dict[str, Any]]]:
    with SCHEMA_PATH.open("r", encoding="utf-8") as fh:
        schema = yaml.safe_load(fh)
    outputs = schema.get("outputs", {}) or {}
    output_groups = schema.get("outputGroups") or []
    return outputs, output_groups


def clean_value(value: Any) -> Any:
    if isinstance(value, str):
        text = value.strip()
        if text.startswith("${") and text.endswith("}"):
            text = text[2:-1]
        text = re.sub(r"\$\{([^}]*)\}", r"\1", text)
        return text
    if isinstance(value, dict):
        return {k: clean_value(v) for k, v in value.items()}
    if isinstance(value, list):
        return [clean_value(v) for v in value]
    return value


def summarise_value(value: Any) -> str:
    cleaned = clean_value(value)
    if isinstance(cleaned, (dict, list)):
        summary = json.dumps(cleaned, ensure_ascii=False)
    else:
        summary = str(cleaned)
    summary = " ".join(summary.split())
    if len(summary) > 180:
        summary = summary[:177].rstrip() + "…"
    return summary


def render_table(rows: Iterable[Dict[str, Any]]) -> str:
    headers = [
        "Output name (`outputs.tf`)",
        "Declared in `schema.yaml`?",
        "Title in Application Tab",
        "Sensitive?",
        "Value Source",
    ]
    lines = ["| " + " | ".join(headers) + " |"]
    lines.append("| " + " | ".join(["---"] * len(headers)) + " |")
    for row in rows:
        line = "| {output} | {declared} | {title} | {sensitive} | {value} |".format(**row)
        lines.append(line)
    return "\n".join(lines)


def main() -> None:
    terraform_outputs = load_terraform_outputs()
    schema_outputs, output_groups = load_schema()
    terraform_output_names = [name for name, _ in terraform_outputs]

    application_groups = [
        group for group in output_groups
        if group.get("title", "").strip().lower() == "application information"
    ]
    application_output_names: List[str] = []
    for group in application_groups:
        application_output_names.extend(group.get("outputs", []))

    rows = []
    for name, body in terraform_outputs:
        value_summary = summarise_value(body.get("value")) if "value" in body else ""
        declared = name in schema_outputs
        declared_text = "✅ Yes" if declared else "❌ No"
        title = schema_outputs.get(name, {}).get("title", "(auto-labelled)") if declared else "(auto-labelled)"
        sensitive_flag = body.get("sensitive", False)
        sensitive_text = "true" if sensitive_flag else "false"
        rows.append({
            "output": f"`{name}`",
            "declared": declared_text,
            "title": title,
            "sensitive": sensitive_text,
            "value": f"`{value_summary}`",
        })

    schema_only = sorted(set(schema_outputs.keys()) - set(terraform_output_names))
    terraform_only = sorted(set(terraform_output_names) - set(schema_outputs.keys()))

    table_md = render_table(rows)

    lines: List[str] = []
    lines.append("# Application information output mapping")
    lines.append("")
    lines.append(
        "This document maps Terraform root module outputs to the Oracle Cloud Resource Manager schema so "
        "you can see which values appear on the **Application information** tab." )
    lines.append("")
    lines.append("## Terraform outputs")
    lines.append("")
    lines.append("The root module defines the following outputs in [`outputs.tf`](../outputs.tf).")
    lines.append("")
    lines.append(table_md)
    lines.append("")
    lines.append("## Findings")
    lines.append("")
    if terraform_only:
        lines.append("- Outputs missing from `schema.yaml`: ``{}``.".format("`, `".join(terraform_only)))
    else:
        lines.append("- All Terraform outputs are declared in `schema.yaml`.")
    if schema_only:
        lines.append("- Outputs declared in `schema.yaml` but missing from Terraform: ``{}``.".format("`, `".join(schema_only)))
    else:
        lines.append("- No extra outputs are declared in `schema.yaml`.")
    if not application_groups:
        lines.append("- `schema.yaml` does not currently define an `outputGroups` entry for **Application information**.")
    else:
        lines.append(
            "- The following outputs are surfaced on the **Application information** tab: ``{}``.".format(
                "`, `".join(application_output_names) if application_output_names else "(none)"
            )
        )
    lines.append("")
    lines.append("## Surface additional outputs on Application information")
    lines.append("")
    lines.append("To show more Terraform outputs in Application information:")
    lines.append("1. Add them to the `outputs` map in [`schema.yaml`](../schema.yaml) with user-friendly titles.")
    lines.append("2. Create or update an `outputGroups` entry with `title: Application information` and list the output names.")
    lines.append("3. Re-run this script to refresh the mapping table.")
    lines.append("")
    lines.append("Generated by [`scripts/generate_application_info_mapping.py`](../scripts/generate_application_info_mapping.py).")

    TARGET_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
