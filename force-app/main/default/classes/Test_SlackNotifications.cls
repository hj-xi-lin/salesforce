@isTest
public class Test_SlackNotifications {
    
    @isTest
    static void testHttpCallout() {
        // Create a mock response for the HTTP callout
        HttpMock mock = new HttpMock();
        mock.setMock('{"response": "test"}', 200);
        
        // Set the mock response to the mock HTTP callout
        Test.setMock(HttpCalloutMock.class, mock);
        
        // Call the httpCallout method and verify the response
        //String response = String.valueof(HttpController.httpCallout('GET', 'https://example.com/api/test', 'test message'));
        
        List<SlackNotifications.SlackMessageRequest> inputList = new  List<SlackNotifications.SlackMessageRequest>();
        SlackNotifications.SlackMessageRequest input = new SlackNotifications.SlackMessageRequest();
        input.ChannelName = System.Label.HEYPAKET;
        input.message = 'Test Message';
        inputList.add(input);
        SlackNotifications.sendMessage(inputList);
        //System.assertEquals('{"response": "test"}', response);
    }
    
    // Inner class to mock the HTTP callout response
    private class HttpMock implements HttpCalloutMock {
        private String responseBody;
        private Integer responseStatus;
        
        public void setMock(String responseBody, Integer responseStatus) {
            this.responseBody = responseBody;
            this.responseStatus = responseStatus;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setBody(responseBody);
            res.setStatus(String.valueOf(responseStatus));
            return res;
        }
    }

}