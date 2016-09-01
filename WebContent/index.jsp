<html>
  <head>
    <script type="text/javascript">
      // Your Client ID can be retrieved from your project in the Google
      // Developer Console, https://console.developers.google.com
      var CLIENT_ID = '976681386035-6hb2kfe045am480sqfg32hmk3c4jcc96.apps.googleusercontent.com';
      
      var fileId = "";

      var SCOPES = ['https://www.googleapis.com/auth/drive.metadata.readonly', 'https://www.googleapis.com/auth/drive.file'];

      /**
       * Check if current user has authorized this application.
       */
      function checkAuth() {
        gapi.auth.authorize(
          {
            'client_id': '976681386035-6hb2kfe045am480sqfg32hmk3c4jcc96.apps.googleusercontent.com',
            'scope': SCOPES.join(' '),
            'immediate': true
          }, handleAuthResult);
      }


/**
 * Insert new file.
 *
 * @param {File} fileData File object to read data from.
 * @param {Function} callback Function to call when the request is complete.
 */
function insertFile(fileData, callback) {

  const boundary = '-------314159265358979323846';
  const delimiter = "\r\n--" + boundary + "\r\n";
  const close_delim = "\r\n--" + boundary + "--";

    var contentType = 'application/octet-stream';
    var metadata = {
      'title': 'document.enc',
      'mimeType': 'application/octet-stream'
    };

    var base64Data = btoa(fileData);
    var multipartRequestBody =
        delimiter +
        'Content-Type: application/json\r\n\r\n' +
        JSON.stringify(metadata) +
        delimiter +
        'Content-Type: ' + contentType + '\r\n' +
        'Content-Transfer-Encoding: base64\r\n' +
        '\r\n' +
        base64Data +
        close_delim;

	var path = '/upload/drive/v3/files';
	var method = 'POST';
	if (window.fileId && window.fileId.length > 0) {
		path = path + "/" + window.fileId;
		method = 'PATCH';
	}

    var request = gapi.client.request({
        'path': path,
        'method': method,
        'params': {'uploadType': 'multipart'},
        'headers': {
          'Content-Type': 'multipart/mixed; boundary="' + boundary + '"'
        },
        'body': multipartRequestBody});
    if (!callback) {
      callback = function(file) {
        console.log(file)
      };
    }
    request.execute(callback);
  
}


      /**
       * Handle response from authorization server.
       *
       * @param {Object} authResult Authorization result.
       */
      function handleAuthResult(authResult) {
        var authorizeDiv = document.getElementById('authorize-div');
        if (authResult && !authResult.error) {
          // Hide auth UI, then load client library.
          authorizeDiv.style.display = 'none';
          loadDriveApi();
        } else {
          // Show auth UI, allowing the user to initiate authorization by
          // clicking authorize button.
          authorizeDiv.style.display = 'inline';
        }
      }

      /**
       * Initiate auth flow in response to user clicking authorize button.
       *
       * @param {Event} event Button click event.
       */
      function handleAuthClick(event) {
        gapi.auth.authorize(
          {client_id: CLIENT_ID, scope: SCOPES, immediate: false},
          handleAuthResult);
        return false;
      }

      /**
       * Load Drive API client library.
       */
      function loadDriveApi() {
        gapi.client.load('drive', 'v3', listFiles);
        
      }

	  function initDocument() {
	  	//var pre = document.getElementById('output');
        //var textContent = document.createTextNode("Google docs initialized." + '\n');
        //pre.appendChild(textContent);
        
        insertFile(document.getElementById("padText").value, 
        	function() {
        		console.log("Upload Complete.");
        	});
	  }

	  function downloadFile(fileId) {
	  
	          var request = gapi.client.drive.files.get({
            'fileId': fileId,
            'alt':'media'
          }).then (function(jsonResp) {
 				console.log(jsonResp.body);
 				document.getElementById("padText").value = jsonResp.body;
 				window.fileId = fileId;
          }, function(errorResp) { 
          		console.log("Problem fetching file: " + errorResp)}
          );
          	  
	  }

      /**
       * Print files.
       */
      function listFiles() {
      
   
       
        var request = gapi.client.drive.files.list({
            'pageSize': 10,
            'fields': "nextPageToken, files(id, name)",
            'q': "name='document.enc'",
            "fields": "files(id,webContentLink,name)"
          }).then(function(resp) {
            var files = resp.result.files;
            if (files && files.length == 1) {
            	downloadFile(files[0].id);
            } else {
              appendPre('No (or multiple) files found.)');
            }
          });

          
      }

      /**
       * Append a pre element to the body containing the given message
       * as its text node.
       *
       * @param {string} message Text to be placed in pre element.
       */
      function appendPre(message) {
        var pre = document.getElementById('output');
        var textContent = document.createTextNode(message + '\n');
        pre.appendChild(textContent);
      }


 function arrayBufferToHexString(arrayBuffer) {
        var byteArray = new Uint8Array(arrayBuffer);
        var hexString = "";
        var nextHexByte;

        for (var i=0; i<byteArray.byteLength; i++) {
            nextHexByte = byteArray[i].toString(16);
            if (nextHexByte.length < 2) {
                nextHexByte = "0" + nextHexByte;
            }
            hexString += nextHexByte;
        }
        return hexString;
    }
    
    function stringToArrayBuffer(string) {
        var encoder = new TextEncoder("utf-8");
        return encoder.encode(string);
    }

    function deriveAKey() {
        var saltString = "SecurePadSaltAndPeppa";
        var iterations = 1000;
        var hash = "SHA-256";

        var passwordString = document.getElementById("password").value;
    
    
           // First, create a PBKDF2 "key" containing the password
        window.crypto.subtle.importKey(
            "raw",
            stringToArrayBuffer(passwordString),
            {"name": "PBKDF2"},
            false,
            ["deriveKey"]).
        // Derive a key from the password
        then(function(baseKey){
            return window.crypto.subtle.deriveKey(
                {
                    "name": "PBKDF2",
                    "salt": stringToArrayBuffer(saltString),
                    "iterations": iterations,
                    "hash": hash
                },
                baseKey,
                {"name": "AES-CBC", "length": 128}, // Key we want
                true,                               // Extrable
                ["encrypt", "decrypt"]              // For new key
                );
        }).
        // Export it so we can display it
        then(function(aesKey) {
            return window.crypto.subtle.exportKey("raw", aesKey);
        }).
        // Display it in hex format
        then(function(keyBytes) {
            var hexKey = arrayBufferToHexString(keyBytes);
            document.getElementById("generatedKey").innerText = hexKey;
        }).
        catch(function(err) {
            alert("Key derivation failed: " + err.message);
            });
            
            
            
    
    }
    
    
document.addEventListener("DOMContentLoaded", function() {
    "use strict";

    // Check that web crypto is even available
    if (!window.crypto || !window.crypto.subtle) {
        alert("Your browser does not support the Web Cryptography API! This page will not work.");
        return;
    }

    document.getElementById("btnGenerateKey").addEventListener("click", deriveAKey);

    // Rest of code goes here.

});


    </script>

    <script src="promiz.min.js"></script>
    <script src="webcrypto-shim.js"></script>
    <script src="https://apis.google.com/js/client.js?onload=checkAuth">
    </script>
  </head>
  <body>
    <div id="authorize-div" style="display: none">
      <span>Authorize access to Drive API</span>
      <!--Button for the user to click to initiate auth sequence -->
      <button id="authorize-button" onclick="handleAuthClick(event)">
        Authorize
      </button>
    </div>
    <pre id="output"></pre>
    
      <button id="save" onclick="initDocument();">
        Save
      </button><br />
      Password: <input type="text" id="password" /><span id="generatedKey">None.</span><input type="button" id="btnGenerateKey"  value="Generate Key" /> <br />
	<textarea rows="25" cols="80" id="padText"></textarea>

  </body>
</html>