# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/render_guardian"

class TestRenderBudget < Minitest::Test
  def test_defaults
    budget = RenderGuardian::Budget.new
    assert_equal 100, budget.limit_for(:max_template_time_ms)
    assert_equal 50, budget.limit_for(:max_partial_time_ms)
    assert_equal 3, budget.limit_for(:max_db_queries_per_partial)
  end

  def test_custom
    budget = RenderGuardian::Budget.new(max_template_time_ms: 200)
    assert_equal 200, budget.limit_for(:max_template_time_ms)
  end
end

class TestProfiler < Minitest::Test
  def setup
    @budget = RenderGuardian::Budget.new(max_template_time_ms: 100, max_partial_time_ms: 50)
    @profiler = RenderGuardian::Profiler.new(@budget)
  end

  def test_ingest
    @profiler.ingest([
      { template: "index", partial: "_header", duration_ms: 30, db_queries: ["SELECT 1"] }
    ])
    assert_equal 1, @profiler.events.size
  end

  def test_stats_by_template
    @profiler.ingest([
      { template: "index", partial: "", duration_ms: 120, db_queries: [] },
      { template: "index", partial: "", duration_ms: 80, db_queries: [] }
    ])
    stats = @profiler.stats_by_template
    assert_equal 1, stats.size
    assert_equal 2, stats["index"][:count]
    assert_equal 100, stats["index"][:avg_ms]
  end

  def test_slow_templates
    @profiler.ingest([
      { template: "slow", partial: "", duration_ms: 150, db_queries: [] },
      { template: "fast", partial: "", duration_ms: 50, db_queries: [] }
    ])
    assert_equal 1, @profiler.slow_templates.size
    assert_equal "slow", @profiler.slow_templates.first.template
  end

  def test_slow_partials
    @profiler.ingest([
      { template: "index", partial: "_heavy", duration_ms: 80, db_queries: [] },
      { template: "index", partial: "_light", duration_ms: 10, db_queries: [] }
    ])
    assert_equal 1, @profiler.slow_partials.size
    assert_equal "_heavy", @profiler.slow_partials.first.partial
  end
end

class TestNPlusOneDetector < Minitest::Test
  def test_detects_repeated_queries
    budget = RenderGuardian::Budget.new(n_plus_one_threshold: 3, max_db_queries_per_partial: 1)
    profiler = RenderGuardian::Profiler.new(budget)
    profiler.ingest([
      { template: "index", partial: "_item", duration_ms: 10, db_queries: ["SELECT * FROM items WHERE id=1"] },
      { template: "index", partial: "_item", duration_ms: 10, db_queries: ["SELECT * FROM items WHERE id=1"] },
      { template: "index", partial: "_item", duration_ms: 10, db_queries: ["SELECT * FROM items WHERE id=1"] },
      { template: "index", partial: "_item", duration_ms: 10, db_queries: ["SELECT * FROM items WHERE id=1"] }
    ])
    findings = RenderGuardian::NPlusOneDetector.new(profiler).detect
    assert findings.any? { |f| f[:type] == :repeated_query }
  end
end

class TestHelperTracker < Minitest::Test
  def test_detects_slow_helpers
    budget = RenderGuardian::Budget.new(max_helper_time_ms: 10)
    profiler = RenderGuardian::Profiler.new(budget)
    profiler.ingest([
      { template: "index", partial: "", duration_ms: 50, db_queries: [],
        helpers_called: [{ name: "expensive_format", time_ms: 25 }] },
      { template: "show", partial: "", duration_ms: 50, db_queries: [],
        helpers_called: [{ name: "expensive_format", time_ms: 15 }] }
    ])
    findings = RenderGuardian::HelperTracker.new(profiler).analyze
    assert_equal 1, findings.size
    assert_equal "expensive_format", findings.first[:helper]
  end

  def test_ignores_fast_helpers
    budget = RenderGuardian::Budget.new(max_helper_time_ms: 10)
    profiler = RenderGuardian::Profiler.new(budget)
    profiler.ingest([
      { template: "index", partial: "", duration_ms: 10, db_queries: [],
        helpers_called: [{ name: "fast_helper", time_ms: 2 }] }
    ])
    findings = RenderGuardian::HelperTracker.new(profiler).analyze
    assert_equal 0, findings.size
  end
end

class TestReport < Minitest::Test
  def test_report_from_analyze
    report = RenderGuardian.analyze(
      render_log: [
        { template: "index", partial: "_row", duration_ms: 200, db_queries: ["SELECT * FROM items"] },
        { template: "index", partial: "_row", duration_ms: 200, db_queries: ["SELECT * FROM items"] },
        { template: "index", partial: "_row", duration_ms: 200, db_queries: ["SELECT * FROM items"] }
      ],
      budget: RenderGuardian::Budget.new(n_plus_one_threshold: 2, max_db_queries_per_partial: 1)
    )
    s = report.summary
    assert_equal 3, s[:total_renders]
    assert s[:n_plus_one_issues] >= 1
    assert_match(/Render Guardian Report/, report.to_s)
  end
end
