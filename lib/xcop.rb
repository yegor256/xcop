# Copyright (c) 2017-2020 Yegor Bugayenko
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
require_relative 'xcop/version'

# Xcop main module.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2020 Yegor Bugayenko
# License:: MIT
module Xcop
  # Command line interface.
  class CLI
    def initialize(files, license, nocolor = false)
      @files = files
      @license = license
      @nocolor = nocolor
    end

    def run
      @files.each do |f|
        doc = Document.new(f)
        diff = doc.diff(@nocolor)
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
        Document.new(f).fix(@license)
        yield(f) if block_given?
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
    def diff(nocolor = false)
      xml = Nokogiri::XML(File.open(@path), &:noblanks)
      ideal = xml.to_xml(indent: 2)
      now = File.read(@path)
      differ(ideal, now, nocolor)
    end

    # Return the difference for the license.
    def ldiff(license)
      xml = Nokogiri::XML(File.open(@path), &:noblanks)
      comment = xml.xpath('/comment()')[0]
      now = comment.nil? ? '' : comment.text.to_s.strip
      ideal = license.strip
      differ(ideal, now)
    end

    # Fixes the document.
    def fix(license = '')
      xml = Nokogiri::XML(File.open(@path), &:noblanks)
      unless license.empty?
        xml.xpath('/comment()').remove
        xml.children.before(
          Nokogiri::XML::Comment.new(xml, "\n#{license.strip}\n")
        )
      end
      ideal = xml.to_xml(indent: 2)
      File.write(@path, ideal)
    end

    private

    def differ(ideal, fact, nocolor = false)
      return '' if ideal == fact
      if nocolor
        Differ.diff_by_line(ideal, fact).to_s
      else
        Differ.format = :color
        Differ.diff_by_line(schars(ideal), schars(fact)).to_s
      end
    end

    def schars(text)
      text.gsub(/\n/, "\\n\n")
    end
  end
end
