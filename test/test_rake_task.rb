# SPDX-FileCopyrightText: Copyright (c) 2017-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'tmpdir'
require 'rake'
require_relative '../lib/xcop/rake_task'

# Xcop rake task.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2026 Yegor Bugayenko
# License:: MIT
class TestRakeTask < Minitest::Test
  def test_basic
    Dir.mktmpdir 'test' do |dir|
      Dir.chdir(dir)
      f = File.join(dir, 'a.xml')
      File.write(f, "<?xml version=\"1.0\"?>\n<x/>\n")
      Xcop::RakeTask.new(:xcop1) do |task|
        task.quiet = true
      end
      Rake::Task['xcop1'].invoke
      File.delete(f)
    end
  end

  def test_with_broken_xml
    Dir.mktmpdir 'test' do |dir|
      Dir.chdir(dir)
      f = File.join(dir, 'broken.xml')
      File.write(f, "<z><a><b></b></a>\n\n</z>")
      Xcop::RakeTask.new(:xcop2) do |task|
        task.excludes = ['test/**/*']
      end
      assert_raises SystemExit do
        Rake::Task['xcop2'].invoke
      end
      File.delete(f)
    end
  end
end
