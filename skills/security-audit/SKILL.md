---
name: Security Audit
description: Automated security audit skill for detecting secrets, tokens, and security vulnerabilities in code
version: 1.0.0
author: Cloud Neutral Toolkit
tags: [security, audit, secrets, tokens, best-practices]
---

# Security Audit Skill

This skill provides automated security auditing capabilities for detecting secrets, tokens, API keys, and other security vulnerabilities in your codebase.

## Overview

The Security Audit Skill helps you:
- Detect hardcoded secrets and API keys
- Verify secure token transmission
- Check for logging of sensitive information
- Validate environment variable usage
- Ensure compliance with security best practices

## Usage

### Quick Audit

Run a quick security audit on your repository:

```bash
./skills/security-audit/scripts/quick-audit.sh
```

### Full Audit

Run a comprehensive security audit with detailed reporting:

```bash
./skills/security-audit/scripts/full-audit.sh
```

### Token Transmission Audit

Specifically audit service token transmission:

```bash
./skills/security-audit/scripts/audit-token-transmission.sh
```

### Pre-commit Hook

Install as a pre-commit hook to prevent secrets from being committed:

```bash
./skills/security-audit/scripts/install-pre-commit-hook.sh
```

## What It Checks

### 1. Hardcoded Secrets Detection

Scans for:
- API keys (AWS, Google Cloud, Stripe, etc.)
- Database passwords
- Private keys
- OAuth tokens
- JWT secrets

### 2. Token Transmission Security

Verifies:
- Tokens only in HTTP headers, never in URLs
- No query parameter leakage
- Proper HTTPS usage
- No token logging

### 3. Environment Variable Security

Checks:
- Secrets read from environment variables
- No hardcoded credentials
- Proper .env file usage
- .gitignore includes .env files

### 4. Logging Security

Detects:
- Logging of sensitive tokens
- Password logging
- API key exposure in logs
- Debug output containing secrets

### 5. Error Handling

Validates:
- Generic error messages
- No information leakage
- Proper error sanitization

## Configuration

Create a `.security-audit.yml` file in your repository root:

```yaml
# Security Audit Configuration
version: 1.0

# Patterns to detect (regex)
secret_patterns:
  - name: "AWS Access Key"
    pattern: "AKIA[0-9A-Z]{16}"
    severity: "critical"
  
  - name: "Generic API Key"
    pattern: "api[_-]?key['\"]?\\s*[:=]\\s*['\"][a-zA-Z0-9]{32,}['\"]"
    severity: "high"
  
  - name: "Private Key"
    pattern: "-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----"
    severity: "critical"

# Files to exclude from scanning
exclude_paths:
  - "node_modules/"
  - ".git/"
  - "*.test.js"
  - "*.test.ts"
  - "test/fixtures/"

# Custom token names to check
custom_tokens:
  - "INTERNAL_SERVICE_TOKEN"
  - "JWT_SECRET"
  - "DATABASE_PASSWORD"

# Logging patterns to detect
logging_patterns:
  - "console.log.*password"
  - "console.log.*token"
  - "console.log.*secret"
  - "logger.*apiKey"
```

## Best Practices

### ✅ DO

1. **Use Environment Variables**
   ```typescript
   const apiKey = process.env.API_KEY
   ```

2. **Transmit Tokens via Headers**
   ```typescript
   headers: {
     'X-Service-Token': process.env.INTERNAL_SERVICE_TOKEN
   }
   ```

3. **Generic Error Messages**
   ```typescript
   return { error: 'Authentication failed' }
   ```

4. **Sanitize Logs**
   ```typescript
   console.log(`Request to ${url.replace(/token=.+/, 'token=***')}`)
   ```

5. **Use Secrets Management**
   - Cloud Run Secrets
   - AWS Secrets Manager
   - HashiCorp Vault

### ❌ DON'T

1. **Hardcode Secrets**
   ```typescript
   // ❌ NEVER DO THIS
   const apiKey = "your-api-key..."
   ```

2. **Tokens in URLs**
   ```typescript
   // ❌ NEVER DO THIS
   fetch(`/api/data?token=${serviceToken}`)
   ```

3. **Log Sensitive Data**
   ```typescript
   // ❌ NEVER DO THIS
   console.log('Token:', serviceToken)
   ```

4. **Expose in Error Messages**
   ```typescript
   // ❌ NEVER DO THIS
   return { error: `Invalid token: ${token}` }
   ```

5. **Commit .env Files**
   ```bash
   # ❌ NEVER DO THIS
   git add .env
   ```

## Integration with CI/CD

### GitHub Actions

```yaml
name: Security Audit

on: [push, pull_request]

jobs:
  security-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Security Audit
        run: |
          chmod +x ./skills/security-audit/scripts/full-audit.sh
          ./skills/security-audit/scripts/full-audit.sh
      
      - name: Upload Audit Report
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: security-audit-report
          path: security-audit-report.txt
```

### Cloud Build

```yaml
steps:
  - name: 'bash'
    args:
      - '-c'
      - |
        chmod +x ./skills/security-audit/scripts/full-audit.sh
        ./skills/security-audit/scripts/full-audit.sh
```

## Reporting

Audit reports include:

- **Summary**: Pass/fail status and issue count
- **Critical Issues**: Hardcoded secrets, exposed credentials
- **High Priority**: Insecure token transmission, logging issues
- **Medium Priority**: Missing .gitignore entries, weak patterns
- **Low Priority**: Best practice recommendations
- **Compliance**: Checklist of security requirements

## Examples

### Example 1: Detect Hardcoded API Key

```bash
$ ./skills/security-audit/scripts/quick-audit.sh

❌ CRITICAL: Hardcoded API key detected
   File: src/config.ts:15
   Pattern: api_key = "sk_live_..."
   
   Fix: Use environment variable instead
   const apiKey = process.env.API_KEY
```

### Example 2: Token in URL

```bash
$ ./skills/security-audit/scripts/audit-token-transmission.sh

❌ HIGH: Token in URL parameter
   File: src/api/client.ts:42
   Code: fetch(`/api?token=${token}`)
   
   Fix: Use HTTP header instead
   headers: { 'Authorization': `Bearer ${token}` }
```

### Example 3: Sensitive Logging

```bash
$ ./skills/security-audit/scripts/quick-audit.sh

⚠️  MEDIUM: Potential sensitive data logging
   File: src/auth/middleware.ts:28
   Code: console.log('User token:', userToken)
   
   Fix: Remove or redact sensitive data
   console.log('User authenticated')
```

## Advanced Usage

### Custom Patterns

Add custom secret patterns to detect:

```bash
./skills/security-audit/scripts/quick-audit.sh \
  --pattern "custom[_-]secret['\"]?\\s*[:=]\\s*['\"][^'\"]+['\"]" \
  --severity critical
```

### Specific File Scan

Scan specific files or directories:

```bash
./skills/security-audit/scripts/quick-audit.sh \
  --path src/auth/ \
  --path src/api/
```

### Output Formats

Generate reports in different formats:

```bash
# JSON output
./skills/security-audit/scripts/full-audit.sh --format json > audit.json

# Markdown report
./skills/security-audit/scripts/full-audit.sh --format markdown > AUDIT.md

# HTML report
./skills/security-audit/scripts/full-audit.sh --format html > audit.html
```

## Troubleshooting

### False Positives

If the audit detects false positives, add them to `.security-audit-ignore`:

```
# .security-audit-ignore
src/test/fixtures/sample-key.txt:5  # Test fixture, not a real key
docs/examples/api-example.md:12     # Documentation example
```

### Performance

For large repositories, use incremental scanning:

```bash
# Only scan changed files
./skills/security-audit/scripts/quick-audit.sh --incremental

# Only scan files changed in last commit
./skills/security-audit/scripts/quick-audit.sh --since HEAD~1
```

## Support

For issues or questions:
- GitHub Issues: https://github.com/cloud-neutral-toolkit/.github/issues
- Documentation: https://github.com/cloud-neutral-toolkit/.github/docs
- Email: security@svc.plus

## License

MIT License - See LICENSE file for details
