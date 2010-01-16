#!/usr/bin/env ruby

##
# A very simple Camping application for experimenting
# with Javascript and Ajax.

require 'rubygems'
require_gem 'camping', '>= 1.5'
require 'camping'

Camping.goes :Server

module Server

  ##
  # Returns the contents of a file,
  # relative to the current file's directory.

  def render_file(filename)
    File.read("#{File.dirname(__FILE__)}/#{filename}")
  end

  ##
  # A short message when a resource should be accessed only
  # with a certain method.

  def http_method_error
    "This page is meant to be requested with POST, but you did a GET"
  end

  ##
  # Returns true if the current resource was requested
  # via Ajax.

  def ajax?
    env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'
  end

  ##
  # Make a string javascript-friendly.
  #
  # From Rails.

  def escape_js(javascript)
  (javascript || '').gsub('\\','\0\0').gsub(/\r\n|\n|\r/, "\\n").gsub(/["']/) { |m| "\\#{m}" }
  end

end

module Server::Controllers

  class Index < R "/"
    def get
      render_file 'index.html'
    end
  end

  class Tracker < R "/tracker"
    def get
      http_method_error
    end

    def post
      env.to_yaml
    end
  end


  class Article < R '/article'
    def get
      render_file "article_fragment.html"
    end

    def post
      sleep 2
      if (input.error)
        r 500, 'Server Error!'
      else
        get
      end
    end
  end

  class Edit < R '/edit'
    def get
      http_method_error
    end

    def post
      if ajax?
        @headers['Content-Type'] = "application/javascript; charset=utf-8"
        "$('preview_output').update('#{escape_js(stylize_text(input.story))}');"
      else
        stylize_text(input.story)
      end
    end

    ##
    # Make all instances of 'butter' strong.

    def stylize_text(text)
      text.gsub(/(butter)/i, '<strong>\1</strong>')
    end
  end

  class Signup < R '/signup'
    def get
      http_method_error
    end

    def post
      "Your postal code is: #{input.postal_code}"
    end
  end

  class UsernameCheck < R '/username_check'
    def post
      # Assumes post via ajax
      # TODO Don't return if blank
      @headers['Content-Type'] = "application/javascript; charset=utf-8"
      if input.username == 'buster'
        "$('username_check').update('Sorry, the name <strong>#{escape_js(input.username)}</strong> has already been taken. Please choose another.'); " +
        "$('username_check').show(); " +
        "$('username').addClassName('error');"
      else
        "$('username_check').update('<strong>#{escape_js(input.username)}</strong> is available!'); " +
        "$('username_check').show(); " +
        "$('username').removeClassName('error');"
      end
    end
  end

  class PostalCodeLookup < R '/postal_code_lookup'
    def post
      require 'json'
      # Assumes post via ajax
      @headers['Content-Type'] = "application/javascript; charset=utf-8"
      # Hard-coded. A live app would look this up in a database.
      {'locality' => 'San Francisco', 'region' => 'CA'}.to_json
    end
  end

  class HCardLookup < R '/hcard_lookup'
    def post
      require 'json'
      require 'mofo'
      # Assumes post via Ajax
      h = HCard.find(input.url)

      @headers['Content-Type'] = "application/javascript; charset=utf-8"
      {
        'adr' => {
          'region' => h.adr.region,
          'locality' => h.adr.locality,
          'country-name' => h.adr.country_name,
          'street-address' => h.adr.street_address,
          'postal-code' => h.adr.postal_code
        }
      }.to_json
      
    rescue Exception => e
      # TODO A better way to pass an error would be helpful.
      return r(500, "Server Error: #{e.message}")
    end
  end


  # -- The Basics --

  class Pages < R '/([^/]+\.html)'
    def get(filename)
      @headers["Content-Type"] = "text/html; charset=utf-8"
      render_file filename
    end
  end

  class Stylesheets < R '/(stylesheets/.*\.css)'
    def get(filename)
      @headers["Content-Type"] = "text/css; charset=utf-8"
      render_file filename
    end
  end

  class Javascripts < R '/(javascripts/.*\.js)'
    def get(filename)
      @headers["Content-Type"] = "application/javascript"
      render_file filename
    end
  end

  class Images < R '/(images/.*\.png)'
    def get(filename)
      @headers["Content-Type"] = "image/png"
      File.read(filename)
    end
  end

end
