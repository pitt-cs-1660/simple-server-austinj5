# ---------- FIRST STAGE ----------
# Use Python 3.12 base image
FROM python:3.12-slim AS builder

# Install uv package manager
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set working directory
WORKDIR /app

# Copy neccessary
COPY pyproject.toml ./
COPY tests ./tests
COPY cc_simple_server ./cc_simple_server

# Install Python dependencies into a virtual environment
RUN uv sync --no-install-project --no-editable


# ---------- FINAL STAGE ----------
# Use Python 3.12-slim base image
FROM python:3.12-slim

WORKDIR /app

# Copy neccessary
COPY --from=builder --chown=appuser:appuser /app/.venv /app/.venv
COPY --from=builder --chown=appuser:appuser /app/cc_simple_server ./cc_simple_server
COPY --from=builder --chown=appuser:appuser /app/tests ./tests

# Environment variables
ENV VIRTUAL_ENV=/app/.venv
ENV PATH="/app/.venv/bin:${PATH}"
ENV PYTHONPATH=/app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

# Create non-root user for security
RUN useradd -m appuser
RUN chown -R appuser:appuser /app
USER appuser

# Expose port 8000
EXPOSE 8000

# Set CMD to run FastAPI server on 0.0.0.0:8000
CMD ["uvicorn", "cc_simple_server.server:app", "--reload", "--host", "0.0.0.0", "--port", "8000"]