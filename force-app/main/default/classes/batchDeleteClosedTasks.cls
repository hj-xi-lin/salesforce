/*
*      @author       Varun Subhash
*      @date         Sept-2025
*      @description  Batch class to delete tasks older than 2 years(RO-2616)
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      Developer    Date                Description
*      ------------------------------------------------------------------------------------      
*/


public class batchDeleteClosedTasks implements Database.Batchable<sObject> {

    private static final Boolean USE_HARD_DELETE;
    private static final Integer CUTOFF_YEARS;
    private static final DateTime CUTOFF_DATETIME;

    // Static block for initializing constants
    static {
        USE_HARD_DELETE = true;
        CUTOFF_YEARS = Integer.valueOf(Label.HouseKeeping_TaskCutoffYears);
        CUTOFF_DATETIME = System.now().addYears(-CUTOFF_YEARS);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Log the start of the batch process
        Logger.info('Starting batchDeleteClosedTasks with cutoff=' + CUTOFF_DATETIME + ', hardDelete=' + USE_HARD_DELETE);
        return Database.getQueryLocator([
            SELECT Id
            FROM Task
            WHERE CreatedDate < :CUTOFF_DATETIME
            AND Status = 'Completed'
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Task> taskList) {
        if (taskList.isEmpty()) return;

        // Log the size of the current scope
        Logger.info('Executing batchDeleteClosedTasks with scope size=' + taskList.size());

        // Partial success handling
        Database.DeleteResult[] results = Database.delete(taskList, USE_HARD_DELETE);

        // Track results using Nebula Logger
        Integer successCount = 0;
        Integer errorCount = 0;

        for (Database.DeleteResult dr : results) {
            if (dr.isSuccess()) {
                successCount++;
            } else {
                errorCount++;
                for (Database.Error err : dr.getErrors()) {
                    Logger.error('Failed to delete Task with ID: ' + dr.getId() + 
                                 '. Error: ' + err.getStatusCode() + ' - ' + err.getMessage());
                }
            }
        }

        // Log success and error counts for the current scope
        Logger.info('Batch scope processed. Successes=' + successCount + ', Errors=' + errorCount);

        // Save the log for this execution
        Logger.saveLog();
    }

    public void finish(Database.BatchableContext bc) {
        
        // Log the completion of the batch process
        Logger.info('Finished batchDeleteClosedTasks. Check logs for detailed results.');
        Logger.saveLog();
    }
}