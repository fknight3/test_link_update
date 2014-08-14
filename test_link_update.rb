require 'test_link_api'
require 'optparse'

# This module is designed to be loaded into a Test::Unit::TestCase child.  It enables
# the tests to be easily inserted into TestLink, with the class name as the suite, and 
# the class methods as each test case.  It also can update a test plan with the result
# of an execution.
#
# Known issues include having to pass the file name when inserting the tests.  Also if
# the file contained multiple class definitions, this won't work so well either.
module TestLinkUpdate
  POUND_SIGN = /(\n|^)#[\s]*/ # matches any "^#" or "\n#" plus any whitespace after
  LEADING_BR = /^<BR\/>/ # matches and breaks at the start of a string
  #EXPECTED = /#\n#[\s]*Expected:/ # split on blank comment line followed by word "Expected:"
  EXPECTED = /\n[\s]*\n[\s]*Expected:/ # split on blank comment line followed by word "Expected:"

  def update_test_link_with_result
    parse_test_plan #get the test plan name, if provided

    # Update result if all needed data exists
    if updateable?
      tl=TestLinkAPI.new
      tcid=tl.get_test_case_id_from_path(@test_proj, @test_folder_path, tst_case_name)
      # initialize cache, if it's not already
      @@id_cache = Hash.new unless defined?(@@id_cache)
      # check the cache, or get ID's if they aren't cached
      tpid = @@id_cache[tst_plan_name] || tl.getTestPlanIDByName(tst_plan_name, tst_project_name)
      bid = (@@id_cache[tst_plan_name + ":build"] || tl.getLatestBuildIDForTestPlan(tpid)) unless tpid.nil?
      # cache the plan ID and build ID
      @@id_cache[tst_plan_name] = tpid
      @@id_cache[tst_plan_name + ":build"] = bid
      tl.reportTCResult(tcid, tpid, tst_result, bid, run_notes) unless tcid.nil? || tpid.nil? || bid.nil?
    end
  end

  def run_notes
    notes = ""
    result = instance_variable_get :@_result #Test::Unit::TestResult which accumulates
    fault = result.faults.find {|f| f.test_name == name} if result
    notes << fault.to_s if fault # if there is a fault
    notes << "\n#{@test_notes}" if @test_notes
    return notes
  end

  # alias for update_test_link_with_result
  def updateTestLinkWithResult(*args)
    update_test_link_with_result *args
  end
  
  # Add class methods into including class
  def self.included(klass)
    klass.extend ClassMethods
  end

  # Determine if a test is updatable, i.e. all information is known
  def updateable?
    return false if tst_plan_name.nil?
    return false if tst_project_name.nil?
    return true
  end

  # Parse the test plan from the command line arguments
  def parse_test_plan
    if !defined?(@@test_plan) || @@test_plan.nil?
      @@test_plan = ENV["TEST_PLAN"]
      # fix for newer test::unit which leaves "--" on ARGV
      ARGV.delete("--")
      OptionParser.new do |opts|
        opts.on("-q QAR", String) {|val| @@test_plan=val}
      end.parse!
    end
  end

  # Return the test case name
  # Can't start with "test" or it will run as a test
  def tst_case_name
    if defined?(MiniTest::Unit::TestCase) && self.class.ancestors.include?(MiniTest::Unit::TestCase)
      @__name__
    else
      name.split('(').first
    end
  end

  # Return the test plan name, or nil if it's not defined
  # Can't start with "test" or it will run as a test
  def tst_plan_name
    defined?(@@test_plan) ? @@test_plan : nil
  end

  # Return the test project name
  # Can't start with "test" or it will run as a test
  def tst_project_name
    self.class.instance_variable_get("@test_proj")
  end

  # Return the test suite name
  # Can't start with "test" or it will run as a test
  def tst_suite_name
    self.class.name
  end

  # Return the result as "p" or "f", for use by testlink api
  # Can't start with "test" or it will run as a test
  def tst_result
    passed? ? "p" : "f"
  end

  # Methods for the including class
  module ClassMethods
    attr_accessor :tl

    # Checks to see if the tests exist, and if not, it creates a folder and adds them
    # It requires you to put in your testlink login because testlink is stupid
    def insert_tests_to_test_link(authorLogin, file=nil)
      # Guess the filename if it is nil
      file = underscore(self.name) + ".rb" if file.nil?
      #Parse out the comments
      comment_hash=parse_comments(file)

      @tl=TestLinkAPI.new
      suite_comment = comment_hash[tst_suite_name]
      tsid=get_or_create_suite_id(tst_suite_name, suite_comment)
      #Get all tests, and add each one to the suite
      get_test_names.each do |tc|
        #Check if test exists already
        tcid=@tl.get_test_case_id_from_path(@test_proj, @test_folder_path, tc)
        #Add test if it doesn't exist
        
        # get comments for test
        comment = comment_hash[tc]

        @tl.createTestCase(@test_proj, tsid, tc, "Test from Test/Unit TestCase", comment["steps"], comment["expected"], authorLogin) if tcid.nil?
      end
      nil
    end

    # Return array of tests from MiniTest or Test/Unit TestCase
    def get_test_names
      if defined?(MiniTest::Unit::TestCase) && self.ancestors.include?(MiniTest::Unit::TestCase)
        self.test_methods
      else
       self.suite.tests.map {|t| t.method_name}
      end
    end

    # alias for insert_tests_to_test_link
    def insertTestsToTestLink(*args)
      insert_tests_to_test_link *args
    end

    # Populate the test_project and folder_path variables
    def set_tree_path(tree_path)
      if tree_path.is_a? String then
        @test_proj = tree_path
        @test_folder_path = []
      elsif tree_path.is_a? Array then
        @test_proj = tree_path.shift
        @test_folder_path = tree_path
      else
        raise ArgumentError, "Must send a String or Array of Strings"
      end
    end

    # alias for set_tree_path
    def setTreePath(*args)
      set_tree_path *args
    end

    # Helper method to resolve the folder path into a suite Id
    # If the Suite doesn't exist, create it
    # Returns the ID of the suite
    def get_or_create_suite_id(suite_name, suite_comment_if_new=nil)
      parent_id = nil
      suite_id = nil
      # Two cases, either there's a folder path, or there isn't
      # If there is, we will find the parent folder ID
      # In either case, we will find the suite ID if it already exists
      if @test_folder_path.nil? || @test_folder_path.empty? then
        suite_id = @tl.getFirstLevelTestSuiteIDByName(suite_name, @test_proj)
      else
        folder_path=@test_folder_path.clone #We will perform destructive actions on this array, so copy it
        parent_id = @tl.getFirstLevelTestSuiteIDByName(folder_path.shift, @test_proj)
        folder_path.each { |folder| parent_id = @tl.getChildTestSuiteIDByName(folder, parent_id)}
        raise "Folder path does not exist in Testlink: #{@test_proj} -> #{@test_folder_path.join(" -> ")}" if parent_id.nil?
        suite_id = @tl.getChildTestSuiteIDByName(suite_name, parent_id)
      end

      # If the suite_id is nil, the suite needs to be created
      suite_id = @tl.createTestSuite(suite_name, @test_proj, suite_comment_if_new, parent_id).first["id"] if suite_id.nil?

      return suite_id.to_i
    end
#    private :getSuiteId


    # Uses RDoc to parse out the comments associated with each method and the class,
    # then puts them in a more useable hash.
    def parse_comments(file)
      comment_hash = Hash.new
      oldverbose=$VERBOSE
      # RDoc included with ruby 1.8.x won't load in IRB
      # so comments will not get populated.  You can install
      # a newer RDoc via gem, or use Ruby 1.9+.
      begin
        $VERBOSE=nil
        require 'rdoc/rdoc'
      rescue NameError
        # If RDoc fails to load, use generic test descriptions instead
        puts "Cannot load RDoc.  Generic steps will be used"
        parsed = nil
      else
        opt=RDoc::Options.new
        opt.files=[file]
        if File.exists?(file)
          parser = RDoc::RDoc.new
          if RDoc::VERSION > "4"
            parser.store = RDoc::Store.new
            parser.options = opt
            parsed=parser.parse_files(opt.files).first.classes.find {|c| c.name == self.name}
          elsif RDoc::VERSION > "3" #RDoc keeps changing how you call the parser
            parser.options = opt
            parsed=parser.parse_files(opt.files).first.classes.find {|c| c.name == self.name}
          else
            parsed=parser.parse_files(opt).first.classes.find {|c| c.name == self.name}
          end
        else
          puts "Cannot find file: #{file}.  Generic steps will be used"
          parsed = nil
        end
      ensure
        # Put the classname into the hash.
        set_suite_comment(comment_hash, parsed)

        # Put each method and description into the hash
        get_test_names.each do |test|
          set_test_comment(comment_hash, parsed, test)
        end
      end
      $VERBOSE=oldverbose
      return comment_hash

    end

    def set_suite_comment(comment_hash, parsed)
      default_comment = "Test Suite generated from Test::Unit::TestCase"
      if parsed.nil?
        comment = nil
      else
        comment = parsed.comment
        comment = comment.text if comment.respond_to?(:text) #RDoc 4
      end
      comment = default_comment if comment.nil? || comment == ""
      comment_hash[self.name] = comment.gsub(TestLinkUpdate::POUND_SIGN, "<BR/>").gsub(TestLinkUpdate::LEADING_BR, "").strip
    end
    private :set_suite_comment

    def set_test_comment(comment_hash, parsed, method)
      default_steps = "Run automated test"
      default_expected = "Test should pass"
      comment = nil
      unless parsed.nil?
        comment = parsed.method_list.find {|m| m.name == method}
      end
      # comment is now either nil, or the method rdoc object
      if comment.nil?
        comment = ""
      else
        comment = comment.comment
        comment = comment.text if comment.respond_to?(:text) #RDoc 4
      end
      # comment is now either "", or a real comment
      steps, expected = comment.split TestLinkUpdate::EXPECTED
      steps ||= default_steps
      steps.gsub!("\n", "<BR/>") #Darkfish generator doesn't use breaks, but TestLink needs them for proper spacing
      expected ||= default_expected
      expected.gsub!("\n", "<BR/>") #Darkfish generator doesn't use breaks, but TestLink needs them for proper spacing
      comment_hash[method] = {"steps" => steps.gsub(TestLinkUpdate::POUND_SIGN, "<BR/>").gsub(TestLinkUpdate::LEADING_BR, "").strip, "expected" => expected.gsub(TestLinkUpdate::POUND_SIGN, "<BR/>").gsub(TestLinkUpdate::LEADING_BR, "").strip}
    end
    private :set_test_comment

    def underscore(camel_cased_word)
      camel_cased_word.to_s.gsub(/::/, '/').
       gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
       gsub(/([a-z\d])([A-Z])/,'\1_\2').
       tr("-", "_").
       downcase
    end
    private :underscore

    def tst_suite_name
      self.name
    end
  end #ClassMethods
  
end #TestLinkUpdate
