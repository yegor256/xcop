<img src="/logo.svg" width="64px"/>

[![EO principles respected here](https://www.elegantobjects.org/badge.svg)](https://www.elegantobjects.org)
[![Managed by Zerocracy](https://www.0crat.com/badge/C3RFVLU72.svg)](https://www.0crat.com/p/C3RFVLU72)
[![DevOps By Rultor.com](http://www.rultor.com/b/yegor256/xcop)](http://www.rultor.com/p/yegor256/xcop)
[![We recommend RubyMine](https://www.elegantobjects.org/rubymine.svg)](https://www.jetbrains.com/ruby/)

[![Build Status](https://travis-ci.org/yegor256/xcop.svg)](https://travis-ci.org/yegor256/xcop)
[![Build status](https://ci.appveyor.com/api/projects/status/orvfo2qgmd1d7a2i?svg=true)](https://ci.appveyor.com/project/yegor256/xcop)
[![PDD status](http://www.0pdd.com/svg?name=yegor256/xcop)](http://www.0pdd.com/p?name=yegor256/xcop)
[![Gem Version](https://badge.fury.io/rb/xcop.svg)](http://badge.fury.io/rb/xcop)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/yegor256/xcop/blob/master/LICENSE.txt)

[![Maintainability](https://api.codeclimate.com/v1/badges/396ec0584e0a84adc723/maintainability)](https://codeclimate.com/github/yegor256/xcop/maintainability)
[![Test Coverage](https://img.shields.io/codecov/c/github/yegor256/xcop.svg)](https://codecov.io/github/yegor256/xcop?branch=master)
[![Hits-of-Code](https://hitsofcode.com/github/yegor256/xcop)](https://hitsofcode.com/view/github/yegor256/xcop)

This command line tool validates your XML files for proper formatting.
If they are not formatted correctly, it prints the difference and
returns with an error. You can use it two ways: 1) to fail your build
if any X-like files (XML, XSD, XSL, XHTML) are not formatted correctly,
and 2) to format them correctly.

Read this blog post of mine first:
[_XCOP—XML Style Checker_](https://www.yegor256.com/2017/08/29/xcop.html).

Install it first (read below if you can't install it):

```bash
$ gem install xcop
```

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

## How to use as GitHub action?

Create new workflow file in repository under `.github/workflows/xcop.yml`:
```yaml
---
name: XCOP
"on":
  # run on push to master events
  push:
    branches:
      - master
  # run on pull requests to master
  pull_request:
    branches:
      - master
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: g4s8/xcop-action@master
```
To customize license location or files pattern use action inputs `license` and `files`:
```yaml
- uses: g4s8/xcop-action@master
  with:
    license: MY_LICENSE.txt
    files: "src/*.xml"
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

## How to contribute

Read [these guidelines](https://www.yegor256.com/2014/04/15/github-guidelines.html).
Make sure you build is green before you contribute
your pull request. You will need to have [Ruby](https://www.ruby-lang.org/en/) 2.3+ and
[Bundler](https://bundler.io/) installed. Then:

```
$ bundle update
$ bundle exec rake
```

If it's clean and you don't see any error messages, submit your pull request.
