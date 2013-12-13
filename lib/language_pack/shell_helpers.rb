require 'shellwords'

module LanguagePack
  module ShellHelpers

    def self.user_env
      @@user_env ||= {}
    end

    def user_env
      @@user_env
    end


    def self.blacklist?(key)
      false
    end

    def self.initialize_env(file)
      if File.exists?(file)
        File.read(file).split("\n").map {|x| x.split("=") }.each do |k,v|
          user_env[k.strip] = v.strip unless blacklist?(k.strip)
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

    def run!(command)
      result = run(command)
      error("Command: '#{command}' failed unexpectedly:\n#{result}") unless $?.success?
      return result
    end

    def run_with_env(command, options = {})
      out = options[:out] || "2>&1"
      env = user_env.merge(options[:env]||{}]).map {|key, value| "#{key}=#{value}"}.join(" ")
      run("env #{env} #{command}", out)
    end

    # run a shell comannd and pipe stderr to stdout
    # @param [String] command to be run
    # @param [out] optional IO redirect
    # @return [String] output of stdout and stderr
    def run(command, out = "2>&1")
      %x{ bash -c #{command.shellescape} #{out} }
    end

    # run a shell command and pipe stderr to /dev/null
    # @param [String] command to be run
    # @return [String] output of stdout
    def run_stdout(command)
      run(command, '2>dev/null')
    end

    # run a shell command and stream the output
    # @param [String] command to be run
    def pipe(command)
      output = ""
      IO.popen(command) do |io|
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
