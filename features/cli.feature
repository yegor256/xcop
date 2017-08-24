Feature: Command Line Processing
  As an author of XML I want to be able to
  call XCOP as a command line tool

  Scenario: Help can be printed
    When I run bin/xcop with "-h"
    Then Exit code is zero
    And Stdout contains "--help"

  Scenario: Version can be printed
    When I run bin/xcop with "--version"
    Then Exit code is zero

  Scenario: Validating correct XML file
    Given I have a "test.xml" file with content:
    """
    <?xml version="1.0"?>
    <hello>Hello, world!</hello>

    """
    When I run bin/xcop with "test.xml"
    Then Stdout contains "OK"
    And Exit code is zero
    And Stdout contains "Validating test.xml..."

  Scenario: Validating correct XML file with license
    Given I have a "licensed.xml" file with content:
    """
    <?xml version="1.0"?>
    <!--
    This is the license,
    which is very very strict!
    -->
    <hello>Hello, world!</hello>

    """
    And I have a "LICENSE" file with content:
    """
    This is the license,
    which is very very strict!
    """
    When I run bin/xcop with "--license LICENSE licensed.xml"
    Then Stdout contains "OK"
    And Exit code is zero
    And Stdout contains "Validating licensed.xml..."

  Scenario: Validating incorrect XML file
    Given I have a "abc.xml" file with content:
    """
    <a><b>something</b>
    </a>
    """
    When I run bin/xcop with "abc.xml"
    Then Exit code is not zero

  Scenario: Validating correct XML file with broken license
    Given I have a "licensed.xml" file with content:
    """
    <?xml version="1.0"?>
    <!--
    This is the wrong license!
    -->
    <hello>Hello, world!</hello>

    """
    And I have a "LICENSE" file with content:
    """
    This is the right license.
    """
    When I run bin/xcop with "--license LICENSE licensed.xml"
    And Stdout contains "Broken license"
    And Exit code is not zero

