/*
*      @author Arun Kumar
*      @date   09-Jun-2025
*      @description  
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      Developer                       Date                Description
*      ------------------------------------------------------------------------------------
*      
* 
*/

public class batchOldJobCleanup implements Database.Batchable<SObject>, Database.Stateful {
    private Integer inactivePeriod;
    private Integer totalJobs;
    private Integer jobsEligibleForDeletion;
    private Integer jobsWithoutPublishedAt;
    private Integer jobsPublishedBefore30Days;
    private Integer jobsPublishedBefore30DaysWithOldUpdate;
    private Integer jobsPublishedBefore30DaysWithRecentUpdate;
    private Integer jobsPublishedBefore30DaysWithEmptyUpdate;
    private Integer jobsPublishedLast30Days;
    private Integer jobsPublishedLast30DaysWithUpdate;
    private Integer jobsPublishedLast30DaysWithoutUpdate;
    private Integer jobsWithoutPublishedAndUpdated;
    private Integer jobsNeverUpdated;
    
    // Helper for percentage calculation
    private static String pct(Integer part, Integer total) {
        if (total == 0) return '0.00';
        Decimal percent = ((Decimal) part / total) * 100;
        return String.valueOf(percent.setScale(2));
    }
    
    public batchOldJobCleanup() {
        inactivePeriod = Integer.valueOf(Label.Inactive_Period_Days);
    }
    
    public Database.QueryLocator start(Database.BatchableContext context) {
        Date cutoff = Date.today().addDays(-inactivePeriod);
        
        // BEFORE DELETION metrics
        totalJobs = [SELECT COUNT() FROM Job__c];
        jobsWithoutPublishedAt = [SELECT COUNT() FROM Job__c WHERE Published_At__c = NULL];
        jobsPublishedBefore30Days = [SELECT COUNT() FROM Job__c WHERE Published_At__c < :cutoff];
        jobsPublishedBefore30DaysWithOldUpdate = [SELECT COUNT() FROM Job__c WHERE Published_At__c < :cutoff AND Last_Updated_On__c < :cutoff];
        jobsPublishedBefore30DaysWithRecentUpdate = [SELECT COUNT() FROM Job__c WHERE Published_At__c < :cutoff AND Last_Updated_On__c >= :cutoff];
        jobsPublishedBefore30DaysWithEmptyUpdate = [SELECT COUNT() FROM Job__c WHERE Published_At__c < :cutoff AND Last_Updated_On__c = NULL];
        jobsPublishedLast30Days = [SELECT COUNT() FROM Job__c WHERE Published_At__c >= :cutoff];
        jobsPublishedLast30DaysWithUpdate = [SELECT COUNT() FROM Job__c WHERE Published_At__c >= :cutoff AND Last_Updated_On__c != NULL];
        jobsPublishedLast30DaysWithoutUpdate = [SELECT COUNT() FROM Job__c WHERE Published_At__c >= :cutoff AND Last_Updated_On__c = NULL];
        jobsWithoutPublishedAndUpdated = [SELECT COUNT() FROM Job__c WHERE Published_At__c = NULL AND Last_Updated_On__c = NULL];
        jobsNeverUpdated = [SELECT COUNT() FROM Job__c WHERE Last_Updated_On__c = NULL];
        jobsEligibleForDeletion = [SELECT COUNT() FROM Job__c WHERE Published_At__c < :cutoff AND (Last_Updated_On__c < :cutoff OR Last_Updated_On__c = NULL)];
        
        // Query for records eligible for deletion
        return Database.getQueryLocator([
            SELECT Id FROM Job__c
            WHERE Published_At__c < :cutoff
            AND (Last_Updated_On__c < :cutoff OR Last_Updated_On__c = NULL)
        ]);
    }
    
    public void execute(Database.BatchableContext context, List<Job__c> scope) {
        
        // Attempt to delete records with partial success allowed
        Database.DeleteResult[] resultsJobs = Database.delete(scope, false);
        
        // Log errors if any
        for (Database.DeleteResult dr : resultsJobs) {
            if (!dr.isSuccess()) {
                for (Database.Error err : dr.getErrors()) {
                    System.debug(LoggingLevel.ERROR, 'Failed to delete Job with ID: ' + dr.getId() + '. The error occurred: ' + err.getStatusCode() + ' - ' + err.getMessage());
                }
            }
        }    
        Logger.saveLog();
    }
    
    public void finish(Database.BatchableContext context) {
        Date cutoff = Date.today().addDays(-inactivePeriod);
        
        // AFTER DELETION metrics
        Integer currentJobs = [SELECT COUNT() FROM Job__c];
        Integer jobsWithAccountsAndRecruiters = [SELECT COUNT() FROM Job__c WHERE Account__c != NULL AND Recruiter__c != NULL AND (Published_At__c >= :cutoff OR Last_Updated_On__c >= :cutoff)];
        Integer jobsWithAccountsWithoutRecruiters = [SELECT COUNT() FROM Job__c WHERE Account__c != NULL AND Recruiter__c = NULL AND (Published_At__c >= :cutoff OR Last_Updated_On__c >= :cutoff)];
        Integer jobsWithoutAccountsWithRecruiters = [SELECT COUNT() FROM Job__c WHERE Account__c = NULL AND Recruiter__c != NULL AND (Published_At__c >= :cutoff OR Last_Updated_On__c >= :cutoff)];
        Integer jobsWithoutAccountsAndRecruiters = [SELECT COUNT() FROM Job__c WHERE Account__c = NULL AND Recruiter__c = NULL AND (Published_At__c >= :cutoff OR Last_Updated_On__c >= :cutoff)];
        
        // Prepare email content
        String emailBody = '--- Job Cleanup Metrics ---\\n\\n';
        emailBody += 'BEFORE DELETION:\\n';
        emailBody += 'Total Jobs in the System: ' + totalJobs + ' (100%)\\n';
        emailBody += 'Jobs Without Published_At__c: ' + jobsWithoutPublishedAt + ' (' + pct(jobsWithoutPublishedAt, totalJobs) + '%)\\n';
        emailBody += 'Jobs Published Before 30 Days: ' + jobsPublishedBefore30Days + ' (' + pct(jobsPublishedBefore30Days, totalJobs) + '%)\\n';
        emailBody += '  - With Old Updates: ' + jobsPublishedBefore30DaysWithOldUpdate + ' (' + pct(jobsPublishedBefore30DaysWithOldUpdate, totalJobs) + '%)\\n';
        emailBody += '  - With Recent Updates: ' + jobsPublishedBefore30DaysWithRecentUpdate + ' (' + pct(jobsPublishedBefore30DaysWithRecentUpdate, totalJobs) + '%)\\n';
        emailBody += '  - With No Updates: ' + jobsPublishedBefore30DaysWithEmptyUpdate + ' (' + pct(jobsPublishedBefore30DaysWithEmptyUpdate, totalJobs) + '%)\\n';
        emailBody += 'Jobs Published in the Last 30 Days: ' + jobsPublishedLast30Days + ' (' + pct(jobsPublishedLast30Days, totalJobs) + '%)\\n';
        emailBody += '  - With Updates: ' + jobsPublishedLast30DaysWithUpdate + ' (' + pct(jobsPublishedLast30DaysWithUpdate, totalJobs) + '%)\\n';
        emailBody += '  - Without Updates: ' + jobsPublishedLast30DaysWithoutUpdate + ' (' + pct(jobsPublishedLast30DaysWithoutUpdate, totalJobs) + '%)\\n';
        emailBody += 'Jobs Without Both Published_At__c and Last_Updated_On__c: ' + jobsWithoutPublishedAndUpdated + ' (' + pct(jobsWithoutPublishedAndUpdated, totalJobs) + '%)\\n';
        emailBody += 'Jobs That Have Never Been Updated: ' + jobsNeverUpdated + ' (' + pct(jobsNeverUpdated, totalJobs) + '%)\\n';
        emailBody += 'Jobs Eligible for Deletion: ' + jobsEligibleForDeletion + ' (' + pct(jobsEligibleForDeletion, totalJobs) + '%)\\n\\n';
        
        emailBody += 'AFTER DELETION:\\n';
        emailBody += 'Current Jobs in the System: ' + currentJobs + ' (100%)\\n';
        emailBody += 'Jobs with Accounts and Recruiters: ' + jobsWithAccountsAndRecruiters + ' (' + pct(jobsWithAccountsAndRecruiters, currentJobs) + '%)\\n';
        emailBody += 'Jobs with Accounts but without Recruiters: ' + jobsWithAccountsWithoutRecruiters + ' (' + pct(jobsWithAccountsWithoutRecruiters, currentJobs) + '%)\\n';
        emailBody += 'Jobs without Accounts but with Recruiters: ' + jobsWithoutAccountsWithRecruiters + ' (' + pct(jobsWithoutAccountsWithRecruiters, currentJobs) + '%)\\n';
        emailBody += 'Jobs without Accounts and without Recruiters: ' + jobsWithoutAccountsAndRecruiters + ' (' + pct(jobsWithoutAccountsAndRecruiters, currentJobs) + '%)\\n';
        
        // Send email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(Label.JobCleanupEmailRecipients.split(','));
        email.setSubject('Daily Job Cleanup Metrics');
        email.setPlainTextBody(emailBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
}