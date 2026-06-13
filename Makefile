.PHONY: help dev prod stop logs clean seed migrate migrate-prod studio test test-cov test-e2e lint build flutter-test flutter-build flutter-analyze ps

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

dev: ## Start development environment
	docker compose up -d
	@echo "Dev stack running: API->http://localhost:3000 | PgAdmin->http://localhost:5050 | Swagger->http://localhost:3000/api/docs"

prod: ## Start production environment
	docker compose -f docker-compose.prod.yml up -d

stop: ## Stop all containers
	docker compose down
	docker compose -f docker-compose.prod.yml down 2>/dev/null || true

logs: ## Follow logs (usage: make logs s=backend)
	docker compose logs -f $(s)

clean: ## Remove all containers, volumes, and images
	docker compose down -v --remove-orphans
	docker system prune -f

seed: ## Run database seed
	docker compose exec backend npm run prisma:seed

migrate: ## Run database migrations
	docker compose exec backend npx prisma migrate dev

migrate-prod: ## Run production migrations (non-interactive)
	docker compose -f docker-compose.prod.yml exec backend npx prisma migrate deploy

studio: ## Open Prisma Studio
	cd backend && npx prisma studio

test: ## Run backend tests
	cd backend && npm run test

test-cov: ## Run tests with coverage
	cd backend && npm run test:cov

test-e2e: ## Run e2e tests
	cd backend && npm run test:e2e

lint: ## Lint backend code
	cd backend && npm run lint

build: ## Build backend for production
	cd backend && npm run build

flutter-test: ## Run Flutter tests
	cd frontend && flutter test

flutter-build: ## Build Flutter APK release
	cd frontend && flutter build apk --release

flutter-analyze: ## Analyze Flutter code
	cd frontend && flutter analyze

ps: ## Show running containers
	docker compose ps
