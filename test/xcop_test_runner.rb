# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'tmpdir'
require 'fileutils'
require 'open3'

# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
class XcopTestRunner
  VALID_XML = "<?xml version=\"1.0\"?>\n<root>content</root>\n".freeze
  INVALID_XML = '<root>  content  </root>'.freeze
  MALFORMED_XML = '<unclosed>'.freeze

  def initialize(test_instance)
    @test = test_instance
  end

  def with_temp_dir(&block)
    Dir.mktmpdir(&block)
  end

  def with_xml_file(filename, content)
    with_temp_dir { |dir| yield(create_xml_in_dir(dir, filename, content)) }
  end

  def create_xml_in_dir(dir, filename, content)
    File.write(File.join(dir, filename), content)
    File.join(dir, filename)
  end

  def create_xml_in_subdir(dir, subdir, filename, content)
    FileUtils.mkdir_p(File.join(dir, subdir))
    create_xml_in_dir(File.join(dir, subdir), filename, content)
  end

  def create_file_in_dir(dir, filename, content)
    File.write(File.join(dir, filename), content)
    File.join(dir, filename)
  end

  def create_non_xml_file(dir, filename)
    create_file_in_dir(dir, filename, 'not xml')
  end

  def create_empty_subdir(dir, subdir)
    FileUtils.mkdir_p(File.join(dir, subdir))
    File.join(dir, subdir)
  end

  def create_config_file(dir, content)
    File.write(File.join(dir, '.xcop'), content)
  end

  def build_large_xml(items_count)
    content = "<?xml version=\"1.0\"?>\n<root>\n"
    items_count.times { |i| content += "  <item id=\"#{i}\">data</item>\n" }
    "#{content}</root>\n"
  end

  def normalize_path(path)
    File.realpath(path)
  end

  def run_xcop(*args)
    xcop_dir = File.join(__dir__, '..')
    xcop_path = File.join(xcop_dir, 'bin', 'xcop')
    absolute_args = args.map do |arg|
      if arg.start_with?('-')
        arg
      else
        begin
          File.absolute_path(arg)
        rescue Errno::ENOENT
          arg
        end
      end
    end
    Open3.capture3('bundle', 'exec', 'ruby', xcop_path, *absolute_args, chdir: xcop_dir)
  end

  def run_xcop_in_dir(dir, *args)
    xcop_dir = File.join(__dir__, '..')
    xcop_path = File.join(xcop_dir, 'bin', 'xcop')
    env = { 'BUNDLE_GEMFILE' => File.join(xcop_dir, 'Gemfile') }
    Open3.capture3(env, 'bundle', 'exec', 'ruby', xcop_path, *args, chdir: dir)
  end

  def assert_looks_good(file)
    stdout, stderr, status = run_xcop(file)
    @test.assert_equal("#{file} looks good\n", stdout)
    @test.assert_empty(stderr)
    @test.assert_equal(0, status.exitstatus)
  end

  def assert_invalid_xml(file, pattern)
    stdout, stderr, status = run_xcop(file)
    @test.assert_match(pattern, stdout)
    @test.assert_empty(stderr)
    @test.assert_equal(1, status.exitstatus)
  end

  def assert_fixed(file)
    stdout, stderr, status = run_xcop('--fix', file)
    @test.assert_equal("#{file} fixed\n", stdout)
    @test.assert_empty(stderr)
    @test.assert_equal(0, status.exitstatus)
  end

  def assert_quiet_run(*args)
    stdout, stderr, status = run_xcop(*args)
    @test.assert_empty(stdout)
    @test.assert_empty(stderr)
    @test.assert_equal(0, status.exitstatus)
  end
end
