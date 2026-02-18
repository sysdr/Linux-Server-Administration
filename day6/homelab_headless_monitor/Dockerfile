FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY system_health.py dashboard.py ./
COPY templates/ ./templates/
ENV RUN_IN_LOOP=false
EXPOSE 5000
CMD ["python3", "dashboard.py"]
