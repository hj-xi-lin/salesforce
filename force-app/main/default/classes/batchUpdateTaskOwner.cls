/*
 *      @author Arun Kumar
 *      @date   24-Mar-2023
 *      @description   Batch class to update task ownership
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 *      
 * 
 */
global class batchUpdateTaskOwner implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT Id, Status, OwnerId, Is_Owner_changed__c, Account.OwnerId FROM Task WHERE Is_Owner_changed__c = True AND (Status = \'Open\' OR Status = \'In Progress\')';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Task> taskList){
		
        List<Task> taskToUpdateList = new List<Task>();
        
        if(!taskList.isEmpty()){
            for(task tk : taskList){
                if(tk.OwnerId != tk.Account.OwnerId){
                    tk.OwnerId = tk.Account.OwnerId;
                    tk.Is_Owner_changed__c = false;
                    taskToUpdateList.add(tk);
                }
            }
            
            if(!taskToUpdateList.isEmpty()){
                try{
                    update taskToUpdateList;
                }catch(Exception e){
                    System.debug('Error occured while updating task owner: '+e.getMessage());
                }
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
    }
}