# GuardDuty Detection Coverage Report

## Methodology

GuardDuty's built-in sample findings generator (`aws guardduty create-sample-findings`) was used to populate the detector with realistic, AWS-curated findings spanning the full range of GuardDuty's detection capabilities. This is the same mechanism AWS itself recommends for testing detection pipelines without generating real malicious activity in the account.

400 unique findings were retrieved via the GuardDuty API and classified by:
- **MITRE ATT&CK tactic**, inferred from each finding's type prefix (GuardDuty finding type naming follows a `Tactic:Resource/Threat` convention that maps closely to ATT&CK tactic categories)
- **Severity band**, using AWS GuardDuty's own Low (0–3.9) / Medium (4–6.9) / High (7–10) scale

The automated response pipeline (EventBridge → Lambda → SNS, see `lambda-response.tf`) was separately validated via direct Lambda invocation with a synthetic finding payload, confirming successful processing and alert delivery.

## Results: Coverage by MITRE ATT&CK Tactic

| Tactic | Findings | % of Total |
|---|---|---|
| Persistence | 71 | 17.8% |
| Defense Evasion | 65 | 16.2% |
| Execution | 57 | 14.2% |
| Impact | 52 | 13.0% |
| Privilege Escalation | 43 | 10.8% |
| Initial Access | 35 | 8.8% |
| Discovery | 27 | 6.8% |
| Multiple (Attack Sequence) | 21 | 5.2% |
| Credential Access | 20 | 5.0% |
| Exfiltration | 6 | 1.5% |
| Other/Uncategorized | 3 | 0.8% |

## Results: Severity Distribution

| Severity Band | Findings | % of Total |
|---|---|---|
| High (7–10) | 176 | 44.0% |
| Medium (4–6.9) | 159 | 39.8% |
| Low (0–3.9) | 65 | 16.2% |

**212 distinct GuardDuty finding types** were represented across the 400 sample findings, demonstrating breadth across credential compromise, reconnaissance, privilege escalation, persistence mechanisms, defense evasion, and data exfiltration scenarios.

## Interpretation

The detector shows coverage across 8 of the primary MITRE ATT&CK tactics relevant to a cloud environment. Persistence, Defense Evasion, and Execution are the most heavily represented categories in GuardDuty's finding catalogue, reflecting AWS's detection emphasis on runtime and container-level threats (via GuardDuty Runtime Monitoring) alongside classical IAM and network-based threats.

**Limitation:** GuardDuty's sample findings do not trigger EventBridge events, a known AWS behaviour (undocumented directly, but consistently observed). This was worked around by validating the response pipeline (EventBridge → Lambda → SNS) independently via direct Lambda invocation with a synthetic payload matching the real event schema — see the "Automated Response" section of the main README for that validation.

## Next Steps

To close the gap between sample-finding coverage and *live* detection validation, a follow-up phase would involve triggering GuardDuty's other official testing mechanism — deliberately performing benign but detectable actions from within the account (e.g. querying the EC2 instance metadata service in a way that mimics credential exfiltration, or making an unusual API call pattern) and confirming a *real* finding is generated and correctly routed through the full pipeline end-to-end.
