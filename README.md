# Alex-Koin

A distributed highly valued virtual currency.

## Set up for Local Development

This assumes you have docker set up.

You will also need a slack bot token to test with. You can create your own slack org for free and then add a bot integration. You'll want to set up a `.env` file with your token that looks like this:

```
export SLACK_TOKEN=asdf-TOKEN-STUFF
```

You'll then need to `source .env` to get the `SLACK_TOKEN` into your env, since the process expects it for the bot to work.


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
