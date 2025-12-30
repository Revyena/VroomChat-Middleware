#!/bin/bash
set -e

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL at ${DB_HOST}:${DB_PORT:-5432}..."
until pg_isready -h "$DB_HOST" -p "${DB_PORT:-5432}" > /dev/null 2>&1; do
  echo "PostgreSQL not ready yet, sleeping 1s..."
  sleep 1
done
echo "PostgreSQL is ready!"

composer install --no-interaction

# Run migrations
echo "Running Laravel migrations..."
php artisan migrate

# Check if rr is already installed and executable
if [ ! -f "./rr" ] || [ ! -x "./rr" ]; then
    echo "RoadRunner binary not found or not executable. Installing..."
    vendor/bin/rr get-binary
    chmod +x ./rr
    echo "RoadRunner installed successfully."
else
    echo "RoadRunner binary already installed. Skipping installation."
fi

chmod +x ./rr

exec "$@"
