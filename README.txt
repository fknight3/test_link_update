= Test Link Update, a module for Test::Unit::TestCase objects

This module lets you insert your test methods into Test Link, as well as update a test plan in Test Link when they are run.

== Create your dev key
You have to add your personal devkey from TestLink into the config.yaml file before you can use it. This is because the devkey identifies the updates were made by you. To find your devkey, sign into TestLink. Then click on "Personal". There will be a section on generating your dev or API key.

You need to have a dev key and the XMLRPC endpoint defined in a file in <tt>~/.test_link_update/config.yaml</tt>  The format should look like this:

 devkey: abcd123
 endpoint: http://my.testlink.server/testlink/lib/api/xmlrpc.php

You can find your home directory by typing <tt>echo $HOME</tt> on linux, or <tt>echo %USERPROFILE%</tt> on Windows.  This is where you need to create the <tt>.test_link_update</tt> folder, and then place the <tt>config.yaml</tt> file.

== Update your tests

Change your testcase to include the TestLinkUpdate module. You also have to define what TestLink project and folder structure the tests are a part of. Lastly, you need to call the update method in your teardown.

<b>TestCase Before Update</b>

  require 'test/unit'

  # Description of class
  class TcDemo < Test::Unit::TestCase
 
    def setup
      #Setup code
    end
 
    # Description of test
    def test_always_pass
      assert_equal true, true
    end
 
    def teardown
      #teardown code
    end
 
  end

<b>TestCase After Update</b>

  require 'test/unit'
  require 'test_link_update'                    #<-- Require the module
 
  # Description of class

  class TcDemo < Test::Unit::TestCase
    include TestLinkUpdate                      #<-- Include the module
    set_tree_path ["My Project", "Sub Folder"]  #<-- Add the project and any sub-folder structure to use in Test Link

    def setup
      #Setup code  
    end
 
    # Description of test
    def test_always_pass
      assert_equal true, true
    end
 
    def teardown
      #teardown code
      update_test_link_with_result              #<-- Send pass/fail result to Test Link on teardown
    end
 
  end

===Commenting your tests
If you add comments to your test methods, they will get used as the test steps when inserted into TestLink. This is a good practice to document your automated tests, and also makes the TestLink tests more useful. I.e:

  # Create a new user, and make sure the response is successful
  def test_create_new_user
    ...
  end

Additionally, you can add steps and an expected result in such a way that they are added to TestLink separately. Just use "Expected:" on a new line of comment with a commented empty line between them. For example:

  # Create a new user with all required fields
  # Extract the status from the response
  #
  # Expected: The status should be a success code.
  def test_create_new_user
    ...
  end

==Using the module
===Inserting tests to TestLink
To insert the tests into testlink, you simply need to call the class method TestLinkUpdate::ClassMethods#insert_tests_to_test_link with your testlink userid and the name of the file that contains the tests:

  require 'tc_demo'
  TcDemo.insert_tests_to_test_link("yourTestLinkID","tc_demo.rb")

The module will try to guess the file name if you use Ruby conventions.  For example a test class of TcDemo should be in a file named "tc_demo.rb".

When inserting them, the comments that describe the class will be used for the test suite description. And the comments describing the test method will become the steps for the test case.
===Updating test results to TestLink
Once you have created a test plan and build in TestLink and added the testcases, you can update the result by adding the -q parameter followed by the test plan (should be the QAR) name when running your test:
  ruby tc_demo.rb -- -q "my qar name"
If you are using MiniTest's Test::Unit, it does not pass command-line parameters to the tests.  So you will need to set the environment variable "TEST_PLAN":
  export TEST_PLAN="my qar name"
  ruby tc_demo.rb

=Ruby RSpec/TestLink module

==Update your tests
Change your spec to include the TestLinkUpdate module.  You also have to define what TestLink project and folder structure the tests are a part of.  Lastly, you need to call the update method in your teardown.
<b>Spec Before Update</b>

  describe "Ruby core class" do
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
    end
  end

<b>Spec After Update</b>

  require 'test_link_rspec'                                   #<-- Require the plugin
  RSpec::TestLink.set_tree_path ["My Project", "My Folder"]   #<-- Set up the project and folder path that aligns with TestLink

  describe "Ruby core class" do
    after(:each) do                                           #<-- Add after processing to update TestLink 
      update_test_link_with_result                            #<-- with pass/fail information
    end                                                       #<--

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
    end
  end

==Using the module
===Inserting tests to TestLink
To insert the tests into testlink, you simply need to call the method <b>insert_tests_to_testlink</b> with your testlink 
userid.  This is easily done in IRB:

  require 'array_spec'
  RSpec::TestLink.insert_tests_to_test_link("yourTestLinkID")

When inserting them, the tests will be the examples defined by RSpec.  In the case above, the inserted tests would be:
- Ruby core class Array with no elements should be empty
- Ruby core class Array with no elements should have a length of zero

Because of the way the tests are inserted without executing, this will not work well with one-liner style RSpec tests.  They have no meaningful description until after they are run.

===Updating test results to TestLink
Once you have created a test plan and build in TestLink and added the testcases, you can update the result by adding an environment variable "TEST_PLAN" with the value of the test plan (should be the QAR) name:
  export TEST_PLAN="my qar name"
  rspec array_spec.rb

