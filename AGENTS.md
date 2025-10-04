# Agents Guide

## Project Overview

Phoenix LiveView application for evaluating child/teen growth using WHO growth standards. The application calculates percentiles and z-scores for weight, height, BMI, and head circumference measurements.

## High-Level Data Flow

A typical user workflow for a growth calculation follows this path:

1.  A user navigates to the main `GrowthLive` page.
2.  They enter child data (age, sex) into the `child_form_component` and measurement data (weight, height, etc.) into the `measure_form_component`.
3.  The `GrowthLive` view handles the form submission event and sends the data to the `Growth.Calculate` module.
4.  `Calculate.ex` uses functions from `zscore.ex` and `percentile.ex`, which compare the user's data against the WHO reference data loaded from `priv/indicators/`.
5.  The results are passed back to the UI and displayed in the `results_component`.
6.  The `growth_chart.js` client-side hook receives the new data and updates the chart visualization.

## Key Domain Concepts

-   **Z-Score**: A measurement of how many standard deviations a data point is from the mean (average) of a reference population. It provides a precise understanding of how a child's measurement compares to the growth standard. A z-score of 0 is exactly at the mean.
-   **Percentile**: The percentage of the reference population that has a measurement less than or equal to the child's. For example, a weight at the 50th percentile means the child's weight is greater than or equal to that of 50% of children of the same age and sex in the reference group.

## Project Organization

```
lib/
├── growth/                   # Core business logic
│   ├── calculate.ex          # Growth calculations
│   ├── child.ex              # Child schema/management
│   ├── classify.ex           # Growth classification
│   ├── csv_loader.ex         # CSV data loading
│   ├── load_reference*.ex    # Reference data loading
│   ├── mailer.ex             # Email functionality
│   ├── measure.ex            # Measurement handling
│   ├── percentile.ex         # Percentile calculations
│   ├── prom_ex*.ex           # Monitoring/telemetry
│   └── zscore.ex             # Z-score calculations
├── growth_web/               # Web layer
│   ├── components/           # Phoenix components
│   │   ├── layouts/          # Layout templates
│   │   └── core_components.ex
│   ├── controllers/          # HTTP controllers
│   ├── live/                 # LiveView components
│   │   ├── growth_live.ex
│   │   ├── child_form_component.ex
│   │   ├── measure_form_component.ex
│   │   └── results_component.ex
│   └── endpoint.ex           # Phoenix endpoint
└── growth_web.ex             # Application web module

assets/                       # Frontend assets
├── css/
│   └── app.css               # Tailwind CSS styles
├── js/
│   ├── app.js                # Main JavaScript entry
│   └── hooks/
│       └── growth_chart.js   # Chart.js integration
└── vendor/
    └── topbar.js             # Phoenix topbar

priv/
├── indicators/               # WHO growth reference data
│   ├── bmi_for_age.csv
│   ├── head_circumference_for_age.csv
│   ├── height_for_age.csv
│   └── weight_for_age.csv
└── static/                  # Static assets
```

## Key Libraries & Dependencies

### Backend (Elixir/Phoenix)

- **Phoenix**: Web framework with LiveView
- **Bandit**: HTTP server
- **Phoenix LiveView**: Real-time UI updates
- **Phoenix Live Dashboard**: Monitoring dashboard
- **Swoosh**: Email library
- **Gettext**: Internationalization
- **Jason**: JSON parsing
- **Nimble CSV**: CSV processing for reference data
- **Finch**: HTTP client

### Observability & Monitoring

- **OpenTelemetry**: Distributed tracing
- **PromEx**: Prometheus metrics
- **Telemetry**: Application telemetry
- **Logger JSON**: Structured logging

### Development Tools

- **Credo**: Code analysis
- **Dialyzer**: Static type checking
- **Esbuild**: JavaScript bundling
- **Tailwind CSS**: Utility-first CSS framework

### Frontend

- **Chart.js**: Data visualization (via growth_chart.js hook)
- **Phoenix LiveView**: Server-side rendering with real-time updates
- **Tailwind CSS**: Styling framework
- **Heroicons**: Icon library
- **DaisyUI**: Component library for **Tailwind CSS**

## Build, Lint, and Test

- Build: `task build` | Build app: `task build:application` | Build assets: `task build:assets`
- Clean: `task clean` | Setup: `task setup` | Format: `task format`
- Lint: `task lint` (format + credo + dialyzer) | Format check: `task check:format`
- Static analysis: `task check:dialyzer` | Credo: `task check:credo`
- Test: `task test` | Single test: `task test:single -- path/to/test.exs:line_number`
- All checks: `task ci` (creates PLT, lints, runs tests)
- Server: `task server` (start Phoenix dev server)

## Frontend Development

### JavaScript Architecture

- **app.js**: Main entry point, initializes LiveView socket
- **hooks/growth_chart.js**: Custom LiveView hook for Chart.js integration
  - Handles growth chart rendering and updates
  - Connects to LiveView for real-time data updates
- **vendor/topbar.js**: Phoenix development topbar

### CSS Architecture

- **app.css**: Main stylesheet using Tailwind CSS
- **tailwind.config.js**: Tailwind configuration
- Uses utility-first CSS approach with component classes

### LiveView Integration

- Real-time form validation and updates
- Dynamic chart rendering based on measurement data
- Server-side rendering with client-side interactivity

## Code Style

- Formatting: Default elixir formatter (2 spaces, LF, UTF-8)
- Imports: Alphabetized, use `alias` and `import` appropriately
- Naming: `snake_case` for vars/functions, `CamelCase` for modules
- Error Handling: `with` statements for complex logic, pattern match returns
- Typespecs: `@spec` on all public functions
- Documentation: `@moduledoc` on modules, `@doc` on public functions
- Phoenix: Follow conventions, use `~H` for HEEx templates, `@impl true` for callbacks
- Structs: Use `%Module{}` syntax, define defaults in defstruct
- Functions: Private functions with `defp`, group similar functions together
- Git: Conventional commits, present tense, imperative mood
  - Follow the [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/) guidelines

## Environment Setup

- **Erlang**: 28.1
- **Elixir**: 1.18.4
- **Node.js**: 24.9.0 (for assets)
- **mise**: Runtime management (recommended)

Use `task bootstrap` and `task setup` for initial environment setup.

## Environment Variables

The application uses the following environment variables for configuration, particularly in production releases:

- `SECRET_KEY_BASE`: **Required**. A 64-character secret used to sign and encrypt cookies. Can be generated with `mix phx.gen.secret`.
- `PHX_SERVER`: Set to `true` when running in a release environment to start the web server.
- `PHX_HOST`: The hostname of the server (e.g., `localhost`, `example.com`).
- `PHX_PORT`: The external port the server listens on (e.g., `4000`).
- `OTEL_EXPORTER_OTLP_ENDPOINT`: The URL for the OpenTelemetry collector (e.g., `http://otel-collector:4318`).

## Development Observability

This project includes a Docker-based observability stack powered by Signoz for development.

- **To Start:** From the project root, run `docker compose --profile observability up`.
- **To Access UI:** The Signoz UI is available at `http://localhost:8080`, where you can explore traces, metrics, and logs for the application.
