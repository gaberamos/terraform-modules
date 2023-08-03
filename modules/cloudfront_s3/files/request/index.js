function handler(event) {
    var request = event.request;
    var headers = request.headers;
    var host = request.headers.host.value;
    var clientIP = event.viewer.ip;
   
   // If origin header is missing, set it equal to the host header.
   if (!headers.origin)
       headers.origin = {value:`https://${host}`};

    //Add the true-client-ip header to the incoming request
    request.headers['true-client-ip'] = {value: clientIP};

   return request;
}