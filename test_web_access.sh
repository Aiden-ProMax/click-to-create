#!/bin/bash
# Test AutoPlanner web accessibility

set -e

echo "=========================================="
echo "AutoPlanner Web Accessibility Test"
echo "=========================================="
echo ""

URL="https://autoplanner-110580126301.europe-west1.run.app/"

echo "Testing URL: $URL"
echo ""

# Test 1: HTTP Status Code
echo "Test 1: HTTP Status Code..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ PASS: HTTP 200 OK"
else
    echo "❌ FAIL: HTTP $HTTP_CODE (expected 200)"
    exit 1
fi

# Test 2: Response contains HTML
echo ""
echo "Test 2: Response contains HTML..."
RESPONSE=$(curl -s "$URL" | head -50)
if echo "$RESPONSE" | grep -q "<!DOCTYPE\|<html\|<head"; then
    echo "✅ PASS: Valid HTML response"
else
    echo "❌ FAIL: No HTML found in response"
    exit 1
fi

# Test 3: Response time
echo ""
echo "Test 3: Response time..."
RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" "$URL")
echo "Response time: ${RESPONSE_TIME}s"

# Test 4: SSL/TLS
echo ""
echo "Test 4: SSL/TLS Certificate..."
if curl -s "$URL" > /dev/null 2>&1; then
    echo "✅ PASS: SSL/TLS working"
else
    echo "❌ FAIL: SSL/TLS error"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ All tests passed!"
echo "=========================================="
echo ""
echo "Application is accessible at:"
echo "$URL"
