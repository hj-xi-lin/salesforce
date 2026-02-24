@isTest
public class Test_batchCategoryAndClientOnAccount {
    
    @isTest
    static void testBatchUpdate(){
        
        List<Account> accList = new List<Account>();
        List<Category3__c> cList = new List<Category3__c>();
        List<string> categoryList = new list<string>{'Auditors','Computer Games','Call Center','Lawyer','Engineering','Estates','IT Consulting','Job Promotion','Translation','Management Consultant','Headhunter','Research Centers','Software Manufacturer','Temporary Employment Agencies','Tester','Training'};
        
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
            acc.X2020_Reference_Clients__c = '';
            accList.add(acc); 
        }
        insert accList;
        
        for(integer i = 0; i < categoryList.size(); i++){
            Category3__c ct = new Category3__c();
            ct.Category__c = categoryList[i];
            ct.Reference_Clients__c = 'Sample client'+categoryList[i];
            cList.add(ct);
        }
        insert cList;
        
        Test.startTest();
        Database.executeBatch(new batchCategoryAndClientOnAccount());
        Test.stopTest();    
    }
}