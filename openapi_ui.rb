# enable :sessions
use Rack::Session::Pool #to save session data in server(not in cookie)

def getAccountInfo()
  tokens = session['luna_token']
  result = Hash.new

  #get contract ids and account id/name
  endpoint_acct = "/papi/v0/groups/"
  endpoint_cont = "/papi/v0/contracts/"
  result_acct = makeGetRequest(tokens[:baseurl], endpoint_acct, tokens[:clienttoken], tokens[:secret], tokens[:accesstoken])
  result_cont = makeGetRequest(tokens[:baseurl], endpoint_cont, tokens[:clienttoken], tokens[:secret], tokens[:accesstoken])

  begin
    jsonObj_acct = JSON.parse(result_acct)
    jsonObj_cont = JSON.parse(result_cont)

    account_id = jsonObj_acct["accountId"]
    account_name = jsonObj_acct["accountName"]
    contracts = jsonObj_cont["contracts"]

    result["account_id"] = account_id.nil? ? "Please allow access to PAPI" : account_id.split("_").last
    result["account_name"] = account_name.nil? ? "Please allow access to PAPI" : account_name

    if not contracts.nil?
      arr_contracts = Array.new
      contracts["items"].each do |each_contract|
        contract_id = each_contract["contractId"].split("_").last
        arr_contracts.push({"contractId" => contract_id})
      end
      result["contracts"] = arr_contracts
    else
      result["contracts"] = "Please allow access to PAPI"
    end
  rescue JSON::ParserError => e
    result["account_id"] = "Please allow access to PAPI"
    result["account_name"] = "Please allow access to PAPI"
    result["contracts"] = "Please allow access to PAPI"
  end

  #get contract name. only run when there was a contract
  if result["contracts"].class == Array
    endpoint_cont_name = "/billing-usage/v1/reportSources"
    result_cont_name = makeGetRequest(tokens[:baseurl], endpoint_cont_name, tokens[:clienttoken], tokens[:secret], tokens[:accesstoken])
    begin
      jsonObj_cont_name = JSON.parse(result_cont_name)
      if jsonObj_cont_name["status"] == "ok" and not jsonObj_cont_name["contents"].nil?
        contents = jsonObj_cont_name["contents"]
        contents.each do |each_content|
          result["contracts"].each do |each_contract|
            if each_contract["contractId"] == each_content["id"] then each_contract["contractName"] = each_content["name"] end
          end
        end
      else
        raise JSON::ParserError
      end
    rescue JSON::ParserError => e
      result["contracts"].each do |each_contract|
        each_contract["contractName"] = "Please allow access to Billing Center API v1"
      end
    end
  end
  return result
end

def makeGetRequest(base_url, endpoint_url, client_token, client_secret, access_token, headers = {})
	baseuri = URI(base_url)
	http = Akamai::Edgegrid::HTTP.new(address = baseuri.host, post = baseuri.port)
	http.setup_edgegrid(
		client_token: client_token,
		client_secret: client_secret,
		access_token: access_token
	)
  req = Net::HTTP::Get.new(URI.join(baseuri.to_s, endpoint_url).to_s, initheader = headers)
	res = http.request(req)
  return res.body
end

def makeHeadRequest(base_url, endpoint_url, client_token, client_secret, access_token, headers = {})
	baseuri = URI(base_url)
	http = Akamai::Edgegrid::HTTP.new(address = baseuri.host, post = baseuri.port)
	http.setup_edgegrid(
		client_token: client_token,
		client_secret: client_secret,
		access_token: access_token
	)
  req = Net::HTTP::Head.new(URI.join(baseuri.to_s, endpoint_url).to_s, initheader = headers)
	res = http.request(req)
  return res.body
end

def makePostRequest(base_url, endpoint_url, client_token, client_secret, access_token, request_body, headers = {})
	baseuri = URI(base_url)
  begin
    JSON.parse(request_body)
    headers["Content-Type"] = "application/json"
  rescue JSON::ParserError => e
    headers["Content-Type"] = "application/x-www-form-urlencoded;charset=UTF-8"
  end

	http = Akamai::Edgegrid::HTTP.new(address = baseuri.host, post = baseuri.port)
	http.setup_edgegrid(
		client_token: client_token,
		client_secret: client_secret,
		access_token: access_token
	)
	req = Net::HTTP::Post.new(URI.join(baseuri.to_s, endpoint_url).to_s, initheader = headers)
	req.body = request_body
	res = http.request(req)
  return res.body
end

def makePutRequest(base_url, endpoint_url, client_token, client_secret, access_token, request_body, headers = {})
	baseuri = URI(base_url)
  begin
    JSON.parse(request_body)
    headers["Content-Type"] = "application/json"
  rescue JSON::ParserError => e
    headers["Content-Type"] = "application/x-www-form-urlencoded;charset=UTF-8"
  end
	http = Akamai::Edgegrid::HTTP.new(address = baseuri.host, post = baseuri.port)
	http.setup_edgegrid(
		client_token: client_token,
		client_secret: client_secret,
		access_token: access_token
	)
	req = Net::HTTP::Put.new(URI.join(baseuri.to_s, endpoint_url).to_s, initheader = headers)
	req.body = request_body
	res = http.request(req)
  return res.body
end

def makeDeleteRequest(base_url, endpoint_url, client_token, client_secret, access_token, body = nil, headers = {})
	baseuri = URI(base_url)
	http = Akamai::Edgegrid::HTTP.new(address = baseuri.host, post = baseuri.port)
	http.setup_edgegrid(
		client_token: client_token,
		client_secret: client_secret,
		access_token: access_token
	)
  req = Net::HTTP::Delete.new(URI.join(baseuri.to_s, endpoint_url).to_s, initheader = headers)
  req.body = body if not body.nil?
	res = http.request(req)
  return res.body
end

get '/' do
  send_file './public/index.html'
end

get '/upload' do
	erb :upload
end

post "/upload" do
  api_client_type = params['apiclienttype']
  tmpfile = params['upload_file'][:tempfile].read
  tmpfile = tmpfile.gsub("\n", "|").squeeze("|").split("|")

  apitokens = Hash.new
  apitokens[:apiclienttype] = api_client_type

  tmpfile.each_with_index do |each, index|
    case each
    when /Base URL:/
      apitokens[:baseurl] = each.split("Base URL:").last.strip
    when /Access Tokens:/
      apitokens[:accesstoken] = tmpfile[index+1].strip
    when /Client token:/ && /Secret:/
      items = each.split
      items.each_with_index do |each_item, item_index|
        if each_item == "token:"
          apitokens[:clienttoken] = items[item_index+1]
        elsif each_item == "Secret:"
          apitokens[:secret] = items[item_index+1]
        end
      end
    end
  end

  if apitokens.length == 5
    session[api_client_type] = {
      :baseurl => apitokens[:baseurl],
      :accesstoken => apitokens[:accesstoken],
      :clienttoken => apitokens[:clienttoken],
      :secret => apitokens[:secret],
      :apiclienttype => apitokens[:apiclienttype]
    }
    #if it is luna_token get account informations
    if api_client_type == "luna_token"
      account_info = getAccountInfo
      session[api_client_type][:account_id] = account_info["account_id"]
      session[api_client_type][:account_name] = account_info["account_name"]
      session[api_client_type][:contracts] = account_info["contracts"]
    end

    apitokens[:result] = "success"
    return apitokens.to_json.to_s
  else
    return { :result => "Parse Error" }.to_json.to_s
  end
end


get "/run/:tokentype" do
  content_type 'text/html', :charset => 'utf-8'
  endpoint = request.env["HTTP_ENDPOINT"].to_s.delete(' ')
  req_headers = Hash.new
  req_headers["Luna-Token"] = request.env["HTTP_LUNA_TOKEN"].to_s.delete(' ') if not request.env["HTTP_LUNA_TOKEN"].nil?
  req_headers["Content-Type"] = request.env["CONTENT_TYPE"].to_s.delete(' ') if not request.env["CONTENT_TYPE"].nil?

  begin
    URI.parse(endpoint)
  rescue URI::InvalidURIError => e
    return %Q[{"error" : "#{e.message}"}]
  end

  if not endpoint.nil?
    api_token_type = params['tokentype']
    tokens = session[api_token_type]
    result = makeGetRequest(tokens[:baseurl], endpoint, tokens[:clienttoken], tokens[:secret], tokens[:accesstoken], req_headers)
    return result
  else
    return %Q[{"error" : "no end point URL provided"}]
  end
end

head "/run/:tokentype" do
  content_type 'text/html', :charset => 'utf-8'
  endpoint = request.env["HTTP_ENDPOINT"].to_s.delete(' ')
  req_headers = Hash.new
  req_headers["Luna-Token"] = request.env["HTTP_LUNA_TOKEN"].to_s.delete(' ') if not request.env["HTTP_LUNA_TOKEN"].nil?
  req_headers["Content-Type"] = request.env["CONTENT_TYPE"].to_s.delete(' ') if not request.env["CONTENT_TYPE"].nil?

  begin
    URI.parse(endpoint)
  rescue URI::InvalidURIError => e
    return %Q[{"error" : "#{e.message}"}]
  end

  if not endpoint.nil?
    api_token_type = params['tokentype']
    tokens = session[api_token_type]
    result = makeHeadRequest(tokens[:baseurl], endpoint, tokens[:clienttoken], tokens[:secret], tokens[:accesstoken], req_headers)
    return result
  else
    return %Q[{"error" : "no end point URL provided"}]
  end
end

post "/run/:tokentype" do
  content_type 'text/html', :charset => 'utf-8'
  request_body = request.body.read
  endpoint = request.env["HTTP_ENDPOINT"].to_s.delete(' ')
  req_headers = Hash.new
  req_headers["Luna-Token"] = request.env["HTTP_LUNA_TOKEN"].to_s.delete(' ') if not request.env["HTTP_LUNA_TOKEN"].nil?
  req_headers["Content-Type"] = request.env["CONTENT_TYPE"].to_s.delete(' ') if not request.env["CONTENT_TYPE"].nil?

  begin
    URI.parse(endpoint)
  rescue JSON::ParserError => e
    return %Q[{"error" : "#{e.message}"}]
  end

  if not endpoint.nil?
    api_token_type = params['tokentype']
    tokens = session[api_token_type]
    result = makePostRequest(tokens[:baseurl], endpoint, tokens[:clienttoken], tokens[:secret], tokens[:accesstoken], request_body, req_headers)
    return result
  else
    return %Q[{"error" : "no end point URL provided"}]
  end
end

put "/run/:tokentype" do
  content_type 'text/html', :charset => 'utf-8'
  request_body = request.body.read
  endpoint = request.env["HTTP_ENDPOINT"].to_s.delete(' ')
  req_headers = Hash.new
  req_headers["Luna-Token"] = request.env["HTTP_LUNA_TOKEN"].to_s.delete(' ') if not request.env["HTTP_LUNA_TOKEN"].nil?
  req_headers["Content-Type"] = request.env["CONTENT_TYPE"].to_s.delete(' ') if not request.env["CONTENT_TYPE"].nil?

  begin
    URI.parse(endpoint)
  rescue URI::InvalidURIError => e
    return %Q[{"error" : "#{e.message}"}]
  end

  if not endpoint.nil?
    api_token_type = params['tokentype']
    tokens = session[api_token_type]
    result = makePutRequest(tokens[:baseurl], endpoint, tokens[:clienttoken], tokens[:secret], tokens[:accesstoken], request_body, req_headers)
    return result
  else
    return %Q[{"error" : "no end point URL provided"}]
  end
end

delete "/run/:tokentype" do
  content_type 'text/html', :charset => 'utf-8'
  request_body = request.body.read
  endpoint = request.env["HTTP_ENDPOINT"].to_s.delete(' ')
  req_headers = Hash.new
  req_headers["Luna-Token"] = request.env["HTTP_LUNA_TOKEN"].to_s.delete(' ') if not request.env["HTTP_LUNA_TOKEN"].nil?
  req_headers["Content-Type"] = request.env["CONTENT_TYPE"].to_s.delete(' ') if not request.env["CONTENT_TYPE"].nil?

  begin
    URI.parse(endpoint)
  rescue URI::InvalidURIError => e
    return %Q[{"error" : "#{e.message}"}]
  end

  if not endpoint.nil?
    api_token_type = params['tokentype']
    tokens = session[api_token_type]
    result = makeDeleteRequest(tokens[:baseurl], endpoint, tokens[:clienttoken], tokens[:secret], tokens[:accesstoken], request_body, req_headers)
    return result
  else
    return %Q[{"error" : "no end point URL provided"}]
  end
end

get "/gettoken/:tokentype" do
  api_token_type = params['tokentype']
  tokens = session[api_token_type]
  return tokens.to_json.to_s
end

get "/gettokens" do
  tokens = ["ccu_token", "luna_token", "dns_token", "img_token", "csi_token"]
  hshToken = Hash.new
  tokens.each do |each_token|
    if not session[each_token].nil?
      hshToken[each_token] = session[each_token].to_json.to_s
    end
  end
  return hshToken.to_json.to_s
end

get "/getaccountinfo" do
  session_hash = session["luna_token"]
  if session_hash.nil?
    return %Q[{"error" : "Please upload LUNA token"}]
  else
    temp = Hash.new
    temp[:accountId] = session_hash[:account_id]
    temp[:accountName] = session_hash[:account_name]
    temp[:contracts] = session_hash[:contracts]
    return temp.to_json.to_s
  end
end

post "/saveresponse" do
  response_value = params['response']
  session["response_value"] = response_value
  res = { :result => "success" }
  return  res.to_json.to_s
end

get "/loadresponse" do
  content_type 'text/html', :charset => 'utf-8'
  saved_response = session["response_value"]
  return saved_response
end















