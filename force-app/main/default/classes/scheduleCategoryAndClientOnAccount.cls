/*
 *      @author Arun Kumar
 *      @date   29-Aug-2023
 *      @description   Apex class to schedule the category and reference clients logic
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 *      
 * 
 */
global class scheduleCategoryAndClientOnAccount implements Schedulable  {
    global void execute(SchedulableContext sc) {
       batchCategoryAndClientOnAccount batch = new batchCategoryAndClientOnAccount();
       Database.executeBatch(batch);
    }
}