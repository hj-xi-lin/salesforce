@isTest
public class CampaignMemberTriggerHandlerTest {
    @isTest
    public static void dotest(){
        Account objAcc = new Account(Name='Test Account');
        Insert objAcc;
        Contact testContact = new Contact(AccountId = objAcc.Id, FirstName = 'TestContactF', LastName = 'TestContactL', Email = 'none@none.net');
        insert testContact;
        Contact testContact2 = new Contact(AccountId = objAcc.Id, FirstName = 'TestContactF2', LastName = 'TestContactL2', Email = 'none2@none.net');
        insert testContact2;
        Campaign objCampaign = new Campaign(Type='Email', Name='Test Campaign',Target_Group__c = 'HR' ,  Lead_Score_Group__c= 'AA');
        Insert objCampaign;
        //Creates a new campaign memeber, associaites it with 1 provider sales campaign, and inserts
        CampaignMember newMember = 
        new CampaignMember(CampaignId = objCampaign.Id,Status='Sent', ContactId = testContact.Id);
        insert newMember;
        Test.startTest();
        CampaignMember newMember2 = 
        new CampaignMember(CampaignId = objCampaign.Id,Status='Sent', ContactId = testContact2.Id);
        insert newMember2;
        Test.stopTest();
    }
}