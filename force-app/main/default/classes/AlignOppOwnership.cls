/*
*      @author Lisa Müller
*      @date   02-Jan-2024
*      @description   Logic to align opp and account ownership RO-1623
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      Developer                       Date                Description
*      ------------------------------------------------------------------------------------
* 
* 
*/

public class AlignOppOwnership implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        
   	 	// Check for record limit
        Feature_Activation__mdt fa = Feature_Activation__mdt.getInstance('LimitOwnershipAlignmentBatchSize');
        Boolean isActive = (Boolean)fa.get('Is_Active__c');
        
        String query;
        if(isActive){
            // Fetch limit from custom label
        	Integer batchSize = Integer.valueOf(Label.LIMIT_OwnershipAlignmentAutomation);
       	 	query = 'SELECT Id, OwnerId, Account.OwnerId FROM Opportunity WHERE AccountId != NULL AND Account_Owner_Aligned__c = false AND IsClosed = false LIMIT ' + batchSize;
        }
        
        else{
           	query = 'SELECT Id, OwnerId, Account.OwnerId FROM Opportunity WHERE AccountId != NULL AND Account_Owner_Aligned__c = false AND IsClosed = false';
        }
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Opportunity> opps){
        // Get active user IDs
        Map<Id, User> activeUsers = new Map<Id, User>([SELECT Id FROM User WHERE IsActive = true]);
        
        // update owner to account owner
        for (Opportunity opp : opps){
            // check if the account owner is an active user
            if(activeUsers.containsKey(opp.Account.OwnerId)){
            	opp.OwnerId = opp.Account.OwnerId;    
            }
        }
        
      	Database.SaveResult[] results = Database.update(opps, false);
        
        // Log errors
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
            	for(Database.Error err : sr.getErrors()) {
                	Logger.finest('Failed to update Opportunity with ID: ' + sr.getId() + '. The error occurred: ' + err.getStatusCode() + ' - ' + err.getMessage());
            		}
        		}
    		}		
    	Logger.saveLog();
        
    }
    
    public void finish(Database.BatchableContext BC){
        }

}