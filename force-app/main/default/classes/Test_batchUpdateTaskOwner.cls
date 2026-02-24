@isTest
public class Test_batchUpdateTaskOwner {
    
    @isTest
    static void testBatchUpdate(){
        List<Account> accList = new List<Account>();
        List<Opportunity> oppList = new List<Opportunity>();
        List<Task> taskList = new List<Task>();
        List<string> categoryList = new list<string>{'Auditors','Computer Games','Call Center','Lawyer','Engineering','Tester','Training'};
        
         for(integer i = 0; i < categoryList.size(); i++) {
            Account acc = new Account();
            acc.Name = 'TestIT'+i;
            acc.Category_1__c = 'Service Provider';
            acc.Category_2__c = 'Consultant & IT';
            acc.Category_3__c = categoryList[i];
            acc.NumberOfEmployees = 15000;
            acc.Service_Country__c = 'DE';
            acc.Stage_ACM__c = 'Lost';
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
            oppList.add(opp);
        }
        insert oppList;
        
        for(integer i = 0; i < accList.size(); i++){
            Task tk = new Task();
            tk.Subject = 'Follow-Up Quote';
            tk.Status = 'Open';
            //tk.AccountId = accList[i];
            tk.Is_Owner_changed__c = true;
            taskList.add(tk);
        }
        insert taskList;
        
        Test.startTest();
        Database.executeBatch(new batchUpdateTaskOwner());
        Test.stopTest();
        
    }

}