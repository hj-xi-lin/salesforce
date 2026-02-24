global class scheduleDeleteClosedTasks implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Schedule the batch job
        batchDeleteClosedTasks batchJob = new batchDeleteClosedTasks();
        Database.executeBatch(batchJob); 
    }
}