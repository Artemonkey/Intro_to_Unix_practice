#!/bin/sh

echo "Migrate start"
poetry run python manage.py migrate

echo "Check superuser"
poetry run python manage.py shell << EOF
import os
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username=os.getenv("USERNAME")).exists():
    print("User creating")
    User.objects.create_superuser(
        os.getenv("USERNAME"),
        os.getenv("EMAIL"),
        os.getenv("PASSWORD")
    )
EOF

echo "Start Django on gunicorn!"
exec poetry run gunicorn config.wsgi:application --reload
