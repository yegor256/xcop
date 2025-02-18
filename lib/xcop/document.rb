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

# One document.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
class Xcop::Document
  # Ctor.
  # +path+:: Path of it
  def initialize(path)
    @path = path
  end

  # Return the difference, if any (empty string if everything is clean).
  def diff(nocolor: false)
    xml = Nokogiri::XML(File.open(@path), &:noblanks)
    ideal = xml.to_xml(indent: 2)
    now = File.read(@path)
    differ(ideal, now, nocolor: nocolor)
  end

  # Fixes the document.
  def fix
    xml = Nokogiri::XML(File.open(@path), &:noblanks)
    ideal = xml.to_xml(indent: 2)
    File.write(@path, ideal)
  end

  private

  def differ(ideal, fact, nocolor: false)
    return '' if ideal == fact
    if nocolor
      Differ.diff_by_line(ideal, fact).to_s
    else
      Differ.format = :color
      Differ.diff_by_line(schars(ideal), schars(fact)).to_s
    end
  end

  def schars(text)
    text.gsub("\n", "\\n\n")
  end
end
