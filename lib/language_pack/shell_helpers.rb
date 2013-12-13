require 'shellwords'

module LanguagePack
  module ShellHelpers

    def self.user_env_hash
      @@user_env_hash ||= {}
    end

    def user_env_hash
      @@user_env_hash
    end

    def self.blacklist?(key)
      %w(PATH GEM_PATH GEM_HOME GIT_DIR).include?(key)
    end

    def self.initialize_env(path)
      if file = Pathname.new("#{path}") && file.exist?
        file.read.split("\n").map {|x| x.split("=") }.each do |k,v|
          user_env_hash[k.strip] = v.strip unless blacklist?(k.strip)
        end
      end
    end

    # display error message and stop the build process
    # @param [String] error message
    def error(message)
      Kernel.puts " !"
      message.split("\n").each do |line|
        Kernel.puts " !     #{line.strip}"
      end
      Kernel.puts " !"
      log "exit", :error => message if respond_to?(:log)
      exit 1
    end

    def run!(command, options = {})
      result = run(command, options)
      error("Command: '#{command}' failed unexpectedly:\n#{result}") unless $?.success?
      return result
    end

    # run a shell comannd and pipe stderr to stdout
    # @param [String] command to be run
    # @param [options] optional IO redirect
    # @return [String] output of stdout and stderr

    def run(command, options = {})
      options[:out] ||= "2>&1"
      options[:env] ||= {}
      options[:env] = user_env_hash.merge(options[:env]) if options[:user_env]
      env           = options[:env].map {|key, value| "#{key}=#{value}"}.join(" ")
      %x{ bash -c #{env} #{command.shellescape} #{out} }
    end

    # run a shell command and pipe stderr to /dev/null
    # @param [String] command to be run
    # @return [String] output of stdout
    def run_stdout(command, options = {})
      options[:out] ||= '2>/dev/null')
      run(command, options)
    end

    # run a shell command and stream the output
    # @param [String] command to be run
    def pipe(command, options = {})
      output = ""
      options[:env] ||= {}
      options[:env] = user_env_hash.merge(options[:env]) if options[:user_env]
      env = options[:env].map {|key, value| "#{key}=#{value}"}.join(" ")
      IO.popen("#{env} #{command}") do |io|
        until io.eof?
          buffer = io.gets
          output << buffer
          puts buffer
        end
      end

      output
    end

    # display a topic message
    # (denoted by ----->)
    # @param [String] topic message to be displayed
    def topic(message)
      Kernel.puts "-----> #{message}"
      $stdout.flush
    end

    # display a message in line
    # (indented by 6 spaces)
    # @param [String] message to be displayed
    def puts(message)
      message.split("\n").each do |line|
        super "       #{line.strip}"
      end
      $stdout.flush
    end

    def warn(message)
      @warnings ||= []
      @warnings << message
    end

    def deprecate(message)
      @deprecations ||= []
      @deprecations << message
    end
  end
end
