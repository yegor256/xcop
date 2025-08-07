# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'tmpdir'
require_relative '../lib/xcop/cli'

# Tests for Xcop CLI fix functionality.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
class TestXcopFix < Minitest::Test
  def test_does_not_fix_valid_file
    Dir.mktmpdir 'test_no_fix' do |dir|
      f = File.join(dir, 'valid.xml')
      content = "<?xml version=\"1.0\"?>\n<root>\n  <item>test</item>\n</root>\n"
      File.write(f, content)
      cli = Xcop::CLI.new([f])
      cli.fix
      assert_equal(content, File.read(f))
    end
  end

  def test_fixes_invalid_file
    Dir.mktmpdir 'test_fix' do |dir|
      f = File.join(dir, 'invalid.xml')
      File.write(f, '<root><item>test</item></root>')
      original_content = File.read(f)
      cli = Xcop::CLI.new([f])
      cli.fix
      refute_equal(original_content, File.read(f))
      cli_check = Xcop::CLI.new([f])
      result = nil
      cli_check.run { |file| result = file }
      assert_equal(f, result)
    end
  end

  def test_fixes_multiple_files
    Dir.mktmpdir 'test_fix_multiple' do |dir|
      f1 = File.join(dir, 'invalid1.xml')
      f2 = File.join(dir, 'invalid2.xml')
      File.write(f1, '<root><item>test1</item></root>')
      File.write(f2, '<data><value>test2</value></data>')
      original_content1 = File.read(f1)
      original_content2 = File.read(f2)
      fixed = []
      cli = Xcop::CLI.new([f1, f2])
      cli.fix { |file| fixed << file }
      assert_equal(2, fixed.length)
      assert_includes(fixed, f1)
      assert_includes(fixed, f2)
      refute_equal(original_content1, File.read(f1))
      refute_equal(original_content2, File.read(f2))
    end
  end
end
