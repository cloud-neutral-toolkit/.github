# Security Audit Skill

Automated security auditing for detecting secrets, tokens, and vulnerabilities.

## Quick Start

```bash
# Run quick security audit
./skills/security-audit/scripts/quick-audit.sh
```

## Documentation

- **[SKILL.md](./SKILL.md)** - Complete skill documentation
- **[BEST_PRACTICES.md](./BEST_PRACTICES.md)** - Security best practices guide

## Features

- ✅ Hardcoded secrets detection
- ✅ Token transmission security validation
- ✅ Sensitive data logging detection
- ✅ Environment variable security checks
- ✅ Error handling validation

## Usage

### Quick Audit

```bash
./skills/security-audit/scripts/quick-audit.sh
```

### Install in Other Repositories

```bash
# Copy skill to your repository
cp -r skills/security-audit /path/to/your/repo/skills/

# Run audit
cd /path/to/your/repo
./skills/security-audit/scripts/quick-audit.sh
```

## What It Detects

- AWS Access Keys
- Private Keys
- API Keys (Stripe, etc.)
- Hardcoded Passwords
- Tokens in URLs
- Sensitive Data in Logs
- Missing .gitignore entries

## Exit Codes

- `0` - Audit passed (no critical/high issues)
- `1` - Audit failed (critical issues found)

## Integration

### Pre-commit Hook

```bash
#!/bin/bash
./skills/security-audit/scripts/quick-audit.sh
exit $?
```

### GitHub Actions

```yaml
- name: Security Audit
  run: ./skills/security-audit/scripts/quick-audit.sh
```

## License

MIT
