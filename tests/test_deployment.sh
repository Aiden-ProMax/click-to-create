#!/bin/bash
# Test script for deployed AutoPlanner application
# Tests the production URL and key endpoints
# Includes debugging for common issues

DEPLOY_URL="https://autoplanner-110580126301.us-central1.run.app"
FAILED=0

echo "========================================="
echo "  AutoPlanner Deployment Test Suite"
echo "========================================="
echo "URL: $DEPLOY_URL"
echo "Timestamp: $(date)"
echo ""

# Test 1: Main page connectivity
echo "Test 1: Main page connectivity..."
MAIN_RESPONSE=$(curl -s -w "\n%{http_code}" "$DEPLOY_URL/" | tail -1)
echo "  Status: $MAIN_RESPONSE"
if [ "$MAIN_RESPONSE" != "200" ] && [ "$MAIN_RESPONSE" != "301" ]; then
    echo "  ❌ FAILED - Expected 200 or 301, got $MAIN_RESPONSE"
    FAILED=$((FAILED+1))
else
    echo "  ✅ PASSED"
fi
echo ""

# Test 2: API endpoint availability
echo "Test 2: API endpoint availability..."
EVENTS_RESPONSE=$(curl -s -w "\n%{http_code}" "$DEPLOY_URL/api/events/" | tail -1)
echo "  Events API: $EVENTS_RESPONSE"
if [ "$EVENTS_RESPONSE" = "403" ] || [ "$EVENTS_RESPONSE" = "401" ]; then
    echo "  ✅ PASSED (requires authentication)"
elif [ "$EVENTS_RESPONSE" = "200" ]; then
    echo "  ✅ PASSED (public access)"
else
    echo "  ⚠️  Unexpected status: $EVENTS_RESPONSE"
fi
echo ""

# Test 3: Static files check
echo "Test 3: Static files availability..."
STATIC_RESPONSE=$(curl -s -w "\n%{http_code}" "$DEPLOY_URL/static/css/style.css" | tail -1)
echo "  Static CSS: $STATIC_RESPONSE"
if [ "$STATIC_RESPONSE" = "404" ]; then
    echo "  ⚠️  Static files not found (CSS_MISSING)"
else
    echo "  ✅ Static files status: $STATIC_RESPONSE"
fi
echo ""

# Test 4: Database connectivity check
echo "Test 4: Checking for database errors..."
# Try to access admin panel which requires database
ADMIN_RESPONSE=$(curl -s -w "\n%{http_code}" "$DEPLOY_URL/admin/" | tail -1)
echo "  Admin panel: $ADMIN_RESPONSE"
if [ "$ADMIN_RESPONSE" = "500" ]; then
    echo "  ⚠️  Internal Server Error (possible database issue)"
    FAILED=$((FAILED+1))
elif [ "$ADMIN_RESPONSE" = "302" ] || [ "$ADMIN_RESPONSE" = "301" ]; then
    echo "  ✅ PASSED (redirecting to login)"
elif [ "$ADMIN_RESPONSE" = "200" ]; then
    echo "  ✅ PASSED (admin panel available)"
fi
echo ""

# Test 5: Health check endpoint
echo "Test 5: Health check..."
# Try accessing dashboard to check if app is responding
DASH_RESPONSE=$(curl -s -w "\n%{http_code}" "$DEPLOY_URL/dashboard.html" | tail -1)
echo "  Dashboard: $DASH_RESPONSE"
if [ "$DASH_RESPONSE" = "200" ] || [ "$DASH_RESPONSE" = "301" ]; then
    echo "  ✅ PASSED"
else
    echo "  ❌ FAILED - Status: $DASH_RESPONSE"
    FAILED=$((FAILED+1))
fi
echo ""

# Summary
echo "========================================="
if [ $FAILED -eq 0 ]; then
    echo "✅ All critical tests passed!"
else
    echo "❌ $FAILED test(s) failed"
fi
echo "========================================="
echo ""
echo "Next steps if tests fail:"
echo "1. Check Cloud Run logs: gcloud beta run revisions logs read <revision-id> --region=us-central1"
echo "2. Verify environment variables are set correctly"
echo "3. Check database connection: CLOUD_SQL_CONNECTION_NAME must be set"
echo "4. Review Django settings for ALLOWED_HOSTS configuration"
echo ""