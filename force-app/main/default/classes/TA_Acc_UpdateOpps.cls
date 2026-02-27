public with sharing class TA_Acc_UpdateOpps implements TriggerAction.AfterUpdate {
	public void afterUpdate(List<Account> newList, List<Account> oldList) {
		update [SELECT Id FROM Opportunity WHERE AccountId IN :newList];
	}
}