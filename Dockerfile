FROM python:3.13-slim
ENV PYTHONDONTWRITEBYTECODE=1
RUN addgroup --system app && adduser --system --ingroup app app \
    && mkdir /data \
    && chown app:app /data
WORKDIR /app
COPY app/requirements.txt .
RUN pip install -r requirements.txt
COPY app/app.py .
USER app
EXPOSE 8000
CMD ["python", "app.py"]