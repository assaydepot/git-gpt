# frozen_string_literal: true

require_relative "gpt/version"
require 'yaml'
require 'json'
require 'openai'

module Git
  module Gpt
    class Error < StandardError; end
    class CLI
      def run(argv=nil)
        prompt =<<-EOS
        You are a software engineer working on a project. You write diligent and detailed commit messages. You are working on a new feature and you are ready to commit your changes.

        The current git status is:
        ```
        $GIT_STATUS
        ```

        The current git diff is:
        ```
        $GIT_DIFF
        ```

        Please write a commit message for this change. The commit message should be a single sentence. The commit message should start with a capital letter. The commit message should end with a period. The commit message should be 50 characters or less.
        EOS

        config = { 
          "model" => "gpt-3.5-turbo", 
          "temperature" => 0.7, 
          "prompt" => prompt,
          "openai_api_key" => ENV["OPENAI_API_KEY"],
          "openai_organization_id" => ENV["OPENAI_ORGANIZATION_ID"]
        }
        config_filename = find_file(".git-gpt-config.yml")
        config_file = YAML.load_file(".git-gpt-config.yml") if config_filename
        config.merge!(config_file) if config_file

        if config["openai_api_key"].nil?
          puts "Please set OPENAI_API_KEY environment variable"
          exit 1
        end

        git_status = `git status #{argv.join(" ")}`
        git_diff = `git diff #{argv.join(" ")}`

        prompt = config["prompt"].gsub("$GIT_STATUS", git_status).gsub("$GIT_DIFF", git_diff)

        client = OpenAI::Client.new(access_token: config["openai_api_key"], organization_id: config["openai_organization_id"])
        response = client.chat(
          parameters: {
            model: config["model"],
            temperature: config["temperature"],
            messages: [{ role: "user", content: prompt }]
          }
        )
        puts response.dig("choices", 0, "message", "content")
      end

      # Find the closest .git-gpt-config.yml file in the current directory, any parent directory or the users home directory
      def find_file(filename)
        paths = []
        path_pieces = Dir.pwd.split(File::SEPARATOR)
        while path_pieces.any?
          path = path_pieces.join(File::SEPARATOR)
          path_pieces.pop
          paths << [path, filename].join(File::SEPARATOR)
        end
        paths << [ENV["HOME"], filename].join(File::SEPARATOR) if ENV["HOME"]
        result = paths.detect { |path| File.exists?(path) }
        result
      end
    end
  end
end