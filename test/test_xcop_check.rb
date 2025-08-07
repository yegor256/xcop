# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'tmpdir'
require_relative '../lib/xcop/cli'

# Tests for Xcop CLI check functionality (analysis without fixes).
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
class TestXcopCheck < Minitest::Test
  def test_validates_valid_file
    Dir.mktmpdir 'test_valid' do |dir|
      f = File.join(dir, 'valid.xml')
      File.write(f, "<?xml version=\"1.0\"?>\n<root>\n  <item>test</item>\n</root>\n")
      cli = Xcop::CLI.new([f])
      result = nil
      cli.run { |file| result = file }
      assert_equal(f, result)
    end
  end

  def test_detects_invalid_file
    Dir.mktmpdir 'test_invalid' do |dir|
      f = File.join(dir, 'invalid.xml')
      File.write(f, '<root><item>test</item></root>')
      cli = Xcop::CLI.new([f])
      assert_raises(StandardError) { cli.run }
    end
  end

  def test_handles_nonexistent_file
    nonexistent = '/tmp/nonexistent_file.xml'
    cli = Xcop::CLI.new([nonexistent])
    assert_raises(Errno::ENOENT) { cli.run }
  end

  def test_handles_empty_xml_file
    Dir.mktmpdir 'test_empty' do |dir|
      xml_file = File.join(dir, 'empty.xml')
      File.write(xml_file, '')
      cli = Xcop::CLI.new([xml_file])
      assert_raises(RuntimeError) { cli.run }
    end
  end

  def test_processes_multiple_files
    Dir.mktmpdir 'test_multiple' do |dir|
      f1 = File.join(dir, 'file1.xml')
      f2 = File.join(dir, 'file2.xml')
      File.write(f1, "<?xml version=\"1.0\"?>\n<root>\n  <item>1</item>\n</root>\n")
      File.write(f2, "<?xml version=\"1.0\"?>\n<root>\n  <item>2</item>\n</root>\n")
      processed = []
      cli = Xcop::CLI.new([f1, f2])
      cli.run { |file| processed << file }
      assert_equal(2, processed.length)
      assert_includes(processed, f1)
      assert_includes(processed, f2)
    end
  end

  def test_reports_error_for_invalid_formatting
    Dir.mktmpdir 'test_error' do |dir|
      f = File.join(dir, 'bad_format.xml')
      File.write(f, '<?xml version="1.0"?><root><item>no proper indenting</item></root>')
      cli = Xcop::CLI.new([f])
      error = assert_raises(RuntimeError) { cli.run }
      assert_match(/Invalid XML formatting/, error.message)
      assert_match(/bad_format.xml/, error.message)
    end
  end
end
