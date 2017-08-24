# encoding: utf-8
#
# Copyright (c) 2017 Yegor Bugayenko
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
require_relative 'xcop/version'

# Xcop main module.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017 Yegor Bugayenko
# License:: MIT
module Xcop
  # Command line interface.
  class CLI
    def initialize(files, license)
      @files = files
      @license = license
    end

    def run
      @files.each do |f|
        print "Validating #{f}... "
        doc = Document.new(f)
        diff = doc.diff
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
        print "OK\n"
      end
    end
  end

  # One document.
  class Document
    # Ctor.
    # +path+:: Path of it
    def initialize(path)
      @path = path
    end

    # Return the difference, if any (empty string if everything is clean).
    def diff
      xml = Nokogiri::XML(File.open(@path), &:noblanks)
      ideal = xml.to_xml(indent: 2)
      now = File.read(@path)
      return Differ.diff_by_line(ideal, now).to_s unless now == ideal
      ''
    end

    # Return the difference for the license.
    def ldiff(license)
      xml = Nokogiri::XML(File.open(@path), &:noblanks)
      now = xml.xpath('/comment()')[0].to_s
      ideal = [
        '<!--',
        *license.strip.split(/\n/).map(&:strip),
        '-->'
      ].join("\n")
      return Differ.diff_by_line(ideal, now).to_s unless now == ideal
      ''
    end
  end
end
