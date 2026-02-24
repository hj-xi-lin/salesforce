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

@isTest
private class Test_TransferInactiveOwnersBatch {

    @isTest
    static void testTransferAccountsToManagers() {
        // Initialize test data variables
        User inactiveOwner;
        User manager;
        List<Account> accounts;

        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Create test data
            Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Large Prospector' LIMIT 1];
            
            // Create the manager user
            manager = new User(
                FirstName = 'Manager',
                LastName = 'User',
                IsActive = true,
                Username = 'manageruser@heyjobs.co',
                Email = 'manageruser@heyjobs.co',
                Alias = 'mgr',
                TimeZoneSidKey = 'Europe/Berlin',
                LocaleSidKey = 'de_DE',
                EmailEncodingKey = 'UTF-8',
                ProfileId = standardProfile.Id,
                LanguageLocaleKey = 'de'
            );
            insert manager;

            // Then create the inactive user with the above manager as their manager
            inactiveOwner = new User(
                FirstName = 'Inactive',
                LastName = 'Owner',
                IsActive = true,
                Username = 'testuser@heyjobs.co',
                Email = 'testuser@heyjobs.co',
                Alias = 'inact',
                TimeZoneSidKey = 'Europe/Berlin',
                LocaleSidKey = 'de_DE',
                EmailEncodingKey = 'UTF-8',
                ProfileId = standardProfile.Id,
                LanguageLocaleKey = 'de',
                ManagerId = manager.Id 
            );
            insert inactiveOwner;
        }

        // Create Account records 
        accounts = new List<Account>{
            new Account(Name = 'Test Account 1', OwnerId = inactiveOwner.Id),
            new Account(Name = 'Test Account 2', OwnerId = inactiveOwner.Id)
        };
        insert accounts;

        // Deactivate the inactive owner 
        System.runAs(new User(Id = UserInfo.getUserId())) {
            inactiveOwner.IsActive = false;
            update inactiveOwner;
        }

        // Execute the batch job
        Test.startTest();
        Database.executeBatch(new TransferInactiveOwnersBatch());
        Test.stopTest();

        // Refresh the account records from the database after batch execution
        accounts = [SELECT OwnerId FROM Account WHERE Id IN :accounts];
        
        // Verify that the OwnerId of the accounts is updated to the ManagerId of the inactive owner
        for (Account acc : accounts) {
            System.assertEquals(manager.Id, acc.OwnerId, 'The Account owner should be updated to the manager.');
        }
    }
}