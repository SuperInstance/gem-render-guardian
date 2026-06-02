# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "render-guardian"
  spec.version       = "0.1.0"
  spec.authors       = ["SuperInstance"]
  spec.email         = ["team@superinstance.com"]
  spec.summary       = "Render conservation guardian — template budgets, partial profiling, N+1 detection"
  spec.description   = "Track render budgets, profile partial performance, detect N+1 queries in views, and measure helper method costs for Ruby web applications."
  spec.homepage      = "https://github.com/SuperInstance/gem-render-guardian"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7"

  spec.files = Dir["lib/**/*.rb", "README.md"]
  spec.require_paths = ["lib"]
end
