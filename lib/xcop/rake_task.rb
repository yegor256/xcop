# Copyright (c) 2017-2018 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'rake'
require 'rake/tasklib'
require_relative '../xcop'

# Xcop rake task.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2018 Yegor Bugayenko
# License:: MIT
module Xcop
  # Rake task.
  class RakeTask < Rake::TaskLib
    attr_accessor :name
    attr_accessor :fail_on_error
    attr_accessor :excludes
    attr_accessor :includes
    attr_accessor :license
    attr_accessor :quiet

    def initialize(*args, &task_block)
      @name = args.shift || :xcop
      @includes = %w[xml xsd xhtml xsl html].map { |e| "**/*.#{e}" }
      @excludes = []
      @license = nil
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
      require 'xcop'
      puts 'Running xcop...' unless @quiet
      bad = Dir.glob(@excludes)
      good = Dir.glob(@includes).reject { |f| bad.include?(f) }
      puts "Inspecting #{pluralize(good.length, 'file')}..." unless @quiet
      begin
        Xcop::CLI.new(good, @license.nil? ? '' : File.read(@license)).run do
          print Rainbow('.').green unless @quiet
        end
      rescue StandardError => e
        abort(e.message)
      end
      return if @quiet
      puts "\n#{pluralize(good.length, 'file')} checked, \
everything looks #{Rainbow('pretty').green}"
    end

    def pluralize(num, text)
      "#{num} #{num == 1 ? text : text + 's'}"
    end
  end
end
