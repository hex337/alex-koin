# Alex-Koin

A distributed highly valued virtual currency.

## Set up for Local Development

Environment variables live in `config/docker.env`. You will want to copy the example file over, and then modify for your particular slack installation.

```
cp config/docker.env.example config/docker.env
```

The main things you'll have to get from slack are:

* A slack token for your app so that it can connect to your slack group
* The slack user id of the bot user
* The slack user id for the project admin
* Optional Koin Lord ids, a single string with a comman between slack user ids.

```sh
make build deps up setup_db migrate up
```

You can then use `make log` to see if the server is running.

## Running Tests

Use `make test` to run tests.

## Interactive mode

If you're a beginner with elixir, it might be really helpful to play with some things in interactive mode

```sh
iex -S mix run
```

