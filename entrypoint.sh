#!/bin/bash
set -e

echo "Starting AutoPlanner..."

# Create webclient.json from environment variable if it exists
if [ -n "$GOOGLE_OAUTH_CLIENT_JSON" ]; then
    echo "Creating webclient.json from environment variable..."
    echo "$GOOGLE_OAUTH_CLIENT_JSON" > /app/webclient.json
    echo "✅ webclient.json created"
fi

# Run migrations
echo "Running Django migrations..."
python manage.py migrate --noinput 2>&1 || {
    echo "Migration failed, continuing anyway..."
}

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput 2>&1 || {
    echo "Static files collection failed, continuing anyway..."
}

echo "Starting Gunicorn..."
exec gunicorn -w 2 -b 0.0.0.0:8080 --timeout=120 autoplanner.wsgi:application
