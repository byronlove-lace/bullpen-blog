#!/bin/sh

while true; do
  flask deploy && break || echo "Deploy command failed, retrying in 5 secs..."
  sleep 5
done

echo "flask deploy ACTIVATED"
exec gunicorn -b 0.0.0.0:${PORT:-8000} \
  --access-logfile - \
  --error-logfile - \
  bullpen_blog:app
