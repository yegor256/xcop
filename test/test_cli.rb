# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'tmpdir'
require_relative '../lib/xcop/cli'

# Test for CLI class.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
class TestCLI < Minitest::Test
  def test_run_with_valid_xml
    Dir.mktmpdir 'test_cli' do |dir|
      file = File.join(dir, 'test.xml')
      File.write(file, "<?xml version=\"1.0\"?>\n<hello>World!</hello>\n")
      cli = Xcop::CLI.new([file])
      cli.run
    end
  end

  def test_run_with_invalid_xml
    Dir.mktmpdir 'test_cli' do |dir|
      file = File.join(dir, 'bad.xml')
      File.write(file, '<hello>Bad formatting</hello>')
      cli = Xcop::CLI.new([file])
      assert_raises(RuntimeError) { cli.run }
    end
  end

  def test_fix_method
    Dir.mktmpdir 'test_cli' do |dir|
      file = File.join(dir, 'bad.xml')
      File.write(file, '<hello>Bad formatting</hello>')
      cli = Xcop::CLI.new([file])
      cli.fix
      content = File.read(file)
      assert_includes(content, '<?xml version="1.0"?>')
    end
  end

  def test_nocolor_option
    Dir.mktmpdir 'test_cli' do |dir|
      file = File.join(dir, 'good.xml')
      File.write(file, "<?xml version=\"1.0\"?>\n<hello>World!</hello>\n")
      cli = Xcop::CLI.new([file], nocolor: true)
      cli.run
    end
  end
end
