function loadHeaderFooter() {
  $("#header_html").load("header.html");
  $("#footer_html").load("footer.html");
}

function loadTokenHtml() {
  $.get("tokens.html", function(data){
    var data = $(data); //oh gee
    var tokens = ["ccu_token", "luna_token"];
    for (var i in tokens) {
      token_response = getTokenFromServer(tokens[i]);
      if (token_response != "null") {
        jsonObj = JSON.parse(token_response);
        var api_client_type = jsonObj.apiclienttype;
        data.find("#"+api_client_type+"-base_url").html("<strong>Base URL : </strong>" + jsonObj.baseurl);
        data.find("#"+api_client_type+"-access_token").html("<strong>Access Token : </strong>" + jsonObj.accesstoken);
        data.find("#"+api_client_type+"-client_token").html("<strong>Client Token : </strong>" + jsonObj.clienttoken);
        data.find("#"+api_client_type+"-secret").html("<strong>Secret : </strong>" + jsonObj.secret);
      }
    }
    $("#token_html").html(data);
  });
}

function getTokenFromServer(api_client_type) {
  url = "/gettoken/" + api_client_type;
  var msg = $.ajax({type: "GET", url: url, async: false}).responseText;
  return msg;
}
