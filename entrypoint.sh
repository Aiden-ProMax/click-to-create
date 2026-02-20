#!/bin/bash
set -e

echo "Starting AutoPlanner..."

# Run migrations if needed
python manage.py migrate --noinput || true

# Collect static files
python manage.py collectstatic --noinput || true

# Start the application
exec gunicorn -w 2 -b 0.0.0.0:8080 --timeout=120 autoplanner.wsgi:application
