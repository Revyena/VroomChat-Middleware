# Dockerfile for PHP 8.4 FPM (Debian-based)
# Uses the official PHP base image and installs common extensions required by Laravel.

FROM php:8.4-fpm

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
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd mbstring exif pcntl bcmath zip intl pdo_pgsql pgsql xml \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user for laravel application
RUN useradd -G www-data,root -u 1000 -d /home/laravel laravel || true
RUN mkdir -p /home/laravel/.composer && chown -R laravel:laravel /home/laravel

WORKDIR /var/www/html

# Copy existing application directory contents
# Note: docker-compose will mount the project directory during development so this is optional
COPY . /var/www/html

# Download dependencies
RUN composer install

# Ensure permissions
RUN chown -R laravel:www-data /var/www/html/storage /var/www/html/bootstrap/cache || true

# Switch to non-root user
USER laravel

EXPOSE 8000

CMD ["php-fpm"]
