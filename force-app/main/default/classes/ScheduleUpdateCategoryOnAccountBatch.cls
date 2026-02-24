public class ScheduleUpdateCategoryOnAccountBatch implements schedulable {
    public void execute(SchedulableContext sc) {
        String query = 'SELECT Id, name, Category_3__c, HeyJobs_Category__c, X2020_Reference_Clients__c, isUpdateThroughCategorybatch__c, recordtype.name FROM Account WHERE CreatedDate = YESTERDAY OR LastModifiedDate = YESTERDAY OR isUpdateThroughCategorybatch__c = True';
        Database.executeBatch(new UpdateCategoryOnAccountBatch(query));
    }
}