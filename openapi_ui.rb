get '/' do
  return "#{params[:hi]}"
end

get '/upload' do
	erb :upload
end


post "/upload" do

#  File.open('uploads/' + params['myfile'][:filename], "w") do |f|
#    f.write(params['myfile'][:tempfile].read)
#  end
  return params['myfile']
end

post '/insertToken' do
  #params['splat']
end
