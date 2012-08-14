gem 'test-unit' if RUBY_VERSION > "1.9"
require 'test/unit'

# Remove and reload TestLinkUpdate in case the test plan had been set by another test in the same environment
# The test plan is a Module variable, so it is shared across all classes that inherit it, in this case all other unit tests
TestLinkUpdate = Module.new if defined? TestLinkUpdate
load 'test_link_update.rb'

# Tests for the updateable? method
# Also tests the "parse_test_plan" method, as that is needed to set the test project variable
class TcUpdateable < Test::Unit::TestCase
  include TestLinkUpdate

  def test_001_no_test_plan
    @test_proj = "something"
    assert_false updateable?, "Should fail due to no test plan being defined"
  end

# Disabled because option parsing throws an error on this
#  def test_002_nil_test_plan
#    @test_proj = "something"
#    ARGV << "-q"
#    parse_test_plan
#    assert_false updateable?, "Should fail due to nil test plan"
#  end

  def test_003_nil_test_project
    ARGV << "-q something"
    parse_test_plan
    assert_false updateable?, "Should fail due to no test project"
  end

  def test_004_success
    self.class.set_tree_path "something"
    # test plan is set from previous test
    assert_true updateable?, "Should be updateable"
  end

end
