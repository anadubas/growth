# Growth

## Evaluating child/teen growth

Your pediatrician or primary caretaker constantly measures your child's anthropometric characteristics, such as weight, height, and head circumference.

However, in between visits, we can take the same measurements and understand how our child is growing.

> [!CAUTION]
> **This is not a diagnostic tool**. Always talk with your pediatrician or primary caretaker.

## Preparing the environment

The application uses:

* [`erlang`](https://www.erlang.org/) on version 28.0.1
* [`elixir`](https://elixir-lang.org/) on version 1.18.4
* [`node`](https://nodejs.org/en) on version 24.4.0

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
# Using mix
mix do loca.rebar --force, local.hex --force
mix do deps.get, deps.compile
# Using taskfile
task prepare_system
task deps
```

We also need to fetch the dependencies for the assets:

```bash
npm install --prefix ./assets
```

### Compiling the application

The application can be compiled by running the following:

```bash
# Using mix
mix do assets.build, compile
# Using taskfile
task assets_build
task compile
```

## Running the application

To start the application, run the following:

```bash
# Using mix
mix phx.server
# Using taskfile
task server
```

### Telemetry

The application emits telemetry events to monitor user interactions and business logic performance. These events can be used for observability, monitoring, and debugging purposes.

#### Events

##### User Journey Events

* `[:growth, :child, :created]` - Emitted when a new child profile is created
  - **Measurements**: `%{count: 1}`
  - **Metadata**: `%{age_in_months: number(), gender: String.t(), measure_date: Date.t()}`

* `[:growth, :measure, :submitted]` - Emitted when anthropometric measurements are submitted for a child
  - **Measurements**: `%{count: 1}`
  - **Metadata**: `%{age_in_months: number(), gender: String.t(), measure_date: Date.t(), has_weight: boolean(), has_height: boolean(), has_head_circumference: boolean()}`

##### Business Logic Span Events

* `[:growth, :calculation, :start]` - Emitted when growth calculation process begins
  - **Measurements**: `%{monotonic_time: integer()}`
  - **Metadata**: `%{age_in_months: integer(), gender: String.t(), measure_date: Date.t()}`

* `[:growth, :calculation, :stop]` - Emitted when growth calculation process completes
  - **Measurements**: `%{duration: native_time(), count: 1, monotonic_time: integer()}`
  - **Metadata**: `%{age_in_months: integer(), gender: String.t(), measure_date: Date.t(), has_weight_result: boolean(), has_height_result: boolean(), has_bmi_result: boolean(), has_head_circumference_result: boolean(), success: boolean()}`

* `[:growth, :calculation, :measure, :start]` - Emitted when individual measurement calculation begins
  - **Measurements**: `%{monotonic_time: integer()}`
  - **Metadata**: `%{age_in_months: number(), gender: String.t(), measure_date: Date.t(), data_type: atom()}`

* `[:growth, :calculation, :measure, :stop]` - Emitted when individual measurement calculation completes
  - **Measurements**: `%{duration: native_time(), monotonic_time: integer()}`
  - **Metadata**: `%{age_in_months: number(), gender: String.t(), measure_date: Date.t(), data_type: atom(), success: boolean()}`

* `[:growth, :reference_data, :load, :start]` - Emitted when reference data loading begins
  - **Measurements**: `%{monotonic_time: integer()}`
  - **Metadata**: `%{age_in_months: number(), gender: String.t(), data_type: atom(), measure_date: Date.t()}`

* `[:growth, :reference_data, :load, :stop]` - Emitted when reference data loading completes
  - **Measurements**: `%{duration: native_time(), monotonic_time: integer()}`
  - **Metadata**: `%{age_in_months: number(), gender: String.t(), data_type: atom(), measure_date: Date.t(), success: boolean(), reason: String.t() | nil}`
