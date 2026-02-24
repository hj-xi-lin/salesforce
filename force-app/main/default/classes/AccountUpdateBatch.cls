global class AccountUpdateBatch implements Database.Batchable<sObject>
{
	global Database.QueryLocator start(Database.BatchableContext BC)
	{
        string RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Discarded').getRecordTypeId();

        String query = 'SELECT Id,No_repeat_purchase_typeform__c from Account where (Stage_ACM__c = \'Prospect\' OR Stage_ACM__c = \'Lost\') AND Segment_V02__c = \'Small\' AND No_repeat_purchase_typeform__c = False And recordtypeId != :RecordTypeId AND Blacklist__c = False';
        system.debug('query::'+query);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Account> accountList)
    {
        list<account> accountUpdateList = new list<account>();
        for ( account acc : accountList)
        {
            account accUpdate = new account();
            accUpdate.id = acc.id;
           accUpdate.No_repeat_purchase_typeform__c = true;
           accountUpdateList.add(accUpdate); 
        }
        database.update(accountUpdateList);
    }  
    global void finish(Database.BatchableContext BC)
    {
    }
}