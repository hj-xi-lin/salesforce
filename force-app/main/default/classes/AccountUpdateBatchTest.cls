@isTest
public class AccountUpdateBatchTest {
    static testMethod void testmethod1(){
        Account acc = new Account();
        acc.Name = 'Test Acc';
        acc.Umbrella_Company__c = true;
        acc.NumberOfEmployees = 2500;
        insert acc;
        Test.startTest();
        AccountUpdateBatch ba= new AccountUpdateBatch();
        Id jobid= Database.executeBatch(ba,5);
        Test.stopTest();
    }
}