# CloudOps Guardrail Box

Portable Azure IaC security guardrails using Checkov + Trivy + custom policies(Raspberry Pi)

## Overview

CloudOps Guardrail Box is a portable DevSecOps security enforcement setup that statically analyses Azure Terraform Infrastructure - as - Code(IaC) before deployment.

It combines:

- Checkov(built -in Azure policies + custom GR_AZURE policies)
    - Trivy(IaC misconfiguration scanning)
    - A single Bash pipeline to generate audit - ready reports

Built and tested on a Raspberry Pi(Linux CLI) to prove cloud security checks can run on low - cost ARM hardware.

## Why it matters

Cloud incidents often come from misconfigurations(open management ports, weak TLS, public endpoints), not sophisticated exploits.

This project demonstrates:

- Shift - left security(catch issues before deploy)
- Policy - as - Code guardrails for repeatability
    - Clear secure vs insecure IaC outcomes
        - Report outputs suitable for review and CI / CD integration

## Tech stack

    - Terraform(AzureRM)
    - Checkov(IaC security scanning)
    - Trivy(misconfiguration scanning)
    - Custom Checkov policies(GR_AZURE_ *)
        - OPA / Rego(policy extensibility)
        - Bash automation
            - Raspberry Pi(portable execution environment)

## Architecture
```
Terraform IaC (good/ bad)
        |
        v
+--------------------------+
|     guardrail_scan.sh    |
|  (orchestrates scanners) |
+--------------------------+
   |                 |
   v                 v
Checkov         Trivy config
(built-in +     (misconfig)
 custom checks)
   |                 |
   +--------+--------+
            v
      Reports output
 (TXT / JSON / SARIF / MD)
 
 ```

## Repository layout
```
cloudops-guardrail/
├── guardrail_scan.sh
├── README.md
├── .gitignore
├── iac/
│   └── terraform/
│       ├── good/
│       │   └── main.tf
│       └── bad/
│           └── main.tf
├── policies/
│   ├── checkov/
│   │   └── custom_checks/
│   │       ├── nsg_no_ssh_internet.py
│   │       ├── storage_no_public_network.py
│   │       └── storage_tls12.py
│   └── terraform/
│       └── azure.rego
└── reports/
    ├── good/
    └── bad/
```

## Security guardrails enforced

### Built -in Azure checks(Checkov)

Examples include:

- Restrict SSH / RDP exposure
    - Enforce secure storage settings(TLS, HTTPS)
        - Restrict public access to storage resources
            - Require stronger replication settings(where applicable)

### Custom Azure policies(Checkov)
```
| ID       | Policy    |
| GR_AZURE_001 | Disallow SSH(22) from Internet on NSG rules |
| GR_AZURE_002 | Storage must disable public network access |
| GR_AZURE_003 | Storage must require TLS 1.2 minimum |
```
## Results(GOOD vs BAD)

### GOOD configuration(secure)

Checkov:

```
Passed checks: 18, Failed checks: 0, Skipped checks: 0
```

Trivy:

```
Misconfigurations: 0
```

### BAD configuration(intentionally insecure)

Checkov:

```
Passed checks: 7, Failed checks: 10, Skipped checks: 0
```

Trivy:

```
HIGH: 1, CRITICAL: 3
```

## How to run

 ```
chmod +x guardrail_scan.sh
./guardrail_scan.sh good
./guardrail_scan.sh bad

```

Reports are written to:

```
reports/good/
reports/bad/
```

## Raspberry Pi build notes

Developed and executed on a Raspberry Pi

Designed to be lightweight and portable for:

    - home labs
        - demos
        - offline assessment
            - travel - friendly "security box"

Development time: approximately 3 days(setup, debugging, custom policy implementation, and validation)

## AZ - 500 relevance

This project maps directly to AZ - 500 themes:

- network security(NSGs)
    - storage hardening(TLS, public access, network access)
        - security posture validation
            - governance and guardrails
                - DevSecOps + policy enforcement

## Roadmap

    - GitHub Actions CI workflow(fail builds on critical findings)
        - Severity scoring + policy thresholds
            - Extend policies to additional Azure services(Key Vault, SQL, AKS, etc.)
                - Export consolidated summary dashboard

## Author

Naga Sai Abhiram Banda

*MSc Cybersecurity | CEH | CloudOps | Blue Team*

GitHub: https://github.com/bandaabhiram
