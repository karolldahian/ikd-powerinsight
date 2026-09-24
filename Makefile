.PHONY: help install lint format typecheck imports test coverage check precommit frontend-lint frontend-build

help:
	@echo "IKD PowerInsight commands:"
	@echo "  make install         Install backend dependencies"
	@echo "  make lint            Run Ruff checks"
	@echo "  make format          Run Ruff formatter"
	@echo "  make typecheck       Run basedpyright"
	@echo "  make imports         Run Import Linter"
	@echo "  make test            Run Pytest"
	@echo "  make coverage        Run tests with coverage"
	@echo "  make check           Run backend quality checks"
	@echo "  make precommit       Run all pre-commit hooks"
	@echo "  make frontend-lint   Run frontend ESLint"
	@echo "  make frontend-build  Build frontend"

install:
	uv sync --directory backend

lint:
	uv run --directory backend ruff check .

format:
	uv run --directory backend ruff format .

typecheck:
	uv run --directory backend basedpyright

imports:
	uv run --directory backend lint-imports --config .importlinter

test:
	uv run --directory backend pytest

coverage:
	uv run --directory backend pytest --cov --cov-report=term-missing

check:
	uv run --directory backend ruff check .
	uv run --directory backend basedpyright
	uv run --directory backend lint-imports --config .importlinter
	uv run --directory backend pytest

precommit:
	uv run --directory backend pre-commit run --all-files

frontend-lint:
	cd frontend && npm run lint

frontend-build:
	cd frontend && npm run build
