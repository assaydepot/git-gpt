# frozen_string_literal: true

require_relative "gpt/version"

module Git
  module Gpt
    class Error < StandardError; end
    def run(argv=nil)
      if ENV["OPENAI_API_KEY"].nil?
        puts "Please set OPENAI_API_KEY environment variable"
        exit 1
      end

      status = `git status #{argv.join(" ")}`
      diff = `git diff #{argv.join(" ")}`
      puts "STATUS"
      puts status

      puts "DIFF"
      puts diff
    end
  end
end