.PHONY: assets bash build deps help iex logs migrate ps restart seed setup_db stop test up publish db_dump release

SERVICE ?= api

APP_NAME ?= `grep 'app:' mix.exs | sed -e 's/\[//g' -e 's/ //g' -e 's/app://' -e 's/[:,]//g'`
APP_VSN ?= `grep 'version:' mix.exs | cut -d '"' -f2`
BUILD ?= `git rev-parse --short HEAD`
SLACK_TOKEN ?= `grep 'SLACK_TOKEN=' .env | cut -d '=' -f2`
KOIN_BOT_ID ?= `grep 'KOIN_BOT_ID=' .env | cut -d '=' -f2`

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

soft-restart: #: Works on a running container
	docker-compose exec -e SLACK_TOKEN=$(SLACK_TOKEN) -e KOIN_BOT_ID=$(KOIN_BOT_ID) api mix deps.clean certifi; mix deps.get; mix run --no-halt

restart: #: Restart the service container
	docker-compose restart $(SERVICE)

seed: #: Seed the DB
	docker-compose exec -T $(SERVICE) mix run priv/repo/seeds.exs

setup_db: #: Create the db table(s)
	docker-compose run --rm $(SERVICE) mix ecto.create

stop: #: Stop running containers
	docker-compose stop

test: #: Run tests
	docker-compose run --rm -e MIX_ENV=test $(SERVICE) mix test

up: #: Start containers
	docker-compose up -d

down: #: Bring down the service
	docker-compose down

db_dump: #: Dump the current database
	docker-compose exec db pg_dump -U postgres alex_koin_dev > akc_backup

release: #: Build a distillery release
	docker-compose exec -e MIX_ENV=prod $(SERVICE) mix release --env=prod

docker-build: #: Build a container for deployment
	docker build --build-arg APP_NAME=$(APP_NAME) \
	  --build-arg APP_VSN=$(APP_VSN) \
	  --build-arg SLACK_TOKEN=$(SLACK_TOKEN) \
	  --build-arg KOIN_BOT_ID=$(KOIN_BOT_ID) \
	  -t $(APP_NAME):$(APP_VSN)-$(BUILD) \
	  -t $(APP_NAME):latest .

help: #: Show help topics
	@grep "#:" Makefile* | grep -v "@grep" | sort | sed "s/\([A-Za-z_ -]*\):.*#\(.*\)/$$(tput setaf 3)\1$$(tput sgr0)\2/g"
