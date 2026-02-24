/*
*      @author Arun Kumar
*      @date   21-Dec-2023
*      @description   Class to streamline the Account Trigger logic
*
*      Modification Log:
*      ------------------------------------------------------------------------------------
*      	Developer                       Date                Description
       	Varun Subhash                   20-02-2024          RO - 1973
		Lisa Müller						20-02-2025			Removed createContacts method to enable field deletion
		Lisa Müller						25-04-2025			RO-2473 added afterUpdate method & deactivated afterInsert since nothing triggered right now
*      ------------------------------------------------------------------------------------
*  
*/
public class AccountTriggerHandler implements TriggerAction.BeforeInsert, TriggerAction.BeforeUpdate, TriggerAction.AfterUpdate{
    
     /**
@Methodname     : beforeInsert
@Param          : List<Account>
@Return         : Null
@Description    : To initiate the logic to perform before inserting account
**/
    public void beforeInsert(List<Account> triggerNew){
       // AccountTriggerFunction.updateSegmentation(triggerNew); 
        AccountTriggerFunction.heyJobsCategoryOnInsert(triggerNew);
        AccountTriggerFunction.validateUmbrellaCompany(triggerNew);
    }
    
 /**
@Methodname     : beforeUpdate
@Param          : List<Account>, List<Account>
@Return         : Null
@Description    : To initiate the logic to perform before updating account
**/
    public void beforeUpdate(List<Account> triggerNew, List<Account> triggerOld){  
        AccountTriggerFunction.heyJobsCategoryOnUpdate(triggerNew, triggerOld);
        AccountTriggerFunction.validateUmbrellaCompany(triggerNew);
    } 
    
 /**
@Methodname     : afterInsert
@Param          : List<Account>
@Return         : Null
@Description    : To initiate the logic to perform after inserting account
**/
    //public void afterInsert(List<Account> triggerNew){

    //}

/**
@Methodname     : afterUpdate
@Param          : List<Account>, List<Account>
@Return         : Null
@Description    : To initiate the logic to perform after updating account
**/
    public void afterUpdate(List<Account> triggerNew, List<Account> triggerOld){
        Customer360Functions.createHelperRecords(triggerNew, triggerOld);
       
    } 
    
}