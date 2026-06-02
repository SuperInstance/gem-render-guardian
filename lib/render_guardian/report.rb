# frozen_string_literal: true

module RenderGuardian
  class Report
    attr_reader :budget, :profiler, :n_plus_one_findings, :helper_findings

    def initialize(budget, profiler, n_plus_one_findings, helper_findings)
      @budget              = budget
      @profiler            = profiler
      @n_plus_one_findings = n_plus_one_findings
      @helper_findings     = helper_findings
    end

    def summary
      {
        total_renders:     @profiler.events.size,
        templates:         @profiler.stats_by_template.size,
        slow_templates:    @profiler.slow_templates.size,
        slow_partials:     @profiler.slow_partials.size,
        n_plus_one_issues: @n_plus_one_findings.size,
        slow_helpers:      @helper_findings.size
      }
    end

    def to_h
      {
        summary:         summary,
        template_stats:  @profiler.stats_by_template,
        partial_stats:   @profiler.stats_by_partial,
        n_plus_one:      @n_plus_one_findings,
        helpers:         @helper_findings
      }
    end

    def to_s
      lines = []
      lines << "=== Render Guardian Report ==="
      s = summary
      lines << "Renders: #{s[:total_renders]} | Templates: #{s[:templates]}"
      lines << "Slow templates: #{s[:slow_templates]} | Slow partials: #{s[:slow_partials]}"
      lines << "N+1 issues: #{s[:n_plus_one_issues]} | Slow helpers: #{s[:slow_helpers]}"
      lines << ""

      if @n_plus_one_findings.any?
        lines << "--- N+1 Issues ---"
        @n_plus_one_findings.each { |f| lines << "  [#{f[:severity].upcase}] #{f[:message]}" }
        lines << ""
      end

      if @helper_findings.any?
        lines << "--- Slow Helpers ---"
        @helper_findings.each { |f| lines << "  [#{f[:severity].upcase}] #{f[:message]}" }
        lines << ""
      end

      if s[:slow_templates].zero? && s[:n_plus_one_issues].zero? && s[:slow_helpers].zero?
        lines << "✅ All renders within budget!"
      end

      lines.join("\n")
    end
  end
end
