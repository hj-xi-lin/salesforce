@isTest
public class Test_CreateAutomatedTasks 
{
    @isTest static void test1() 
    {
        List<Account> accList = new List<Account>();
        for(Integer i = 0; i < 50; i++) {
            Account acc = new Account();
            acc.Name = 'Test Account '+i;
            acc.Stage_acm__c = 'Expansion';
            acc.NumberOfEmployees = 2;
            acc.Service_Country__c = 'DE';
            accList.add(acc);
        }
        Account acc2 = new Account();
        acc2.Name = 'Test Account';
        acc2.Stage_acm__c = 'Expansion';
        acc2.NumberOfEmployees = 2;
        acc2.Service_Country__c = 'DE';
        accList.add(acc2);
        
        Account acc3 = new Account();
        acc3.Name = 'Test Account';
        acc3.Stage_acm__c = 'Retention';
        acc3.NumberOfEmployees = 2;
        acc3.Service_Country__c = 'DE';
        accList.add(acc3);        
        
        insert accList;
        
        Test.startTest();
        //Integer quarter = math.round((Date.today().month()+1)/3.0);
        //String query = 'SELECT id, ownerId, Potential__c FROM Account where Segment__c = \'SMB\' AND (Potential__c = \'Question Marks\' OR Potential__c = \'Cash Cow\' OR Potential__c = \'Stars\') AND (Stage_acm__c = \'Expansion\' OR Stage_acm__c = \'Retention\')';
        
        Integer quarter = 4;
        String query = 'SELECT id, ownerId FROM Account where (Stage_acm__c = \'Expansion\' OR Stage_acm__c = \'Retention\')';
        createAutomatedTasks cat = new createAutomatedTasks(query,quarter);
        Database.executeBatch(cat);
        
        // Negative Use case
        createAutomatedTasks cat2 = new createAutomatedTasks(query,2);
        Database.executeBatch(cat2);
        Test.stopTest();
        System.assertEquals(52, [select id from task].size());
    }
}