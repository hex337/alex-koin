# Alex-Koin

A distributed highly valued virtual currency.

## Set up for Local Development

This assumes you have docker set up.

You will also need a slack bot token to test with. You can create your own slack org for free and then add a bot integration. You'll want to set up a `.env` file with your token that looks like this:

```
SLACK_TOKEN=asdf-TOKEN-STUFF
KOIN_BOT_ID=UC123456
```

Docker will pick up variables defined in your `.env` when you build a container and make them available when running.

```sh
make build
make deps
make up
make setup_db
make migrate
make up
```

You can then use `make log` to see if the server is running.

## Running Tests

Use `make test` to run tests.
