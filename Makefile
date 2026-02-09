.PHONY: up down logs rebuild
.PHONY: up-whatsapp logs-whatsapp

up:
	docker compose up --build -d

down:
	docker compose down -v

logs:
	docker compose logs -f --tail=200

up-whatsapp:
	docker compose -f docker-compose.yml -f infra/compose/docker-compose.whatsapp.yml --profile whatsapp up --build -d

logs-whatsapp:
	docker compose -f docker-compose.yml -f infra/compose/docker-compose.whatsapp.yml --profile whatsapp logs -f --tail=200

rebuild:
	docker compose build --no-cache
