FROM python:3.11-bullseye

USER root

# Set work directory
WORKDIR /app

# Install dependencies for psycopg2 and cleanup apt cache
RUN apt-get update && apt-get install --no-install-recommends -y dnsutils libpq-dev python3-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install pip and project dependencies
RUN python -m pip install --no-cache-dir pip==22.0.4
COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY . /app/

# Run migrations, create log file, set ownership and permissions
RUN python3 /app/manage.py migrate --noinput || true \
    && touch /app/app.log \
    && chown -R 1000:0 /app \
    && chmod 664 /app/app.log \
    && chmod -R u+rw /app

EXPOSE 8000

# Run migrations again (optional but kept from your original Dockerfile)
RUN python3 /app/manage.py migrate

# Switch to user with UID 1000 to avoid permission issues
USER 1000

# Set working directory again (redundant but explicit)
WORKDIR /app

# Run Gunicorn server
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "6", "pygoat.wsgi"]
