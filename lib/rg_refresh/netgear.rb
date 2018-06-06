# frozen_string_literal: true
require 'http/cookie'
require 'net/http'
require 'uri'

module RgRefresh
  class Netgear
    LoginRequired = Class.new(StandardError)

    attr_reader \
      :base_uri, :http, :password, :jar,
      :ports_vlans,
      :hash, :state

    def initialize(opts)
      @base_uri = URI(opts.fetch(:address))
      @http = Net::HTTP.new(@base_uri.host, @base_uri.port)
      @password = opts.fetch(:password)
      @jar = HTTP::CookieJar.new

      @ports_vlans = opts.fetch(:ports_vlans).each_value do |arr|
        arr.map! do |vlan|
          if (vlan_name = vlan.to_s[/^\.(.+)/, 1])
            opts[:vlans].fetch(vlan_name.to_sym)
          else
            vlan
          end
        end
      end

      @hash = nil
      @state = []
    end

    def self.start(opts)
      new(opts).tap do |netgear|
        netgear.login
        netgear.sync
      end
    end

    def login
      res = post('/login.cgi', { :password=>password })

      fail 'Maximum sessions reached' \
        if res.body.include?('Maximum sessions reached')
    end

    def sync
      res = request('/8021qBasic.cgi')

      parse_inputs(res.body, /hash/, /port\d+/) do |name, value|
        if name == 'hash'
          @hash = value
        elsif name.sub!(/^port/, '')
          @state[name.to_i] = value.to_i
        end
      end
    end

    def transition_to(mode)
      arr = ports_vlans.fetch(mode)

      new_state = state
        .map
        .with_index {|vlan, port| arr[port] || vlan }

      form_data = new_state
        .map
        .with_index {|vlan, port| ["port#{port}".to_sym, vlan] }
        .to_h
        .merge!(:status=>'Enable', :hash=>hash)

      post('/8021qBasic.cgi', form_data)

      sync

      fail 'Unable to set VLANs' unless state == new_state
    end

    def finish
      begin
        request('/logout.cgi')
      rescue LoginRequired
      end

      begin
        http.finish
      rescue IOError
      end
    end

    private

    def request(path, verb=:Get)
      uri = base_uri.dup
      uri.path += path

      req = Net::HTTP.const_get(verb).new(uri)

      # HTTP::Cookie's quoting is broken on older Rubies, so we'll do it manually.
      #req['Cookie'] = HTTP::Cookie.cookie_value(jar.cookies(uri))
      if (sid_cookie = jar.cookies(uri).find {|cookie| cookie.name == 'SID' })
        req['Cookie'] = '%s=%s' % [sid_cookie.name, sid_cookie.value]
      end

      yield req if block_given?

      res = http.request(req)
      Array(res.get_fields('Set-Cookie')).each do |value|
        jar.parse(value, uri)
      end

      raise LoginRequired if res.body.include?('RedirectToLoginPage')

      res
    end

    def post(path, form_data)
      request(path, :Post) do |req|
        req.form_data = form_data
      end
    end

    def parse_inputs(data, *pats)
      name_re = /<input.+name=['"]?(#{Regexp.union(pats)})['"]?/
      value_re = /value=['"]?(\d+)['"]?/

      data.each_line do |line|
        if (name = line[name_re, 1]) && (value = line[value_re, 1])
          yield name, value
        end
      end
    end
  end
end
