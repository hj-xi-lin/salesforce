@isTest
public class Test_batchHeyPaketActivation {
    
    @isTest
    static void testBatchUpdate(){
        List<Account> accList = new List<Account>();
        List<Opportunity> oppList = new List<Opportunity>();
        List<string> categoryList = new list<string>{'Auditors','Computer Games','Call Center','Lawyer','Engineering','Estates','IT Consulting','Job Promotion','Translation','Management Consultant','Headhunter','Research Centers','Software Manufacturer','Temporary Employment Agencies','Tester','Training'};
        
         for(integer i = 0; i < categoryList.size(); i++) {
            Account acc = new Account();
            acc.Name = 'TestIT'+i;
            acc.Category_1__c = 'Service Provider';
            acc.Category_2__c = 'Consultant & IT';
            acc.Category_3__c = categoryList[i];
            acc.NumberOfEmployees = 15000;
            acc.Service_Country__c = 'DE';
            acc.Stage_ACM__c = 'Outbound';
            acc.Test_Account__c = true;
            accList.add(acc); 
        }
        insert accList;
        
        for(integer i = 0; i < accList.size(); i++){
            Opportunity opp = new Opportunity();
            opp.Name = 'test';
            opp.RecordTypeId = '0121v000000z2JFAAY';
            opp.AccountId = accList[i].Id;
            opp.CloseDate = Date.today() + 180;
            opp.StageName = 'Closed Lost';
            opp.plLossReason__c = 'Currently not hiring';
            opp.Loss_Reason_Detail__c = 'Test';
            opp.Timestamp_Reactivation__c = Date.today();
            opp.HeyPaket_Start_Date__c = Date.today();
            opp.HeyPaket_Type__c = 'Essential';
            oppList.add(opp);
        }
        insert oppList;
        
        Test.startTest();
        Database.executeBatch(new batchHeyPaketActivation());
        Test.stopTest();
        
    }

}