global class ScheduleCreateAutomatedTasks implements Schedulable {
    global void execute(SchedulableContext sc) {
        Integer quarter = math.round((Date.today().month()+1)/3.0);
        //String query = 'SELECT id, ownerId, Potential__c FROM Account where Segment__c = \'SMB\' AND (Potential__c = \'Question Marks\' OR Potential__c = \'Cash Cows\' OR Potential__c = \'Stars\') AND (Stage_acm__c = \'Expansion\' OR Stage_acm__c = \'Retention\')';
        String query = 'SELECT id, ownerId FROM Account where Segment_V02__c = \'Small\' AND (Stage_acm__c = \'Expansion\' OR Stage_acm__c = \'Retention\')';
        createAutomatedTasks cat = new createAutomatedTasks(query,quarter);
        Database.executeBatch(cat);
    }
}