# Growth

## Evaluating child/teen growth

Your pediatrician or primary caretaker constantly measures your child's anthropometric characteristics, such as weight, height, and head circumference.

However, in between visits, we can take the same measurements and understand how our child is growing.

> [!CAUTION]
> **This is not a diagnostic tool. Always talk with your pediatrician or primary caretaker.**

## Preparing the environment

The application uses:

* [`erlang`](https://www.erlang.org/) on version 27.1.3
* [`elixir`](https://elixir-lang.org/) on version 1.17.2
* [`node`](https://nodejs.org/en) on version 23.0.0

> [!NOTE]
> `node` is used to fetch needed dependencies for our `assets`

### Installing runtimes

The [`mise`](https://mise.jdx.dev) makes managing runtimes easier.

With `mise` installed, it's possible to install the runtimes using:

```bash
mise install
```

### Getting application dependencies

To get the `elixir` dependencies, we can run:

```bash
mix do loca.rebar --force, local.hex --force
mix do deps.get, deps.compile
```

We also need to fetch the dependencies for the assets:

```bash
npm install --prefix ./assets
```

### Compiling the application

The application can be compiled by running the following:

```bash
mix do assets.build, compile
```

## Running the application

To start the application, run the following:

```bash
mix phx.server
```
