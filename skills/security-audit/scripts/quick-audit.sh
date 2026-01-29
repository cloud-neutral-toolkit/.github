#!/bin/bash
# Quick Security Audit Script
# Performs fast security checks for common issues

set -e

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
CRITICAL=0
HIGH=0
MEDIUM=0
LOW=0

echo "=========================================="
echo "Quick Security Audit"
echo "=========================================="
echo ""

# Get repository root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO_ROOT"

echo "📁 Repository: $REPO_ROOT"
echo "⏰ Scan started: $(date)"
echo ""

# Function to report issue
report_issue() {
    local severity=$1
    local message=$2
    local file=$3
    local line=$4
    
    case $severity in
        CRITICAL)
            echo -e "${RED}❌ CRITICAL${NC}: $message"
            ((CRITICAL++))
            ;;
        HIGH)
            echo -e "${RED}⚠️  HIGH${NC}: $message"
            ((HIGH++))
            ;;
        MEDIUM)
            echo -e "${YELLOW}⚠️  MEDIUM${NC}: $message"
            ((MEDIUM++))
            ;;
        LOW)
            echo -e "${BLUE}ℹ️  LOW${NC}: $message"
            ((LOW++))
            ;;
    esac
    
    if [ -n "$file" ]; then
        echo "   📄 File: $file${line:+:$line}"
    fi
    echo ""
}

# Check 1: Hardcoded secrets patterns
echo "🔍 Check 1: Scanning for hardcoded secrets..."
echo "---------------------------------------------"

# AWS Keys
if git grep -n "AKIA[0-9A-Z]\{16\}" -- '*.ts' '*.js' '*.go' '*.py' '*.java' 2>/dev/null; then
    report_issue "CRITICAL" "AWS Access Key detected" "$(git grep -l 'AKIA[0-9A-Z]\{16\}' -- '*.ts' '*.js' '*.go' '*.py' '*.java' 2>/dev/null | head -1)"
fi

# Private keys
if git grep -n "BEGIN.*PRIVATE KEY" -- '*.pem' '*.key' '*.ts' '*.js' '*.go' 2>/dev/null; then
    report_issue "CRITICAL" "Private key detected" "$(git grep -l 'BEGIN.*PRIVATE KEY' 2>/dev/null | head -1)"
fi

# Generic API keys (common patterns)
if git grep -nE "api[_-]?key['\"]?\s*[:=]\s*['\"][a-zA-Z0-9]{32,}['\"]" -- '*.ts' '*.js' '*.go' '*.py' 2>/dev/null | grep -v "process.env" | grep -v "os.Getenv"; then
    report_issue "HIGH" "Potential hardcoded API key" "$(git grep -lE 'api[_-]?key.*[:=].*[a-zA-Z0-9]{32,}' -- '*.ts' '*.js' '*.go' '*.py' 2>/dev/null | grep -v 'process.env' | head -1)"
fi

# Stripe keys
if git grep -nE "sk_(live|test)_[a-zA-Z0-9]{24,}" -- '*.ts' '*.js' '*.go' '*.py' 2>/dev/null | grep -v "YOUR_" | grep -v "PLACEHOLDER" | grep -v "<"; then
    report_issue "CRITICAL" "Stripe API key detected" "$(git grep -lE 'sk_(live|test)_[a-zA-Z0-9]{24,}' 2>/dev/null | head -1)"
fi

# Database passwords
if git grep -nE "password['\"]?\s*[:=]\s*['\"][^'\"]{8,}['\"]" -- '*.ts' '*.js' '*.go' '*.py' '*.yml' '*.yaml' 2>/dev/null | grep -v "process.env" | grep -v "os.Getenv" | grep -v "YOUR_PASSWORD" | grep -v "example"; then
    report_issue "CRITICAL" "Potential hardcoded password" "$(git grep -lE 'password.*[:=].*[a-zA-Z0-9]{8,}' 2>/dev/null | head -1)"
fi

echo "✓ Secret scanning complete"
echo ""

# Check 2: Token transmission security
echo "🔍 Check 2: Token transmission security..."
echo "---------------------------------------------"

# Tokens in URL parameters
if git grep -nE "token.*[\?&]|[\?&].*token" -- '*.ts' '*.js' '*.go' '*.py' 2>/dev/null | grep -v "// " | grep -v "# "; then
    report_issue "HIGH" "Token may be transmitted in URL parameter" "$(git grep -lE 'token.*[\?&]' 2>/dev/null | head -1)"
fi

# Tokens in query strings
if git grep -nE "query.*token|token.*query" -- '*.ts' '*.js' '*.go' '*.py' 2>/dev/null | grep -v "// " | grep -v "# " | grep -v "queryToken"; then
    report_issue "MEDIUM" "Potential token in query string" "$(git grep -lE 'query.*token' 2>/dev/null | head -1)"
fi

echo "✓ Token transmission check complete"
echo ""

# Check 3: Sensitive data logging
echo "🔍 Check 3: Sensitive data logging..."
echo "---------------------------------------------"

# Console.log with tokens
if git grep -nE "console\.log.*token|console\.log.*password|console\.log.*secret|console\.log.*apiKey" -- '*.ts' '*.js' 2>/dev/null | grep -v "// " | grep -v "Proxying" | grep -v "Target URL"; then
    report_issue "MEDIUM" "Potential sensitive data logging" "$(git grep -lE 'console\.log.*(token|password|secret|apiKey)' 2>/dev/null | head -1)"
fi

# Logger with sensitive data
if git grep -nE "logger\.(info|debug|warn).*token|logger\.(info|debug|warn).*password" -- '*.ts' '*.js' '*.go' '*.py' 2>/dev/null | grep -v "// " | grep -v "# "; then
    report_issue "MEDIUM" "Potential sensitive data in logs" "$(git grep -lE 'logger.*token' 2>/dev/null | head -1)"
fi

# fmt.Print with tokens (Go)
if git grep -nE "fmt\.Print.*token|fmt\.Print.*password|log\.Print.*token" -- '*.go' 2>/dev/null | grep -v "// "; then
    report_issue "MEDIUM" "Potential sensitive data logging in Go" "$(git grep -lE 'fmt\.Print.*token' 2>/dev/null | head -1)"
fi

echo "✓ Logging check complete"
echo ""

# Check 4: Environment variable usage
echo "🔍 Check 4: Environment variable security..."
echo "---------------------------------------------"

# Check if .env is in .gitignore
if [ -f .gitignore ]; then
    if ! grep -q "^\.env$" .gitignore && ! grep -q "^\.env" .gitignore; then
        report_issue "HIGH" ".env file not in .gitignore" ".gitignore"
    fi
else
    report_issue "MEDIUM" "No .gitignore file found"
fi

# Check for committed .env files
if git ls-files | grep -E "^\.env$|^\.env\.production$|^\.env\.local$" 2>/dev/null; then
    report_issue "CRITICAL" ".env file committed to repository" "$(git ls-files | grep '\.env' | head -1)"
fi

echo "✓ Environment variable check complete"
echo ""

# Check 5: Error handling
echo "🔍 Check 5: Error message security..."
echo "---------------------------------------------"

# Error messages exposing tokens
if git grep -nE "error.*token.*\$\{|error.*password.*\$\{" -- '*.ts' '*.js' '*.go' '*.py' 2>/dev/null | grep -v "// " | grep -v "# "; then
    report_issue "HIGH" "Error message may expose sensitive data" "$(git grep -lE 'error.*token.*\$\{' 2>/dev/null | head -1)"
fi

echo "✓ Error handling check complete"
echo ""

# Summary
echo "=========================================="
echo "Audit Summary"
echo "=========================================="
echo -e "${RED}Critical Issues: $CRITICAL${NC}"
echo -e "${RED}High Priority:   $HIGH${NC}"
echo -e "${YELLOW}Medium Priority: $MEDIUM${NC}"
echo -e "${BLUE}Low Priority:    $LOW${NC}"
echo ""

TOTAL=$((CRITICAL + HIGH + MEDIUM + LOW))

if [ $CRITICAL -gt 0 ]; then
    echo -e "${RED}❌ AUDIT FAILED${NC} - Critical issues must be fixed immediately"
    echo ""
    echo "Recommendations:"
    echo "1. Remove all hardcoded secrets"
    echo "2. Use environment variables for sensitive data"
    echo "3. Review and fix all critical issues before committing"
    exit 1
elif [ $HIGH -gt 0 ]; then
    echo -e "${YELLOW}⚠️  AUDIT WARNING${NC} - High priority issues should be addressed"
    echo ""
    echo "Recommendations:"
    echo "1. Review high priority issues"
    echo "2. Implement recommended fixes"
    echo "3. Run audit again to verify"
    exit 0
elif [ $TOTAL -gt 0 ]; then
    echo -e "${BLUE}ℹ️  AUDIT PASSED${NC} - Some minor issues detected"
    echo ""
    echo "Consider addressing medium/low priority issues for better security"
    exit 0
else
    echo -e "${GREEN}✅ AUDIT PASSED${NC} - No security issues detected"
    echo ""
    echo "Great job! Your code follows security best practices."
    exit 0
fi
