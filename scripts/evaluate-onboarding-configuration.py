#!/usr/bin/env python3
"""Evaluate onboarding settings without executing, resolving, or mutating anything."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent.parent
CHOICES = {"guided-setup": "guidedSettings", "existing-setup": "existingSettings"}
STATES = {"validated", "customized", "unverified", "blocked"}
REQUEST_FIELDS = {"schemaVersion", "kind", "domainId", "choiceId", "settings"}
ADMISSION_FIELDS = {
    "schemaVersion", "kind", "domainId", "allowedChoiceIds", "baseState",
    "profileId", "existingProfileIndependentlyValidated",
}
REFERENCE_PATTERNS = {
    "opaque-reference": re.compile(r"^ref:[A-Za-z0-9][A-Za-z0-9._-]{0,127}$"),
    "path-grant-reference": re.compile(r"^grant:[A-Za-z0-9][A-Za-z0-9._-]{0,127}$"),
    "secret-reference": re.compile(r"^secret:[A-Za-z0-9][A-Za-z0-9._-]{0,127}$"),
}


class PolicyError(ValueError):
    pass


def load_object(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise PolicyError(f"JSON root must be an object: {path}")
    return value


def validate_contract(contract: dict[str, Any]) -> None:
    if contract.get("schemaVersion") != 1 or contract.get("runtimeAdmitted") is not False:
        raise PolicyError("Setting schema must be version 1 and runtime-admission false.")
    if contract.get("defaultDecision") != "blocked":
        raise PolicyError("Unknown setting combinations must default to blocked.")
    policy = contract.get("rendererInputPolicy", {})
    required_false = {
        "unknownFieldsAllowed", "rawEndpointsAllowed", "rawFilesystemPathsAllowed",
        "plaintextCredentialsAllowed", "commandsExecutablesArgumentsOrEnvironmentAllowed",
        "rendererSuppliedEvidenceOrApprovalAllowed",
    }
    if any(policy.get(key) is not False for key in required_false):
        raise PolicyError("Renderer input policy must reject every authority-bearing input class.")
    if policy.get("opaqueReferencesResolvedOnlyByNativeOrEngineAuthority") is not True:
        raise PolicyError("Opaque references must remain outside renderer authority.")


def blocked(domain_id: Any, choice_id: Any, reasons: list[str]) -> dict[str, Any]:
    return result(domain_id, choice_id, "blocked", reasons, [])


def result(domain_id: Any, choice_id: Any, state: str, reasons: list[str], setting_ids: list[str]) -> dict[str, Any]:
    return {
        "schemaVersion": 1,
        "kind": "onboarding-configuration-decision",
        "domainId": domain_id if isinstance(domain_id, str) else None,
        "choiceId": choice_id if isinstance(choice_id, str) else None,
        "configurationState": state,
        "executionAllowed": state in {"validated", "customized"},
        "reasonCodes": sorted(set(reasons)),
        "evaluatedSettingIds": sorted(setting_ids),
        "effects": {
            "networkUsed": False, "filesWritten": False, "downloadsStarted": False,
            "processesStarted": False, "approvalGranted": False,
            "sensitiveValuesReturned": False,
        },
    }


def exact_fields(value: dict[str, Any], allowed: set[str]) -> bool:
    return set(value) <= allowed


def value_state(definition: dict[str, Any], value: Any) -> str:
    kind = definition.get("type")
    if kind in REFERENCE_PATTERNS:
        return "validated" if isinstance(value, str) and REFERENCE_PATTERNS[kind].fullmatch(value) else "blocked"
    if kind == "boolean":
        if not isinstance(value, bool):
            return "blocked"
        validated = definition.get("validatedValues", [])
        return "validated" if value in validated else "unverified"
    if kind == "integer":
        if isinstance(value, bool) or not isinstance(value, int):
            return "blocked"
        minimum, maximum = definition.get("minimum"), definition.get("maximum")
        if not isinstance(minimum, int) or not isinstance(maximum, int) or not minimum <= value <= maximum:
            return "blocked"
        valid_min = definition.get("validatedMinimum", minimum)
        valid_max = definition.get("validatedMaximum", maximum)
        return "validated" if valid_min <= value <= valid_max else "unverified"
    if kind == "enum":
        allowed = definition.get("allowedValues", [])
        if value not in allowed:
            return "blocked"
        return "validated" if value in definition.get("validatedValues", []) else "unverified"
    return "blocked"


def evaluate(request: dict[str, Any], admission: dict[str, Any], contract: dict[str, Any]) -> dict[str, Any]:
    validate_contract(contract)
    domain_id, choice_id = request.get("domainId"), request.get("choiceId")
    if not exact_fields(request, REQUEST_FIELDS) or request.get("schemaVersion") != 1 or request.get("kind") != "onboarding-settings-request":
        return blocked(domain_id, choice_id, ["invalid-or-authority-bearing-request"])
    if not exact_fields(admission, ADMISSION_FIELDS) or admission.get("schemaVersion") != 1 or admission.get("kind") != "trusted-onboarding-admission":
        return blocked(domain_id, choice_id, ["invalid-trusted-admission"])
    domains = {item.get("id"): item for item in contract.get("domains", [])}
    domain = domains.get(domain_id)
    settings = request.get("settings")
    if domain is None or not isinstance(settings, dict):
        return blocked(domain_id, choice_id, ["unknown-domain-or-invalid-settings"])
    if admission.get("domainId") != domain_id:
        return blocked(domain_id, choice_id, ["cross-domain-admission-rejected"])
    allowed_choices = admission.get("allowedChoiceIds")
    known_choices = {*CHOICES, "not-now"}
    if (not isinstance(allowed_choices, list)
            or len(allowed_choices) != len(set(allowed_choices))
            or any(not isinstance(item, str) or item not in known_choices for item in allowed_choices)):
        return blocked(domain_id, choice_id, ["invalid-trusted-admission"])
    if choice_id not in known_choices or choice_id not in allowed_choices:
        return blocked(domain_id, choice_id, ["choice-not-admitted"])
    base_state = admission.get("baseState")
    profile_id = admission.get("profileId")
    independently_validated = admission.get("existingProfileIndependentlyValidated")
    if (base_state not in {"validated", "unverified", "blocked"}
            or not isinstance(profile_id, str) or not profile_id or len(profile_id) > 128
            or not isinstance(independently_validated, bool)):
        return blocked(domain_id, choice_id, ["invalid-trusted-admission"])
    if choice_id == "not-now":
        return blocked(domain_id, choice_id, ["user-deferred"] if not settings else ["not-now-must-be-effect-free"])
    definitions = {item.get("id"): item for item in domain.get(CHOICES[choice_id], [])}
    unknown = sorted(set(settings) - set(definitions))
    if unknown:
        return blocked(domain_id, choice_id, ["unknown-setting"])
    states = [value_state(definitions[key], value) for key, value in settings.items()]
    if "blocked" in states:
        return blocked(domain_id, choice_id, ["unsafe-or-invalid-setting"])
    if base_state == "blocked":
        return blocked(domain_id, choice_id, ["base-profile-blocked"])
    if base_state == "unverified":
        return result(domain_id, choice_id, "unverified", ["base-profile-unverified"], list(settings))
    if choice_id == "existing-setup" and independently_validated is not True:
        return result(domain_id, choice_id, "unverified", ["existing-profile-not-independently-validated"], list(settings))
    if "unverified" in states:
        return result(domain_id, choice_id, "unverified", ["setting-outside-validated-evidence"], list(settings))
    state = "customized" if settings else "validated"
    return result(domain_id, choice_id, state, ["within-exact-validated-bounds"], list(settings))


def self_test() -> None:
    contract = load_object(ROOT / "config/onboarding-setting-schemas.json")
    def req(domain: str, choice: str, settings: dict[str, Any]) -> dict[str, Any]:
        return {"schemaVersion": 1, "kind": "onboarding-settings-request", "domainId": domain, "choiceId": choice, "settings": settings}
    def adm(domain: str, state: str = "validated", independent: bool = True) -> dict[str, Any]:
        return {"schemaVersion": 1, "kind": "trusted-onboarding-admission", "domainId": domain, "allowedChoiceIds": ["guided-setup", "existing-setup", "not-now"], "baseState": state, "profileId": "fixture-exact-profile", "existingProfileIndependentlyValidated": independent}
    cases = [
        (req("image-generation", "guided-setup", {}), adm("image-generation"), "validated"),
        (req("image-generation", "guided-setup", {"steps": 20}), adm("image-generation"), "customized"),
        (req("image-generation", "guided-setup", {"steps": 100}), adm("image-generation"), "unverified"),
        (req("text-providers", "existing-setup", {"connection-scope": "public"}), adm("text-providers"), "blocked"),
        (req("image-generation", "guided-setup", {"shell-command": "whoami"}), adm("image-generation"), "blocked"),
        (req("text-providers", "existing-setup", {"credential-reference": "plaintext-password"}), adm("text-providers"), "blocked"),
        ({**req("image-generation", "guided-setup", {}), "configurationState": "validated"}, adm("image-generation"), "blocked"),
        (req("text-providers", "existing-setup", {}), adm("text-providers", independent=False), "unverified"),
        (req("image-generation", "not-now", {}), adm("image-generation"), "blocked"),
        (req("image-generation", "guided-setup", {}), adm("text-providers"), "blocked"),
        (req("image-generation", "guided-setup", {}), {**adm("image-generation"), "allowedChoiceIds": "guided-setup"}, "blocked"),
    ]
    for index, (request, admission, expected) in enumerate(cases, 1):
        decision = evaluate(request, admission, contract)
        assert decision["configurationState"] == expected, (index, decision)
        assert not any(decision["effects"].values())
        assert "fixture-exact-profile" not in json.dumps(decision)
    print(f"Onboarding configuration policy self-test passed: {len(cases)} cases")


def main() -> int:
    parser = argparse.ArgumentParser(description="Evaluate renderer-supplied onboarding settings without machine effects.")
    parser.add_argument("--request-path")
    parser.add_argument("--admission-path")
    parser.add_argument("--schema-path", default=str(ROOT / "config/onboarding-setting-schemas.json"))
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    try:
        if args.self_test:
            self_test()
            return 0
        if not args.request_path or not args.admission_path:
            raise PolicyError("--request-path and --admission-path are required.")
        decision = evaluate(load_object(Path(args.request_path)), load_object(Path(args.admission_path)), load_object(Path(args.schema_path)))
        sys.stdout.write(json.dumps(decision, indent=2) + "\n")
        return 0 if decision["configurationState"] in {"validated", "customized"} else 2
    except (OSError, json.JSONDecodeError, PolicyError) as error:
        print(f"onboarding-policy-error: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
