# frozen_string_literal: true

module RenderGuardian
  class NPlusOneDetector
    def initialize(profiler)
      @profiler = profiler
    end

    def detect
      findings = []
      threshold = @profiler.budget.limit_for(:n_plus_one_threshold)

      # Check per-partial query counts
      @profiler.stats_by_partial.each do |partial, stats|
        if stats[:total_queries] / stats[:count] > @profiler.budget.limit_for(:max_db_queries_per_partial)
          findings << {
            type:           :n_plus_one_suspected,
            severity:       :high,
            partial:        partial,
            avg_queries:    (stats[:total_queries].to_f / stats[:count]).round(2),
            threshold:      @profiler.budget.limit_for(:max_db_queries_per_partial),
            render_count:   stats[:count],
            message:        "Partial '#{partial}' averages #{(stats[:total_queries].to_f / stats[:count]).round(2)} DB queries per render (threshold: #{@profiler.budget.limit_for(:max_db_queries_per_partial)})"
          }
        end
      end

      # Detect repeated identical queries across events (classic N+1 pattern)
      query_counts = Hash.new(0)
      @profiler.events.each do |event|
        event.db_queries.each { |q| query_counts[q] += 1 }
      end

      query_counts.select { |_, count| count >= threshold }.each do |query, count|
        findings << {
          type:     :repeated_query,
          severity: :high,
          query:    query,
          count:    count,
          message:  "Query executed #{count} times across renders — possible N+1: '#{query[0..80]}'"
        }
      end

      findings
    end
  end
end
