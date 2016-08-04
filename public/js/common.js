function loadPage(filename) {
  $("#main_body").hide().load(filename).fadeIn('slow');
}

function loadHeaderFooter() {
  $("#header_html").hide().load("header.html").fadeIn("slow");
  $("#footer_html").hide().load("footer.html").fadeIn("slow");
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

function sendAPIRequestGet(endpoint, tokentype) {
  var result = $.ajax({
      type: "GET",
      url: "/run/" + tokentype,
      beforeSend: function(xhr) {
        xhr.setRequestHeader("Endpoint", endpoint)
      },
      async: false
    }).responseText;

  return result;
}

function sendAPIRequestPost(endpoint, tokentype, body) {
  var result = $.ajax({
    type: "POST",
    url: "/run/" + tokentype,
    beforeSend: function(xhr) {
      xhr.setRequestHeader("Endpoint", endpoint)
    },
    data: body,
    async: false
  }).responseText;

  return result;
}

function syntaxHighlight(json) {
	if (typeof json != 'string') {
	  json = JSON.stringify(json, undefined, 2);
	}
	json = json.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
	return json.replace(/("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g, function (match) {
		var cls = 'number';
		if (/^"/.test(match)) {
			if (/:$/.test(match)) {
				cls = 'key';
			} else {
				cls = 'string';
			}
		} else if (/true|false/.test(match)) {
			cls = 'boolean';
		} else if (/null/.test(match)) {
			cls = 'null';
		}
		return '<span class="' + cls + '">' + match + '</span>';
	});
}
