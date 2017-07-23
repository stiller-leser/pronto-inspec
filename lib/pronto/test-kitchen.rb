require 'pronto'

module Pronto
  class TestKitchen < Runner
    def run
      puts "HIHO UNCLE JOE "
      return [] if !@patches || @patches.count.zero?

      @patches
        .select { |patch| patch.additions > 0 }
        .map { |patch| inspect(patch) }
        .flatten.compact

      byebug
    end

    private

    def git_repo_path
      @git_repo_path ||= Rugged::Repository.discover(File.expand_path(Dir.pwd)).workdir
    end
  end
end
