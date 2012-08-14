gem 'test-unit' if RUBY_VERSION > "1.9"
require 'test/unit'
require 'test_link_update'

# Class with a comment
class ClassWithComment < Test::Unit::TestCase
  include TestLinkUpdate
end

class ClassWithoutComment < Test::Unit::TestCase
  include TestLinkUpdate
end


# Tests the class "parse_comments" methods
class TcParseComments < Test::Unit::TestCase
  include TestLinkUpdate

  def setup
    @filename = __FILE__
    @wrong_file = "unit_tests/tc_updateable.rb"
  end

  def test_get_class_comment
    comments = ClassWithComment.parse_comments(@filename)

    assert_equal "Class with a comment", comments["ClassWithComment"], "Class comment was wrong"
  end

  def test_get_default_class_comment
    comments = ClassWithoutComment.parse_comments(@filename)

    assert_equal "Test Suite generated from Test::Unit::TestCase", comments["ClassWithoutComment"], "Class comment was wrong"
  end

  # step comment
  def test_method_with_step
    comments = self.class.parse_comments(@filename)

    assert_equal "step comment", comments[tst_case_name]["steps"], "Steps comment didn't match"
    assert_equal "Test should pass", comments[tst_case_name]["expected"], "Expected comment wasn't the default"
  end

  # step one
  # step two
  def test_method_with_multiple_steps
    comments = self.class.parse_comments(@filename)

    assert_equal "step one<BR/>step two", comments[tst_case_name]["steps"], "Steps comment didn't match"
    assert_equal "Test should pass", comments[tst_case_name]["expected"], "Expected comment wasn't the default"
  end

  #step one
  #step two
  def test_method_with_no_leading_whitespace
    comments = self.class.parse_comments(@filename)

    assert_equal "step one<BR/>step two", comments[tst_case_name]["steps"], "Steps comment didn't match"
    assert_equal "Test should pass", comments[tst_case_name]["expected"], "Expected comment wasn't the default"
  end

  #step one
  #step two
  #
  #Expected: expectation
  def test_method_with_steps_result_no_leading_whitespace
    comments = self.class.parse_comments(@filename)

    assert_equal "step one<BR/>step two", comments[tst_case_name]["steps"], "Steps comment didn't match"
    assert_equal "expectation", comments[tst_case_name]["expected"], "Expected comment didn't match"
  end

  # step one
  # step two
  #
  # Expected: expectation one
  # expectation two
  def test_method_with_steps_result
    comments = self.class.parse_comments(@filename)

    assert_equal "step one<BR/>step two", comments[tst_case_name]["steps"], "Steps comment didn't match"
    assert_equal "expectation one<BR/>expectation two", comments[tst_case_name]["expected"], "Expected comment didn't match"
  end

  def test_no_method_comment
    comments = self.class.parse_comments(@filename)

  end

  def test_not_a_file
    comments = self.class.parse_comments("not_a_file.rb")

    assert_equal "Test Suite generated from Test::Unit::TestCase", comments[self.class.name], "Class comment wasn't the default"
    assert_equal "Run automated test", comments[tst_case_name]["steps"], "Steps comment wasn't the default"
    assert_equal "Test should pass", comments[tst_case_name]["expected"], "Expected comment wasn't the default"
  end

  def test_wrong_file
    comments = self.class.parse_comments(@wrong_file)

    assert_equal "Test Suite generated from Test::Unit::TestCase", comments[self.class.name], "Class comment wasn't the default"
    assert_equal "Run automated test", comments[tst_case_name]["steps"], "Steps comment wasn't the default"
    assert_equal "Test should pass", comments[tst_case_name]["expected"], "Expected comment wasn't the default"
  end

end
