@isTest
public class CloseQuoteTest {
    Static Account acc = new Account(
        name = 'test',
        NumberOfEmployees = 2500,
        Service_Country__c = 'DE',
        Contact_Email__c ='test@test.com',
        Contact_First_Name__c ='testF',
        Contact_Last_Name__c = 'testL',
        txtContactsSalutation__c = 'Herr',
        Competitor_1_current_future__c = 'None'
        
    );
    
    Static Opportunity  opp = new Opportunity (
        name = 'test',
        CloseDate = Date.today(),
        StageName= 'Offer',
        plLossReason__c = 'Admin Only: Clean-Up Sales Funnel'
    );
    
   
    Static Contact con = new Contact(
       LastName ='test',
       Email = 'test@test.com'
    );
    
  
    Static Quote q = new Quote (
        name= 'test'
    );
    
    static testMethod void testCloseQuote() {
        insert acc;
        insert con;
        
        opp.AccountId = acc.Id;
        insert opp;
        
        q.OpportunityId = opp.Id;
        insert q;
        q.Status ='Sent';
        update q;
        
        Onboarding__c onb = new Onboarding__c();
        onb.Account__c = q.AccountId;
        onb.Opportunity__c = q.OpportunityId;
        onb.Contact__c = con.Id;
        onb.txtComments__c = 'test';
        insert onb;
        
        opp.Onboarding__c = onb.Id;
        update opp;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(q);
        CloseQuote testCTRL = new CloseQuote(sc);
        testCTRL.getAttachments();
        testCTRL.AddAttachs();
        testCTRL.save();
        
        closeQuoteRejected testCTRLRejected = new closeQuoteRejected(sc);
        testCTRLRejected.save();
        testCTRLRejected.saveComplete();
    }
    
    static testMethod void testCloseQuoteWithoutOnboarding() {
        insert acc;
        insert con;
        
        opp.AccountId = acc.Id;
        insert opp;
        
        q.OpportunityId = opp.Id;
        insert q;
        q.Status ='Sent';
        update q;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(q);
        CloseQuote testCTRL = new CloseQuote(sc);
        testCTRL.fileList = null;
        testCTRL.getAttachments();
        testCTRL.AddAttachs();
        testCTRL.save();
    }
    
    static testMethod void testCloseQuoteWithAttachment() {
        insert acc;
        insert con;
        
        opp.AccountId = acc.Id;
        insert opp;
        
        q.OpportunityId = opp.Id;
        insert q;
        q.Status ='Sent';
        update q;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(q);
        CloseQuote testCTRL = new CloseQuote(sc);
        
        Attachment att = new Attachment();
        att.Name = 'Test Attachment';
        att.Body = Blob.valueOf('Test Body');
        testCTRL.fileList = new List<Attachment>{att};
        
        testCTRL.uploadAttachment();
        testCTRL.save();
    }
}