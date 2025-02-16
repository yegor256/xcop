# Copyright (c) 2017-2025 Yegor Bugayenko
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

require 'nokogiri'
require 'differ'
require 'rainbow'
require_relative 'version'
require_relative 'document'

# Command line interface.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
class Xcop::CLI
  def initialize(files, license, nocolor: false)
    @files = files
    @license = license
    @nocolor = nocolor
  end

  def run
    @files.each do |f|
      doc = Xcop::Document.new(f)
      diff = doc.diff(nocolor: @nocolor)
      unless diff.empty?
        puts diff
        raise "Invalid XML formatting in #{f}"
      end
      unless @license.empty?
        ldiff = doc.ldiff(@license)
        unless ldiff.empty?
          puts ldiff
          raise "Broken license in #{f}"
        end
      end
      yield(f) if block_given?
    end
  end

  # Fix them all.
  def fix
    @files.each do |f|
      Xcop::Document.new(f).fix(@license)
      yield(f) if block_given?
    end
  end
end
