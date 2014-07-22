require 'xmlrpc/client'
require 'yaml'

#This is just thrown together sort of quick.  Some of the methods should probably return true/false, but don't yet
#Some probably need more error handling and that sort of thing as well.  And some are "virtual" methods in that
#TestLink's API doesn't actually implement them.
#
#The initial goal was just to provide enough functionality for the test_link module for test::unit to work. 
#
#The correct/preferred way to configure this module is to have a file ".test_link_update/config.yaml" in your home directory.  The
#file should define the variables "endpoint" for the TestLink API endpoint, and "devkey" for your personal TestLink dev key.  Alternately
#you can instantiate it with the endpoint url, and then set the devkey attribute before making calls.
class TestLinkAPI
  attr_reader :tl
  attr_accessor :devkey

  # Set the path this file is loaded from, so the config can be loaded properly too
  CONFIG_FILE = (ENV['HOME'] || ENV['USERPROFILE']) + "/.test_link_update/config.yaml"
  
  def initialize(endpoint=nil)
    if File.exists? CONFIG_FILE
      config=YAML.load_file CONFIG_FILE
    else
      warn "Config file: #{CONFIG_FILE} doesn't exist.  Make sure to initialize with TestLink API endpoint, and set the devkey"
      config = {}
    end
    endpoint ||= config["endpoint"]
    @tl=XMLRPC::Client.new2(endpoint)
    @devkey=config["devkey"]
  end
  
  def getTestCaseIDByName(testcasename, testsuitename, testprojectname)
    args={"devKey"=>@devkey, "testcasename"=>testcasename, "testprojectname"=>testprojectname, "testsuitename"=>testsuitename}
    res=@tl.call("tl.getTestCaseIDByName", args)
    if res.is_a?(Hash) && res.length == 1 && res.keys.first == res.keys.first.to_i.to_s #Stupid hack because testlink sucks it, and returns an extra depth on tests that exist in multiple projects
      res = [res.values.first]
    end
    res.first["id"].nil? ? nil : res.first["id"].to_i
  end
  
  def reportTCResult(testcaseid, testplanid, status, buildid, notes="")
    args={"devKey"=>@devkey, "testcaseid"=>testcaseid, "testplanid"=>testplanid, "status"=>status, "buildid"=>buildid, "notes"=>notes}
    res=@tl.call("tl.reportTCResult", args)
    res
  end
  
  def getLatestBuildIDForTestPlan(testplanid)
    args={"devKey"=>@devkey, "testplanid"=>testplanid}
    resp=@tl.call("tl.getLatestBuildForTestPlan", args)
    return resp.class == Array ? nil : resp["id"].to_i
  end
  
  def createTestSuite(testsuitename, test_project, details=nil, parentID=nil)
    proj_id = test_project.is_a?(Numeric) ? test_project : getProjectIDByName(test_project)
    args={"devKey"=>@devkey, "testprojectid"=>proj_id, "testsuitename"=>testsuitename}
    args["details"]=details if details.is_a? String
    args["parentid"]=parentID if parentID.is_a? Numeric
    res=@tl.call("tl.createTestSuite", args)
    res
  end
  
  def createTestCase(test_project, testsuiteid, testcasename, summary, steps, expectedresults, authorlogin)
    proj_id = test_project.is_a?(Numeric) ? test_project : getProjectIDByName(test_project)
    step = {"actions" => steps, "expected_results" => expectedresults, "step_number" => 1, "execution_type" => 2}
    args={"devKey"=>@devkey, "executiontype"=>2, "testprojectid"=>proj_id, "testsuiteid"=>testsuiteid, "testcasename"=>testcasename, "summary"=>summary, "steps"=>[step], "authorlogin"=>authorlogin}
    res=@tl.call("tl.createTestCase", args)
    res
  end
  
  def getTestPlanIDByName(testplan, test_project)
    proj_id = test_project.is_a?(Numeric) ? test_project : getProjectIDByName(test_project)
    args={"devKey"=>@devkey, "testprojectid"=>proj_id}
    resp=@tl.call("tl.getProjectTestPlans", args)
    resp.each do |val|
      return val["id"].to_i if val["name"] == testplan
    end
    return nil
  end
  
  def getProjectIDByName(test_projectname)
    args={"devKey"=>@devkey}
    resp=@tl.call("tl.getProjects", args)
    resp.each do |a|
      return a["id"].to_i if a["name"] == test_projectname
    end
    return nil
  end

  def getFirstLevelTestSuitesForTestProject(test_project)
    proj_id = test_project.is_a?(Numeric) ? test_project : getProjectIDByName(test_project)
    args={"devKey"=>@devkey, "testprojectid"=>proj_id}
    @tl.call("tl.getFirstLevelTestSuitesForTestProject", args)
  end

  def getFirstLevelTestSuiteIDByName(testsuitename, test_project)
    resp=getFirstLevelTestSuitesForTestProject(test_project)
    resp.each do |a|
      return a["id"].to_i if a["name"] == testsuitename
    end
    return nil
  end

  def getChildTestSuiteIDByName(child_name, parent_id)
    resp=getTestSuitesForTestSuite(parent_id)
    # They return an empty string if the parent is completely empty
    if resp.is_a? String then
      return nil
    # An empty or populated array is normally returned
    elsif resp.is_a? Array then
      resp.each do |a|
        return a["id"].to_i if a["name"] == child_name
      end
    # Testlink 1.9 sucks.  If there are multiple children, it's a hash where the key is the id, and the value is another hash of the child
    # If there is one child, there is no id as the key.  It's just a hash of the one child.  So good luck...
    # I am testing the value of the first pair to see if it's a hash.
    elsif resp.is_a? Hash then
      if resp.first[1].is_a? Hash then # many children
        resp.each do |id, hash|
          return hash["id"].to_i if hash["name"] == child_name
        end
      else # single child
        return resp["id"].to_i if resp["name"] == child_name
      end
    end
    # If the suite wasn't found, return nil
    return nil
  end

  def getTestSuitesForTestSuite(test_suite_id)
    raise ArgumentError, "Passed parameter is not Numeric: #{test_suite_id}" unless test_suite_id.is_a? Numeric
    args={"devKey"=>@devkey, "testsuiteid"=>test_suite_id}
    @tl.call("tl.getTestSuitesForTestSuite", args)
  end

  def get_test_suite_id_from_path(test_project, test_folder_path)
    suite_id = nil
    folder_path=test_folder_path.clone
    suite_id = getFirstLevelTestSuiteIDByName(folder_path.shift, test_project)
    folder_path.each { |folder| suite_id = getChildTestSuiteIDByName(folder, suite_id)}
    raise "Folder path does not exist in Testlink: #{test_project} -> #{test_folder_path.join(" -> ")}" if suite_id.nil?
    return suite_id
  end

  def getTestCasesForTestSuite(test_suite_id)
    raise ArgumentError, "Passed parameter is not Numeric: #{test_suite_id}" unless test_suite_id.is_a? Numeric
    args={"devKey"=>@devkey, "testsuiteid"=>test_suite_id, "deep"=>false}
    @tl.call("tl.getTestCasesForTestSuite", args)
  end

  def get_test_case_id_from_path(test_project, test_folder_path, test_case_name)
    suite_id = get_test_suite_id_from_path(test_project, test_folder_path)
    test_cases = getTestCasesForTestSuite(suite_id)
    return nil if test_cases == "" #TestLink returns an empty string instead of an empty array, woohoo
    test_case = test_cases.find {|test_case| test_case['name'] == test_case_name}
    return nil if test_case.nil?
    return test_case['id'].to_i
  end
end
