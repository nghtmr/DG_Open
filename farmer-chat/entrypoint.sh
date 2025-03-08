#!/bin/bash
set -e
echo "Running entrypoint.sh"

# Create log files
touch /app/uvicorn_logs.txt
touch /app/celery_pid.pid
touch /app/celery_logs.txt

# Change to app directory
cd /app

# Set default port if not provided
PORT=${PORT:-8080}

# Start log tailing in background
tail -n 0 -f /app/uvicorn_logs.txt &
TAIL_PID=$!

# Start Gunicorn
echo "Starting Gunicorn on port $PORT"
/opt/venv/bin/gunicorn --workers=4 --bind 0.0.0.0:$PORT --log-level debug \
    --access-logfile /app/uvicorn_logs.txt --error-logfile /app/uvicorn_logs.txt \
    --log-file /app/uvicorn_logs.txt --capture-output django_core.wsgi:application &
GUNICORN_PID=$!

# Start Celery worker with a non-root user if possible
echo "Starting Celery worker"
if [ "$(id -u)" = "0" ]; then
    # If running as root, try to use a different user
    if getent passwd celery > /dev/null 2>&1; then
        /opt/venv/bin/celery -A django_core worker -l DEBUG -c 16 --max-tasks-per-child=2 \
            --pidfile /app/celery_pid.pid --logfile /app/celery_logs.txt --uid=celery &
    else
        echo "Warning: Running Celery as root"
        /opt/venv/bin/celery -A django_core worker -l DEBUG -c 16 --max-tasks-per-child=2 \
            --pidfile /app/celery_pid.pid --logfile /app/celery_logs.txt &
    fi
else
    /opt/venv/bin/celery -A django_core worker -l DEBUG -c 16 --max-tasks-per-child=2 \
        --pidfile /app/celery_pid.pid --logfile /app/celery_logs.txt &
fi
CELERY_PID=$!

# Handle process termination properly
trap 'kill $GUNICORN_PID $CELERY_PID $TAIL_PID' SIGTERM SIGINT

# Wait for Gunicorn to exit
wait $GUNICORN_PID
