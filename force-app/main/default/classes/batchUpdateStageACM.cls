global class batchUpdateStageACM implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext bc){
        //String query = 'SELECT NumberOfEmployees, Segment_V02__c FROM Account WHERE Segment_V02__c = NULL';
        String query = 'SELECT AccountId FROM Opportunity WHERE StageName = \'Closed Lost\' AND Timestamp_Reactivation__c <> NULL AND Timestamp_Reactivation__c = TODAY AND Account.Stage_ACM__c = \'Lost\'';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> oppList){

        if(!oppList.isEmpty()){
            List<Account> accList = UtilityFunctions.updateStageACMOnReactivation(oppList);
            update accList;
        }
    }

    global void finish(Database.BatchableContext bc) {
    }
}