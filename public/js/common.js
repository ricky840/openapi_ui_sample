function getFormattedDate(date) {
  var year = date.getFullYear();
  var month = (1 + date.getMonth()).toString();
  month = month.length > 1 ? month : '0' + month;
  var day = date.getDate().toString();
  day = day.length > 1 ? day : '0' + day;
  return month + '/' + day + '/' + year;
}

//for notification hide rather than dismiss
$(function() {
	$("[data-hide]").on("click", function(){
		$(this).closest("." + $(this).attr("data-hide")).hide();
	});
});

function showNotification(msg) {
  $("#notification .notification_content").html(msg);
  $("#notification").show();
}

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
    token_response = getAllTokenFromServer();
    jsonObj_response = JSON.parse(token_response);
    if (jsonObj_response.length != 0) {
      var keys = Object.keys(jsonObj_response);
      for (var i in keys) {
        var key_name = keys[i];
        var jsonObj_tokenData = JSON.parse(jsonObj_response[key_name]);
        var api_client_type = jsonObj_tokenData.apiclienttype;
        data.find("#"+api_client_type+"-label").addClass("label-success");
        data.find("#"+api_client_type+"-base_url").html("<strong>Base URL: </strong>" + jsonObj_tokenData.baseurl);
        data.find("#"+api_client_type+"-access_token").html("<strong>Access Token: </strong>" + jsonObj_tokenData.accesstoken);
        data.find("#"+api_client_type+"-client_token").html("<strong>Client Token: </strong>" + jsonObj_tokenData.clienttoken);
        data.find("#"+api_client_type+"-secret").html("<strong>Secret: </strong>" + jsonObj_tokenData.secret);

        /* if luna_token uploaded update and show account info as well */
        if (key_name == 'luna_token') {
          var account_info = getAccountInfoFromServer();
          account_info = JSON.parse(account_info);
          data.find("#account_name").html(account_info.accountName);
          data.find("#account_id").html(account_info.accountId);
          contracts = account_info.contracts;
          if (contracts.constructor === Array) {
            data.find("#account_info-label").addClass("label-success");
            for (var i in contracts) {
              var contractId = contracts[i].contractId;
              var contractName = contracts[i].contractName;
              htmltags = "<span>"+contractId+":"+" "+contractName+"</span><br>";
              data.find("#contracts").append(htmltags);
            }
          } else {
            data.find("#contracts").html(account_info.contracts);
          }
          data.find("#account_info").show(); //only show when luna_token is uploaded.
        }
      }
    }
    //show tokens
    $("#token_html").html(data).hide().fadeIn("slow");
  });
}

function getAccountInfoFromServer() {
  var url = "/getaccountinfo";
  var msg = $.ajax({type: "GET", url: url, async: false}).responseText;
  return msg;
}

function getTokenFromServer(api_client_type) {
  url = "/gettoken/" + api_client_type;
  var msg = $.ajax({type: "GET", url: url, async: false}).responseText;
  return msg;
}

function getAllTokenFromServer() {
  url = "/gettokens";
  var msg = $.ajax({type: "GET", url: url, async: false}).responseText;
  return msg;
}

function seeIfTokenUploaded(tokentype) {
  var msg = getTokenFromServer(tokentype);
  if (msg != "null") {
    return true;
  } else {
    return false;
  }
}

function sendAPIRequestGet(endpoint, tokentype) {
  if (seeIfTokenUploaded(tokentype)) {
    var result = $.ajax({
        type: "GET",
        url: "/run/" + tokentype,
        beforeSend: function(xhr) {
          xhr.setRequestHeader("Endpoint", endpoint);
					showLoadingSpinner();
        },
				success: function(responseTxt, status, jxhr) {
          if (responseTxt) {
            showResponse(endpoint, responseTxt);
          } else {
		        temp_response = '{"status":"'+status+'","msg":"Empty response body from the server."}'
            showResponse(endpoint, temp_response);
          }
				}
      }).responseText;

    return result;
  } else {
    showNotification(tokentype + " is not uploaded. Please upload and try again.");
    return '{ "status": "token does not exist" }';
  }
}

function sendAPIRequestDelete(endpoint, tokentype) {
  if (seeIfTokenUploaded(tokentype)) {
    var result = $.ajax({
        type: "DELETE",
        url: "/run/" + tokentype,
        beforeSend: function(xhr) {
          xhr.setRequestHeader("Endpoint", endpoint);
					showLoadingSpinner();
        },
				success: function(responseTxt, status, jxhr) {
          if (responseTxt) {
            showResponse(endpoint, responseTxt);
          } else {
		        temp_response = '{"status":"'+status+'","msg":"Empty response body from the server."}'
            showResponse(endpoint, temp_response);
          }
				}
      }).responseText;

    return result;
  } else {
    showNotification(tokentype + " is not uploaded. Please upload and try again.");
    return '{ "status": "token does not exist" }';
  }
}

function sendAPIRequestPost(endpoint, tokentype, body) {
  if (seeIfTokenUploaded(tokentype)) {

		if (IsJsonString(body)) {
			var apiurl = "/run/";
		} else {
      var apiurl = "/runrb/";
    }

    var result = $.ajax({
      type: "POST",
      url: apiurl + tokentype,
      beforeSend: function(xhr) {
        xhr.setRequestHeader("Endpoint", endpoint)
        showLoadingSpinner();
      },
      data: body,
      success: function(responseTxt, status, jxhr) {
        if (responseTxt) {
          showResponse(endpoint, responseTxt);
        } else {
          temp_response = '{"status":"'+status+'","msg":"Empty response body from the server."}'
          showResponse(endpoint, temp_response);
        }
      }
    }).responseText;

    return result;
  } else {
    showNotification(tokentype + " is not uploaded. Please upload and try again.");
    return '{ "status": "token does not exist" }';
  }
}

function sendAPIRequestPut(endpoint, tokentype, body) {
  if (seeIfTokenUploaded(tokentype)) {
    var result = $.ajax({
      type: "PUT",
      url: "/run/" + tokentype,
      beforeSend: function(xhr) {
        xhr.setRequestHeader("Endpoint", endpoint)
        showLoadingSpinner();
      },
      data: body,
      success: function(responseTxt, status, jxhr) {
        if (responseTxt) {
          showResponse(endpoint, responseTxt);
        } else {
          temp_response = '{"status":"'+status+'","msg":"Empty response body from the server."}'
          showResponse(endpoint, temp_response);
        }
      }
    }).responseText;

    return result;
  } else {
    showNotification(tokentype + " is not uploaded. Please upload and try again.");
    return '{ "status": "token does not exist" }';
  }
}

function IsJsonString(str) {
	try {
		JSON.parse(str);
	} catch (e) {
		return false;
	}
	return true;
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

function validateJsonTextarea(textarea_wrapper_id, textarea_id) {
  var jsontxt = $("#"+textarea_id).val();
  var wrapper_box = $("#"+textarea_wrapper_id);
  if (IsJsonString(jsontxt)) {
    wrapper_box.removeClass("has-error");
    wrapper_box.children("span").remove();
    wrapper_box.append('<span class="glyphicon glyphicon-ok form-control-feedback"></span>');
    if (!wrapper_box.hasClass("has-success")) {wrapper_box.addClass("has-success");}
  } else {
    wrapper_box.removeClass("has-error");
    wrapper_box.children("span").remove();
    wrapper_box.append('<span class="glyphicon glyphicon-remove form-control-feedback"></span>');
    if (!wrapper_box.hasClass("has-error")) {wrapper_box.addClass("has-error");}
  }
}

//for each API fucntions. when side menu clicks hide/show
function showAPIActionContent(obj_Id) {
  $(".each_api_action").hide();
  $("#"+obj_Id).show();
}

//show api call response
function showResponse(request, return_response) {
  if (IsJsonString(request)) {
    var requestContent = syntaxHighlight(JSON.parse(request));
  } else {
    var requestContent = request;
  }
  if (IsJsonString(return_response)) {
    var returnContent = syntaxHighlight(JSON.parse(return_response));
  } else {
    var returnContent = return_response;
  }
  html = "<label class='actioncontentlabel'>Request</label><pre>"+requestContent+"</pre>";
	html = html + "<label class='actioncontentlabel'>Response</label><pre>"+returnContent+"</pre>";
  $("#api_response").html(html);
  $("#loading_spinner").hide();
  $("#api_response_wrapper").hide();
  $("#api_response_wrapper").fadeIn("slow").focus();
}

function showLoadingSpinner() {
  $("#api_response").empty();
  $("#loading_spinner").show();
	$("#api_response_wrapper").show();
}
