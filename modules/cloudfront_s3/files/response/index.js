function handler(event) {
    var response = event.response;
    var headers = response.headers;
    
    // Set the cache-control header
     headers['cache-control'] = {value: 'public, max-age=63072000'};


    // If Access-Control-Allow-Origin CORS header is missing, add it.
    // Since JavaScript doesn't allow for hyphens in variable names, we use the dict["key"] notation.
    if (!response.headers['access-control-allow-origin'] && request.headers['origin']) {
        response.headers['access-control-allow-origin'] = {value: request.headers['origin'].value};
        console.log("Access-Control-Allow-Origin was missing, adding it now.");
    }

    // Set HTTP security headers
    // Since JavaScript doesn't allow for hyphens in variable names, we use the dict["key"] notation 
    headers['strict-transport-security'] = { value: 'max-age=63072000; includeSubdomains; preload'}; 
    headers['content-security-policy'] = { value: "default-src 'none'; img-src '*'; script-src '*'; style-src '*'; object-src 'none'"}; 
    headers['x-content-type-options'] = { value: 'nosniff'}; 
    headers['x-frame-options'] = {value: 'DENY'}; 
    headers['x-xss-protection'] = {value: '1; mode=block'}; 

    // Return response to viewers
    return response;
}
