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

require 'minitest/autorun'
require 'nokogiri'
require 'tmpdir'
require 'slop'
require_relative '../lib/xcop'

# Xcop main module test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017 Yegor Bugayenko
# License:: MIT
class TestXcop < Minitest::Test
  def test_basic
    Dir.mktmpdir 'test1' do |dir|
      f = File.join(dir, 'a.xml')
      File.write(f, "<?xml version=\"1.0\"?>\n<hello>Dude!</hello>\n")
      assert_equal(Xcop::Document.new(f).diff, '')
    end
  end

  def test_license_presence
    Dir.mktmpdir 'test2' do |dir|
      f = File.join(dir, 'a.xml')
      license = "Copyright (c) All Good People\nDon't touch it!\n\n"
      File.write(
        f,
        [
          '<?xml version="1.0"?>',
          '<!--',
          'Copyright (c) All Good People',
          'Don\'t touch it!',
          '-->',
          '<hello>Dude!</hello>',
          ''
        ].join("\n")
      )
      assert_equal(Xcop::Document.new(f).ldiff(license), '')
    end
  end

  def test_fixes_document
    Dir.mktmpdir 'test3' do |dir|
      f = File.join(dir, 'bad.xml')
      license = "Copyright (c) Me, Myself, and I\nLike it?\n\n"
      File.write(f, '<hello>My friend!</hello>')
      Xcop::Document.new(f).fix(license)
      assert_equal(Xcop::Document.new(f).diff, '')
      assert_equal(Xcop::Document.new(f).ldiff(license), '')
    end
  end

  def test_removes_previous_license
    Dir.mktmpdir 'test4' do |dir|
      f = File.join(dir, 'bad.xml')
      license = "the license to add\n\n\nhey"
      File.write(f, '<hello>how do you do?</hello>')
      Xcop::Document.new(f).fix(license)
      Xcop::Document.new(f).fix(license)
      assert_equal(Nokogiri::XML(File.read(f)).xpath('/comment()').length, 1)
    end
  end
end
