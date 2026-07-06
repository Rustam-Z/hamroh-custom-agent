up:
	docker build -t hamroh-base ./framework
	docker compose up -d --build

update:
	./scripts/commit-memories.sh
	git pull
	git submodule update --init --remote framework
	git diff --quiet framework || (git add framework && git commit -m "bump framework [skip ci]" && git push)
	$(MAKE) up

logs:
	docker compose logs -f agent

down:
	docker compose down
