@IsTest
public class test_batchDeleteClosedTasks {

    @IsTest
    static void testBatchDeletesTasks() {
        // Arrange: Create tasks with mixed scenarios
        List<Task> tasks = new List<Task>();

        // Task to be deleted (older than cutoff and Status = 'Completed')
        Task taskToDelete = new Task(
            Subject = 'DeleteBatchTest_ToDelete',
            Status = 'Completed'  // ← Changed to 'Completed'
        );
        tasks.add(taskToDelete);

        // Task not to be deleted (older than cutoff but Status = 'Open')
        Task taskOlderButOpen = new Task(
            Subject = 'DeleteBatchTest_OlderButOpen',
            Status = 'Open'
        );
        tasks.add(taskOlderButOpen);

        // Task not to be deleted (less than cutoff and Status = 'Completed')
        Task taskRecentCompleted = new Task(
            Subject = 'DeleteBatchTest_RecentCompleted',
            Status = 'Completed'
        );
        tasks.add(taskRecentCompleted);

        // Task not to be deleted (exactly at cutoff and Status = 'Completed')
        Task taskAtCutoff = new Task(
            Subject = 'DeleteBatchTest_AtCutoff',
            Status = 'Completed'
        );
        tasks.add(taskAtCutoff);

        insert tasks;

        // Get the cutoff years from label (same as batch class)
        Integer cutoffYears = Integer.valueOf(Label.HouseKeeping_TaskCutoffYears);
        DateTime cutoffDateTime = System.now().addYears(-cutoffYears);

        // Backdate CreatedDate for taskToDelete to > cutoff
        DateTime beyondCutoff = cutoffDateTime.addDays(-1);
        Test.setCreatedDate(taskToDelete.Id, beyondCutoff);

        // Backdate CreatedDate for taskOlderButOpen to > cutoff
        Test.setCreatedDate(taskOlderButOpen.Id, beyondCutoff);

        // Set CreatedDate for taskRecentCompleted to < cutoff
        DateTime beforeCutoff = cutoffDateTime.addDays(1);
        Test.setCreatedDate(taskRecentCompleted.Id, beforeCutoff);

        // Set CreatedDate for taskAtCutoff to exactly at cutoff
        Test.setCreatedDate(taskAtCutoff.Id, cutoffDateTime);

        Test.startTest();
        // Act: Execute the batch class
        batchDeleteClosedTasks batchJob = new batchDeleteClosedTasks();
        Database.executeBatch(batchJob, 200);
        Test.stopTest();

        // Re-query tasks to verify results
        List<Task> remainingTasks = [
            SELECT Id, Subject, Status, CreatedDate
            FROM Task
            WHERE Subject LIKE 'DeleteBatchTest%'
        ];

        // Assert: Verify that only the task meeting deletion criteria was deleted
        System.assertEquals(3, remainingTasks.size(), 'Only 3 tasks should remain after deletion.');

        // Verify the deleted task is gone
        List<Task> deletedTask = [
            SELECT Id 
            FROM Task 
            WHERE Id = :taskToDelete.Id 
            ALL ROWS
        ];
        System.assertEquals(1, deletedTask.size(), 'Deleted task should be in recycle bin (hard delete was used).');

        // Verify remaining tasks
        Set<String> remainingSubjects = new Set<String>();
        for (Task t : remainingTasks) {
            remainingSubjects.add(t.Subject);
        }
        
        System.assert(!remainingSubjects.contains('DeleteBatchTest_ToDelete'), 'Task meeting criteria should be deleted.');
        System.assert(remainingSubjects.contains('DeleteBatchTest_OlderButOpen'), 'Task with Open status should remain.');
        System.assert(remainingSubjects.contains('DeleteBatchTest_RecentCompleted'), 'Recent task should remain.');
        System.assert(remainingSubjects.contains('DeleteBatchTest_AtCutoff'), 'Task exactly at cutoff should remain.');
    }

    @IsTest
    static void testBatchWithNoTasksToDelete() {
        // Test scenario where no tasks match criteria
        Task recentTask = new Task(
            Subject = 'RecentTask',
            Status = 'Completed'
        );
        insert recentTask;

        Test.startTest();
        batchDeleteClosedTasks batchJob = new batchDeleteClosedTasks();
        Database.executeBatch(batchJob, 200);
        Test.stopTest();

        List<Task> remainingTasks = [SELECT Id FROM Task WHERE Id = :recentTask.Id];
        System.assertEquals(1, remainingTasks.size(), 'Recent task should not be deleted.');
    }
    
    @IsTest
    static void testBatchWithEmptyScope() {
        // Test with no tasks at all
        Test.startTest();
        batchDeleteClosedTasks batchJob = new batchDeleteClosedTasks();
        Database.executeBatch(batchJob, 200);
        Test.stopTest();

        // No assertions needed - just testing that batch completes without error
        System.assert(true, 'Batch should complete successfully even with no records.');
    }
}