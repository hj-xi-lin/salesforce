@isTest
public class Test_AccountTriggerFunction {
     
     /**
    @Methodname     : test_accountTrigger
    @Param          : Null
    @Return         : Null
    @Description    : Tests "AccountTriggerFunction" methods - updateSegmentation, heyJobsCategoryOnInsert
    **/
    @isTest static void test_accountTrigger(){
        
        List<Account> accountList = new List<Account>();
        
        Account acc = new Account(
            Name ='Foo',
            NumberOfEmployees = 2500,
            Service_Country__c = 'DE',
            Category_1__c = 'Service Provider',
            Category_2__c = 'Health',
            Category_3__c = 'Medical Services');
        accountList.add(acc);
        
        Test.StartTest();
        insert accountList;
        Test.StopTest();
    }
    
    /**
    @Methodname     : test_
    @Param          : Null
    @Return         : Null
    @Description    : Tests the "AccountTriggerFunction" method - heyJobsCategoryOnUpdate
    **/
    
    
    @isTest static void test_validateUmbrellaCompany(){
        
        Account acc = new Account(
            Name ='Glucklich GmbH',
            NumberOfEmployees = 2500,
            Service_Country__c = 'DE',
            Category_1__c = 'Service Provider',
            Category_2__c = 'Health',
            Category_3__c = 'Medical Services');
         insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'test',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales').getRecordTypeId(),
            AccountId = acc.Id,
            StageName = 'Qualified Prospect',
            CloseDate = Date.today() + 180);
        insert opp;
        
        Test.StartTest();
        Account accToEdit = [SELECT Id,Category_3__c FROM Account LIMIT 1];
        accToEdit.Umbrella_Company__c = TRUE;
        
        try {
            update accToEdit;
            Assert.fail('DmlException expected');
        } catch (DmlException e) {
            Assert.isTrue(e.getMessage().contains('Umbrella Company'));
        }
        Test.StopTest();
    }
}