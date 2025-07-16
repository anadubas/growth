## Build, Lint, and Test

- Build: `task build`
- Lint: `task lint` (runs build, format check, credo, and dialyzer)
- Format check: `task check_format`
- Static analysis: `task check_dialyzer`
- Test: `task test`
- Run a single test: `task test_single -- path/to/test.exs:line_number`
- Run all checks: `task ci`

## Code Style

- Formatting: Use the default `elixir` formatter (`task format`).
- Imports: Keep imports alphabetized.
- Naming: Follow `elixir` conventions (`snake_case` for variables and functions, `CamelCase` for modules).
- Error Handling: Use `with` statements for complex logic and pattern match on return values.
- `Typespecs`: Add `@spec` to all public functions.
- Documentation: Add `@doc` to all public functions.
- Documentation: Add `@moduledoc` to all modules.
- `phoenix`: Follow `phoenix` conventions for controllers, views, and templates. Use `~H` for `HEEx` templates.

## Commit Messages

- Follow the [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/) format.
- Use the present tense (`Add feature` not `Added feature`).
- Use the imperative mood (`Add feature` not `Adds feature`).
