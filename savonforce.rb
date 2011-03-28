require "rubygems"
require "savon"

module Savon
  class WSDL
    def soap_endpoint= (new_endpoint)
      @soap_endpoint = new_endpoint
    end
  end
end

module SavonForce
  class Binding
    def initialize(wsdl)
      @wsdl = wsdl
      @client = Savon::Client.new(wsdl)
    end
    
    def login(username, password_and_token)
      response = @client.login do |soap|
        soap.body = {:username => username, :password => password_and_token}
      end
      result = response.to_hash[:login_response][:result]
      returned_endpoint = result[:server_url]
      @session_id = result[:session_id]
      @client.wsdl.soap_endpoint = returned_endpoint
    end
    
    def method_missing(method, *args)
      unless args.size == 1 && [Hash, Array].include?(args[0].class)
        raise 'Expected 1 Hash or Array argument'
      end
      call_soap_api(method, args[0])
    end
    
    def call_soap_api(method, args)
      response = @client.send(method) do |soap|
        soap.header = { 'wsdl:SessionHeader' => {
          'wsdl:sessionId' => @session_id }}
        soap.body = args
      end
      response = response.to_hash
      result = response["#{method}_response".to_sym][:result]
      return result
    end
  end
end
