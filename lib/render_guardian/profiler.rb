# frozen_string_literal: true

module RenderGuardian
  RenderEvent = Struct.new(
    :template, :partial, :duration_ms, :db_queries, :helpers_called, :timestamp,
    keyword_init: true
  )

  class Profiler
    attr_reader :budget, :events

    def initialize(budget)
      @budget = budget
      @events = []
    end

    def ingest(events)
      Array(events).each do |e|
        @events << RenderEvent.new(
          template:       e[:template].to_s,
          partial:        e[:partial].to_s,
          duration_ms:    e[:duration_ms].to_f,
          db_queries:     Array(e[:db_queries]),
          helpers_called: Array(e[:helpers_called]),
          timestamp:      e[:timestamp] || Time.now
        )
      end
    end

    def stats_by_template
      @events.group_by(&:template).transform_values do |evts|
        durations = evts.map(&:duration_ms)
        {
          count:       durations.size,
          total_ms:    durations.sum,
          avg_ms:      durations.sum / durations.size,
          max_ms:      durations.max,
          min_ms:      durations.min,
          total_queries: evts.sum { |e| e.db_queries.size }
        }
      end
    end

    def stats_by_partial
      @events.select { |e| !e.partial.empty? }.group_by(&:partial).transform_values do |evts|
        durations = evts.map(&:duration_ms)
        {
          count:       durations.size,
          total_ms:    durations.sum,
          avg_ms:      durations.sum / durations.size,
          max_ms:      durations.max,
          total_queries: evts.sum { |e| e.db_queries.size }
        }
      end
    end

    def slow_templates
      max_ms = @budget.limit_for(:max_template_time_ms)
      @events.select { |e| e.template && e.duration_ms > max_ms }
    end

    def slow_partials
      max_ms = @budget.limit_for(:max_partial_time_ms)
      @events.select { |e| !e.partial.empty? && e.duration_ms > max_ms }
    end
  end
end
