require 'pronto'
require 'yaml'
require 'colorize'
require 'nokogiri'
require 'open3'

module Pronto
  class Inspec < Runner
    def initialize(_, _ = nil)
      super
      begin
        @config = YAML.load_file('.pronto-inspec.yml')
      rescue
        abort('Could not find .pronto-inspec file. See .pronto-inspec.sample.yml'.red)
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
      abort('All suites are empty, please specify files.'.red) if @suites_to_check.count.zero?
      @suites_to_run ||= []
    end

    def copy_lines(str_in, str_out)
      str_in.each_line {|line| str_out.puts line}
    end

    def run
      return [] if !@patches || @patches.count.zero?

      @patches
        .select { |patch| patch.additions > 0 }
        .map { |patch| inspect(patch) }

      result = []

      if @suites_to_run.count > 0
        puts "\nCreated runlist: #{@suites_to_run}\n".green
        result = []
        @suites_to_run.each do |suite|
          cmd = "#{@kitchen_command} #{suite}"
          Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
            stdin.close
            err_thr = Thread.new { copy_lines(stderr, $stdout) }
            copy_lines(stdout, $stdout)
            err_thr.join
            exit_status = wait_thr.value
            unless exit_status.success?
              abort "Test kitchen failed".red
            end
          end
          doc = Nokogiri::XML(File.open(@inspec_file))
          testsuites = doc.xpath('//testsuite')
          testsuites.each_with_index do |testsuite, index|
            failed = testsuites[index].attr('failed')
            name = testsuites[index].attr('name')
            if failed.to_i > 0
              failures = ''
              testsuite.xpath('//failure').each do |failure|
                failures += "- #{failure.attr('message')} \n"
              end
              result.push(create_message(suite, "Testsuite '#{name}' in #{suite} expirienced #{failed} failures: \n#{failures}".red))
            else
              puts "\n No failures found for testsuite '#{name}' in kitchen suite '#{suite}'".green
            end
          end
        end
      else
        puts 'Found no matching files in suites'.red
      end

      result
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
        puts "\tSearching for '#{changed_file}' in suite '#{suite_name}'...".blue
        suite['files'].each do |file|
          if @suites_to_run.include?(suite_name)
            next
          elsif file.include?('**')
            puts 'Found wildcard, adding suite to runlist'.green
            @suites_to_run.push(suite_name)
          elsif file[-1,1] == '*'
            puts "\t\tMatching changed '#{changed_file}' against #{suite_name}".blue
            if changed_file.include?(file[0, file.size-2])
              puts "\t\t\tFound '#{file}' in '#{suite_name}'! Adding '#{suite_name}' to run list".green
              @suites_to_run.push(suite_name)
            end
          elsif changed_file.include?(file)
            puts "\t\tMatching changed '#{changed_file}' against suite file '#{file}'...".blue
            puts "\t\t\tFound '#{file}' in '#{suite_name}'! Adding '#{suite_name}' to run list".green
            @suites_to_run.push(suite_name)
          else
            next
          end
        end
      end
    end
  end
end
