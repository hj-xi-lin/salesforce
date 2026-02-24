@isTest
public with sharing class Chatter_GetMentionsTest {
    @isTest(SeeAllData=true)
    static void executeTest() {
        FeedItem f = new FeedItem();
        f.Body = 'legal test';
        f.parentID = UserInfo.getUserId();
        insert f;
        List<Chatter_GetMentions.Request> requests = new List<Chatter_GetMentions.Request>();
        Chatter_GetMentions.Request req = new Chatter_GetMentions.Request();
        req.feedItemId = f.Id;
        requests.add(req);
        Test.startTest();
        List<Chatter_GetMentions.Response> result = Chatter_GetMentions.execute(requests);
        Test.stopTest();
        System.assertEquals(true, result != null);
        System.assertEquals(1, result.size());
        System.assertEquals(true, result[0].userIdList != null);
        System.assertEquals(0, result[0].userIdList.size());
    }
}