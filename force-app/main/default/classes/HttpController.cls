/*
 *      @author Arun Kumar
 *      @date   21-Apr-2023
 *      @description   Class to handle callouts to external systems
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 *      
 * 
 */
public with sharing class HttpController {

    /**
    @Methodname     : httpCallout
    @Param          : String httpMethod, String endpoint, String message
    @Return         : HttpResponse
    @Description    : To make a callout using HTTP protocol
    **/
    public static HttpResponse httpCallout(String httpMethod, String endpoint, String message) {
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(httpMethod);
        req.setBody(message);
        
        // Create a new HTTP object to send the request object
        Http http = new Http();
        HttpResponse res = http.send(req);
        return res;
    }
}