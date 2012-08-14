gem 'test-unit' if RUBY_VERSION > "1.9"
require 'test/unit'
require 'test_link_update'

# Tests the various "tst_xxx_name" methods
class TcNameStuff < Test::Unit::TestCase
  include TestLinkUpdate

  def test_tst_case_name
    assert_equal "test_tst_case_name", tst_case_name, "Test case name is wrong"
  end

  def test_tst_plan_name_01_nil
    assert_nothing_raised("tst_plan_name threw an exception") { tst_plan_name }
    assert_nil tst_plan_name, "Test plan name isn't nil"
  end

  def test_tst_plan_name_02
    plan = "plan name"
    ARGV << "-q" << plan
    parse_test_plan

    assert_equal plan, tst_plan_name, "Test plan name is wrong"
  end

  def test_tst_project_name_01_nil
    assert_nothing_raised("tst_project_name threw an exception") { tst_project_name }
    assert_nil tst_project_name, "Test project name isn't nil"
  end

  def test_tst_project_name_02
    name ="project name"
    self.class.set_tree_path name

    assert_equal name, tst_project_name, "Test project name is wrong"
  end

  # should equal the name of this class
  def test_tst_suite_name
    assert_equal "TcNameStuff", tst_suite_name, "Test suite name is wrong"
  end

end
