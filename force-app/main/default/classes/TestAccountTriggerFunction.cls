@isTest
public class TestAccountTriggerFunction {
    
    @IsTest
    static void test_updateSegmentation(){
        
        Test.startTest();
        List<Account> accountList = TestDataFactory.createNewAccount(1);
        accountList[0].numberofemployees = 3500;
        insert accountList;
        Test.stopTest(); 
    }

    @IsTest
    static void test_queueForHeyJobsCategoryUpdate(){
        
        Test.startTest();
        List<Account> accountList = TestDataFactory.createNewAccount(1);
        accountList[0].Category_1__c = 'Service Provider';
        accountList[0].Category_2__c = 'Consultant & IT';
        accountList[0].Category_3__c = 'Headhunter';
        insert accountList;
        Test.stopTest(); 
    }
}