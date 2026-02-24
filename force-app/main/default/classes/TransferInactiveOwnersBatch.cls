/*
*      @author - Varun Subhash
*      @date - 16-Apr-2024
*      @description - Transfer Accounts with Inactive Owners to their Managers RO-2027
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      Developer                       Date                Description
*      ------------------------------------------------------------------------------------
* 
* 
*/


public class TransferInactiveOwnersBatch implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext BC) {
    
        // QueryLocator allows processing of large data sets by splitting query results into batches
        return Database.getQueryLocator([
            SELECT Id, OwnerId
            FROM Account
            WHERE Owner.IsActive = false
            AND Owner.ManagerId != null
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Account> scope) {
        // Collect OwnerIds to retrieve the Managers in a single SOQL query
        Set<Id> ownerIds = new Set<Id>();
        for (Account acc : scope) {
            ownerIds.add(acc.OwnerId);
        }

        // Retrieve active Managers in a single query
        
        Map<Id, Id> activeManagers = new Map<Id, Id>();
        for(User usr: [SELECT Id, ManagerId FROM User
                         WHERE Id IN :ownerIds])
                         {
                            activeManagers.put(Usr.Id, usr.ManagerId);
                         }

        // Prepare the list of Accounts to update
        List<Account> accountsToUpdate = new List<Account>();
        for (Account acc : scope) {
            // Update Account Owner to the Manager if the Manager is active
            if (activeManagers.get(acc.OwnerId) != null) {
                acc.OwnerId = activeManagers.get(acc.OwnerId);
                accountsToUpdate.add(acc);
            }
        }

        // Perform the update 
        if (!accountsToUpdate.isEmpty()) {
            Database.SaveResult[] updateResults = Database.update(accountsToUpdate, false);
            // Handle partial update success and log errors
            for (Database.SaveResult sr : updateResults) {
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Failed to update Account with ID: ' + sr.getId() + ' - ' + err.getStatusCode() + ': ' + err.getMessage());
                        
                    }
                }
            }
            
            Logger.saveLog();
        }
    }

    public void finish(Database.BatchableContext BC) {
        
    }
}