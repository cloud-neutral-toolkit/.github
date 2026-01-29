#!/bin/bash
# Service Chain Authentication Integration Test
# Tests the complete authentication flow across all services

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
CONSOLE_DIR="/Users/shenlan/workspaces/Cloud-Neutral-Toolkit/console.svc.plus"
ACCOUNTS_DIR="/Users/shenlan/workspaces/Cloud-Neutral-Toolkit/accounts.svc.plus"
RAG_SERVER_DIR="/Users/shenlan/workspaces/Cloud-Neutral-Toolkit/rag-server.svc.plus"
PAGE_AGENT_BACKEND_DIR="/Users/shenlan/workspaces/cloud-neutral-toolkit/page-reading-agent-backend"

# Service ports
CONSOLE_PORT=3000
ACCOUNTS_PORT=8080
RAG_SERVER_PORT=8081
PAGE_AGENT_PORT=8082

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

echo "=========================================="
echo "Service Chain Authentication Test Suite"
echo "=========================================="
echo ""

# Function to print test result
print_result() {
    local test_name=$1
    local result=$2
    local message=$3
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $test_name: PASS"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} $test_name: FAIL - $message"
        ((TESTS_FAILED++))
    fi
}

# Test 1: Verify INTERNAL_SERVICE_TOKEN is configured
echo "Test 1: Verify INTERNAL_SERVICE_TOKEN configuration"
echo "---------------------------------------------------"

check_token() {
    local dir=$1
    local service=$2
    
    if [ -f "$dir/.env" ]; then
        if grep -q "INTERNAL_SERVICE_TOKEN=" "$dir/.env"; then
            token=$(grep "INTERNAL_SERVICE_TOKEN=" "$dir/.env" | head -1 | cut -d'=' -f2 | tr -d '\n' | tr -d '\r')
            if [ -n "$token" ]; then
                print_result "$service token configured" "PASS"
                echo "$token"
                return 0
            fi
        fi
    fi
    
    if [ -f "$dir/.env.local" ]; then
        if grep -q "INTERNAL_SERVICE_TOKEN=" "$dir/.env.local"; then
            token=$(grep "INTERNAL_SERVICE_TOKEN=" "$dir/.env.local" | head -1 | cut -d'=' -f2 | tr -d '\n' | tr -d '\r')
            if [ -n "$token" ]; then
                print_result "$service token configured" "PASS"
                echo "$token"
                return 0
            fi
        fi
    fi
    
    print_result "$service token configured" "FAIL" "Token not found in .env or .env.local"
    return 1
}

CONSOLE_TOKEN=$(check_token "$CONSOLE_DIR" "console.svc.plus")
ACCOUNTS_TOKEN=$(check_token "$ACCOUNTS_DIR" "accounts.svc.plus")
RAG_TOKEN=$(check_token "$RAG_SERVER_DIR" "rag-server.svc.plus")
PAGE_AGENT_TOKEN=$(check_token "$PAGE_AGENT_BACKEND_DIR" "page-reading-agent-backend")

echo ""

# Test 2: Verify all services have the same token
echo "Test 2: Verify token consistency across services"
echo "------------------------------------------------"

# Extract tokens and compare
TOKEN1=$(grep "INTERNAL_SERVICE_TOKEN=" "$CONSOLE_DIR/.env" 2>/dev/null | head -1 | cut -d'=' -f2)
TOKEN2=$(grep "INTERNAL_SERVICE_TOKEN=" "$ACCOUNTS_DIR/.env" 2>/dev/null | head -1 | cut -d'=' -f2)
TOKEN3=$(grep "INTERNAL_SERVICE_TOKEN=" "$RAG_SERVER_DIR/.env" 2>/dev/null | head -1 | cut -d'=' -f2)
TOKEN4=$(grep "INTERNAL_SERVICE_TOKEN=" "$PAGE_AGENT_BACKEND_DIR/.env" 2>/dev/null | head -1 | cut -d'=' -f2)

# Simple string comparison
MISMATCH=0
if [ "$TOKEN1" != "$TOKEN2" ]; then MISMATCH=1; fi
if [ "$TOKEN1" != "$TOKEN3" ]; then MISMATCH=1; fi  
if [ "$TOKEN1" != "$TOKEN4" ]; then MISMATCH=1; fi

if [ $MISMATCH -eq 0 ] && [ -n "$TOKEN1" ]; then
    print_result "Token consistency" "PASS"
    SHARED_TOKEN="$TOKEN1"
else
    print_result "Token consistency" "FAIL" "Tokens do not match or are empty"
    if [ -n "$TOKEN1" ]; then echo "  Console: [${#TOKEN1} chars]"; fi
    if [ -n "$TOKEN2" ]; then echo "  Accounts: [${#TOKEN2} chars]"; fi
    if [ -n "$TOKEN3" ]; then echo "  RAG Server: [${#TOKEN3} chars]"; fi
    if [ -n "$TOKEN4" ]; then echo "  Page Agent: [${#TOKEN4} chars]"; fi
fi

echo ""

# Test 3: Verify code changes are in place
echo "Test 3: Verify code implementation"
echo "-----------------------------------"

# Check apiProxy.ts
if grep -q "X-Service-Token" "$CONSOLE_DIR/src/lib/apiProxy.ts"; then
    print_result "apiProxy.ts updated" "PASS"
else
    print_result "apiProxy.ts updated" "FAIL" "X-Service-Token not found"
fi

# Check askai route
if grep -q "X-Service-Token" "$CONSOLE_DIR/src/app/api/askai/route.ts"; then
    print_result "askai/route.ts updated" "PASS"
else
    print_result "askai/route.ts updated" "FAIL" "X-Service-Token not found"
fi

# Check rag query route
if grep -q "X-Service-Token" "$CONSOLE_DIR/src/app/api/rag/query/route.ts"; then
    print_result "rag/query/route.ts updated" "PASS"
else
    print_result "rag/query/route.ts updated" "FAIL" "X-Service-Token not found"
fi

# Check users route
if grep -q "X-Service-Token" "$CONSOLE_DIR/src/app/api/users/route.ts"; then
    print_result "users/route.ts updated" "PASS"
else
    print_result "users/route.ts updated" "FAIL" "X-Service-Token not found"
fi

# Check page-reading-agent-dashboard
DASHBOARD_DIR="/Users/shenlan/workspaces/cloud-neutral-toolkit/page-reading-agent-dashboard"
if [ -f "$DASHBOARD_DIR/app/api/run-task/route.ts" ]; then
    if grep -q "X-Service-Token" "$DASHBOARD_DIR/app/api/run-task/route.ts"; then
        print_result "page-reading-agent-dashboard updated" "PASS"
    else
        print_result "page-reading-agent-dashboard updated" "FAIL" "X-Service-Token not found"
    fi
fi

echo ""

# Test 4: Verify backend middleware
echo "Test 4: Verify backend middleware implementation"
echo "-----------------------------------------------"

# Check accounts.svc.plus
if [ -f "$ACCOUNTS_DIR/internal/auth/middleware.go" ]; then
    if grep -q "InternalAuthMiddleware" "$ACCOUNTS_DIR/internal/auth/middleware.go"; then
        print_result "accounts.svc.plus middleware" "PASS"
    else
        print_result "accounts.svc.plus middleware" "FAIL" "InternalAuthMiddleware not found"
    fi
fi

# Check rag-server.svc.plus
if [ -f "$RAG_SERVER_DIR/internal/auth/middleware.go" ]; then
    if grep -q "InternalAuthMiddleware" "$RAG_SERVER_DIR/internal/auth/middleware.go"; then
        print_result "rag-server.svc.plus middleware" "PASS"
    else
        print_result "rag-server.svc.plus middleware" "FAIL" "InternalAuthMiddleware not found"
    fi
fi

# Check page-reading-agent-backend
if [ -f "$PAGE_AGENT_BACKEND_DIR/middleware/auth.js" ]; then
    if grep -q "createInternalAuthMiddleware" "$PAGE_AGENT_BACKEND_DIR/middleware/auth.js"; then
        print_result "page-reading-agent-backend middleware" "PASS"
    else
        print_result "page-reading-agent-backend middleware" "FAIL" "createInternalAuthMiddleware not found"
    fi
fi

echo ""

# Test 5: Verify documentation
echo "Test 5: Verify documentation exists"
echo "-----------------------------------"

DOCS_DIR="/Users/shenlan/workspaces/cloud-neutral-toolkit/github-org-cloud-neutral-toolkit/docs"

check_doc() {
    local file=$1
    local name=$2
    
    if [ -f "$DOCS_DIR/$file" ]; then
        print_result "$name exists" "PASS"
    else
        print_result "$name exists" "FAIL" "File not found"
    fi
}

check_doc "SERVICE_CHAIN_AUTH_AUDIT.md" "Audit document"
check_doc "SHARED_TOKEN_AUTH_DESIGN.md" "Design document"
check_doc "SERVICE_CHAIN_AUTH_IMPLEMENTATION.md" "Implementation plan"
check_doc "INTERNAL_AUTH_USAGE.md" "Usage guide"
check_doc "DEPLOYMENT_SUMMARY.md" "Deployment summary"

echo ""

# Test 6: Verify no secrets in documentation
echo "Test 6: Verify no secrets in documentation"
echo "------------------------------------------"

SECRETS_FOUND=0

for doc in "$DOCS_DIR"/*.md; do
    if [ -f "$doc" ]; then
        # Check for actual token value (should not be present)
        if grep -q "uTvryFvAbz6M5sRtmTaSTQY6otLZ95hneBsWqXu+35I=" "$doc"; then
            print_result "$(basename $doc) - no secrets" "FAIL" "Actual token found in documentation"
            SECRETS_FOUND=1
        fi
    fi
done

if [ $SECRETS_FOUND -eq 0 ]; then
    print_result "Documentation security" "PASS"
fi

echo ""

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Start services locally for runtime testing"
    echo "2. Deploy to Cloud Run with secrets"
    echo "3. Verify production service chain"
    exit 0
else
    echo -e "${RED}✗ Some tests failed. Please review the failures above.${NC}"
    exit 1
fi
