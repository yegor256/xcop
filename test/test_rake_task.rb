# Copyright (c) 2017-2022 Yegor Bugayenko
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
require 'tmpdir'
require 'rake'
require_relative '../lib/xcop/rake_task'

# Xcop rake task.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2022 Yegor Bugayenko
# License:: MIT
class TestRakeTask < Minitest::Test
  def test_basic
    Dir.mktmpdir 'test' do |dir|
      Dir.chdir(dir)
      f = File.join(dir, 'a.xml')
      File.write(f, "<?xml version=\"1.0\"?>\n<x/>\n")
      Xcop::RakeTask.new(:xcop1) do |task|
        task.quiet = true
        # task.license = 'LICENSE.txt'
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
