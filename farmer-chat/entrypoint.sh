#!/bin/bash
# set -e

echo "Running entrypoint.sh"

# Source the environment variable file
touch /app/uvicorn_logs.txt
touch /app/celery_pid.pid
touch /app/celery_logs.txt
tail -n 0 -f /app/uvicorn_logs.txt &

cd /app

# Set default port if not provided
PORT=${PORT:-8080}

# Gunicorn run
/opt/venv/bin/gunicorn --workers=4 --bind 0.0.0.0:$PORT --log-level debug \
    --access-logfile /app/uvicorn_logs.txt --error-logfile /app/uvicorn_logs.txt \
    --log-file /app/uvicorn_logs.txt --capture-output django_core.wsgi:application &

# Start Celery worker
/opt/venv/bin/celery -A django_core worker -l DEBUG -c 16 --max-tasks-per-child=2 \
    --pidfile /app/celery_pid.pid --logfile /app/celery_logs.txt &

wait

# Keep the container running
exec "$@"
