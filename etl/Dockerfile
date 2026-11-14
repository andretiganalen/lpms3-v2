FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY lpms3_data ./lpms3_data
ENV PYTHONUNBUFFERED=1
CMD ["python", "-m", "lpms3_data"]
