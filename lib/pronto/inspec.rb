require 'pronto'
require 'byebug'
require 'yaml'
require 'colorize'
require 'nokogiri'

module Pronto
  class Inspec < Runner
    def initialize(_, _ = nil)
      super
      begin
        @config = YAML.load_file('.pronto-test-kitchen.yml')
      rescue
        abort('Could not find .pronto-test-kitchen file.'.red)
      end

      @kitchen_command = @config['kitchen_command']
      abort('Please specify a base command for kitchen, i.e. kitchen test'.red) if @kitchen_command.nil?
      @inspec_file = @config['inspec_file']
      abort('Please specify the name of the inspec file'.red) if @inspec_file.nil?

      @suites_to_check = []
      @config['suites'].each do |suite|
        if suite['files'].count > 0
          @suites_to_check.push(suite)
        else
          puts "No files configured for suite #{suite.first[0]}\n".yellow
        end
      end
      abort('All suites are empty, please specify files.'.red) if @suites_to_check.count.zero
      @suites_to_run ||= []
    end

    def run
      return [] if !@patches || @patches.count.zero?

      @patches
        .select { |patch| patch.additions > 0 }
        .map { |patch| inspect(patch) }

      failures = []

      if @suites_to_run.count > 0
        puts "\nCreated runlist: #{@suites_to_run}".blue
        failures = []
        @suites_to_run.each do |suite|
          system("#{@kitchen_command} #{suite}")
          doc = Nokogiri::XML(File.open(@inspec_file))
          testsuites = doc.xpath('//testsuite')
          testsuites.each_with_index do |_, index|
            failed = testsuites[index].attr('failed')
            name = testsuites[index].attr('name')
            if failed.to_i > 0
              failures.push(create_message(suite, "Suite '#{name}' expirienced #{failed} failures"))
            else
              puts "\n No failures found for testsuite '#{name}' in kitchen suite '#{suite}'".green
            end
          end
        end
      else
        puts 'Found no matching files in suites'.red
      end

      failures
    end

    private

    def create_message(suite, output)
      Message.new(suite, @patches.first.added_lines.first, :error, output)
    end

    def git_repo_path
      @git_repo_path ||= Rugged::Repository.discover(File.expand_path(Dir.pwd)).workdir
    end

    def inspect(patch)
      changed_file = patch.new_file_full_path.to_s
      @suites_to_check.each do |suite|
        suite_name = suite.first[0]
        puts "\nInspecting '#{suite_name}'...".yellow
        puts "\tSearching for '#{changed_file}' in suite '#{suite_name}'...".yellow
        suite['files'].each do |file|
          puts "\t\tMatching changed '#{changed_file}' against suite file '#{file}'...".yellow
          next unless changed_file.include?(file) || @suites_to_run.include?(suite_name)
          puts "\t\t\tFound '#{file}' in '#{suite_name}'! Adding '#{suite_name}' to run list".blue
          @suites_to_run.push(suite_name)
        end
      end
    end
  end
end
