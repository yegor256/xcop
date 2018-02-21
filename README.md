[![EO principles respected here](https://cdn.rawgit.com/yegor256/elegantobjects.github.io/master/badge.svg)](http://www.elegantobjects.org)
[![Managed by Zerocracy](https://www.0crat.com/badge/C3RFVLU72.svg)](https://www.0crat.com/p/C3RFVLU72)
[![DevOps By Rultor.com](http://www.rultor.com/b/yegor256/xcop)](http://www.rultor.com/p/yegor256/xcop)
[![We recommend RubyMine](http://img.teamed.io/rubymine-recommend.svg)](https://www.jetbrains.com/ruby/)

[![Build Status](https://travis-ci.org/yegor256/xcop.svg)](https://travis-ci.org/yegor256/xcop)
[![Build status](https://ci.appveyor.com/api/projects/status/orvfo2qgmd1d7a2i?svg=true)](https://ci.appveyor.com/project/yegor256/xcop)
[![PDD status](http://www.0pdd.com/svg?name=yegor256/xcop)](http://www.0pdd.com/p?name=yegor256/xcop)
[![Gem Version](https://badge.fury.io/rb/xcop.svg)](http://badge.fury.io/rb/xcop)
[![Dependency Status](https://gemnasium.com/yegor256/xcop.svg)](https://gemnasium.com/yegor256/xcop)
[![Code Climate](http://img.shields.io/codeclimate/github/yegor256/xcop.svg)](https://codeclimate.com/github/yegor256/xcop)
[![Test Coverage](https://img.shields.io/codecov/c/github/yegor256/xcop.svg)](https://codecov.io/github/yegor256/xcop?branch=master)

## What this is for?

This command line tool validates your XML files for proper formatting.
If they are not formatted correctly, it prints the difference and
returns with an error. You can use it two ways: 1) to fail your build
if any X-like files (XML, XSD, XSL, XHTML) are not formatted correctly,
and 2) to format them correctly.

## How to install?

Install it first:

```bash
$ gem install xcop
```

## How to run?

Run it locally and read its output:

```bash
$ xcop --help
```

To validate formatting of your XML files just pass their names
as arguments:

```bash
$ xcop file1.xml file2.xml
```

If your files are not formatted correctly and `xcop` complains, you
can ask it to "beautify" them, using `--fix` option:

```bash
$ xcop --fix broken-file.xml
```

To fix all files in the directory you can do
([won't work](https://askubuntu.com/questions/343727/) if your file names contain spaces):

```bash
$ xcop --fix $(find . -name '*.xml')
```

## How to use in `Rakefile`?

This is what you need there:

```ruby
require 'xcop/rake_task'
desc 'Run XCop on all XML/XSL files in all directories'
Xcop::RakeTask.new(:xcop) do |task|
  task.license = 'LICENSE.txt' # no license by default
  task.quiet = true # FALSE by default
  task.includes = ['**/*.xml', '**/*.xsl'] # xml|xsd|xhtml|xsl|html by default
  task.excludes = ['target/**/*'] # empty by default
end
```

## How to use in Maven `pom.xml`?

You can integrate it with the help of
[maven-antrun-plugin](http://maven.apache.org/plugins/maven-antrun-plugin/):

```xml
<project>
  [...]
  <build>
    [...]
    <plugins>
      [...]
      <plugin>
        <artifactId>maven-antrun-plugin</artifactId>
        <version>1.8</version>
        <executions>
          <execution>
            <phase>verify</phase>
            <configuration>
              <target>
                <apply executable="xcop" failonerror="true">
                  <arg value="--license"/>
                  <arg value="LICENSE.txt"/>
                  <fileset dir=".">
                    <include name="**/*.xml"/>
                    <include name="**/*.xsd"/>
                    <exclude name="target/**/*"/>
                    <exclude name=".idea/**/*"/>
                  </fileset>
                </apply>
              </target>
            </configuration>
            <goals>
              <goal>run</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
    </plugins>
  </build>
</project>
```

## How to use in Ant `project.xml`?

Something like this should work:

```xml
<project>
  [...]
  <target name="xcop">
    <apply executable="xcop" failonerror="true">
      <arg value="--license"/>
      <arg value="LICENSE.txt"/>
      <fileset dir=".">
        <include name="**/*.xml"/>
        <include name="**/*.xsd"/>
        <exclude name="target/**/*"/>
        <exclude name=".idea/**/*"/>
      </fileset>
    </apply>
  </target>
</project>
```

## How to contribute?

Just submit a pull request. Make sure `rake` passes.

## License

(The MIT License)

Copyright (c) 2017-2018 Yegor Bugayenko

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the 'Software'), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
