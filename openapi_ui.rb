enable :sessions

def makeGetRequest(base_url, endpoint_url, client_token, client_secret, access_token)
	baseuri = URI(base_url)
	http = Akamai::Edgegrid::HTTP.new(address = baseuri.host, post = baseuri.port)
	http.setup_edgegrid(
		client_token: client_token,
		client_secret: client_secret,
		access_token: access_token
	)
  req = Net::HTTP::Get.new(URI.join(baseuri.to_s, endpoint_url).to_s)
	res = http.request(req)
  return res.body
end

def makePostRequest(base_url, endpoint_url, client_token, client_secret, access_token, request_body)
	baseuri = URI(base_url)
	http = Akamai::Edgegrid::HTTP.new(address = baseuri.host, post = baseuri.port)
	http.setup_edgegrid(
		client_token: client_token,
		client_secret: client_secret,
		access_token: access_token
	)
	req = Net::HTTP::Post.new(
		URI.join(baseuri.to_s, endpoint_url).to_s,
		initheader = { 'Content-Type' => 'application/json' }
	)
	req.body = request_body
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
    return apitokens.to_json.to_s
  else
    return { :result => "Parse Error" }.to_json.to_s
  end
end

get "/run/:tokentype" do
  endpoint = request.env["HTTP_ENDPOINT"].to_s
  if not endpoint.nil?
    api_token_type = params['tokentype']
    tokens = session[api_token_type]
    result = makePostRequest(tokens[:baseurl], endpoint, tokens[:clienttoken], tokens[:secret], tokens[:accesstoken])
    return result
  else
    return %Q[{"error" : "no end point URL provided"}]
  end
end

post "/run/:tokentype" do
  endpoint = request.env["HTTP_ENDPOINT"].to_s
  begin
    request_body = JSON.parse(request.body.read).to_s
  rescue ParserError => e
    return %Q[{"error" : "#{e.message}"}]
  end

  if not endpoint.nil?
    api_token_type = params['tokentype']
    tokens = session[api_token_type]
    result = makePostRequest(tokens[:baseurl], endpoint, tokens[:clienttoken], tokens[:secret], tokens[:accesstoken], request.body.read)
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

















