gem 'test-unit' if RUBY_VERSION > "1.9"
require 'test/unit'

# Remove and reload TestLinkUpdate in case the test plan had been set by another test in the same environment
# The test plan is a Module variable, so it is shared across all classes that inherit it, in this case all other unit tests
TestLinkUpdate = Module.new if defined? TestLinkUpdate
load 'test_link_update.rb'

# Tests the "parse_test_plan" method
class TcParseTestPlan < Test::Unit::TestCase
  include TestLinkUpdate

  def test_001_no_options
    parse_test_plan

    assert_nil tst_plan_name, "Test plan should be nil"
  end

  def test_002_env_setting
    plan = "my env plan"
    ENV["TEST_PLAN"] = plan
    parse_test_plan

    assert_equal plan, tst_plan_name, "Test plan name was not parsed properly from ENV variable"
    @@test_plan = nil
  end

  def test_003_parse_options
    plan = "my plan"
    ARGV << "-q" << plan
    parse_test_plan

    assert_equal plan, tst_plan_name, "Test plan name was not parsed properly from options"
  end

  # Try to parse options again, it should still
  # use the options from the prior test
  def test_004_parse_options_again
    plan = "my new plan"
    ARGV << "-q" << plan
    parse_test_plan

    assert_not_equal plan, tst_plan_name, "Test plan should not have been parsed again"
  end
end
