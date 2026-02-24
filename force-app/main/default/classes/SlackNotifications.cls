/*
 *      @author Arun Kumar
 *      @date   21-Apr-2023
 *      @description   Class to process the logic for sending notification to slack 
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 *      
 * 
 */
public class SlackNotifications {
    
    /**
    @Methodname     : sendMessage
    @Param          : String httpMethod, String endpoint, String message
    @Return         : HttpResponse
    @Description    : To make a callout using HTTP protocol
    **/
    @InvocableMethod(label='Send Slack Message' description='Sends a message to a Slack channel')
    public static void sendMessage(List<SlackMessageRequest> slackMessageRequest) {
        
        //Getting endpoint
        String endpoint = getWebHookURL(slackMessageRequest.get(0).channelName);
		
        //Generate the message
        String jsonMessage = slackMessageRequest.get(0).message;
        
        //Sending message to slack channel
		HttpResponse response = HttpController.httpCallout('POST', endpoint, jsonMessage);
    }
    
    public static String getWebHookURL(String channelName){
        String webHookURL;
        
        if(channelName != NULL){
            try{
                Slack_Channel__mdt channel = Slack_Channel__mdt.getInstance(channelName);
        		webHookURL = (String)channel.get('Webhook__c');  
            }catch(Exception e){
                webHookURL = null;
            }
        }
        return webHookURL;
    }
    
      
    public class SlackMessageRequest {
        @InvocableVariable(required=true description='The name of the Slack channel')
        public String channelName;
        @InvocableVariable(required=true description='The message to send to the Slack channel')
        public String message;  
    }
}