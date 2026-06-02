# frozen_string_literal: true

require_relative "render_guardian/budget"
require_relative "render_guardian/profiler"
require_relative "render_guardian/n_plus_one_detector"
require_relative "render_guardian/helper_tracker"
require_relative "render_guardian/report"

module RenderGuardian
  class Error < StandardError; end

  def self.analyze(render_log:, budget: nil)
    budget   ||= Budget.new
    profiler = Profiler.new(budget)
    profiler.ingest(render_log)

    n_plus_one = NPlusOneDetector.new(profiler).detect
    helpers    = HelperTracker.new(profiler).analyze

    Report.new(budget, profiler, n_plus_one, helpers)
  end
end
