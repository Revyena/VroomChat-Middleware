# Dockerfile for PHP 8.4 FPM (Debian-based)
# Uses the official PHP base image and installs common extensions required by Laravel.

FROM php:8.4-fpm

WORKDIR /app

# Install system packages and PHP extensions
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libzip-dev \
    zip \
    unzip \
    libicu-dev \
    libxml2-dev \
    libpq-dev \
    postgresql-client \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd mbstring exif pcntl bcmath zip intl pdo_pgsql pgsql xml sockets \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
COPY composer.json composer.lock /app/

RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts

COPY . /app
RUN composer run post-autoload-dump

RUN chmod -R 777 storage
RUN chmod -R 775 bootstrap/cache


# Download dependencies
RUN composer require laravel/octane --dev
RUN composer install --prefer-dist --no-interaction --optimize-autoloader
RUN php artisan octane:install --server=roadrunner

# Ensure permissions
RUN chown -R laravel:www-data /var/www/html/storage /var/www/html/bootstrap/cache || true

# Switch to non-root user

EXPOSE 8000

RUN rm -rf /rr
RUN vendor/bin/rr get-binary
RUN chmod +x vendor/bin/rr

COPY .docker/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["php", "artisan", "octane:start", "--server=roadrunner", "--host=0.0.0.0", "--port=8000"]
