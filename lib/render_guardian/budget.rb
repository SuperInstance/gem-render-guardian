# frozen_string_literal: true

module RenderGuardian
  class Budget
    DEFAULTS = {
      max_template_time_ms:     100,
      max_partial_time_ms:      50,
      max_helper_time_ms:       20,
      max_db_queries_per_partial: 3,
      n_plus_one_threshold:     5
    }.freeze

    attr_reader :limits

    def initialize(limits = {})
      @limits = DEFAULTS.merge(limits.transform_keys(&:to_sym))
    end

    def limit_for(key)
      @limits[key.to_sym]
    end
  end
end
