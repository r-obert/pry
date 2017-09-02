module Pry::JRuby
  extend self
  begin
    require 'jruby'
  rescue LoadError
    ::JRuby = Class.new(BasicObject) do
      def self.method_missing(*a)
        self
      end
    end
  end

  def run_jruby_in_process?
    ::JRuby.runtime.instance_config.run_ruby_in_process
  end

  def inprocess_launch_jruby!(boolean)
    ::JRuby.runtime.instance_config.run_ruby_in_process = boolean
  end
end
