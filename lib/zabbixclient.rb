require 'rubygems'
require 'json'
require 'net/http'
require 'logger'

class ZabbixClient

    @restclient_options = { :content_type => 'application/json' }

    @url
    @auth_hash
    @options
    @log

    def initialize ( options = {} )
        @options   = options

        @log = Logger.new(STDERR)
        if( @options[:debug] )
            @log.level = Logger::DEBUG
        else
            @log.level = Logger::WARN
        end

        @auth_hash = authenticate

    end

    def authenticate ( )

        response = request( 'user.authenticate',  
            :user     => @options[:user], 
            :password => @options[:password] 
        )

    end

    def request_json( method, *args )

        req = {
            :jsonrpc => '2.0',
            :method  => method,
            :params  => Hash[*args.flatten],
            :id      => rand( 100000 )
        }

        if @auth_hash
            req[:auth] = @auth_hash
        end

        JSON.generate( req )

    end

    def request( method, *args ) 

        json = request_json( method, *args )

        uri  = URI.parse( @options[:url] )
        http = Net::HTTP::new( uri.host, uri.port )

        request = Net::HTTP::Post.new( uri.request_uri )
        request.add_field( 'Content-Type', 'application/json-rpc' )
        request.body = json

        @log.debug( "HTTP Request: #{uri} #{json}" )

        response = http.request( request )

        unless response.code == "200"
            raise "HTTP Error: #{response.code}"
        end

        @log.debug( "HTTP Response: #{response.body}" )

        result = JSON.parse( response.body )

        if result['error']
            raise "JSON-RPC error: #{result['error']}"
        end

        result['result']

    end

end

