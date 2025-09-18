# Agents Guide

## Build, Lint, and Test

- Build: `task build` | Build app: `task build:application` | Build assets: `task build:assets`
- Clean: `task clean` | Setup: `task setup` | Format: `task format`
- Lint: `task lint` (format + credo + dialyzer) | Format check: `task check:format`
- Static analysis: `task check:dialyzer` | Credo: `task check:credo`
- Test: `task test` | Single test: `task test:single -- path/to/test.exs:line_number`
- All checks: `task ci` (creates PLT, lints, runs tests)
- Server: `task server` (start Phoenix dev server)

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
