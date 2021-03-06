# frozen_string_literal: true

if RUBY_ENGINE == 'ruby' && ENV['COVERAGE'] == 'true'
  require 'yaml'
  rubies = YAML.load(File.read(File.join(__dir__, '..', '.travis.yml')))['rvm']
  latest_mri = rubies.select { |v| v =~ /\A\d+\.\d+.\d+\z/ }.max

  if RUBY_VERSION == latest_mri
    require 'simplecov'
    SimpleCov.start do
      add_filter '/spec/'
    end
  end
end

begin
  require 'byebug'
rescue LoadError; end

require 'dry-auto_inject'

module Test
  def self.remove_constants
    constants.each(&method(:remove_const))
  end
end

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.filter_run_when_matching :focus

  config.after do
    Test.remove_constants
  end

  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true
  end
end
