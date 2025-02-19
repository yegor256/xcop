# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'rake'
require 'rake/tasklib'
require_relative '../xcop/cli'

# Xcop rake task.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
class Xcop::RakeTask < Rake::TaskLib
  attr_accessor :name, :fail_on_error, :excludes, :includes, :quiet

  def initialize(*args, &task_block)
    super()
    @name = args.shift || :xcop
    @includes = %w[xml xsd xhtml xsl html].map { |e| "**/*.#{e}" }
    @excludes = []
    @quiet = false
    desc 'Run Xcop' unless ::Rake.application.last_description
    task(name, *args) do |_, task_args|
      RakeFileUtils.send(:verbose, true) do
        yield(*[self, task_args].slice(0, task_block.arity)) if block_given?
        run
      end
    end
  end

  private

  def run
    puts 'Running xcop...' unless @quiet
    bad = Dir.glob(@excludes)
    good = Dir.glob(@includes).reject { |f| bad.include?(f) }
    puts "Inspecting #{pluralize(good.length, 'file')}..." unless @quiet
    begin
      Xcop::CLI.new(good).run do
        print Rainbow('.').green unless @quiet
      end
    rescue StandardError => e
      puts e.message
      abort(e.message)
    end
    return if @quiet
    puts \
      "\n#{pluralize(good.length, 'file')} checked, " \
      "everything looks #{Rainbow('pretty').green}"
  end

  def pluralize(num, text)
    "#{num} #{num == 1 ? text : "#{text}s"}"
  end
end
