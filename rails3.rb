#!/usr/bin/env ruby

#
# LiteSpeed Web Server rails 3.x runner 
# Grzegorz Derebecki <grzegorz.derebecki@xan.pl>
#

require "rubygems"
require "rack"
require "stringio"

module Lsws
  class Server
  
    attr_accessor :root
    attr_accessor :environment
    attr_accessor :name
    attr_accessor :config
  
    def initialize(root, environment, name = nil)
      self.root = root
      self.environment = environment
      self.name = name || root
      self.config = "config.ru"
    end
  
    def fix_env
      ENV['RAILS_ROOT'] = root
      ENV['RAILS_ENV']  = environment
    end
    
    def run!
      # fix lsapi bug that remove RAILS_ROOT value in ENV 
      fix_env
      
      # setup process name
      $0="RAILS: #{name} (#{environment})"
      
      # save memory
      GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=)
      
      # this is done by require lsapi but it shoulden't be
      Dir.chdir(root)
      
      # load rails app and start server
      Rack::Handler::LSWS.run *Rack::Builder.parse_file(config)  
    end
  end
  
  # this class change RewindableInput 
  module RewindableInput
    
    def self.included(base)
      base.class_eval do
        alias_method :initialize_without_string_io, :initialize
        alias_method :initialize, :initialize_with_string_io
      end
    end
    
    def initialize_with_string_io(io, &block)
      initialize_without_string_io(StringIO.new(io), &block)
    end
  end
   
end

# first get server instance becous lsapi removes rails_root env (this is BUG!)
server = Lsws::Server.new(ENV['RAILS_ROOT'], ENV['RAILS_ENV'], ENV['APP_NAME'])

# fix rewindableinput for litespeed webserver
require "rack/rewindable_input"
Rack::RewindableInput.send(:include, Lsws::RewindableInput)

# run server
server.run!
