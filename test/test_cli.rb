# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'tmpdir'
require_relative '../lib/xcop/cli'

# Tests for CLI class.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
class CLITest < Minitest::Test
  def test_run_valid_file_no_exception
    Dir.mktmpdir 'test_valid' do |dir|
      f = File.join(dir, 'valid.xml')
      File.write(f, "<?xml version=\"1.0\"?>\n<root>\n  <item>test</item>\n</root>\n")
      cli = Xcop::CLI.new([f])
      result = nil
      cli.run { |file| result = file }
      assert_equal(f, result)
    end
  end

  def test_run_invalid_file_exception
    Dir.mktmpdir 'test_invalid' do |dir|
      f = File.join(dir, 'invalid.xml')
      File.write(f, '<root><item>test</item></root>')
      cli = Xcop::CLI.new([f])
      assert_raises(StandardError) { cli.run }
    end
  end

  def test_run_nonexistent_file_exception
    nonexistent = '/tmp/nonexistent_file.xml'
    cli = Xcop::CLI.new([nonexistent])
    assert_raises(Errno::ENOENT) { cli.run }
  end

  def test_run_empty_file_runtime_error
    Dir.mktmpdir 'test_empty' do |dir|
      xml_file = File.join(dir, 'empty.xml')
      File.write(xml_file, '')
      cli = Xcop::CLI.new([xml_file])
      assert_raises(RuntimeError) { cli.run }
    end
  end

  def test_run_multiple_files_no_exceptions
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

  def test_run_invalid_file_exception_and_messages
    Dir.mktmpdir 'test_error' do |dir|
      f = File.join(dir, 'bad_format.xml')
      File.write(f, '<?xml version="1.0"?><root><item>no proper indenting</item></root>')
      cli = Xcop::CLI.new([f])
      error = assert_raises(RuntimeError) { cli.run }
      assert_match(/Invalid XML formatting/, error.message)
      assert_match(/bad_format.xml/, error.message)
    end
  end

  def test_fix_valid_file_no_changes
    Dir.mktmpdir 'test_no_fix' do |dir|
      f = File.join(dir, 'valid.xml')
      content = "<?xml version=\"1.0\"?>\n<root>\n  <item>test</item>\n</root>\n"
      File.write(f, content)
      cli = Xcop::CLI.new([f])
      cli.fix
      assert_equal(content, File.read(f))
    end
  end

  def test_fix_invalid_file_changing_file
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

  def test_fix_multiple_invalid_files_changing_them_all
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
      refute_equal(original_content1, File.read(f1))
      refute_equal(original_content2, File.read(f2))
    end
  end
end
