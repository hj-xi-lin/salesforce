@isTest
public class Test_batchRevertCampaignExclusion {
    
    @isTest
    static void testBatchUpdate(){
        List<Account> accList = new List<Account>();
        List<Opportunity> oppList = new List<Opportunity>();
        List<Contact> conList = new List<Contact>();
        List<string> categoryList = new list<string>{'Auditors','Computer Games','Call Center','Lawyer','Engineering','Estates','IT Consulting','Job Promotion','Translation','Management Consultant','Headhunter','Research Centers','Software Manufacturer','Temporary Employment Agencies','Tester','Training'};
        
         for(integer i = 0; i < categoryList.size(); i++) {
            Account acc = new Account();
            acc.Name = 'TestIT'+i;
            acc.Category_1__c = 'Service Provider';
            acc.Category_2__c = 'Consultant & IT';
            acc.Category_3__c = categoryList[i];
            acc.NumberOfEmployees = 15000;
            acc.Service_Country__c = 'DE';
            acc.Stage_ACM__c = 'Prospect';
            acc.Test_Account__c = true;
            accList.add(acc); 
        }
        insert accList;
        
        for(integer i = 0; i < accList.size(); i++){
            Contact con = new Contact();
            con.FirstName = 'Test';
            con.LastName = 'Arrivo'+String.valueOf(i);
            con.Email = con.LastName+'@sampleusers.de';
            con.Exclude_from_Outreach__c = true;
            con.Timestamp_Exclude_from_Outreach__c = System.Today()-45;
            conList.add(con);
        }
        insert conList;
        
        Test.startTest();
        Database.executeBatch(new batchRevertCampaignExclusion());
        Test.stopTest();
        
    }

}