# Render Guardian

Render conservation guardian — template budgets, partial profiling, N+1 query detection, and helper method cost tracking for Ruby web applications.

## Installation

```bash
gem install render-guardian
```

## Usage

```ruby
require "render_guardian"

# Analyze render events
report = RenderGuardian.analyze(
  render_log: [
    { template: "index", partial: "_row", duration_ms: 200,
      db_queries: ["SELECT * FROM items WHERE id=1"],
      helpers_called: [{ name: "format_price", time_ms: 5 }] },
    # ... more events
  ]
)

puts report
puts report.summary
```

## Features

- **Render Budget** — max time per template/partial
- **Partial Profiling** — stats by template and partial
- **N+1 Detection** — repeated queries and high query-per-partial ratios
- **Helper Cost Tracking** — find slow helper methods
- **Conservation Reports** — human and machine-readable

## License

MIT
