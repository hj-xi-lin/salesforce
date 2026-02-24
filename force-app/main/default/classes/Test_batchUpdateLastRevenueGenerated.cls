@isTest
public class Test_batchUpdateLastRevenueGenerated {
    
    @isTest
    static void testBatchUpdate(){
        List<Account> accList = new List<Account>();
        List<string> categoryList = new list<string>{'Auditors','Computer Games','Call Center'};
        
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
            acc.Last_Revenue_Generated__c = Date.today() - i;
            accList.add(acc); 
        }
        insert accList;
        
        Test.startTest();
        Database.executeBatch(new batchUpdateLastRevenueGenerated());
        Test.stopTest();
        
    }
}