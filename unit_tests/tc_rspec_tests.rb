require 'test/unit'
require 'test_link_rspec'

class TcRspecTests < Test::Unit::TestCase

  def test_rspec_tests
    expected_array = ["Ruby core class Array with no elements should be empty", "Ruby core class Array with no elements should have a length of zero", "Ruby core class Array with one element should not be empty", "Ruby core class Array with one element should have a length of one", "Ruby core class Hash with no elements should be empty", "Ruby core class Hash with no elements should have a length of zero", "Some custom class should exist", "1 example at (eval):47"]
    eval DATA
    assert_equal expected_array, RSpec::TestLink.rspec_tests, "The tests extracted from RSpec are incorrect"
  end

  def test_accessors
    RSpec::TestLink.set_tree_path ["Project", "blah blah", "Folder"]
    assert_equal "Project", RSpec::TestLink.test_proj, ".test_proj accessor returns the wrong value"
    assert_equal "Folder", RSpec::TestLink.test_suite, ".test_suite accessor returns the wrong value"
  end

DATA = 'describe "Ruby core class" do
describe Array do
  describe "with no elements" do
    it "should be empty" do
      a = Array.new
      a.should be_empty
    end
    it "should have a length of zero" do
      a = Array.new
      a.length.should be(0)
    end
  end

  describe "with one element" do
    it "should not be empty" do
      a = [1]
      a.should_not be_empty
    end
    it "should have a length of one" do
      a = [1]
      a.length.should be(1)
    end
  end
end

describe Hash do
  describe "with no elements" do
    it "should be empty" do
      a = Hash.new
      a.should be_empty
    end
    it "should have a length of zero" do
      a = Hash.new
      a.length.should be(0)
    end
  end
end
end

describe "Some custom class" do
 it "should exist" do
  1.should be(1)
 end
end

describe 1 do
  it { should be(1)}
end'
end
