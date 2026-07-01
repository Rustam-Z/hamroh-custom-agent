up:
	docker build -t hamroh-base ./framework
	docker compose up -d --build

logs:
	docker compose logs -f agent

down:
	docker compose down
