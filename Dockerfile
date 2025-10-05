# ---------- FIRST STAGE ----------
# Use Python 3.12 base image
FROM python:3.12 AS builder

# Install uv package manager
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set working directory
WORKDIR /app

# Copy dependency files
COPY pyproject.toml ./

# Install Python dependencies into a virtual environment
RUN uv sync --no-install-project --no-editable

# Copy the tests directory into the builder stage (so it exists later)
COPY tests ./tests

# Copy your app source code (optional but often useful if tests import it)
COPY cc_simple_server ./cc_simple_server


# ---------- FINAL STAGE ----------
# Use Python 3.12-slim base image (smaller footprint)
FROM python:3.12-slim

WORKDIR /app

# Copy stuff
COPY --from=builder --chown=appuser:appuser /app/.venv /app/.venv
COPY --from=builder --chown=appuser:appuser /app/cc_simple_server ./cc_simple_server
COPY --from=builder --chown=appuser:appuser /app/tests ./tests

# Environment variables
ENV VIRTUAL_ENV=/app/.venv
ENV PATH="/app/.venv/bin:${PATH}"
ENV PYTHONPATH=/app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

# Create non-root user
RUN useradd -m appuser
RUN chown -R appuser:appuser /app
USER appuser

# Expose port 8000
EXPOSE 8000

# Set CMD to run FastAPI server on 0.0.0.0:8000
CMD ["uvicorn", "cc_simple_server.server:app", "--reload", "--host", "0.0.0.0", "--port", "8000"]