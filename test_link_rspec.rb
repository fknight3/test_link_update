require 'rspec'
require 'test_link_api'

module RSpec

  module TestLink

    def self.insert_tests_to_testlink(author_login)
      @tl = TestLinkAPI.new
      suite_id = get_suite_id
      description = "Test from RSpec test case"
      step = "Run automated test"
      expected = "Test should pass"
      rspec_tests.each do |test|
        test_id = @tl.get_test_case_id_from_path(@test_proj, @test_folder_path, test)
        @tl.createTestCase(@test_proj, suite_id, test, description, step, expected, author_login) if test_id.nil?
      end
    end

    # returns the list of tests defined in RSpec
    def self.rspec_tests(example_group=nil)
      if example_group.nil?
        ::RSpec::Core::ExampleGroup.children.map {|child| rspec_tests(child)}.flatten
      elsif example_group.children.empty?

        # Check for Module/Class based example group description
        if "#{example_group.description}".include? '::'
          example_group.examples.map { |x| "It #{x.description}" }
        else
          example_group.examples.map { |x| "#{example_group.description} #{x.description}"}
        end
      else
        
        # Check for Module/Class based example group description
        if "#{example_group.description}".include? '::'
          example_group.children.map { |c| rspec_tests(c) }.flatten.map { |d| "#{d}" }
        else
          example_group.children.map { |c| rspec_tests(c)}.flatten.map { |d| "#{example_group.description} #{d}" }
        end
      end
    end

    # Populate the test_project and folder_path variables
    def self.set_tree_path(tree_path)
      raise ArgumentError, "Must send an Array of Strings" unless tree_path.is_a? Array
      raise ArgumentError, "Array must have at least two entries, the project and the suite folder" unless tree_path.length > 1
      @test_proj = tree_path.shift
      @test_folder_path = tree_path
      @test_suite = tree_path.last
    end

    def self.test_proj
      @test_proj
    end

    def self.test_suite
      @test_suite
    end

    # Helper method to resolve the folder path into a suite Id
    # Returns the ID of the suite
    def self.get_suite_id()
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
      end

      return parent_id.to_i
    end
  end

  module Core
    class ExampleGroup
      def update_test_link_with_result
        test_plan = ENV["TEST_PLAN"]
        
        # Check for Module/Class based example group description
        if "#{self.class.metadata[:example_group][:full_description]}".include? '::'
          test_name = "It #{self.example.description}"
        else
          test_name = "#{self.class.metadata[:example_group][:full_description]} #{self.example.description}"
        end
        
        if test_plan && test_name
          tl = TestLinkAPI.new
          test_suite = ::RSpec::TestLink.test_suite
          test_proj = ::RSpec::TestLink.test_proj
          test_id = tl.getTestCaseIDByName(test_name, test_suite, test_proj)
          # initialize cache, if it's not already
          @@testlink_cache = Hash.new unless defined?(@@testlink_cache)
          # check the cache, or get ID's if they aren't cached
          plan_id = @@testlink_cache[test_plan] || tl.getTestPlanIDByName(test_plan, test_proj)
          build_id = (@@testlink_cache[test_plan + ":build"] || tl.getLatestBuildIDForTestPlan(plan_id)) unless plan_id.nil?
          # cache the plan ID and build ID
          @@testlink_cache[test_plan] = plan_id
          @@testlink_cache[test_plan + ":build"] = build_id
          result = example.exception ? "f" : "p"
          run_note = ""
          run_note = example.exception.to_s if example.exception
          tl.reportTCResult(test_id, plan_id, result, build_id, run_note) unless test_id.nil? || plan_id.nil? || build_id.nil?
        end
      end
    end
  end
end
