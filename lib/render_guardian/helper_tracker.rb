# frozen_string_literal: true

module RenderGuardian
  class HelperTracker
    def initialize(profiler)
      @profiler = profiler
    end

    def analyze
      helper_stats = Hash.new { |h, k| h[k] = { count: 0, total_ms: 0, templates: [] } }
      max_ms = @profiler.budget.limit_for(:max_helper_time_ms)

      # Track helper calls from events that have helper timing data
      @profiler.events.each do |event|
        Array(event.helpers_called).each do |h|
          name = h.is_a?(Hash) ? h[:name].to_s : h.to_s
          time = h.is_a?(Hash) ? h[:time_ms].to_f : 0
          helper_stats[name][:count] += 1
          helper_stats[name][:total_ms] += time
          helper_stats[name][:templates] << event.template unless helper_stats[name][:templates].include?(event.template)
        end
      end

      findings = []
      helper_stats.each do |name, stats|
        avg = stats[:total_ms] / stats[:count]
        if avg > max_ms
          findings << {
            type:       :slow_helper,
            severity:   :medium,
            helper:     name,
            avg_ms:     avg.round(2),
            total_ms:   stats[:total_ms].round(2),
            count:      stats[:count],
            templates:  stats[:templates],
            message:    "Helper '#{name}' averages #{avg.round(2)}ms (limit: #{max_ms}ms), called #{stats[:count]} times"
          }
        end
      end

      findings
    end
  end
end
