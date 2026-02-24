global inherited sharing class Chatter_GetMentions {
    
    @InvocableMethod(label='Chatter Get Mentions' description='Extract @ Mentions from Chatter Post')
    global static List<Response> execute(List<Request> requests) {

        List<Response> responses = new List<Response>();

        for(Request curRequest: requests ){
           
            Response curResponse = new Response();

            String feedItemId = curRequest.feedItemId;
            List<String> userIdList = new List<String>();
            
            ConnectApi.FeedElement feedItem = ConnectApi.ChatterFeeds.getFeedElement(Null, feedItemId);
            List<ConnectApi.MessageSegment> messageSegments = feedItem.body.messageSegments;
            
            for (ConnectApi.MessageSegment messageSegment : messageSegments) {
                
                if (messageSegment instanceof ConnectApi.MentionSegment) {
                    ConnectApi.MentionSegment mentionSegment = (ConnectApi.MentionSegment) messageSegment;
                    //System.debug('Mentioned UserId: ' + mentionSegment.record.id);
                    
                    userIdList.add((String)mentionSegment.record.id);
                }
            }
            System.debug(userIdList);
            curResponse.userIdList = userIdList;

            responses.add(curResponse);
        }
        return responses;
    }   

    global class InvocableActionException extends Exception{}

    global class Request {
        @InvocableVariable (label='Feed Item Id') global String feedItemId;
        }
    
    global class Response {
        @invocableVariable
        global List<String> userIdList;
    }
}