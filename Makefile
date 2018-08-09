.PHONY: assets bash build deps help iex logs migrate ps restart seed setup_db stop test up

SERVICE?=api

default: help

assets: #: install npm assets for the project
	docker-compose exec $(SERVICE) bash -c "cd assets && npm install"

bash: #: Bash prompt on running container
	docker-compose exec $(SERVICE) bash

build: #: Build containers
	docker-compose build

deps: #: Install the dependencies
	docker-compose run --rm $(SERVICE) mix deps.get

iex: #: Interactive elixir shell on container
	docker-compose exec $(SERVICE) iex -S mix

logs: #: Tail the service container's logs
	docker-compose logs -tf $(SERVICE)

migrate: #: Run migrations
	docker-compose run --rm $(SERVICE) mix ecto.migrate

ps: #: Show running processes
	docker-compose ps

restart: #: Restart the service container
	docker-compose restart $(SERVICE)

seed: #: Seed the DB
	docker-compose exec -T $(SERVICE) mix run priv/repo/seeds.exs

setup_db: #: Create the db table(s)
	docker-compose run --rm $(SERVICE) mix ecto.create

stop: #: Stop running containers
	docker-compose stop

test: #: Run tests
	docker-compose exec $(SERVICE) mix test

up: #: Start containers
	docker-compose up -d

down:
	docker-compose down

help: #: Show help topics
	@grep "#:" Makefile | grep -v "@grep" | sed "s/.*:\([A-Za-z_ -]*\):.*#\(.*\)/$$(tput setaf 3)\1$$(tput sgr0)\2/g" | sort
