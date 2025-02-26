# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'nokogiri'
require 'tmpdir'
require 'slop'
require_relative '../lib/xcop/document'

# Test for Document class.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
class TestXcop < Minitest::Test
  def test_basic
    Dir.mktmpdir 'test1' do |dir|
      f = File.join(dir, 'a.xml')
      File.write(f, "<?xml version=\"1.0\"?>\n<hello>Dude!</hello>\n")
      assert_equal('', Xcop::Document.new(f).diff)
      File.delete(f)
    end
  end

  def test_file_without_tail_eol
    Dir.mktmpdir 'test9' do |dir|
      f = File.join(dir, 'no-eol.xml')
      File.write(f, "<?xml version=\"1.0\"?>\n<x/>")
      refute_equal(Xcop::Document.new(f).diff, '')
      File.delete(f)
    end
  end

  def test_fixes_document
    Dir.mktmpdir 'test3' do |dir|
      f = File.join(dir, 'bad.xml')
      File.write(f, '<hello>My friend!</hello>')
      Xcop::Document.new(f).fix
      assert_equal('', Xcop::Document.new(f).diff)
      File.delete(f)
    end
  end
end
