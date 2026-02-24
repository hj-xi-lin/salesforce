/*
*      @author 			Lisa Müller
*      @date   			Apr-2025
*      @description   	Class to handle asynchronous updates for Account records (RO-2473)
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      Developer		Date                Description
*      ------------------------------------------------------------------------------------			
*/

public class AccountSummaryHelper {
    @future
    public static void updateAccounts(Set<Id> accountIds) {
        List<Account> accountsToUpdate = [SELECT Id, AI_Summary_Helper__c FROM Account WHERE Id IN :accountIds];
        for (Account acc : accountsToUpdate) {
            acc.AI_Summary_Helper__c = 'Generate Summary';
        }
        update accountsToUpdate;
    }
}