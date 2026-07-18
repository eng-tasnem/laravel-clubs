FROM php:8.2-fpm

# تثبيت الاعتمادات الأساسية للنظام
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    nginx

# تثبيت إضافات PHP التي يحتاجها Laravel
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# تثبيت Composer داخل الخادم
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# نسخ ملفات المشروع إلى الخادم
WORKDIR /var/www
COPY . /var/www

# تثبيت مكتبات المشروع وضبط الصلاحيات
RUN composer install --no-dev --optimize-autoloader
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# تجهيز إعدادات Nginx لتشغيل مجلد public الخاص بـ Laravel
RUN echo 'server { \n\
    listen 80; \n\
    root /var/www/public; \n\
    index index.php index.html; \n\
    location / { \n\
        try_files $uri $uri/ /index.php?$query_string; \n\
    } \n\
    location ~ \.php$ { \n\
        include fastcgi_params; \n\
        fastcgi_pass 127.0.0.1:9000; \n\
        fastcgi_index index.php; \n\
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; \n\
    } \n\
}' > /etc/nginx/sites-available/default

# تشغيل خادم PHP و Nginx معاً عند إقلاع الموقع
CMD nginx -g "daemon off;" & php-fpm